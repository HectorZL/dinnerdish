import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dinnerhome/models/audit_entry.dart';
import 'package:dinnerhome/models/menu_item.dart';
import 'package:dinnerhome/models/modifier.dart';
import 'package:dinnerhome/models/order.dart';
import 'package:dinnerhome/models/order_item.dart' as order_item;
import 'package:dinnerhome/models/user.dart';
import 'package:dinnerhome/models/payment_method.dart';
import 'package:dinnerhome/models/payment_summary.dart';
import 'package:dinnerhome/models/payment_transaction.dart';
import 'package:dinnerhome/presentation/screens/create_order_screen.dart';
import 'package:dinnerhome/providers/providers.dart';
import 'package:dinnerhome/services/auth_service.dart';
import 'package:dinnerhome/services/menu_service.dart';
import 'package:dinnerhome/services/order_service.dart';
import 'package:dinnerhome/services/payment_service.dart';
import 'package:dinnerhome/services/audit_service.dart';
import 'package:dinnerhome/services/socket_service.dart';

// ── Mock Services ──────────────────────────────────────────────

class MockMenuService implements MenuService {
  @override
  Future<List<MenuItem>> fetchMenu() async => [
        MenuItem(
          id: 'item-1',
          name: 'Pasta Carbonara',
          priceCents: 1200,
          modifiers: [
            Modifier(id: 'mod-1', name: 'Sin queso', priceCents: 0),
          ],
          available: true,
          category: 'Platos Principales',
        ),
        MenuItem(
          id: 'item-2',
          name: 'Ensalada César',
          priceCents: 850,
          modifiers: [],
          available: true,
          category: 'Entrantes',
        ),
      ];

  @override
  Future<MenuItem?> getMenuItem(String id) async => null;

  @override
  Future<MenuItem> createMenuItem(MenuItem item) async => item;

  @override
  Future<MenuItem> updateMenuItem(String id, MenuItem item) async => item;

  @override
  Future<void> deleteMenuItem(String id) async {}

  @override
  Future<List<String>> getCategories() async => ['Entrantes', 'Platos Principales'];

  @override
  Future<void> adjustStock(String itemId, String? variationId, int quantityChange) async {}
}

class MockOrderService implements OrderService {
  int _counter = 0;

  @override
  Future<List<Order>> getActiveOrders() async {
    return [];
  }

  @override
  Future<Order> createDraft({
    required String waiterId,
    String? tableId,
  }) async {
    _counter++;
    return Order(
      id: 'order-$_counter',
      tableId: tableId ?? '',
      waiterId: waiterId,
      items: [],
      status: OrderStatus.draft,
      subtotalCents: 0,
      taxCents: 0,
      totalCents: 0,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<Order> updateTable({
    required String orderId,
    required String tableId,
  }) async {
    throw UnimplementedError('updateTable not expected in basic tests');
  }

  @override
  Future<Order> addItem({
    required String orderId,
    required order_item.OrderItem item,
  }) async {
    throw UnimplementedError('addItem not expected in basic tests');
  }

  @override
  Future<Order> updateItem({
    required String orderId,
    required order_item.OrderItem item,
    required String byUserId,
  }) async {
    throw UnimplementedError('updateItem not expected in basic tests');
  }

  @override
  Future<Order> removeItem({
    required String orderId,
    required String itemId,
    required String byUserId,
  }) async {
    throw UnimplementedError('removeItem not expected in basic tests');
  }

  @override
  Future<Order> sendToKitchen({
    required String orderId,
    required String byUserId,
  }) async {
    throw UnimplementedError('sendToKitchen not expected in basic tests');
  }

  @override
  Future<Order> updateStatus({
    required String orderId,
    required OrderStatus status,
    required String byUserId,
  }) async {
    throw UnimplementedError('updateStatus not expected in basic tests');
  }

  @override
  Future<Order?> getOrder(String orderId) async => null;

  @override
  Stream<OrderEvent> watchOrders() => const Stream.empty();
}

class MockAuthService implements AuthService {
  @override
  Future<User> login(String username, String password) async => User(
        id: 'user-1',
        username: 'test',
        name: 'Test Waiter',
        role: Role.mesero,
      );

  @override
  Future<User> loginWithTestUser(User user) async => user;

  @override
  Future<void> logout() async {}

  @override
  Future<User?> getCurrentUser() async => User(
        id: 'user-1',
        username: 'test',
        name: 'Test Waiter',
        role: Role.mesero,
      );
}

const _mockUser = User(
  id: 'user-1',
  username: 'test',
  name: 'Test Waiter',
  role: Role.mesero,
);

class MockAuditService implements AuditService {
  @override
  Future<void> record({
    required String action,
    required String userId,
    required Map<String, dynamic> metadata,
    DateTime? timestamp,
  }) async {}

  @override
  Future<List<AuditEntry>> list({int limit = 100, int offset = 0}) async => [];
}

class MockPaymentService implements PaymentService {
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
    throw UnimplementedError();
  }

  @override
  Future<List<PaymentTransaction>> getPaymentHistory(String orderId) async => [];

  @override
  Future<List<PaymentTransaction>> splitPayment({
    required String orderId,
    required List<int> splitAmountsCents,
    required String processedBy,
  }) async {
    throw UnimplementedError();
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

  @override
  List<PaymentTransaction> watchPendingRequests() => [];
}

class MockSocketService implements SocketService {
  @override
  Stream<OrderEvent> get orderEvents => const Stream.empty();

  @override
  void emitOrderEvent(OrderEvent event) {}

  @override
  void dispose() {}
}

// ── ProviderScope builder ──────────────────────────────────────

Widget createTestApp() {
  return ProviderScope(
    overrides: [
      currentUserProvider.overrideWith((ref) {
        final notifier = CurrentUserNotifier(MockAuthService());
        notifier.state = AsyncValue.data(_mockUser);
        return notifier;
      }),
      menuServiceProvider.overrideWith((ref) => MockMenuService()),
      orderServiceProvider.overrideWith((ref) => MockOrderService()),
      auditServiceProvider.overrideWith((ref) => MockAuditService()),
      paymentServiceProvider.overrideWith((ref) => MockPaymentService()),
      socketServiceProvider.overrideWith((ref) => MockSocketService()),
    ],
    child: const MaterialApp(home: CreateOrderScreen()),
  );
}

// ── Tests ──────────────────────────────────────────────────────

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('CreateOrderScreen', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(createTestApp());
      // Should show the loading indicator initially (no crash)
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows loading state initially', (tester) async {
      await tester.pumpWidget(createTestApp());

      // _isLoading starts as true → CircularProgressIndicator visible
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows menu items after async load completes', (tester) async {
      await tester.pumpWidget(createTestApp());
      // Pump twice: flush microtasks for async load, then rebuild
      await tester.pump();
      await tester.pump();

      // The loading indicator should be gone
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Menu items should appear
      expect(find.text('Pasta Carbonara'), findsOneWidget);
      expect(find.text('Ensalada César'), findsOneWidget);

      // Prices should appear in dish cards
      expect(find.text('12.00€'), findsAtLeastNWidgets(1));
      expect(find.text('8.50€'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows header with waiter info', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump();
      await tester.pump();

      // The currentUser mock has name 'Test Waiter'
      expect(find.textContaining('Test Waiter'), findsOneWidget);
    });

    testWidgets('allows adding an item via the counter button',
        (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump();
      await tester.pump();

      // Find and tap the add (+) button for the first dish
      final addButtons = find.byIcon(Icons.add);
      expect(addButtons, findsAtLeastNWidgets(1));

      await tester.tap(addButtons.first);
      await tester.pump();

      // The summary should now show 1 selected item
      expect(find.text('1 Items — 12.00€'), findsOneWidget);
    });

    testWidgets('counter increments quantity display', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump();
      await tester.pump();

      // Add an item twice
      final addButtons = find.byIcon(Icons.add);
      await tester.tap(addButtons.first);
      await tester.pump();

      await tester.tap(addButtons.first);
      await tester.pump();

      // Summary shows 2 selected items
      expect(find.text('2 Items — 24.00€'), findsOneWidget);
    });

    testWidgets('remove button decreases quantity', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump();
      await tester.pump();

      // Add twice, then remove once
      final addButtons = find.byIcon(Icons.add);
      await tester.tap(addButtons.first);
      await tester.pump();
      await tester.tap(addButtons.first);
      await tester.pump();

      // Now remove one
      final removeButtons = find.byIcon(Icons.remove);
      await tester.ensureVisible(removeButtons.first);
      await tester.pumpAndSettle();
      await tester.tap(removeButtons.first);
      await tester.pump();

      expect(find.text('1 Items — 12.00€'), findsOneWidget);
    });

    testWidgets('shows search field and category filters', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump();
      await tester.pump();

      // Search field hint
      expect(find.text('Buscar plato...'), findsOneWidget);

      // Category buttons
      expect(find.text('Todos'), findsOneWidget);
      expect(find.text('Entrantes'), findsOneWidget);
      expect(find.text('Platos Principales'), findsOneWidget);
      expect(find.text('Bebidas'), findsOneWidget);
      expect(find.text('Postres'), findsOneWidget);
    });

    testWidgets('shows order summary at bottom', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump();
      await tester.pump();

      // Summary section
      expect(find.text('0 Items — 0.00€'), findsOneWidget);
    });
  });
}
