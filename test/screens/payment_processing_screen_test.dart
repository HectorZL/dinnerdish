import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dinnerhome/models/user.dart';
import 'package:dinnerhome/models/order.dart';
import 'package:dinnerhome/models/order_item.dart' as order_item;
import 'package:dinnerhome/models/payment_method.dart';
import 'package:dinnerhome/models/payment_status.dart';
import 'package:dinnerhome/models/payment_summary.dart';
import 'package:dinnerhome/models/payment_transaction.dart';
import 'package:dinnerhome/presentation/screens/payment_processing_screen.dart';
import 'package:dinnerhome/providers/providers.dart';
import 'package:dinnerhome/services/auth_service.dart';
import 'package:dinnerhome/services/order_service.dart';
import 'package:dinnerhome/services/payment_service.dart';

// ── Mock Services ──────────────────────────────────────────────

const _mockUser = User(
  id: 'user-cajero-1',
  username: 'cajero',
  name: 'María García',
  role: Role.cajero,
);

class MockPaymentProcAuthService implements AuthService {
  @override
  Future<User> login(String username, String password) async => _mockUser;

  @override
  Future<User> loginWithTestUser(User user) async => user;

  @override
  Future<void> logout() async {}

  @override
  Future<User?> getCurrentUser() async => _mockUser;
}

class MockPaymentProcOrderService implements OrderService {
  final Order? order;
  final bool shouldThrow;

  MockPaymentProcOrderService({this.order, this.shouldThrow = false});

  @override
  Future<Order?> getOrder(String orderId) async {
    if (shouldThrow) {
      throw Exception('Simulated order error');
    }
    return order;
  }

  @override
  Future<List<Order>> getActiveOrders() async {
    return order != null ? [order!] : [];
  }

  @override
  Future<Order> createDraft({required String waiterId, String? tableId}) async {
    throw UnimplementedError();
  }

  @override
  Future<Order> updateTable({required String orderId, required String tableId}) async {
    throw UnimplementedError();
  }

  @override
  Future<Order> addItem({
    required String orderId,
    required order_item.OrderItem item,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Order> updateItem({
    required String orderId,
    required order_item.OrderItem item,
    required String byUserId,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Order> removeItem({
    required String orderId,
    required String itemId,
    required String byUserId,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Order> sendToKitchen({
    required String orderId,
    required String byUserId,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Order> updateStatus({
    required String orderId,
    required OrderStatus status,
    required String byUserId,
  }) async {
    return order ?? makeTestOrder(id: orderId);
  }

  @override
  Stream<OrderEvent> watchOrders() => const Stream.empty();
}

class MockPaymentProcPaymentService implements PaymentService {
  final bool processShouldThrow;

  MockPaymentProcPaymentService({this.processShouldThrow = false});

  @override
  List<PaymentTransaction> watchPendingRequests() => [];

  @override
  Future<void> requestPayment({
    required String orderId,
    required String requestedBy,
    String? reason,
  }) async {}

  @override
  Future<PaymentTransaction> processPayment({
    required String orderId,
    required int amountCents,
    required PaymentMethod method,
    required String processedBy,
  }) async {
    if (processShouldThrow) {
      throw Exception('Simulated payment processing error');
    }
    return PaymentTransaction(
      id: 'txn-1',
      orderId: orderId,
      processedBy: processedBy,
      amountCents: amountCents,
      method: method,
      status: PaymentStatus.completed,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<List<PaymentTransaction>> getPaymentHistory(String orderId) async => [];

  @override
  Future<List<PaymentTransaction>> splitPayment({
    required String orderId,
    required List<int> splitAmountsCents,
    required String processedBy,
  }) async {
    return splitAmountsCents.map((amount) => PaymentTransaction(
      id: 'split-txn-${splitAmountsCents.indexOf(amount)}',
      orderId: orderId,
      processedBy: processedBy,
      amountCents: amount,
      method: PaymentMethod.split,
      status: PaymentStatus.completed,
      createdAt: DateTime.now(),
    )).toList();
  }

  @override
  Future<PaymentTransaction> refundPayment(String transactionId) async {
    throw UnimplementedError();
  }

  @override
  Future<List<PaymentSummary>> getPaymentSummaryByMethod({
    required DateTime startDate,
    required DateTime endDate,
  }) async => [];
}

Order makeTestOrder({required String id, int totalCents = 2500}) {
  return Order(
    id: id,
    tableId: 'table-5',
    waiterId: 'waiter-1',
    items: [
      order_item.OrderItem(
        id: 'item-1',
        menuItemId: 'menu-1',
        quantity: 2,
        status: order_item.OrderStatus.sent,
        modifierIds: [],
        priceCents: 1000,
      ),
    ],
    status: OrderStatus.billed,
    subtotalCents: 2000,
    taxCents: 500,
    totalCents: totalCents,
    createdAt: DateTime(2026, 5, 8, 14, 30),
  );
}

// ── ProviderScope builder ──────────────────────────────────────

Widget buildPaymentApp({
  required MockPaymentProcOrderService orderService,
  required MockPaymentProcPaymentService paymentService,
}) {
  return ProviderScope(
    overrides: [
      currentUserProvider.overrideWith((ref) {
        final notifier = CurrentUserNotifier(MockPaymentProcAuthService());
        notifier.state = AsyncValue.data(_mockUser);
        return notifier;
      }),
      orderServiceProvider.overrideWith((ref) => orderService),
      paymentServiceProvider.overrideWith((ref) => paymentService),
    ],
    child: MaterialApp(
      home: PaymentProcessingScreen(orderId: 'order-1'),
    ),
  );
}

// ── Tests ──────────────────────────────────────────────────────

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('PaymentProcessingScreen', () {
    testWidgets('shows order details after loading', (tester) async {
      final orderService = MockPaymentProcOrderService(order: makeTestOrder(id: 'order-1'));
      final paymentService = MockPaymentProcPaymentService();

      await tester.pumpWidget(buildPaymentApp(
        orderService: orderService,
        paymentService: paymentService,
      ));
      await tester.pump();
      await tester.pump();

      // App bar title (appears once - only in AppBar)
      expect(find.text('Procesar Pago'), findsAtLeastNWidgets(1));

      // Process button exists (identified by key)
      expect(find.byKey(const Key('processPaymentButton')), findsOneWidget);

      // Order ID displayed
      expect(find.textContaining('order-1'), findsOneWidget);

      // Table info
      expect(find.text('table-5'), findsOneWidget);

      // Waiter info
      expect(find.text('waiter-1'), findsOneWidget);

      // Prices
      expect(find.text('\$20.00'), findsOneWidget); // subtotal
      expect(find.text('\$5.00'), findsOneWidget);  // tax
      expect(find.text('\$25.00'), findsOneWidget);  // total
    });

    testWidgets('shows payment method options', (tester) async {
      final orderService = MockPaymentProcOrderService(order: makeTestOrder(id: 'order-1'));
      final paymentService = MockPaymentProcPaymentService();

      await tester.pumpWidget(buildPaymentApp(
        orderService: orderService,
        paymentService: paymentService,
      ));
      await tester.pump();
      await tester.pump();

      // Payment method labels
      expect(find.text('Efectivo'), findsOneWidget);
      expect(find.text('Tarjeta'), findsOneWidget);
      expect(find.text('QR / Bizum'), findsOneWidget);

      // Split button
      expect(find.text('Dividir'), findsOneWidget);
    });

    testWidgets('process payment shows success dialog', (tester) async {
      final orderService = MockPaymentProcOrderService(order: makeTestOrder(id: 'order-1'));
      final paymentService = MockPaymentProcPaymentService(processShouldThrow: false);

      await tester.pumpWidget(buildPaymentApp(
        orderService: orderService,
        paymentService: paymentService,
      ));
      await tester.pump();
      await tester.pump();

      // Find the process button by key
      final processButton = find.byKey(const Key('processPaymentButton'));
      expect(processButton, findsOneWidget);
      await tester.ensureVisible(processButton);
      await tester.pump();

      await tester.tap(processButton);
      await tester.pump();
      await tester.pump();

      // Success dialog should appear
      expect(find.text('Pago Exitoso'), findsOneWidget);
      expect(find.text('Volver a Solicitudes'), findsOneWidget);
    });

    testWidgets('process payment shows error snackbar on failure',
        (tester) async {
      final orderService = MockPaymentProcOrderService(order: makeTestOrder(id: 'order-1'));
      final paymentService = MockPaymentProcPaymentService(processShouldThrow: true);

      await tester.pumpWidget(buildPaymentApp(
        orderService: orderService,
        paymentService: paymentService,
      ));
      await tester.pump();
      await tester.pump();

      // Find the process button by key
      final processButton = find.byKey(const Key('processPaymentButton'));
      expect(processButton, findsOneWidget);
      await tester.ensureVisible(processButton);
      await tester.pump();

      await tester.tap(processButton);
      await tester.pump();
      await tester.pump();

      // Error snackbar should appear
      expect(
        find.textContaining('Error al procesar pago'),
        findsOneWidget,
      );
    });

    testWidgets('shows error state when order service throws', (tester) async {
      final orderService = MockPaymentProcOrderService(
        order: null,
        shouldThrow: true,
      );
      final paymentService = MockPaymentProcPaymentService();

      await tester.pumpWidget(buildPaymentApp(
        orderService: orderService,
        paymentService: paymentService,
      ));
      await tester.pump();
      await tester.pump();

      // Error message should appear
      expect(find.textContaining('Simulated order error'), findsOneWidget);

      // Retry button
      expect(find.text('Reintentar'), findsOneWidget);
    });

    testWidgets('shows order not found when order is null', (tester) async {
      final orderService = MockPaymentProcOrderService(order: null);
      final paymentService = MockPaymentProcPaymentService();

      await tester.pumpWidget(buildPaymentApp(
        orderService: orderService,
        paymentService: paymentService,
      ));
      await tester.pump();
      await tester.pump();

      expect(find.text('Orden no encontrada'), findsOneWidget);
    });

    testWidgets('split button is present and visible', (tester) async {
      final orderService = MockPaymentProcOrderService(order: makeTestOrder(id: 'order-1'));
      final paymentService = MockPaymentProcPaymentService();

      await tester.pumpWidget(buildPaymentApp(
        orderService: orderService,
        paymentService: paymentService,
      ));
      await tester.pump();
      await tester.pump();

      // Verify split button exists by key
      final splitButton = find.byKey(const Key('splitPaymentButton'));
      expect(splitButton, findsOneWidget);
    });
  });
}
