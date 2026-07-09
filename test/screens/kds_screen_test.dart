import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dinnerhome/models/order.dart';
import 'package:dinnerhome/models/order_item.dart' as order_item;
import 'package:dinnerhome/presentation/screens/kds_screen.dart';
import 'package:dinnerhome/providers/providers.dart';
import 'package:dinnerhome/services/order_service.dart';
import 'package:dinnerhome/services/socket_service.dart';

// ── Mock Services ──────────────────────────────────────────────

class MockKdsSocketService implements SocketService {
  final _controller = StreamController<OrderEvent>.broadcast();

  @override
  Stream<OrderEvent> get orderEvents => _controller.stream;

  @override
  void emitOrderEvent(OrderEvent event) => _controller.add(event);

  @override
  void dispose() => _controller.close();

  void addOrder(Order order, {String eventType = 'order_update'}) {
    _controller.add(OrderEvent(orderId: order.id, eventType: eventType, order: order));
  }
}

class MockKdsOrderService implements OrderService {
  @override
  Future<List<Order>> getActiveOrders() async {
    return [];
  }

  @override
  Future<Order> createDraft({
    required String waiterId,
    String? tableId,
  }) async {
    throw UnimplementedError('Not used in KDS screen');
  }

  @override
  Future<Order> addItem({
    required String orderId,
    required order_item.OrderItem item,
  }) async {
    throw UnimplementedError('Not used in KDS screen');
  }

  @override
  Future<Order> updateItem({
    required String orderId,
    required order_item.OrderItem item,
    required String byUserId,
  }) async {
    throw UnimplementedError('Not used in KDS screen');
  }

  @override
  Future<Order> removeItem({
    required String orderId,
    required String itemId,
    required String byUserId,
  }) async {
    throw UnimplementedError('Not used in KDS screen');
  }

  @override
  Future<Order> sendToKitchen({
    required String orderId,
    required String byUserId,
  }) async {
    throw UnimplementedError('Not used in KDS screen');
  }

  @override
  Future<Order> updateStatus({
    required String orderId,
    required OrderStatus status,
    required String byUserId,
  }) async {
    return Order(
      id: orderId,
      tableId: '5',
      waiterId: 'waiter-1',
      items: [],
      status: status,
      subtotalCents: 0,
      taxCents: 0,
      totalCents: 0,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<Order> updateTable({
    required String orderId,
    required String tableId,
  }) async {
    throw UnimplementedError('Not used in KDS screen');
  }

  @override
  Future<Order?> getOrder(String orderId) async => null;

  @override
  Stream<OrderEvent> watchOrders() => const Stream.empty();
}

// ── Helpers ────────────────────────────────────────────────────

Order makeOrder({
  required String id,
  required String tableId,
  required OrderStatus status,
}) {
  return Order(
    id: id,
    tableId: tableId,
    waiterId: 'waiter-1',
    items: [
      order_item.OrderItem(
        id: 'oi-1',
        menuItemId: 'menu-1',
        quantity: 2,
        status: order_item.OrderStatus.pending,
        modifierIds: [],
        priceCents: 1200,
      ),
    ],
    status: status,
    subtotalCents: 2400,
    taxCents: 240,
    totalCents: 2640,
    createdAt: DateTime.now(),
  );
}

ProviderScope buildKdsApp(MockKdsSocketService socket) {
  return ProviderScope(
    overrides: [
      socketServiceProvider.overrideWith((ref) => socket),
      orderServiceProvider.overrideWith((ref) => MockKdsOrderService()),
    ],
    child: const MaterialApp(home: KdsScreen()),
  );
}

// ── Tests ──────────────────────────────────────────────────────

void main() {
  late MockKdsSocketService socketService;

  setUp(() {
    socketService = MockKdsSocketService();
  });

  tearDown(() {
    socketService.dispose();
  });

  group('KdsScreen', () {
    testWidgets('shows empty state initially with wait message',
        (tester) async {
      await tester.pumpWidget(buildKdsApp(socketService));

      expect(find.text('Esperando órdenes...'), findsOneWidget);
      expect(find.byIcon(Icons.restaurant_menu), findsOneWidget);
    });

    testWidgets('shows disconnected indicator initially', (tester) async {
      await tester.pumpWidget(buildKdsApp(socketService));

      expect(find.text('Desconectado'), findsOneWidget);
    });

    testWidgets('shows 3 tabs when a ticket arrives', (tester) async {
      await tester.pumpWidget(buildKdsApp(socketService));

      // Emit a pending order
      final pendingOrder = makeOrder(
        id: 'order-1',
        tableId: '5',
        status: OrderStatus.sentToKitchen,
      );
      socketService.addOrder(pendingOrder);

      // Pump to process the stream event
      await tester.pump();
      await tester.pump();

      // The empty state should be gone
      expect(find.text('Esperando órdenes...'), findsNothing);

      // Three tabs should be visible with counts
      expect(find.text('Pendientes (1)'), findsOneWidget);
      expect(find.text('Preparando (0)'), findsOneWidget);
      expect(find.text('Listos (0)'), findsOneWidget);

      // The ticket should have the table info
      expect(find.text('Mesa 5'), findsOneWidget);
    });

    testWidgets('shows connected indicator after receiving event',
        (tester) async {
      await tester.pumpWidget(buildKdsApp(socketService));

      final order = makeOrder(
        id: 'order-1',
        tableId: '3',
        status: OrderStatus.sentToKitchen,
      );
      socketService.addOrder(order);

      await tester.pump();
      await tester.pump();

      expect(find.text('Conectado'), findsOneWidget);
      expect(find.text('Desconectado'), findsNothing);
    });

    testWidgets('sorts tickets into correct tabs by status',
        (tester) async {
      await tester.pumpWidget(buildKdsApp(socketService));

      // Emit one pending, one prepping, one ready
      socketService.addOrder(makeOrder(
        id: 'order-pending',
        tableId: '1',
        status: OrderStatus.sentToKitchen,
      ));
      socketService.addOrder(makeOrder(
        id: 'order-prepping',
        tableId: '2',
        status: OrderStatus.prepping,
      ));
      socketService.addOrder(makeOrder(
        id: 'order-ready',
        tableId: '3',
        status: OrderStatus.ready,
      ));

      await tester.pump();
      await tester.pump();

      expect(find.text('Pendientes (1)'), findsOneWidget);
      expect(find.text('Preparando (1)'), findsOneWidget);
      expect(find.text('Listos (1)'), findsOneWidget);
    });

    testWidgets('updates ticket tab when order status changes',
        (tester) async {
      await tester.pumpWidget(buildKdsApp(socketService));

      // Start with a pending order
      final order = makeOrder(
        id: 'order-1',
        tableId: '5',
        status: OrderStatus.sentToKitchen,
      );
      socketService.addOrder(order);

      await tester.pump();
      await tester.pump();

      expect(find.text('Pendientes (1)'), findsOneWidget);
      expect(find.text('Preparando (0)'), findsOneWidget);

      // Now emit the same order but with prepping status
      final preppingOrder = order.copyWith(status: OrderStatus.prepping);
      socketService.addOrder(preppingOrder);

      await tester.pump();
      await tester.pump();

      expect(find.text('Pendientes (0)'), findsOneWidget);
      expect(find.text('Preparando (1)'), findsOneWidget);
    });
  });
}
