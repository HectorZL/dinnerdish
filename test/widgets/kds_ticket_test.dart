import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dinnerhome/models/order.dart';
import 'package:dinnerhome/models/order_item.dart' as order_item;
import 'package:dinnerhome/widgets/kds_ticket.dart';

void main() {
  final testOrderItem = order_item.OrderItem(
    id: 'oi-1',
    menuItemId: 'menu-1',
    name: 'Item menu-1',
    quantity: 2,
    status: order_item.OrderStatus.pending,
    modifierIds: ['mod-1'],
    priceCents: 1200,
  );

  Order createOrder(OrderStatus status) {
    return Order(
      id: 'order-test-1',
      tableId: '5',
      waiterId: 'waiter-1',
      items: [testOrderItem],
      status: status,
      subtotalCents: 2400,
      taxCents: 240,
      totalCents: 2640,
      createdAt: DateTime.now(),
    );
  }

  Widget buildTicket({
    required Order order,
    VoidCallback? onMarkPrepping,
    VoidCallback? onMarkReady,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: 400,
          child: KdsTicket(
            order: order,
            onMarkPrepping: onMarkPrepping,
            onMarkReady: onMarkReady,
          ),
        ),
      ),
    );
  }

  group('KdsTicket', () {
    testWidgets('renders table info and short order ID', (tester) async {
      final order = createOrder(OrderStatus.sentToKitchen);

      await tester.pumpWidget(buildTicket(order: order));

      expect(find.text('Mesa 5'), findsOneWidget);
      // order.id = 'order-test-1' → split('-').last = '1' → rendered as '#1'
      expect(find.text('#1'), findsOneWidget);
    });

    testWidgets('renders items list with quantity', (tester) async {
      final order = createOrder(OrderStatus.sentToKitchen);

      await tester.pumpWidget(buildTicket(order: order));

      expect(find.text('2x'), findsOneWidget);
      expect(find.text('Item menu-1'), findsOneWidget);
    });

    testWidgets('shows modifier icon when item has modifierIds', (tester) async {
      final order = createOrder(OrderStatus.sentToKitchen);

      await tester.pumpWidget(buildTicket(order: order));

      expect(find.byIcon(Icons.tune), findsOneWidget);
    });

    testWidgets('shows NUEVO badge for sentToKitchen status', (tester) async {
      final order = createOrder(OrderStatus.sentToKitchen);

      await tester.pumpWidget(buildTicket(order: order));

      expect(find.text('NUEVO'), findsOneWidget);
    });

    testWidgets('shows PREPARANDO badge for prepping status', (tester) async {
      final order = createOrder(OrderStatus.prepping);

      await tester.pumpWidget(buildTicket(order: order));

      expect(find.text('PREPARANDO'), findsOneWidget);
    });

    testWidgets('shows LISTO badge for ready status', (tester) async {
      final order = createOrder(OrderStatus.ready);

      await tester.pumpWidget(buildTicket(order: order));

      expect(find.text('LISTO'), findsOneWidget);
    });

    testWidgets('shows "Iniciar Preparación" button when onMarkPrepping is set',
        (tester) async {
      final order = createOrder(OrderStatus.sentToKitchen);

      await tester.pumpWidget(
        buildTicket(order: order, onMarkPrepping: () {}),
      );

      expect(find.text('Iniciar Preparación'), findsOneWidget);
    });

    testWidgets('shows "Marcar Listo" button when onMarkReady is set',
        (tester) async {
      final order = createOrder(OrderStatus.prepping);

      await tester.pumpWidget(
        buildTicket(order: order, onMarkReady: () {}),
      );

      expect(find.text('Marcar Listo'), findsOneWidget);
    });

    testWidgets('calls onMarkPrepping callback on tap', (tester) async {
      var called = false;
      final order = createOrder(OrderStatus.sentToKitchen);

      await tester.pumpWidget(
        buildTicket(order: order, onMarkPrepping: () => called = true),
      );
      await tester.tap(find.text('Iniciar Preparación'));

      expect(called, isTrue);
    });

    testWidgets('calls onMarkReady callback on tap', (tester) async {
      var called = false;
      final order = createOrder(OrderStatus.prepping);

      await tester.pumpWidget(
        buildTicket(order: order, onMarkReady: () => called = true),
      );
      await tester.tap(find.text('Marcar Listo'));

      expect(called, isTrue);
    });

    testWidgets('shows order notes when present', (tester) async {
      final order = createOrder(OrderStatus.sentToKitchen).copyWith(
        notes: 'Sin sal, por favor',
      );

      await tester.pumpWidget(buildTicket(order: order));

      expect(find.text('Sin sal, por favor'), findsOneWidget);
    });

    testWidgets('no action buttons when both callbacks are null', (tester) async {
      final order = createOrder(OrderStatus.ready);

      await tester.pumpWidget(buildTicket(order: order));

      expect(find.text('Iniciar Preparación'), findsNothing);
      expect(find.text('Marcar Listo'), findsNothing);
    });
  });
}
