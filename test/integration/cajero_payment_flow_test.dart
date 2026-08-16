import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dinnerhome/models/order.dart';
import 'package:dinnerhome/models/order_item.dart' as order_item;

import 'integration_test_helpers.dart';

void main() {
  late TestServices services;

  setUp(() {
    services = TestServices();
  });

  tearDown(() {
    services.socket.dispose();
  });

  /// Seeds a complete order ready for payment:
  /// draft → add item → send to kitchen → prepping → ready → billed
  /// Then requests payment.
  Future<String> seedOrderReadyForPayment() async {
    final draft = await services.order.createDraft(
      waiterId: 'user-mesero-1',
      tableId: '5',
    );
    final orderItem = order_item.OrderItem(
      id: 'oi-pay-1',
      menuItemId: 'item-1',
      quantity: 2,
      priceCents: 1200,
      status: order_item.OrderStatus.pending,
      modifierIds: [],
    );
    final orderId = draft.id;

    await services.order.addItem(orderId: orderId, item: orderItem);
    await services.order.sendToKitchen(
      orderId: orderId,
      byUserId: 'user-mesero-1',
    );
    // Transition through valid states
    await services.order.updateStatus(
      orderId: orderId,
      status: OrderStatus.prepping,
      byUserId: 'user-cocinero-1',
    );
    await services.order.updateStatus(
      orderId: orderId,
      status: OrderStatus.ready,
      byUserId: 'user-cocinero-1',
    );
    await services.order.updateStatus(
      orderId: orderId,
      status: OrderStatus.billed,
      byUserId: 'user-cajero-1',
    );

    await services.payment.requestPayment(
      orderId: orderId,
      requestedBy: 'user-mesero-1',
    );

    return orderId;
  }

  group('Cajero Payment Flow', () {
    testWidgets('processes a pending payment request end-to-end',
        (tester) async {
      // Pre-seed the order and payment request
      await seedOrderReadyForPayment();

      // Build app and login as cajero
      await tester.pumpWidget(services.buildApp());
      await tester.pump();
      await loginViaProvider(tester, cajeroUser);

      // Navigate to cashier payments
      await tapDashboardCard(tester, 'Caja y Cobros');
      await tester.pumpAndSettle();

      // Should see the pending payment request
      expect(find.text('Mesa 5'), findsOneWidget);
      expect(find.text('Cuenta Total'), findsOneWidget);
      expect(find.text('Cuenta Separada'), findsOneWidget);

      // ── Tap on Cuenta Total → navigate to payment processing ──
      await tester.tap(find.text('Cuenta Total'));
      await tester.pumpAndSettle();

      // Should be on payment processing screen
      expect(find.text('Procesar Pago'), findsAtLeastNWidgets(1));

      // Efectivo should be available as a payment method
      expect(find.text('Efectivo'), findsOneWidget);

      // ── Process payment ──
      final processButton = find.byKey(const Key('processPaymentButton'));
      await tester.ensureVisible(processButton);
      await tester.pump();
      await tester.tap(processButton);
      await tester.pump();
      await tester.pump();

      // Success dialog appears
      expect(find.text('Pago Exitoso'), findsOneWidget);
      expect(find.text('Volver a Solicitudes'), findsOneWidget);

      // ── Go back to cashier screen ──
      await tester.tap(find.text('Volver a Solicitudes'));
      await tester.pumpAndSettle();

      // No pending requests remain
      expect(find.text('Sin órdenes pendientes'), findsOneWidget);
    });

    testWidgets('shows empty state when no pending requests', (tester) async {
      await tester.pumpWidget(services.buildApp());
      await tester.pump();
      await loginViaProvider(tester, cajeroUser);

      await tapDashboardCard(tester, 'Caja y Cobros');
      await tester.pumpAndSettle();

      expect(find.text('Sin órdenes pendientes'), findsOneWidget);
    });

    testWidgets('records audit entry on payment processing', (tester) async {
      await seedOrderReadyForPayment();

      await tester.pumpWidget(services.buildApp());
      await tester.pump();
      await loginViaProvider(tester, cajeroUser);

      await tapDashboardCard(tester, 'Caja y Cobros');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cuenta Total'));
      await tester.pumpAndSettle();

      // Process payment
      final processButton = find.byKey(const Key('processPaymentButton'));
      await tester.ensureVisible(processButton);
      await tester.pump();
      await tester.tap(processButton);
      await tester.pump();
      await tester.pump();

      // Verify audit entry
      final paymentAudit =
          services.audit.entriesByAction('payment.processed');
      expect(paymentAudit, hasLength(1));
      expect(paymentAudit.first.userId, 'user-cajero-1');
    });
  });
}
