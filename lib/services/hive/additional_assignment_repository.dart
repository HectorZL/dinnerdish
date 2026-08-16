import 'dart:async';

import 'package:dinnerhome/exceptions/validation_exception.dart';
import 'package:dinnerhome/models/menu_additional_assignment.dart';
import 'package:dinnerhome/models/special_additional.dart';
import 'package:hive/hive.dart';

/// Persists menu-to-additional relationships as one validated JSON collection.
///
/// The repository knows only relationship storage. Existence and ownership
/// checks are supplied by the application layer so loading a bad relationship
/// can recover without deleting valid dishes or catalog definitions.
class AdditionalAssignmentRepository {
  static const storageKey = 'menu_additional_assignments_v1';
  static const settingsBoxName = 'settings';

  final Box<dynamic>? _providedSettingsBox;
  final Set<String>? _validMenuItemIds;
  final Set<String>? _validGlobalAdditionalIds;
  final Set<String>? _validSpecialAdditionalIds;
  final FutureOr<bool> Function(String menuItemId)? _menuItemExists;
  final FutureOr<bool> Function(String additionalId)? _globalAdditionalExists;
  final FutureOr<bool> Function(String specialId)? _specialAdditionalExists;
  final FutureOr<SpecialAdditional?> Function(String specialId)?
  _specialAdditionalById;
  final void Function(Object error)? _onRecoverableError;
  final List<MenuAdditionalAssignment> _memoryAssignments =
      <MenuAdditionalAssignment>[];

  AdditionalAssignmentRepository({
    Box<dynamic>? settingsBox,
    Box<dynamic>? box,
    Iterable<String>? validMenuItemIds,
    Iterable<String>? validGlobalAdditionalIds,
    Iterable<String>? validSpecialAdditionalIds,
    FutureOr<bool> Function(String menuItemId)? menuItemExists,
    FutureOr<bool> Function(String additionalId)? globalAdditionalExists,
    FutureOr<bool> Function(String specialId)? specialAdditionalExists,
    FutureOr<SpecialAdditional?> Function(String specialId)?
    specialAdditionalById,
    void Function(Object error)? onRecoverableError,
  }) : _providedSettingsBox = settingsBox ?? box,
       _validMenuItemIds = validMenuItemIds?.toSet(),
       _validGlobalAdditionalIds = validGlobalAdditionalIds?.toSet(),
       _validSpecialAdditionalIds = validSpecialAdditionalIds?.toSet(),
       _menuItemExists = menuItemExists,
       _globalAdditionalExists = globalAdditionalExists,
       _specialAdditionalExists = specialAdditionalExists,
       _specialAdditionalById = specialAdditionalById,
       _onRecoverableError = onRecoverableError;

  Box<dynamic>? get _settingsBox {
    if (_providedSettingsBox != null) return _providedSettingsBox;
    if (Hive.isBoxOpen(settingsBoxName)) {
      return Hive.box<dynamic>(settingsBoxName);
    }
    return null;
  }

  /// Reads valid relationships and skips corrupt, orphaned, or duplicate rows.
  /// A missing key is interpreted as an empty collection.
  Future<List<MenuAdditionalAssignment>> readAll() async {
    final raw = _settingsBox?.get(storageKey) ?? _memoryAssignments;
    if (raw == null) return const <MenuAdditionalAssignment>[];
    if (raw is! List) {
      _report(FormatException('$storageKey no contiene una lista válida.'));
      return const <MenuAdditionalAssignment>[];
    }

    final valid = <MenuAdditionalAssignment>[];
    final logicalKeys = <AdditionalAssignmentKey>{};
    final ids = <String>{};
    for (final value in raw) {
      try {
        if (value is! Map) {
          throw const FormatException('Registro de asignación inválido.');
        }
        final assignment = MenuAdditionalAssignment.fromJson(
          Map<String, dynamic>.from(value),
        );
        if (!await _referencesExist(assignment)) {
          _report(
            InvalidAssignmentException(
              'Se omitió la asignación huérfana ${assignment.id}.',
            ),
          );
          continue;
        }
        if (!logicalKeys.add(assignment.logicalKey) ||
            !ids.add(assignment.id)) {
          _report(
            InvalidAssignmentException(
              'Se omitió la asignación duplicada ${assignment.id}.',
            ),
          );
          continue;
        }
        valid.add(assignment);
      } catch (error) {
        _report(error);
      }
    }
    return List<MenuAdditionalAssignment>.unmodifiable(valid);
  }

  Future<List<MenuAdditionalAssignment>> fetchAll() => readAll();

  Future<List<MenuAdditionalAssignment>> fetchForMenuItem(
    String menuItemId,
  ) async {
    final assignments = await readAll();
    return List<MenuAdditionalAssignment>.unmodifiable(
      assignments.where((assignment) => assignment.menuItemId == menuItemId),
    );
  }

  Future<Map<String, List<MenuAdditionalAssignment>>> fetchGroupedByMenuItem(
    Iterable<String> menuItemIds,
  ) async {
    final assignments = await readAll();
    final result = <String, List<MenuAdditionalAssignment>>{
      for (final id in menuItemIds) id: <MenuAdditionalAssignment>[],
    };
    for (final assignment in assignments) {
      result
          .putIfAbsent(
            assignment.menuItemId,
            () => <MenuAdditionalAssignment>[],
          )
          .add(assignment);
    }
    return {
      for (final entry in result.entries)
        entry.key: List<MenuAdditionalAssignment>.unmodifiable(entry.value),
    };
  }

  /// Adds one relationship idempotently by logical key.
  Future<MenuAdditionalAssignment> assign(
    MenuAdditionalAssignment assignment,
  ) async {
    final assignments = await readAll();
    final existing = assignments.where(
      (candidate) => candidate.logicalKey == assignment.logicalKey,
    );
    if (existing.isNotEmpty) return existing.first;
    await replaceAll([...assignments, assignment]);
    return assignment;
  }

  /// Removes only an assignment belonging to [menuItemId].
  ///
  /// If the id exists for another dish, the request is rejected before any
  /// write. This prevents a malformed relationship from deleting a valid row.
  Future<void> remove(String menuItemId, String assignmentId) async {
    final assignments = await readAll();
    final byId = assignments.where(
      (assignment) => assignment.id == assignmentId,
    );
    if (byId.isEmpty) return;
    final assignment = byId.first;
    if (assignment.menuItemId != menuItemId) {
      throw InvalidAssignmentException(
        'La asignación no pertenece al Plato indicado.',
      );
    }
    await replaceAll(
      assignments.where((candidate) => candidate.id != assignmentId),
    );
  }

  Future<void> removeForMenuItem(String menuItemId, String assignmentId) =>
      remove(menuItemId, assignmentId);

  Future<void> replaceAll(
    Iterable<MenuAdditionalAssignment> assignments,
  ) async {
    final candidate = List<MenuAdditionalAssignment>.unmodifiable(assignments);
    await _validateCandidate(candidate);
    final payload = candidate
        .map((assignment) => assignment.toJson())
        .toList(growable: false);
    final box = _settingsBox;
    if (box != null) {
      // One put replaces the complete collection. A failed put does not update
      // the repository's in-memory projection or publish a partial list.
      await box.put(storageKey, payload);
    } else {
      _memoryAssignments
        ..clear()
        ..addAll(candidate);
    }
  }

  Future<void> writeAll(Iterable<MenuAdditionalAssignment> assignments) =>
      replaceAll(assignments);

  Future<void> saveAll(Iterable<MenuAdditionalAssignment> assignments) =>
      replaceAll(assignments);

  Future<void> removeAllForGlobal(String additionalId) async {
    final assignments = await readAll();
    final candidate = assignments.where(
      (assignment) =>
          !(assignment.source == AdditionalSource.global &&
              assignment.additionalId == additionalId),
    );
    if (candidate.length != assignments.length) await replaceAll(candidate);
  }

  Future<void> _validateCandidate(
    List<MenuAdditionalAssignment> candidate,
  ) async {
    final logicalKeys = <AdditionalAssignmentKey>{};
    final ids = <String>{};
    for (final assignment in candidate) {
      if (!logicalKeys.add(assignment.logicalKey)) {
        throw InvalidAssignmentException(
          'La asignación de adicional ya existe para ese Plato.',
        );
      }
      if (!ids.add(assignment.id)) {
        throw InvalidAssignmentException(
          'No se puede guardar dos veces la asignación ${assignment.id}.',
        );
      }
      if (!await _referencesExist(assignment)) {
        throw InvalidAssignmentException(
          'La asignación contiene una referencia inexistente.',
        );
      }
    }
  }

  Future<bool> _referencesExist(MenuAdditionalAssignment assignment) async {
    if (!await _exists(
      assignment.menuItemId,
      _validMenuItemIds,
      _menuItemExists,
    )) {
      return false;
    }

    if (assignment.source == AdditionalSource.global) {
      return _exists(
        assignment.additionalId,
        _validGlobalAdditionalIds,
        _globalAdditionalExists,
      );
    }

    if (!await _exists(
      assignment.additionalId,
      _validSpecialAdditionalIds,
      _specialAdditionalExists,
    )) {
      return false;
    }
    final resolver = _specialAdditionalById;
    if (resolver != null) {
      final special = await resolver(assignment.additionalId);
      if (special == null || !special.belongsTo(assignment.menuItemId)) {
        return false;
      }
    }
    return true;
  }

  Future<bool> _exists(
    String id,
    Set<String>? knownIds,
    FutureOr<bool> Function(String id)? callback,
  ) async {
    if (knownIds != null && !knownIds.contains(id)) return false;
    if (callback == null) return true;
    return await callback(id);
  }

  void _report(Object error) {
    _onRecoverableError?.call(error);
  }
}
