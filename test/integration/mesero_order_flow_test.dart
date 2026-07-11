import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'integration_test_helpers.dart';

void main() {
  late TestServices services;

  setUp(() {
    services = TestServices();
  });

  tearDown(() {
    services.socket.dispose();
  });

  group('Mesero Order Flow', () {
    testWidgets('creates order with items, sends to kitchen, requests payment',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(services.buildApp());
      await tester.pump();
      await loginViaProvider(tester, meseroUser);

      // Should be at dashboard
      expect(find.text('Gestión de Pedidos'), findsOneWidget);

      // ── Navigate to Create Order ──
      await tapDashboardCard(tester, 'Gestión de Pedidos');
      await tester.pump();
      await tester.pump();

      // Menu items should appear after load
      expect(find.text('Pasta Carbonara'), findsOneWidget);
      expect(find.text('Ensalada César'), findsOneWidget);

      // ── Add 2 Pasta Carbonara ──
      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pump();
      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pump();

      // ── Add 1 Ensalada César ──
      await tester.tap(find.byIcon(Icons.add).at(1));
      await tester.pump();

      // ── Verify summary ──
      expect(find.text('3 Ítems seleccionados'), findsOneWidget);

      // Pasta Carbonara (1200¢ × 2) + Ensalada César (850¢ × 1) = 3250¢
      expect(find.text('\$32.50'), findsAtLeastNWidgets(1));

      // ── Send to Kitchen ──
      final sendButton = find.text('Enviar a Cocina');
      await tester.ensureVisible(sendButton);
      await tester.pump();
      await tester.tap(sendButton);
      await tester.pumpAndSettle();

      // Confirmation dialog
      expect(find.text('Confirmar'), findsOneWidget);

      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();

      // Verify success snackbar
      expect(find.text('Pedido enviado a cocina'), findsOneWidget);

      // Verify audit entries
      final kitchenEntries =
          services.audit.entriesByAction('order.sent_to_kitchen');
      expect(kitchenEntries, isNotEmpty);
      expect(kitchenEntries.first.userId, 'user-mesero-1');

      // ── Request Payment ──
      final payButton = find.text('Solicitar Pago');
      await tester.ensureVisible(payButton);
      await tester.pump();
      await tester.tap(payButton);
      await tester.pumpAndSettle();

      // Verify payment requested
      expect(find.text('Pago solicitado al cajero'), findsOneWidget);

      // Verify payment request in service
      expect(services.payment.pendingRequests, hasLength(1));
      expect(services.payment.pendingRequests.first.requestedBy, 'user-mesero-1');
    }, semanticsEnabled: false);

    testWidgets('shows error when sending empty order', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(services.buildApp());
      await tester.pump();
      await loginViaProvider(tester, meseroUser);

      // Navigate to Create Order
      await tapDashboardCard(tester, 'Gestión de Pedidos');
      await tester.pump();
      await tester.pump();

      // Try to send to kitchen without selecting items
      await tester.tap(find.text('Enviar a Cocina'));
      await tester.pumpAndSettle();

      // Error snackbar
      expect(find.text('Seleccione al menos un plato para enviar'),
          findsOneWidget);

      // No confirmation dialog
      expect(find.text('Confirmar'), findsNothing);
    }, semanticsEnabled: false);
  });
}
