import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dinnerhome/models/order.dart';
import 'package:dinnerhome/models/order_item.dart' as oi;
import 'package:dinnerhome/models/table.dart' as table_model;
import 'package:dinnerhome/models/user.dart';
import 'package:dinnerhome/presentation/screens/main_menu_dashboard.dart';
import 'package:dinnerhome/providers/providers.dart';

class FakeCurrentUserNotifier extends StateNotifier<AsyncValue<User?>>
    implements CurrentUserNotifier {
  FakeCurrentUserNotifier(User? user) : super(AsyncValue.data(user));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('MainMenuDashboard', () {
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
              name: 'Arroz con Pollo',
              quantity: 2,
              priceCents: 1000,
              modifierIds: [],
              status: oi.OrderStatus.preparing,
            ),
          ],
        ),
      ];
    });

    testWidgets('renders dashboard with dishes activity, without TIEMPO MEDIO, and with history button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tablesProvider.overrideWith((ref) => Stream.value(mockTables)),
            activeOrdersProvider.overrideWith((ref) => Stream.value(mockOrders)),
            currentUserProvider.overrideWith((ref) => FakeCurrentUserNotifier(mockAdmin)),
          ],
          child: const MaterialApp(
            home: MainMenuDashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. TIEMPO MEDIO must NOT be present
      expect(find.text('TIEMPO MEDIO'), findsNothing);
      expect(find.text('Tiempo Medio'), findsNothing);

      // 2. MESAS OCUPADAS is present and visible
      expect(find.text('MESAS OCUPADAS'), findsOneWidget);

      // 3. Actividad Reciente de Platos is present
      expect(find.text('Actividad Reciente de Platos'), findsOneWidget);
      expect(find.text('Arroz con Pollo'), findsOneWidget);
      expect(find.text('x2'), findsOneWidget);
      expect(find.text('Mesa 1'), findsOneWidget);

      // 4. "REVISAR HISTORIAL DE PLATOS" button is present
      expect(find.text('REVISAR HISTORIAL DE PLATOS'), findsOneWidget);
    });
  });
}
