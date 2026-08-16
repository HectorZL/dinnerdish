import 'package:flutter_test/flutter_test.dart';
import 'package:dinnerhome/exceptions/menu_exception.dart';
import 'package:dinnerhome/models/menu_item.dart';
import 'package:dinnerhome/services/in_memory/in_memory_menu_service.dart';

void main() {
  group('InMemoryMenuService', () {
    // ---------------------------------------------------------------------------
    // Test 1: createMenuItem adds an item to the menu
    // ---------------------------------------------------------------------------
    test('createMenuItem adds a new item and returns it', () async {
      final service = InMemoryMenuService();

      final item = MenuItem(
        id: 'new-item-1',
        name: 'Test Dish',
        priceCents: 1500,
        modifiers: [],
        available: true,
        category: 'Entrantes',
      );

      final created = await service.createMenuItem(item);
      expect(created.id, 'new-item-1');
      expect(created.name, 'Test Dish');
      expect(created.priceCents, 1500);
      expect(created.category, 'Entrantes');

      // Verify it's in the menu
      final menu = await service.fetchMenu();
      expect(menu.any((i) => i.id == 'new-item-1'), isTrue);
    });

    // ---------------------------------------------------------------------------
    // Test 2: updateMenuItem updates an existing item
    // ---------------------------------------------------------------------------
    test('updateMenuItem updates an existing item', () async {
      final service = InMemoryMenuService();

      final updated = await service.updateMenuItem(
        'item-1',
        MenuItem(
          id: 'item-1',
          name: 'Pasta Carbonara Updated',
          priceCents: 1300,
          modifiers: [],
          available: false,
          category: 'Platos Principales',
        ),
      );

      expect(updated.name, 'Pasta Carbonara Updated');
      expect(updated.priceCents, 1300);
      expect(updated.available, isFalse);

      // Verify it's persisted
      final menu = await service.fetchMenu();
      final pasta = menu.firstWhere((i) => i.id == 'item-1');
      expect(pasta.name, 'Pasta Carbonara Updated');
      expect(pasta.priceCents, 1300);
    });

    // ---------------------------------------------------------------------------
    // Test 3: updateMenuItem throws MenuItemNotFoundException
    // ---------------------------------------------------------------------------
    test(
      'updateMenuItem throws MenuItemNotFoundException for unknown id',
      () async {
        final service = InMemoryMenuService();

        expect(
          () => service.updateMenuItem(
            'non-existent',
            MenuItem(
              id: 'non-existent',
              name: 'Ghost Dish',
              priceCents: 1000,
              modifiers: [],
              available: true,
              category: 'Test',
            ),
          ),
          throwsA(isA<MenuItemNotFoundException>()),
        );
      },
    );

    // ---------------------------------------------------------------------------
    // Test 4: deleteMenuItem removes an item
    // ---------------------------------------------------------------------------
    test('deleteMenuItem removes an item from the menu', () async {
      final service = InMemoryMenuService();

      await service.deleteMenuItem('item-2');

      final menu = await service.fetchMenu();
      expect(menu.any((i) => i.id == 'item-2'), isFalse);
      // Other items remain
      expect(menu.any((i) => i.id == 'item-1'), isTrue);
      expect(menu.any((i) => i.id == 'item-3'), isTrue);
    });

    // ---------------------------------------------------------------------------
    // Test 5: deleteMenuItem throws MenuItemNotFoundException
    // ---------------------------------------------------------------------------
    test(
      'deleteMenuItem throws MenuItemNotFoundException for unknown id',
      () async {
        final service = InMemoryMenuService();

        expect(
          () => service.deleteMenuItem('non-existent'),
          throwsA(isA<MenuItemNotFoundException>()),
        );
      },
    );

    // ---------------------------------------------------------------------------
    // Test 6: getCategories returns unique sorted categories
    // ---------------------------------------------------------------------------
    test('getCategories returns unique categories from menu items', () async {
      final service = InMemoryMenuService();

      final categories = await service.getCategories();

      // From seed data: Entrantes, Platos Principales
      expect(categories, contains('Entrantes'));
      expect(categories, contains('Platos Principales'));
      expect(categories.length, 2);
      // Should be sorted
      expect(categories[0], 'Entrantes');
      expect(categories[1], 'Platos Principales');
    });

    // ---------------------------------------------------------------------------
    // Test 7: getCategories reflects newly added items
    // ---------------------------------------------------------------------------
    test('getCategories includes categories from newly added items', () async {
      final service = InMemoryMenuService();

      await service.createMenuItem(
        MenuItem(
          id: 'new-cat-item',
          name: 'New Category Dish',
          priceCents: 1000,
          modifiers: [],
          available: true,
          category: 'Postres',
        ),
      );

      final categories = await service.getCategories();
      expect(categories, contains('Postres'));
      expect(categories.length, 3);
    });

    test('adjustStock updates only the selected variation', () async {
      final service = InMemoryMenuService();
      final before = await service.getMenuItem('item-1');

      await service.adjustStock('item-1', 'var-1-1', -3);

      final after = await service.getMenuItem('item-1');
      expect(after!.stock, before!.stock);
      expect(after.variations.firstWhere((v) => v.id == 'var-1-1').stock, 12);
      expect(
        after.variations.firstWhere((v) => v.id == 'var-1-2').stock,
        before.variations.firstWhere((v) => v.id == 'var-1-2').stock,
      );
    });

    test(
      'adjustStock rejects an unknown item, variation, or negative result',
      () async {
        final service = InMemoryMenuService();

        expect(
          () => service.adjustStock('missing', null, 1),
          throwsA(isA<MenuItemNotFoundException>()),
        );
        expect(
          () => service.adjustStock('item-1', 'missing-variation', 1),
          throwsA(isA<MenuItemVariationNotFoundException>()),
        );
        expect(
          () => service.adjustStock('item-1', 'var-1-1', -16),
          throwsA(isA<StockAdjustmentNegativeException>()),
        );
      },
    );
  });
}
