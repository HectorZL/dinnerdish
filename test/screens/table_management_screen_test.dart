import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dinnerhome/models/order.dart';
import 'package:dinnerhome/models/order_item.dart' as oi;
import 'package:dinnerhome/models/table.dart' as table_model;
import 'package:dinnerhome/models/user.dart';
import 'package:dinnerhome/presentation/screens/table_management_screen.dart';
import 'package:dinnerhome/providers/providers.dart';

class FakeCurrentUserNotifier extends StateNotifier<AsyncValue<User?>>
    implements CurrentUserNotifier {
  FakeCurrentUserNotifier(User? user) : super(AsyncValue.data(user));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('TableManagementScreen', () {
    late List<table_model.Table> mockTables;
    late List<Order> mockOrders;
    late User mockAdmin;

    setUp(() {
      mockAdmin = const User(
        id: 'admin-1',
        username: 'admin',
        name: 'Ana Martínez',
        roles: [Role.admin],
      );

      mockTables = [
        const table_model.Table(
          id: 'table-1',
          number: 1,
          seats: 4,
          status: table_model.TableStatus.occupied,
        ),
        const table_model.Table(
          id: 'table-2',
          number: 2,
          seats: 2,
          status: table_model.TableStatus.available,
        ),
      ];

      mockOrders = [
        Order(
          id: 'order-1',
          tableId: '1',
          waiterId: 'user-mesero-1',
          status: OrderStatus.sentToKitchen,
          subtotalCents: 2000,
          taxCents: 200,
          totalCents: 2200,
          createdAt: DateTime.now(),
          items: [
            const oi.OrderItem(
              id: 'item-1',
              menuItemId: 'm1',
              name: 'Hamburguesa Completa',
              quantity: 2,
              priceCents: 1000,
              modifierIds: [],
              status: oi.OrderStatus.preparing,
            ),
          ],
        ),
      ];
    });

    testWidgets('renders tables with active dishes and allows tapping occupied table for dishes modal', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tablesProvider.overrideWith((ref) => Stream.value(mockTables)),
            activeOrdersProvider.overrideWith((ref) => Stream.value(mockOrders)),
            currentUserProvider.overrideWith((ref) => FakeCurrentUserNotifier(mockAdmin)),
          ],
          child: const MaterialApp(
            home: TableManagementScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Table 1 (occupied) shows dishes
      expect(find.text('Mesa 1'), findsWidgets);
      expect(find.text('OCUPADA'), findsOneWidget);
      expect(find.text('Hamburguesa Completa'), findsOneWidget);
      expect(find.text('x2'), findsOneWidget);

      // Verify Table 2 (available)
      expect(find.text('Mesa 2'), findsOneWidget);
      expect(find.text('DISPONIBLE'), findsOneWidget);

      // Tap Table 1 to view dishes modal
      await tester.tap(find.text('Mesa 1').first);
      await tester.pumpAndSettle();

      // Modal is open with dishes
      expect(find.text('Mesa 1 • Platos Activos'), findsOneWidget);
      expect(find.text('Platos servidos y en cocina (1):'), findsOneWidget);
      expect(find.text('En Cocina'), findsOneWidget);
    });

    testWidgets('respects initialFilter occupied and filter chips', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tablesProvider.overrideWith((ref) => Stream.value(mockTables)),
            activeOrdersProvider.overrideWith((ref) => Stream.value(mockOrders)),
            currentUserProvider.overrideWith((ref) => FakeCurrentUserNotifier(mockAdmin)),
          ],
          child: const MaterialApp(
            home: TableManagementScreen(initialFilter: 'occupied'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Table 1 (occupied) is shown, Table 2 (available) is filtered out
      expect(find.text('Mesa 1'), findsWidgets);
      expect(find.text('Mesa 2'), findsNothing);

      // Tap 'Disponibles (1)'
      await tester.tap(find.text('Disponibles (1)'));
      await tester.pumpAndSettle();

      // Now Table 2 is shown, Table 1 is filtered out
      expect(find.text('Mesa 2'), findsOneWidget);
      expect(find.text('Mesa 1'), findsNothing);
    });
  });
}
