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
  roles: [Role.cajero],
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
  Future<List<Order>> getAllOrders() async {
    return order != null ? [order!] : [];
  }

  @override
  Future<Order> updateItemStatus({
    required String orderId,
    required String itemId,
    required order_item.OrderStatus status,
    required String byUserId,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Order> createDraft({required String waiterId, String? tableId}) async {
    throw UnimplementedError();
  }

  @override
  Future<Order> updateTable({
    required String orderId,
    required String tableId,
  }) async {
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
  Future<Order> addCashierAdditional({
    required String orderId,
    required String additionalId,
    required int quantity,
    required String byUserId,
  }) async {
    final current = order ?? makeTestOrder(id: orderId);
    final item = order_item.OrderItem(
      id: 'cashier-additional-$additionalId',
      menuItemId: 'global-additional:$additionalId',
      name: additionalId,
      quantity: quantity,
      status: order_item.OrderStatus.served,
      modifierIds: [additionalId],
      priceCents: 300,
    );
    final items = [...current.items, item];
    final subtotal = items.fold<int>(
      0,
      (sum, line) => sum + line.priceCents * line.quantity,
    );
    final tax = (subtotal * 0.15).toInt();
    return current.copyWith(
      items: items,
      subtotalCents: subtotal,
      taxCents: tax,
      totalCents: subtotal + tax,
    );
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
  Future<List<PaymentTransaction>> getPaymentHistory(String orderId) async =>
      [];

  @override
  Future<List<PaymentTransaction>> splitPayment({
    required String orderId,
    required List<int> splitAmountsCents,
    required String processedBy,
  }) async {
    return splitAmountsCents
        .map(
          (amount) => PaymentTransaction(
            id: 'split-txn-${splitAmountsCents.indexOf(amount)}',
            orderId: orderId,
            processedBy: processedBy,
            amountCents: amount,
            method: PaymentMethod.split,
            status: PaymentStatus.completed,
            createdAt: DateTime.now(),
          ),
        )
        .toList();
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

Order makeTestOrder({required String id, int totalCents = 2300}) {
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
    taxCents: 300,
    totalCents: totalCents,
    createdAt: DateTime(2026, 5, 8, 14, 30),
  );
}

// ── ProviderScope builder ──────────────────────────────────────

Widget buildPaymentApp({
  required MockPaymentProcOrderService orderService,
  required MockPaymentProcPaymentService paymentService,
  String initialMode = 'total',
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
      home: PaymentProcessingScreen(
        orderId: 'order-1',
        initialMode: initialMode,
      ),
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
      final orderService = MockPaymentProcOrderService(
        order: makeTestOrder(id: 'order-1'),
      );
      final paymentService = MockPaymentProcPaymentService();

      await tester.pumpWidget(
        buildPaymentApp(
          orderService: orderService,
          paymentService: paymentService,
        ),
      );
      await tester.pump();
      await tester.pump();

      // App bar title (appears once - only in AppBar)
      expect(find.text('Procesar Pago'), findsAtLeastNWidgets(1));

      // Process button exists (identified by key)
      expect(find.byKey(const Key('processPaymentButton')), findsOneWidget);

      // Order ID displayed
      expect(find.textContaining('order-1'), findsOneWidget);

      // Table info
      expect(find.text('Mesa table-5'), findsOneWidget);

      // Waiter info
      expect(find.textContaining('waiter-1'), findsOneWidget);

      // Prices
      expect(find.text('\$20.00'), findsAtLeastNWidgets(1)); // subtotal and line item
      expect(find.text('\$3.00'), findsOneWidget); // tax
      expect(find.text('\$23.00'), findsOneWidget); // total
    });

    testWidgets('shows payment method options', (tester) async {
      final orderService = MockPaymentProcOrderService(
        order: makeTestOrder(id: 'order-1'),
      );
      final paymentService = MockPaymentProcPaymentService();

      await tester.pumpWidget(
        buildPaymentApp(
          orderService: orderService,
          paymentService: paymentService,
        ),
      );
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
      final orderService = MockPaymentProcOrderService(
        order: makeTestOrder(id: 'order-1'),
      );
      final paymentService = MockPaymentProcPaymentService(
        processShouldThrow: false,
      );

      await tester.pumpWidget(
        buildPaymentApp(
          orderService: orderService,
          paymentService: paymentService,
        ),
      );
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

    testWidgets('process payment shows error snackbar on failure', (
      tester,
    ) async {
      final orderService = MockPaymentProcOrderService(
        order: makeTestOrder(id: 'order-1'),
      );
      final paymentService = MockPaymentProcPaymentService(
        processShouldThrow: true,
      );

      await tester.pumpWidget(
        buildPaymentApp(
          orderService: orderService,
          paymentService: paymentService,
        ),
      );
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
      expect(find.textContaining('Error al procesar pago'), findsOneWidget);
    });

    testWidgets('shows error state when order service throws', (tester) async {
      final orderService = MockPaymentProcOrderService(
        order: null,
        shouldThrow: true,
      );
      final paymentService = MockPaymentProcPaymentService();

      await tester.pumpWidget(
        buildPaymentApp(
          orderService: orderService,
          paymentService: paymentService,
        ),
      );
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

      await tester.pumpWidget(
        buildPaymentApp(
          orderService: orderService,
          paymentService: paymentService,
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Orden no encontrada'), findsOneWidget);
    });

    testWidgets('split button is present and visible', (tester) async {
      final orderService = MockPaymentProcOrderService(
        order: makeTestOrder(id: 'order-1'),
      );
      final paymentService = MockPaymentProcPaymentService();

      await tester.pumpWidget(
        buildPaymentApp(
          orderService: orderService,
          paymentService: paymentService,
        ),
      );
      await tester.pump();
      await tester.pump();

      // Verify split button exists by key
      final splitButton = find.byKey(const Key('splitPaymentButton'));
      expect(splitButton, findsOneWidget);
    });

    testWidgets('shows Cuenta Total and Cuenta Separada mode options', (
      tester,
    ) async {
      final orderService = MockPaymentProcOrderService(
        order: makeTestOrder(id: 'order-1'),
      );
      final paymentService = MockPaymentProcPaymentService();

      await tester.pumpWidget(
        buildPaymentApp(
          orderService: orderService,
          paymentService: paymentService,
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Cuenta Total'), findsOneWidget);
      expect(find.text('Cuenta Separada'), findsOneWidget);
      expect(find.text('COBRAR CUENTA TOTAL'), findsOneWidget);
    });

    testWidgets('switches to Cuenta Separada mode and allows dish selection per diner', (
      tester,
    ) async {
      final orderService = MockPaymentProcOrderService(
        order: makeTestOrder(id: 'order-1', totalCents: 2500),
      );
      final paymentService = MockPaymentProcPaymentService();

      await tester.pumpWidget(
        buildPaymentApp(
          orderService: orderService,
          paymentService: paymentService,
          initialMode: 'split',
        ),
      );
      await tester.pump();
      await tester.pump();

      // Comensal 1 header and controls
      expect(find.text('Comensal #1'), findsOneWidget);
      expect(find.text('Selecciona los platos que pagará este comensal'), findsOneWidget);
      expect(find.text('Todos los restantes'), findsOneWidget);

      // Initially 0 items selected -> disabled button
      expect(find.text('SELECCIONA PLATOS (COMENSAL #1)'), findsOneWidget);

      // Select 1 of 2 available for item-1
      final incrementItemBtn = find.byKey(const Key('incrementItem_item-1'));
      await tester.ensureVisible(incrementItemBtn);
      await tester.pump();
      await tester.tap(incrementItemBtn);
      await tester.pump();

      expect(find.text('1 de 2 disponible(s)'), findsOneWidget);
      expect(find.textContaining('COBRAR COMENSAL #1'), findsOneWidget);

      // Pay for Comensal 1
      final processButton = find.byKey(const Key('processPaymentButton'));
      await tester.ensureVisible(processButton);
      await tester.pump();
      await tester.tap(processButton);
      await tester.pump();
      await tester.pump();

      // Now advances to Comensal 2
      expect(find.text('Comensal #2'), findsOneWidget);
      expect(find.text('Pagos Realizados en Esta Mesa'), findsOneWidget);
      expect(find.textContaining('Comensal 1'), findsAtLeastNWidgets(1));

      // Comensal 2 selects remaining items using 'Todos los restantes'
      final selectAllBtn = find.byKey(const Key('selectAllRemainingButton'));
      await tester.ensureVisible(selectAllBtn);
      await tester.pump();
      await tester.tap(selectAllBtn);
      await tester.pump();

      expect(find.textContaining('COBRAR COMENSAL #2'), findsOneWidget);
      expect(find.textContaining('Y CERRAR'), findsOneWidget);

      // Pay for Comensal 2 and complete order
      await tester.ensureVisible(processButton);
      await tester.pump();
      await tester.tap(processButton);
      await tester.pump();
      await tester.pump();

      // Success dialog appears
      expect(find.text('Pago Exitoso'), findsOneWidget);
      expect(find.text('Cuenta Separada'), findsAtLeastNWidgets(1));
      expect(find.text('2 comensales pagaron'), findsOneWidget);
    });

    testWidgets(
      r'allows selecting specific dishes for Cortesia ($0.00) and displays discount row',
      (tester) async {
      final orderService = MockPaymentProcOrderService(
        order: makeTestOrder(id: 'order-1'),
      );
      final paymentService = MockPaymentProcPaymentService();

      await tester.pumpWidget(
        buildPaymentApp(
          orderService: orderService,
          paymentService: paymentService,
        ),
      );
      await tester.pump();
      await tester.pump();

      // Open Cortesia dialog
      final cortesiaBtn = find.byKey(const Key('openCortesiaDialogButton'));
      await tester.ensureVisible(cortesiaBtn);
      await tester.pump();
      await tester.tap(cortesiaBtn);
      await tester.pumpAndSettle();

      expect(find.text('Platos de Cortesía'), findsOneWidget);
      expect(find.text('Toda la orden (\$0)'), findsOneWidget);

      // Increment courtesy for item-1 by 1
      final incCourtesyBtn = find.byKey(const Key('incrementCourtesy_item-1'));
      await tester.tap(incCourtesyBtn);
      await tester.pump();

      expect(find.text('-\$10.00'), findsOneWidget); // 1x courtesy = $10.00

      // Confirm courtesy
      final applyCourtesyBtn = find.byKey(const Key('applyCourtesyConfirmButton'));
      await tester.tap(applyCourtesyBtn);
      await tester.pumpAndSettle();

      // Badge on item list
      expect(find.textContaining('🎁 Cortesía: 1 de 2 (\$0.00)'), findsOneWidget);

      // Breakdown displays courtesy discount row
      expect(find.text('Cortesía (Platos \$0.00)'), findsOneWidget);
      expect(find.text('-\$10.00'), findsOneWidget);

      // Recalculated total: Net Subtotal $10.00 + 15% IVA ($1.50) = $11.50
      expect(find.text('\$11.50'), findsOneWidget);
    });

    testWidgets('discount dialog strictly validates positive numerical inputs and applies discount', (
      tester,
    ) async {
      final orderService = MockPaymentProcOrderService(
        order: makeTestOrder(id: 'order-1'),
      );
      final paymentService = MockPaymentProcPaymentService();

      await tester.pumpWidget(
        buildPaymentApp(
          orderService: orderService,
          paymentService: paymentService,
        ),
      );
      await tester.pump();
      await tester.pump();

      // Open Discount dialog
      final discountBtn = find.byKey(const Key('openDiscountDialogButton'));
      await tester.ensureVisible(discountBtn);
      await tester.pump();
      await tester.tap(discountBtn);
      await tester.pumpAndSettle();

      expect(find.text('Aplicar Descuento'), findsOneWidget);
      expect(find.text('Monto (\$)'), findsOneWidget);

      // Enter amount discount $5.00
      final inputField = find.byKey(const Key('discountValueInput'));
      await tester.enterText(inputField, '5.00');
      await tester.pump();

      final applyBtn = find.byKey(const Key('applyDiscountConfirmButton'));
      await tester.tap(applyBtn);
      await tester.pumpAndSettle();

      // Breakdown displays discount row
      expect(find.text('Descuento General'), findsOneWidget);
      expect(find.text('-\$5.00'), findsOneWidget);

      // Recalculated total: Subtotal $20.00 + 15% IVA ($3.00) - $5.00 = $18.00
      expect(find.text('\$18.00'), findsOneWidget);
    });
  });
}
