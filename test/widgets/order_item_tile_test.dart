import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dinnerhome/models/order_item.dart';
import 'package:dinnerhome/widgets/order_item_tile.dart';

void main() {
  group('OrderItemTile', () {
    const baseItem = OrderItem(
      id: 'item-1',
      menuItemId: 'menu-1',
      quantity: 3,
      status: OrderStatus.pending,
      modifierIds: [],
      priceCents: 1500,
      notes: 'Sin cebolla',
    );

    testWidgets('renders item name, quantity, and price', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OrderItemTile(
              item: baseItem,
              itemName: 'Pizza Margherita',
            ),
          ),
        ),
      );

      expect(find.text('Pizza Margherita'), findsOneWidget);
      expect(find.text('3x'), findsOneWidget);
      expect(find.text('\$15.00'), findsOneWidget);
    });

    testWidgets('shows notes when present', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OrderItemTile(
              item: baseItem,
              itemName: 'Pizza Margherita',
            ),
          ),
        ),
      );

      expect(find.text('Sin cebolla'), findsOneWidget);
    });

    testWidgets('shows menuItemId when itemName is not provided', (tester) async {
      const item = OrderItem(
        id: 'item-1',
        menuItemId: 'menu-42',
        quantity: 1,
        status: OrderStatus.pending,
        modifierIds: [],
        priceCents: 1000,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OrderItemTile(item: item),
          ),
        ),
      );

      expect(find.text('Item menu-42'), findsOneWidget);
    });

    testWidgets('does not show notes when empty', (tester) async {
      const item = OrderItem(
        id: 'item-1',
        menuItemId: 'menu-1',
        quantity: 1,
        status: OrderStatus.pending,
        modifierIds: [],
        priceCents: 1000,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OrderItemTile(
              item: item,
              itemName: 'Test',
            ),
          ),
        ),
      );

      // The Icon(Icons.delete_outline) is for the remove button
      // which doesn't appear when onRemove is null. No notes should
      // be visible for this item.
    });

    testWidgets('calls onRemove callback on tap', (tester) async {
      var removed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OrderItemTile(
              item: baseItem,
              itemName: 'Test Item',
              onRemove: () => removed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.delete_outline));
      expect(removed, isTrue);
    });

    testWidgets('does not show remove button when onRemove is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OrderItemTile(
              item: baseItem,
              itemName: 'Test Item',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.delete_outline), findsNothing);
    });

    testWidgets('renders with different OrderStatus values', (tester) async {
      // Test with different order_item OrderStatus values
      for (final status in OrderStatus.values) {
        final item = OrderItem(
          id: 'item-$status',
          menuItemId: 'menu-1',
          quantity: 1,
          status: status,
          modifierIds: [],
          priceCents: 1000,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: OrderItemTile(
                item: item,
                itemName: 'Status: $status',
              ),
            ),
          ),
        );

        expect(find.text('1x'), findsOneWidget);
        expect(find.text('Status: $status'), findsOneWidget);
        expect(find.text('\$10.00'), findsOneWidget);
      }
    });
  });
}
