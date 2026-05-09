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
      // ════════════════════════════════════════════
      // PHASE 1: Admin — morning check
      // ════════════════════════════════════════════
      await tester.pumpWidget(services.buildApp());
      await tester.pump();
      await loginViaProvider(tester, adminUser);

      // Dashboard shows admin options
      expect(find.text('Gestión de Menú'), findsOneWidget);
      expect(find.text('Manage Staff'), findsOneWidget);

      // Navigate to menu to verify items loaded
      await tapDashboardCard(tester, 'Gestión de Menú');
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.text('Pasta Carbonara'), findsOneWidget);
      expect(find.text('Ensalada César'), findsOneWidget);
      expect(find.text('Lomo Saltado'), findsOneWidget);
      expect(find.text('Ceviche Mixto'), findsOneWidget);
      expect(find.text('Sopa del Día'), findsOneWidget);

      // ════════════════════════════════════════════
      // PHASE 2: Mesero — create order for table 5
      // ════════════════════════════════════════════
      await switchUser(tester, meseroUser);

      expect(find.text('View Orders'), findsOneWidget);

      await tapDashboardCard(tester, 'View Orders');
      await tester.pump();
      await tester.pump();

      // Add 2 Pasta Carbonara + 1 Ensalada César
      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pump();
      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pump();
      await tester.tap(find.byIcon(Icons.add).at(1));
      await tester.pump();

      expect(find.text('3 Ítems seleccionados'), findsOneWidget);

      // Send to kitchen
      await tester.tap(find.text('Enviar a Cocina'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();

      expect(find.text('Pedido enviado a cocina'), findsOneWidget);

      // Go back to dashboard
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();
      await tester.pump();

      // ════════════════════════════════════════════
      // PHASE 3: Cocinero — process order in KDS
      // ════════════════════════════════════════════
      await switchUser(tester, cocineroUser);

      await tapDashboardCard(tester, 'Kitchen Orders');
      await tester.pump();
      await tester.pump();
      await tester.pump();

      // Should see the pending order (socket event was emitted)
      expect(find.text('Pendientes (1)'), findsOneWidget);

      // Mark as prepping
      await tester.tap(find.text('Iniciar Preparación'));
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.text('Preparando (1)'), findsOneWidget);

      // Switch tab and mark as ready
      await tester.tap(find.text('Preparando (1)'));
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('Marcar Listo'));
      await tester.pump();
      await tester.pump();
      await tester.pump();

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

      await tapDashboardCard(tester, 'Facturación');
      await tester.pump();
      await tester.pump();

      // Should see payment request
      expect(find.textContaining('Orden #order-1'), findsOneWidget);

      // Process payment
      await tester.tap(find.textContaining('Orden #order-1'));
      await tester.pump();
      await tester.pump();
      await tester.pump();

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
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.text('No hay solicitudes de pago pendientes'), findsOneWidget);

      // ════════════════════════════════════════════
      // PHASE 5: Mesero again — create another order
      // ════════════════════════════════════════════
      await switchUser(tester, meseroUser);

      await tapDashboardCard(tester, 'View Orders');
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pump();

      expect(find.text('1 Ítem seleccionado'), findsOneWidget);

      await tester.tap(find.text('Enviar a Cocina'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();

      expect(find.text('Pedido enviado a cocina'), findsOneWidget);

      // ════════════════════════════════════════════
      // PHASE 6: Admin — check audit log
      // ════════════════════════════════════════════
      await switchUser(tester, adminUser);

      await tapDashboardCard(tester, 'Manage Staff');
      await tester.pump();
      await tester.pump();
      await tester.pump();

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
