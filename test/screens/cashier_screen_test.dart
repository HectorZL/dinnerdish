import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:dinnerhome/models/order.dart';
import 'package:dinnerhome/presentation/screens/cashier_pending_screen.dart';
import 'package:dinnerhome/providers/providers.dart';

Widget buildCashierApp(List<Order> orders) {
  GoogleFonts.config.allowRuntimeFetching = false;
  return ProviderScope(
    overrides: [
      activeOrdersProvider.overrideWith((ref) => Stream.value(orders)),
    ],
    child: const MaterialApp(home: CashierPendingScreen()),
  );
}

Order makeBilledOrder({
  required String id,
  required String tableId,
  int totalCents = 1200,
}) {
  return Order(
    id: id,
    tableId: tableId,
    waiterId: 'waiter-1',
    items: const [],
    status: OrderStatus.billed,
    subtotalCents: totalCents,
    taxCents: 0,
    totalCents: totalCents,
    createdAt: DateTime(2026, 5, 8, 14, 30),
  );
}

void main() {
  group('CashierPendingScreen', () {
    testWidgets('renders the billed orders screen', (tester) async {
      await tester.pumpWidget(buildCashierApp([]));
      await tester.pumpAndSettle();

      expect(find.text('Pendientes de Cobro'), findsOneWidget);
    });

    testWidgets('shows the empty state when no order is billed', (
      tester,
    ) async {
      await tester.pumpWidget(buildCashierApp([]));
      await tester.pumpAndSettle();

      expect(find.text('Sin órdenes pendientes'), findsOneWidget);
    });

    testWidgets('renders billed orders and ignores orders in other states', (
      tester,
    ) async {
      final billedOrder = makeBilledOrder(id: 'order-1', tableId: 'table-5');
      final readyOrder = makeBilledOrder(
        id: 'order-2',
        tableId: 'table-6',
      ).copyWith(status: OrderStatus.ready);

      await tester.pumpWidget(buildCashierApp([billedOrder, readyOrder]));
      await tester.pumpAndSettle();

      expect(find.text('Mesa table-5'), findsOneWidget);
      expect(find.text('Mesa table-6'), findsNothing);
      expect(find.text(r'$12.00'), findsOneWidget);
      expect(find.text('Cuenta Total'), findsOneWidget);
      expect(find.text('Cuenta Separada'), findsOneWidget);
    });
  });
}
