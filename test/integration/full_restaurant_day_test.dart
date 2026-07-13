import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dinnerhome/models/user.dart';
import 'package:dinnerhome/models/order.dart';
import 'package:dinnerhome/providers/providers.dart';


import 'integration_test_helpers.dart';

void main() {
  late TestServices services;

  setUp(() {
    services = TestServices();
  });

  tearDown(() {
    services.socket.dispose();
  });

  /// Switches user by calling the provider notifier.
  Future<void> switchUser(WidgetTester tester, User user) async {
    final ctx = tester.element(find.byType(MaterialApp));
    final container = ProviderScope.containerOf(ctx, listen: false);
    await container.read(currentUserProvider.notifier).loginWithTestUser(user);
    await tester.pumpAndSettle();
  }

  group('Full Restaurant Day', () {
    testWidgets('multi-role restaurant day simulation', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // ════════════════════════════════════════════
      // PHASE 1: Admin — morning check
      // ════════════════════════════════════════════
      await tester.pumpWidget(services.buildApp());
      await tester.pump();
      await loginViaProvider(tester, adminUser);

      // Dashboard shows admin options
      expect(find.text('Administrar menu'), findsOneWidget);
      expect(find.text('Administrar usuarios'), findsOneWidget);

      // Navigate to menu to verify items loaded
      await tapDashboardCard(tester, 'Administrar menu');
      await tester.pumpAndSettle();

      expect(find.text('Pasta Carbonara'), findsOneWidget);
      expect(find.text('Ensalada César'), findsOneWidget);
      expect(find.text('Lomo Saltado'), findsOneWidget);
      expect(find.text('Ceviche Mixto'), findsOneWidget);
      await tester.drag(
        find.byWidgetPredicate((w) => w is ListView && w.scrollDirection == Axis.vertical),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      expect(find.text('Sopa del Día'), findsOneWidget);

      // ════════════════════════════════════════════
      // PHASE 2: Mesero — create order for table 5
      // ════════════════════════════════════════════
      await switchUser(tester, meseroUser);

      expect(find.text('Gestión de Pedidos'), findsOneWidget);

      await tapDashboardCard(tester, 'Gestión de Pedidos');
      await tester.pumpAndSettle();

      // Add 2 Pasta Carbonara + 1 Ensalada César
      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pump();
      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pump();
      await tester.tap(find.byIcon(Icons.add).at(1));
      await tester.pump();

      expect(find.textContaining('3 Items'), findsOneWidget);

      // Open bottom sheet
      await tester.tap(find.textContaining('3 Items'));
      await tester.pumpAndSettle();

      // Send to kitchen
      await tester.tap(find.text('Confirmar y Enviar a Cocina'));
      await tester.pumpAndSettle();

      expect(find.text('Pedido enviado a cocina'), findsOneWidget);

      // Go back to dashboard
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // ════════════════════════════════════════════
      // PHASE 3: Cocinero — process order in KDS
      // ════════════════════════════════════════════
      await switchUser(tester, cocineroUser);

      await tapDashboardCard(tester, 'Pantalla KDS - Cocina');
      await tester.pumpAndSettle();

      // Should see the pending order (socket event was emitted)
      expect(find.text('Pendientes (1)'), findsOneWidget);

      // Mark as prepping
      await tester.tap(find.text('Iniciar Preparación'));
      await tester.pumpAndSettle();

      expect(find.text('Preparando (1)'), findsOneWidget);

      // Switch tab and mark as ready
      await tester.tap(find.text('Preparando (1)'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Marcar Listo'));
      await tester.pumpAndSettle();

      expect(find.text('Listos (1)'), findsOneWidget);

      // ════════════════════════════════════════════
      // PHASE 4: Cajero — process payment
      // ════════════════════════════════════════════
      // First, transition order to billed and request payment
      // We need the order id: it should be "order-1" (first in the test)
      await services.order.updateStatus(
        orderId: 'order-1',
        status: OrderStatus.billed,
        byUserId: 'user-cajero-1',
      );
      await services.payment.requestPayment(
        orderId: 'order-1',
        requestedBy: 'user-mesero-1',
      );

      await switchUser(tester, cajeroUser);

      await tapDashboardCard(tester, 'Caja y Cobros');
      await tester.pumpAndSettle();

      // Should see payment request
      expect(find.text('Mesa 01'), findsOneWidget);

      // Process payment
      await tester.tap(find.text('Cobrar ahora'));
      await tester.pumpAndSettle();

      expect(find.text('Procesar Pago'), findsAtLeastNWidgets(1));

      final processButton = find.byKey(const Key('processPaymentButton'));
      await tester.ensureVisible(processButton);
      await tester.pump();
      await tester.tap(processButton);
      await tester.pump();
      await tester.pump();

      expect(find.text('Pago Exitoso'), findsOneWidget);

      // Return to cashier
      await tester.tap(find.text('Volver a Solicitudes'));
      await tester.pumpAndSettle();

      expect(find.text('Sin órdenes pendientes'), findsOneWidget);

      // ════════════════════════════════════════════
      // PHASE 5: Mesero again — create another order
      // ════════════════════════════════════════════
      await switchUser(tester, meseroUser);

      await tapDashboardCard(tester, 'Gestión de Pedidos');
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pumpAndSettle();

      expect(find.textContaining('1 Items'), findsOneWidget);

      // Open bottom sheet
      await tester.tap(find.textContaining('1 Items'));
      await tester.pumpAndSettle();

      // Send to kitchen
      await tester.tap(find.text('Confirmar y Enviar a Cocina'));
      await tester.pumpAndSettle();

      expect(find.text('Pedido enviado a cocina'), findsOneWidget);

      // Go back to dashboard
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // ════════════════════════════════════════════
      // PHASE 6: Admin — check audit log
      // ════════════════════════════════════════════
      await switchUser(tester, adminUser);

      await tapDashboardCard(tester, 'Administrar usuarios');
      await tester.pumpAndSettle();

      // Navigate to Audit Log from the side menu
      await tester.tap(find.text('Auditoría'));
      await tester.pumpAndSettle();

      // Audit log screen
      expect(find.text('Registro de Auditoría'), findsOneWidget);

      // Verify multiple audit entries
      final allEntries = await services.audit.list();
      expect(allEntries.length, greaterThanOrEqualTo(10),
          reason: 'Should have many audit entries for the full day flow');

      // Verify key actions were recorded
      final actions = allEntries.map((e) => e.action).toSet();
      expect(actions, contains('order.created'));
      expect(actions, contains('order.item_added'));
      expect(actions, contains('order.sent_to_kitchen'));
      expect(actions, contains('order.status_updated'));
      expect(actions, contains('payment.requested'));
      expect(actions, contains('payment.processed'));

      // Verify order-1 data integrity (should be billed)
      final order1 = await services.order.getOrder('order-1');
      expect(order1, isNotNull);
      expect(order1!.status, OrderStatus.billed);
    });
  });
}
