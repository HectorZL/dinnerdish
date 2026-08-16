import 'package:dinnerhome/exceptions/validation_exception.dart';
import 'package:dinnerhome/models/global_additional.dart';
import 'package:dinnerhome/services/additional_service.dart';
import 'package:dinnerhome/services/hive/additional_assignment_repository.dart';
import 'package:dinnerhome/validation/menu_validators.dart';
import 'package:hive/hive.dart';

/// Hive-backed catalog of reusable additional definitions.
///
/// The legacy `settings/global_additionals` key remains the source of truth.
/// The value is always a JSON list without stock; relationships are stored in
/// their own collection and are never inferred from modifiers or names.
class HiveAdditionalService implements AdditionalService {
  static const storageKey = 'global_additionals';
  static const settingsBoxName = 'settings';

  final Box<dynamic>? _settingsBox;
  final AdditionalAssignmentRepository? _assignmentRepository;
  final RemoveGlobalAdditionalAssignments? _removeAssignmentsForGlobal;
  final void Function(Object error)? _onRecoverableError;
  final List<GlobalAdditional> _memoryAdditions = List<GlobalAdditional>.from(
    _initialAdditions(),
  );

  HiveAdditionalService({
    Box<dynamic>? settingsBox,
    AdditionalAssignmentRepository? assignmentRepository,
    RemoveGlobalAdditionalAssignments? removeAssignmentsForGlobal,
    void Function(Object error)? onRecoverableError,
  }) : _settingsBox = settingsBox ?? _openSettingsBox(),
       _assignmentRepository = assignmentRepository,
       _removeAssignmentsForGlobal = removeAssignmentsForGlobal,
       _onRecoverableError = onRecoverableError;

  static Box<dynamic>? _openSettingsBox() {
    if (!Hive.isBoxOpen(settingsBoxName)) return null;
    return Hive.box<dynamic>(settingsBoxName);
  }

  static List<GlobalAdditional> _initialAdditions() => const [
    GlobalAdditional(
      id: 'additional-rice',
      name: 'Porción de arroz',
      priceCents: 300,
      available: true,
    ),
    GlobalAdditional(
      id: 'additional-patacones',
      name: 'Porción de patacones',
      priceCents: 400,
      available: true,
    ),
    GlobalAdditional(
      id: 'additional-avocado',
      name: 'Porción de aguacate',
      priceCents: 350,
      available: true,
    ),
    GlobalAdditional(
      id: 'additional-salad',
      name: 'Ensalada adicional',
      priceCents: 450,
      available: true,
    ),
  ];

  @override
  Future<List<GlobalAdditional>> fetchAdditions({
    bool onlyAvailable = false,
  }) async {
    final additions = await _readAdditions();
    final result = onlyAvailable
        ? additions.where((addition) => addition.available).toList()
        : additions.toList();
    result.sort((a, b) => a.name.compareTo(b.name));
    return List.unmodifiable(result);
  }

  @override
  Future<GlobalAdditional?> getAdditional(String id) async {
    final additions = await _readAdditions();
    for (final addition in additions) {
      if (addition.id == id) return addition;
    }
    return null;
  }

  @override
  Future<GlobalAdditional> createAdditional(GlobalAdditional additional) async {
    final created = _normalizeAndValidate(additional);
    final additions = await _readAdditions();
    if (additions.any((item) => item.id == created.id)) {
      throw InvalidAssignmentException(
        'Ya existe un adicional con ese identificador.',
      );
    }
    _ensureUniqueName(created.name, additions);
    await _writeAdditions([...additions, created]);
    return created;
  }

  @override
  Future<GlobalAdditional> updateAdditional(
    String id,
    GlobalAdditional additional,
  ) async {
    final updated = _normalizeAndValidate(additional.copyWith(id: id));
    final additions = await _readAdditions();
    final index = additions.indexWhere((item) => item.id == id);
    if (index == -1) throw GlobalAdditionalNotFoundException(id);
    _ensureUniqueName(updated.name, additions, excludedId: id);
    final candidate = List<GlobalAdditional>.from(additions)..[index] = updated;
    await _writeAdditions(candidate);
    return updated;
  }

  @override
  Future<void> deleteAdditional(String id) async {
    final additions = await _readAdditions();
    if (!additions.any((item) => item.id == id)) {
      throw GlobalAdditionalNotFoundException(id);
    }

    final candidate = additions.where((item) => item.id != id).toList();
    // The catalog definition is removed first. Relationship cleanup is only
    // attempted after that confirmed write, never while the user is still in
    // the confirmation dialog or when the catalog write fails.
    await _writeAdditions(candidate);
    try {
      await _removeAssignments(id);
    } catch (error) {
      // Keep the operation all-or-nothing at service level when a coordinated
      // assignment cleanup fails. A later retry can then repeat the complete
      // deletion without leaving a global missing from the catalog.
      try {
        await _writeAdditions(additions);
      } catch (restoreError) {
        _report(restoreError);
      }
      rethrow;
    }
  }

  Future<void> _removeAssignments(String additionalId) async {
    final callback = _removeAssignmentsForGlobal;
    if (callback != null) {
      await callback(additionalId);
      return;
    }
    final repository = _assignmentRepository;
    if (repository != null) {
      await repository.removeAllForGlobal(additionalId);
      return;
    }

    // Production uses the same settings box for the assignment repository.
    // If no box is open, there is no persisted relationship to cascade.
    final box = _settingsBox;
    if (box != null) {
      await AdditionalAssignmentRepository(
        settingsBox: box,
      ).removeAllForGlobal(additionalId);
    }
  }

  Future<List<GlobalAdditional>> _readAdditions() async {
    final box = _settingsBox;
    if (box == null) {
      final canonical = _canonicalizeForRead(_memoryAdditions);
      _memoryAdditions
        ..clear()
        ..addAll(canonical);
      return List<GlobalAdditional>.from(canonical);
    }

    final stored = box.get(storageKey);
    if (stored == null) {
      final initial = _canonicalizeForRead(_initialAdditions());
      await box.put(storageKey, _jsonPayload(initial));
      return initial;
    }
    if (stored is! List) {
      _report(FormatException('$storageKey no contiene una lista válida.'));
      return const <GlobalAdditional>[];
    }

    final valid = <GlobalAdditional>[];
    final ids = <String>{};
    final names = <String>{};
    for (final value in stored) {
      try {
        if (value is! Map) {
          throw const FormatException('Registro de adicional global inválido.');
        }
        // GlobalAdditional.fromJson deliberately ignores unknown legacy keys,
        // including a historical `stock`, so loading remains compatible while
        // all future writes use the stock-less canonical JSON below.
        final parsed = GlobalAdditional.fromJson(
          Map<String, dynamic>.from(value),
        );
        final canonical = _normalizeAndValidate(parsed);
        final normalizedName = _nameKey(canonical.name);
        if (!ids.add(canonical.id)) {
          throw InvalidAssignmentException(
            'Se omitió el adicional global duplicado ${canonical.id}.',
          );
        }
        if (!names.add(normalizedName)) {
          throw DuplicateAdditionalException(canonical.name);
        }
        valid.add(canonical);
      } catch (error) {
        // A malformed/duplicated legacy row must not hide valid catalog rows or
        // delete the source payload implicitly. It is recoverable on reload.
        _report(error);
      }
    }
    return valid;
  }

  Future<void> _writeAdditions(List<GlobalAdditional> additions) async {
    final canonical = _canonicalizeForWrite(additions);
    final payload = _jsonPayload(canonical);
    final box = _settingsBox;
    if (box != null) {
      // Replacing the complete JSON list avoids exposing a partially written
      // catalog and keeps the legacy storage key stable.
      await box.put(storageKey, payload);
    } else {
      _memoryAdditions
        ..clear()
        ..addAll(canonical);
    }
  }

  List<GlobalAdditional> _canonicalizeForRead(
    Iterable<GlobalAdditional> additions,
  ) {
    final result = <GlobalAdditional>[];
    final ids = <String>{};
    final names = <String>{};
    for (final addition in additions) {
      try {
        final canonical = _normalizeAndValidate(addition);
        if (!ids.add(canonical.id) || !names.add(_nameKey(canonical.name))) {
          _report(DuplicateAdditionalException(canonical.name));
          continue;
        }
        result.add(canonical);
      } catch (error) {
        _report(error);
      }
    }
    return result;
  }

  List<GlobalAdditional> _canonicalizeForWrite(
    Iterable<GlobalAdditional> additions,
  ) {
    final result = <GlobalAdditional>[];
    final ids = <String>{};
    final names = <String>{};
    for (final addition in additions) {
      final canonical = _normalizeAndValidate(addition);
      if (!ids.add(canonical.id)) {
        throw InvalidAssignmentException(
          'Ya existe un adicional con ese identificador.',
        );
      }
      if (!names.add(_nameKey(canonical.name))) {
        throw DuplicateAdditionalException(canonical.name);
      }
      result.add(canonical);
    }
    return result;
  }

  GlobalAdditional _normalizeAndValidate(GlobalAdditional additional) {
    final name = MenuValidators.ensureName(additional.name);
    final priceCents = MenuValidators.ensurePrice(additional.priceCents);
    return additional.copyWith(name: name, priceCents: priceCents);
  }

  void _ensureUniqueName(
    String name,
    Iterable<GlobalAdditional> additions, {
    String? excludedId,
  }) {
    final candidate = _nameKey(name);
    if (additions.any(
      (item) => item.id != excludedId && _nameKey(item.name) == candidate,
    )) {
      throw DuplicateAdditionalException(name);
    }
  }

  static String _nameKey(String name) => name.trim().toLowerCase();

  static List<Map<String, dynamic>> _jsonPayload(
    Iterable<GlobalAdditional> additions,
  ) => additions.map((addition) => addition.toJson()).toList(growable: false);

  void _report(Object error) {
    _onRecoverableError?.call(error);
  }
}
