import 'dart:async';

import 'package:dinnerhome/exceptions/validation_exception.dart';
import 'package:dinnerhome/models/special_additional.dart';
import 'package:hive/hive.dart';

/// Persists the definitions of dish-owned additional products.
///
/// The repository deliberately stores the collection as one JSON value in the
/// existing `settings` box. This keeps a replacement write atomic at the
/// collection level and prevents a failed operation from publishing a partial
/// list. Relationship checks are injected because this repository must not
/// depend directly on the menu service.
class SpecialAdditionalRepository {
  static const storageKey = 'special_additionals_v1';
  static const settingsBoxName = 'settings';

  final Box<dynamic>? _providedSettingsBox;
  final Set<String>? _validMenuItemIds;
  final FutureOr<bool> Function(String menuItemId)? _menuItemExists;
  final void Function(Object error)? _onRecoverableError;
  final List<SpecialAdditional> _memoryItems = <SpecialAdditional>[];

  SpecialAdditionalRepository({
    Box<dynamic>? settingsBox,
    Box<dynamic>? box,
    Iterable<String>? validMenuItemIds,
    FutureOr<bool> Function(String menuItemId)? menuItemExists,
    void Function(Object error)? onRecoverableError,
  }) : _providedSettingsBox = settingsBox ?? box,
       _validMenuItemIds = validMenuItemIds?.toSet(),
       _menuItemExists = menuItemExists,
       _onRecoverableError = onRecoverableError;

  Box<dynamic>? get _settingsBox {
    if (_providedSettingsBox != null) return _providedSettingsBox;
    if (Hive.isBoxOpen(settingsBoxName)) {
      return Hive.box<dynamic>(settingsBoxName);
    }
    return null;
  }

  /// Reads the complete collection. A missing key is an empty collection.
  /// Invalid entries are logged and omitted so valid menu data remains usable.
  Future<List<SpecialAdditional>> readAll() async {
    final raw = _settingsBox?.get(storageKey) ?? _memoryItems;
    if (raw == null) return const <SpecialAdditional>[];
    if (raw is! List) {
      _report(FormatException('$storageKey no contiene una lista válida.'));
      return const <SpecialAdditional>[];
    }

    final valid = <SpecialAdditional>[];
    for (final value in raw) {
      try {
        if (value is! Map) {
          throw const FormatException(
            'Registro de adicional especial inválido.',
          );
        }
        final item = SpecialAdditional.fromJson(
          Map<String, dynamic>.from(value),
        );
        if (!await _ownerExists(item.ownerMenuItemId)) {
          _report(
            InvalidAssignmentException(
              'Se omitió el adicional especial ${item.id}: su Plato propietario no existe.',
            ),
          );
          continue;
        }
        if (valid.any((existing) => existing.id == item.id)) {
          _report(
            InvalidAssignmentException(
              'Se omitió el adicional especial duplicado ${item.id}.',
            ),
          );
          continue;
        }
        valid.add(item);
      } catch (error) {
        _report(error);
      }
    }
    return List<SpecialAdditional>.unmodifiable(valid);
  }

  Future<List<SpecialAdditional>> fetchAll() => readAll();

  Future<List<SpecialAdditional>> fetchForMenuItem(String menuItemId) async {
    final items = await readAll();
    return List<SpecialAdditional>.unmodifiable(
      items.where((item) => item.ownerMenuItemId == menuItemId),
    );
  }

  Future<SpecialAdditional?> getById(String id) async {
    final items = await readAll();
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  /// Replaces the complete collection after validating every definition.
  Future<void> replaceAll(Iterable<SpecialAdditional> items) async {
    final candidate = List<SpecialAdditional>.unmodifiable(items);
    await _validateCandidate(candidate);
    final payload = candidate
        .map((item) => item.toJson())
        .toList(growable: false);
    final box = _settingsBox;
    if (box != null) {
      // Hive writes the complete list under one key. Do not update any local
      // projection until the write has completed successfully.
      await box.put(storageKey, payload);
    } else {
      _memoryItems
        ..clear()
        ..addAll(candidate);
    }
  }

  Future<void> writeAll(Iterable<SpecialAdditional> items) => replaceAll(items);

  Future<void> saveAll(Iterable<SpecialAdditional> items) => replaceAll(items);

  Future<SpecialAdditional> upsert(SpecialAdditional item) async {
    final items = await readAll();
    final index = items.indexWhere((existing) => existing.id == item.id);
    final candidate = List<SpecialAdditional>.from(items);
    if (index == -1) {
      candidate.add(item);
    } else {
      candidate[index] = item;
    }
    await replaceAll(candidate);
    return item;
  }

  Future<void> delete(String id) async {
    final items = await readAll();
    final candidate = items.where((item) => item.id != id).toList();
    if (candidate.length != items.length) {
      await replaceAll(candidate);
    }
  }

  Future<void> _validateCandidate(List<SpecialAdditional> candidate) async {
    final ids = <String>{};
    for (final item in candidate) {
      if (!ids.add(item.id)) {
        throw InvalidAssignmentException(
          'No se puede guardar dos veces el adicional especial ${item.id}.',
        );
      }
      if (!await _ownerExists(item.ownerMenuItemId)) {
        throw InvalidAssignmentException(
          'El Plato propietario del adicional especial no existe.',
        );
      }
    }
  }

  Future<bool> _ownerExists(String menuItemId) async {
    final knownIds = _validMenuItemIds;
    if (knownIds != null && !knownIds.contains(menuItemId)) return false;
    final exists = _menuItemExists;
    if (exists == null) return true;
    return await exists(menuItemId);
  }

  void _report(Object error) {
    _onRecoverableError?.call(error);
  }
}
