import 'package:flutter_test/flutter_test.dart';

import 'package:dinnerhome/models/order.dart';
import 'package:dinnerhome/models/order_item.dart' as order_item;
import 'package:dinnerhome/widgets/kds_ticket.dart';

import 'integration_test_helpers.dart';

void main() {
  late TestServices services;

  setUp(() {
    services = TestServices();
  });

  tearDown(() {
    services.socket.dispose();
  });

  /// Seeds a kitchen order with Pasta Carbonara × 2 for table 5.
  Future<Order> seedKitchenOrder() async {
    final draft = await services.order.createDraft(
      waiterId: 'user-mesero-1',
      tableId: '5',
    );
    final orderItem = order_item.OrderItem(
      id: 'oi-kds-1',
      menuItemId: 'item-1',
      quantity: 2,
      priceCents: 1200,
      status: order_item.OrderStatus.pending,
      modifierIds: [],
    );
    await services.order.addItem(orderId: draft.id, item: orderItem);
    return services.order.sendToKitchen(
      orderId: draft.id,
      byUserId: 'user-mesero-1',
    );
  }

  group('Cocinero KDS Flow', () {
    testWidgets('receives order, processes through pending→prepping→ready',
        (tester) async {
      // ── Build app and login as cocinero ──
      await tester.pumpWidget(services.buildApp());
      await tester.pump();
      await loginViaProvider(tester, cocineroUser);

      // Dashboard shows Kitchen Orders
      expect(find.text('Pantalla KDS - Cocina'), findsOneWidget);

      // ── Navigate to KDS ──
      await tapDashboardCard(tester, 'Pantalla KDS - Cocina');
      await tester.pump();
      await tester.pump();

      // KDS shows empty state
      expect(find.text('Esperando órdenes...'), findsOneWidget);
      expect(find.text('Conectado'), findsOneWidget);

      // ── Seed a kitchen order (this emits a socket event) ──
      await seedKitchenOrder();
      await tester.pump();
      await tester.pump();

      // Order appears in Pendientes tab
      expect(find.text('Pendientes (1)'), findsOneWidget);
      expect(find.text('Preparando (0)'), findsOneWidget);
      expect(find.text('Listos (0)'), findsOneWidget);
      expect(find.descendant(of: find.byType(KdsTicket), matching: find.text('Mesa 5')), findsOneWidget);
      expect(find.text('Conectado'), findsOneWidget);

      // "Iniciar Preparación" button is visible
      expect(find.text('Iniciar Preparación'), findsOneWidget);

      // ── Mark as Prepping ──
      await tester.tap(find.text('Iniciar Preparación'));
      await tester.pump();
      await tester.pump();
      await tester.pump();

      // Ticket moved to Preparando tab
      expect(find.text('Pendientes (0)'), findsOneWidget);
      expect(find.text('Preparando (1)'), findsOneWidget);
      expect(find.text('Listos (0)'), findsOneWidget);

      // ── Switch to Preparando tab and mark as Ready ──
      await tester.tap(find.text('Preparando (1)'));
      await tester.pumpAndSettle();

      // "Marcar Listo" button visible on the Preparando tab
      expect(find.text('Marcar Listo'), findsOneWidget);

      await tester.tap(find.text('Marcar Listo'));
      await tester.pump();
      await tester.pump();
      await tester.pump();

      // Ticket moved to Listos tab
      expect(find.text('Pendientes (0)'), findsOneWidget);
      expect(find.text('Preparando (0)'), findsOneWidget);
      expect(find.text('Listos (1)'), findsOneWidget);

      // ── Verify audit entries ──
      final statusEntries =
          services.audit.entriesByAction('order.status_updated');
      expect(statusEntries, hasLength(2));
      expect(statusEntries[0].metadata?['toStatus'], 'prepping');
      expect(statusEntries[1].metadata?['toStatus'], 'ready');
    });

    testWidgets('sorts multiple orders into correct tabs', (tester) async {
      await tester.pumpWidget(services.buildApp());
      await tester.pump();
      await loginViaProvider(tester, cocineroUser);

      await tapDashboardCard(tester, 'Pantalla KDS - Cocina');
      await tester.pump();
      await tester.pump();

      // First order → pending
      await seedKitchenOrder();
      await tester.pump();
      await tester.pump();

      expect(find.text('Pendientes (1)'), findsOneWidget);

      // Mark first as prepping
      await tester.tap(find.text('Iniciar Preparación'));
      await tester.pump();
      await tester.pump();
      await tester.pump();

      // Second order → pending
      await seedKitchenOrder();
      await tester.pump();
      await tester.pump();

      // One in each tab
      expect(find.text('Pendientes (1)'), findsOneWidget);
      expect(find.text('Preparando (1)'), findsOneWidget);
      expect(find.text('Listos (0)'), findsOneWidget);
    });

    testWidgets('kitchen user sees only relevant dashboard cards',
        (tester) async {
      await tester.pumpWidget(services.buildApp());
      await tester.pump();
      await loginViaProvider(tester, cocineroUser);

      expect(find.text('Pantalla KDS - Cocina'), findsOneWidget);
      expect(find.text('Caja y Cobros'), findsNothing);
      expect(find.text('Administrar menu'), findsNothing);
    });
  });
}
