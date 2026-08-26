import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dinnerhome/models/order.dart';
import 'package:dinnerhome/models/order_item.dart' as oi;
import 'package:dinnerhome/models/user.dart';
import 'package:dinnerhome/presentation/screens/dish_history_screen.dart';
import 'package:dinnerhome/providers/providers.dart';
import 'package:dinnerhome/services/user_service.dart';

class MockUserService implements UserService {
  final List<User> _users;
  MockUserService(this._users);

  @override
  Future<List<User>> fetchUsers() async => _users;

  @override
  Future<User?> getUser(String id) async {
    try {
      return _users.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<User> createUser(User user) async => user;

  @override
  Future<User> updateUser(String id, User user) async => user;

  @override
  Future<void> deleteUser(String id) async {}
}

void main() {
  group('DishHistoryScreen', () {
    late List<Order> mockOrders;
    late List<User> mockUsers;

    setUp(() {
      mockUsers = [
        const User(
          id: 'user-mesero-1',
          username: 'mesero',
          name: 'Juan Pérez',
          roles: [Role.mesero],
        ),
      ];

      mockOrders = [
        Order(
          id: 'order-1',
          tableId: '4',
          waiterId: 'user-mesero-1',
          status: OrderStatus.sentToKitchen,
          subtotalCents: 2500,
          taxCents: 250,
          totalCents: 2750,
          createdAt: DateTime.now(),
          items: [
            const oi.OrderItem(
              id: 'item-1',
              menuItemId: 'm1',
              name: 'Paella Valenciana',
              quantity: 2,
              priceCents: 1200,
              modifierIds: [],
              status: oi.OrderStatus.preparing,
            ),
            const oi.OrderItem(
              id: 'item-2',
              menuItemId: 'm2',
              name: 'Tapas Variadas',
              quantity: 1,
              priceCents: 350,
              modifierIds: [],
              status: oi.OrderStatus.ready,
            ),
          ],
        ),
      ];
    });

    testWidgets('renders dish history with period tabs, dish items, and no money values', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            allOrdersProvider.overrideWith((ref) => Stream.value(mockOrders)),
            userServiceProvider.overrideWithValue(MockUserService(mockUsers)),
          ],
          child: const MaterialApp(
            home: DishHistoryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Header & Period Tabs
      expect(find.text('Historial de Platos'), findsOneWidget);
      expect(find.text('Día (Hoy)'), findsOneWidget);
      expect(find.text('Esta Semana'), findsOneWidget);
      expect(find.text('Este Mes'), findsOneWidget);
      expect(find.text('Total Histórico'), findsOneWidget);

      // Verify Dishes are displayed
      expect(find.text('Paella Valenciana'), findsOneWidget);
      expect(find.text('Tapas Variadas'), findsOneWidget);
      expect(find.text('Mesa 4'), findsNWidgets(2));
      expect(find.text('x2'), findsOneWidget);
      expect(find.text('x1'), findsOneWidget);

      // Verify NO monetary symbols (€, $, cents) in the table rows
      expect(find.text('27.50€'), findsNothing);
      expect(find.text('12.00€'), findsNothing);
      expect(find.text('3.50€'), findsNothing);
    });

    testWidgets('allows period switching to Semana and Total', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            allOrdersProvider.overrideWith((ref) => Stream.value(mockOrders)),
            userServiceProvider.overrideWithValue(MockUserService(mockUsers)),
          ],
          child: const MaterialApp(
            home: DishHistoryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap 'Esta Semana'
      await tester.tap(find.text('Esta Semana'));
      await tester.pumpAndSettle();
      expect(find.text('Paella Valenciana'), findsOneWidget);

      // Tap 'Total Histórico'
      await tester.tap(find.text('Total Histórico'));
      await tester.pumpAndSettle();
      expect(find.text('Paella Valenciana'), findsOneWidget);
    });
  });
}
