import 'package:dinnerhome/models/global_additional.dart';
import 'package:dinnerhome/services/additional_service.dart';
import 'package:hive/hive.dart';

class HiveAdditionalService implements AdditionalService {
  static const _storageKey = 'global_additionals';

  final Box<dynamic>? _settingsBox;
  final List<GlobalAdditional> _memoryAdditions = _initialAdditions();

  HiveAdditionalService()
    : _settingsBox = Hive.isBoxOpen('settings')
          ? Hive.box<dynamic>('settings')
          : null;

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
        : additions;
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
    final name = additional.name.trim();
    _validate(additional.copyWith(name: name));
    final additions = await _readAdditions();
    if (additions.any((item) => item.id == additional.id)) {
      throw ArgumentError('Ya existe un adicional con ese identificador.');
    }
    if (additions.any(
      (item) => item.name.toLowerCase() == name.toLowerCase(),
    )) {
      throw ArgumentError('Ya existe un adicional con ese nombre.');
    }
    final created = additional.copyWith(name: name);
    await _writeAdditions([...additions, created]);
    return created;
  }

  @override
  Future<GlobalAdditional> updateAdditional(
    String id,
    GlobalAdditional additional,
  ) async {
    final name = additional.name.trim();
    final updated = additional.copyWith(id: id, name: name);
    _validate(updated);
    final additions = await _readAdditions();
    final index = additions.indexWhere((item) => item.id == id);
    if (index == -1) throw ArgumentError('Adicional no encontrado.');
    if (additions.any(
      (item) => item.id != id && item.name.toLowerCase() == name.toLowerCase(),
    )) {
      throw ArgumentError('Ya existe un adicional con ese nombre.');
    }
    additions[index] = updated;
    await _writeAdditions(additions);
    return updated;
  }

  @override
  Future<void> deleteAdditional(String id) async {
    final additions = await _readAdditions();
    if (!additions.any((item) => item.id == id)) {
      throw ArgumentError('Adicional no encontrado.');
    }
    additions.removeWhere((item) => item.id == id);
    await _writeAdditions(additions);
  }

  Future<List<GlobalAdditional>> _readAdditions() async {
    final stored = _settingsBox?.get(_storageKey);
    if (stored is List) {
      return stored
          .whereType<Map>()
          .map(
            (item) =>
                GlobalAdditional.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    }

    final initial = _initialAdditions();
    if (_settingsBox != null) {
      await _settingsBox.put(
        _storageKey,
        initial.map((addition) => addition.toJson()).toList(),
      );
    }
    return List<GlobalAdditional>.from(_memoryAdditions);
  }

  Future<void> _writeAdditions(List<GlobalAdditional> additions) async {
    if (_settingsBox != null) {
      await _settingsBox.put(
        _storageKey,
        additions.map((addition) => addition.toJson()).toList(),
      );
    } else {
      _memoryAdditions
        ..clear()
        ..addAll(additions);
    }
  }

  void _validate(GlobalAdditional additional) {
    if (additional.name.trim().isEmpty) {
      throw ArgumentError('El nombre del adicional es obligatorio.');
    }
    if (additional.priceCents < 0) {
      throw ArgumentError('El precio del adicional no puede ser negativo.');
    }
  }
}
