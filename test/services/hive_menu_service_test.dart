import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:dinnerhome/exceptions/menu_exception.dart';
import 'package:dinnerhome/models/menu_item.dart';
import 'package:dinnerhome/models/menu_item_variation.dart';
import 'package:dinnerhome/services/hive/hive_menu_service.dart';

void main() {
  const boxName = 'menu_items_v1_test';
  late Box<MenuItem> box;

  setUpAll(() async {
    Hive.init('${Directory.systemTemp.path}/dinnerhome-hive-menu-tests');
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

  test('persists base and variation stocks independently after reload', () async {
    final item = MenuItem(
      id: 'dish-1',
      name: 'Plato persistente',
      priceCents: 1000,
      modifiers: const [],
      available: true,
      category: 'Pruebas',
      stock: 7,
      variations: const [
        MenuItemVariation(
          id: 'variation-1',
          name: 'Grande',
          priceCents: 1200,
          stock: 3,
        ),
        MenuItemVariation(
          id: 'variation-2',
          name: 'Pequeña',
          priceCents: 900,
          stock: 9,
        ),
      ],
    );
    final service = HiveMenuService(box: box);

    await service.createMenuItem(item);
    await service.adjustStock(item.id, null, 2);
    await service.adjustStock(item.id, 'variation-1', -1);

    final reloaded = HiveMenuService(box: box);
    final saved = await reloaded.getMenuItem(item.id);
    expect(saved!.stock, 9);
    expect(saved.variations.firstWhere((v) => v.id == 'variation-1').stock, 2);
    expect(saved.variations.firstWhere((v) => v.id == 'variation-2').stock, 9);
  });

  test('rejects missing targets and adjustments below zero without writing', () async {
    final service = HiveMenuService(box: box);
    final item = MenuItem(
      id: 'dish-2',
      name: 'Plato',
      priceCents: 1000,
      modifiers: const [],
      available: true,
      category: 'Pruebas',
      stock: 2,
      variations: const [
        MenuItemVariation(
          id: 'variation-1',
          name: 'Única',
          priceCents: 1000,
          stock: 1,
        ),
      ],
    );
    await service.createMenuItem(item);

    expect(
      () => service.adjustStock('missing', null, 1),
      throwsA(isA<MenuItemNotFoundException>()),
    );
    expect(
      () => service.adjustStock(item.id, 'missing', 1),
      throwsA(isA<MenuItemVariationNotFoundException>()),
    );
    expect(
      () => service.adjustStock(item.id, 'variation-1', -2),
      throwsA(isA<StockAdjustmentNegativeException>()),
    );

    final unchanged = await service.getMenuItem(item.id);
    expect(unchanged!.stock, 2);
    expect(unchanged.variations.single.stock, 1);
  });
}
