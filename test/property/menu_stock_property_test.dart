import 'dart:io';

import 'package:dinnerhome/models/menu_item.dart';
import 'package:dinnerhome/models/menu_item_variation.dart';
import 'package:dinnerhome/services/hive/hive_menu_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  const boxName = 'menu_items_v1_property_test';
  const iterations = 120;
  late Box<MenuItem> box;
  late Directory hiveDirectory;

  setUpAll(() async {
    hiveDirectory = Directory(
      '${Directory.systemTemp.path}${Platform.pathSeparator}dinnerhome-menu-stock-property',
    );
    if (hiveDirectory.existsSync()) {
      hiveDirectory.deleteSync(recursive: true);
    }

    Hive.init(hiveDirectory.path);
    Hive.registerAdapter(MenuItemAdapter());
    Hive.registerAdapter(MenuItemVariationAdapter());
    box = await Hive.openBox<MenuItem>(boxName);
  });

  setUp(() async {
    await box.clear();
  });

  tearDownAll(() async {
    await box.deleteFromDisk();
  });

  test('Feature: ajuste-platos-variaciones-adicionales, Property 1: '
      'Round-trip de stocks independientes', () async {
    final generator = _DeterministicGenerator(seed: 0x51_0C_42);
    final service = HiveMenuService(box: box);

    for (var iteration = 0; iteration < iterations; iteration++) {
      await box.clear();
      final item = _validMenuItem(generator, iteration);

      await service.createMenuItem(item);

      // Recreate the service to ensure the assertion reads the persisted
      // aggregate rather than the object that was passed to create.
      final reloadedService = HiveMenuService(box: box);
      final reloaded = await reloadedService.getMenuItem(item.id);

      expect(reloaded, isNotNull, reason: 'iteration $iteration');
      expect(reloaded!.stock, item.stock, reason: 'iteration $iteration');

      final expectedStocks = <String, int>{
        for (final variation in item.variations) variation.id: variation.stock,
      };
      final actualStocks = <String, int>{
        for (final variation in reloaded.variations)
          variation.id: variation.stock,
      };

      expect(
        actualStocks,
        expectedStocks,
        reason: 'variation stocks at iteration $iteration',
      );
    }

    expect(iterations, greaterThanOrEqualTo(100));
  });
}

MenuItem _validMenuItem(_DeterministicGenerator generator, int iteration) {
  final variationCount = generator.nextInt(7);
  final variations = List<MenuItemVariation>.generate(
    variationCount,
    (index) => MenuItemVariation(
      id: 'property-$iteration-variation-$index',
      name: 'Variación $index',
      priceCents: generator.nextInt(20_001),
      stock: generator.nextInt(1_000_000),
    ),
  );

  return MenuItem(
    id: 'property-$iteration',
    name: 'Plato generado $iteration',
    priceCents: generator.nextInt(20_001),
    modifiers: const [],
    available: iteration.isEven,
    category: 'Pruebas property-based',
    stock: generator.nextInt(1_000_000),
    variations: variations,
    additionalIds: const [],
  );
}

/// Small deterministic generator used because this project has no property
/// testing dependency. It provides reproducible generated valid cases while
/// keeping the property suite executable with the existing Flutter toolchain.
class _DeterministicGenerator {
  _DeterministicGenerator({required int seed}) : _state = seed;

  int _state;

  int nextInt(int exclusiveUpperBound) {
    if (exclusiveUpperBound <= 0) {
      throw ArgumentError.value(
        exclusiveUpperBound,
        'exclusiveUpperBound',
        'must be greater than zero',
      );
    }

    _state = (1_664_525 * _state + 1_013_904_223) & 0x7fffffff;
    return _state % exclusiveUpperBound;
  }
}
