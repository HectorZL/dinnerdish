import 'dart:io';

import 'package:dinnerhome/models/global_additional.dart';
import 'package:dinnerhome/models/order_item.dart';
import 'package:dinnerhome/models/selected_additional.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Box<OrderItem> box;
  late String hivePath;

  setUpAll(() async {
    hivePath = '${Directory.systemTemp.path}/dinnerhome-order-item-tests';
    Hive.init(hivePath);
    Hive.registerAdapter(OrderItemAdapter());
    Hive.registerAdapter(OrderStatusAdapter());
    Hive.registerAdapter(SelectedAdditionalAdapter());
    Hive.registerAdapter(AdditionalSourceAdapter());
    box = await Hive.openBox<OrderItem>('order-items');
  });

  tearDownAll(() async {
    await box.close();
    await Hive.deleteBoxFromDisk('order-items');
    final directory = Directory(hivePath);
    if (directory.existsSync()) {
      await directory.delete(recursive: true);
    }
  });

  test('datos legacy sin selectedAdditionals se leen como lista vacía', () {
    final legacyJson = <String, dynamic>{
      'id': 'item-legacy',
      'menuItemId': globalAdditionalLineMenuItemId('additional-1'),
      'quantity': 1,
      'notes': null,
      'status': 'pending',
      'modifierIds': ['additional-1'],
      'priceCents': 125,
      'name': 'Queso',
      'variationId': null,
    };

    final item = OrderItem.fromJson(legacyJson);

    expect(item.selectedAdditionals, isEmpty);
    expect(item.menuItemId, 'global-additional:additional-1');
    expect(item.modifierIds, ['additional-1']);
  });

  test('los snapshots anidados hacen round-trip JSON exacto', () {
    final selected = SelectedAdditional(
      assignmentId: 'assignment-1',
      additionalId: 'additional-1',
      source: AdditionalSource.special,
      nameSnapshot: '  Salsa picante  ',
      priceCentsSnapshot: 250,
    );
    final item = OrderItem(
      id: 'item-1',
      menuItemId: 'menu-1',
      quantity: 2,
      status: OrderStatus.pending,
      modifierIds: ['modifier-1'],
      priceCents: 1800,
      name: 'Hamburguesa',
      variationId: 'variation-1',
      selectedAdditionals: [selected],
    );

    final restored = OrderItem.fromJson(item.toJson());

    expect(restored.toJson(), item.toJson());
    expect(restored.selectedAdditionals.single.nameSnapshot, 'Salsa picante');
    expect(restored.selectedAdditionals.single.priceCentsSnapshot, 250);
    expect(
      restored.selectedAdditionals.single.source,
      AdditionalSource.special,
    );
  });

  test(
    'los snapshots anidados hacen round-trip Hive sin crear líneas de menú',
    () async {
      final item = OrderItem(
        id: 'item-hive',
        menuItemId: 'menu-1',
        quantity: 1,
        status: OrderStatus.pending,
        modifierIds: [],
        priceCents: 1000,
        selectedAdditionals: [
          SelectedAdditional(
            assignmentId: 'assignment-1',
            additionalId: 'additional-1',
            source: AdditionalSource.global,
            nameSnapshot: 'Queso',
            priceCentsSnapshot: 150,
          ),
        ],
      );

      await box.put(item.id, item);
      final restored = box.get(item.id)!;

      expect(restored.menuItemId, 'menu-1');
      expect(restored.selectedAdditionals, hasLength(1));
      expect(restored.selectedAdditionals.single.toJson(), {
        'assignmentId': 'assignment-1',
        'additionalId': 'additional-1',
        'source': 'global',
        'nameSnapshot': 'Queso',
        'priceCentsSnapshot': 150,
      });
    },
  );

  test(
    'los tipos nuevos usan IDs Hive append-only sin alterar los históricos',
    () {
      expect(OrderItemAdapter().typeId, 4);
      expect(OrderStatusAdapter().typeId, 3);
      expect(SelectedAdditionalAdapter().typeId, 20);
      expect(AdditionalSourceAdapter().typeId, 21);
    },
  );
}
