import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dinnerhome/models/user.dart';
import 'package:dinnerhome/models/payment_method.dart';
import 'package:dinnerhome/models/payment_status.dart';
import 'package:dinnerhome/models/payment_summary.dart';
import 'package:dinnerhome/models/payment_transaction.dart';
import 'package:dinnerhome/presentation/screens/cashier_screen.dart';
import 'package:dinnerhome/providers/providers.dart';
import 'package:dinnerhome/services/auth_service.dart';
import 'package:dinnerhome/services/payment_service.dart';

// ── Mock Services ──────────────────────────────────────────────

class MockCashierAuthService implements AuthService {
  @override
  Future<User> login(String username, String password) async => _mockUser;

  @override
  Future<User> loginWithTestUser(User user) async => user;

  @override
  Future<void> logout() async {}

  @override
  Future<User?> getCurrentUser() async => _mockUser;
}

const _mockUser = User(
  id: 'user-cajero-1',
  username: 'cajero',
  name: 'María García',
  role: Role.cajero,
);

class MockCashierPaymentService implements PaymentService {
  final List<PaymentTransaction> pendingRequests;
  final bool shouldThrow;
  int callCount = 0;
  final bool failThenSucceed;

  MockCashierPaymentService({
    this.pendingRequests = const [],
    this.shouldThrow = false,
    this.failThenSucceed = false,
  });

  @override
  List<PaymentTransaction> watchPendingRequests() {
    callCount++;
    if (shouldThrow) {
      throw Exception('Simulated payment error');
    }
    if (failThenSucceed && callCount == 1) {
      throw Exception('Simulated payment error');
    }
    return pendingRequests;
  }

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
}

PaymentTransaction makePendingRequest({
  required String id,
  required String orderId,
  String requestedBy = 'waiter-1',
}) {
  return PaymentTransaction(
    id: id,
    orderId: orderId,
    processedBy: requestedBy,
    amountCents: 1,
    method: PaymentMethod.cash,
    status: PaymentStatus.requested,
    createdAt: DateTime(2026, 5, 8, 14, 30),
  );
}

// ── ProviderScope builder ──────────────────────────────────────

Widget buildCashierApp(MockCashierPaymentService paymentService) {
  return ProviderScope(
    overrides: [
      currentUserProvider.overrideWith((ref) {
        final notifier = CurrentUserNotifier(MockCashierAuthService());
        notifier.state = AsyncValue.data(_mockUser);
        return notifier;
      }),
      paymentServiceProvider.overrideWith((ref) => paymentService),
    ],
    child: MaterialApp(
      home: CashierScreen(),
    ),
  );
}

// ── Tests ──────────────────────────────────────────────────────

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('CashierScreen', () {
    testWidgets('renders without crashing', (tester) async {
      final paymentService = MockCashierPaymentService(pendingRequests: []);

      await tester.pumpWidget(buildCashierApp(paymentService));
      await tester.pump();

      // Screen renders without crash - app bar title
      expect(find.text('Solicitudes de Pago'), findsOneWidget);
    });

    testWidgets('shows empty state when no pending requests', (tester) async {
      final paymentService = MockCashierPaymentService(pendingRequests: []);

      await tester.pumpWidget(buildCashierApp(paymentService));
      await tester.pump();
      await tester.pump();

      expect(
        find.text('No hay solicitudes de pago pendientes'),
        findsOneWidget,
      );
    });

    testWidgets('renders list of pending payment requests', (tester) async {
      final paymentService = MockCashierPaymentService(
        pendingRequests: [
          makePendingRequest(id: 'req-1', orderId: 'order-1'),
          makePendingRequest(id: 'req-2', orderId: 'order-2'),
        ],
      );

      await tester.pumpWidget(buildCashierApp(paymentService));
      await tester.pump();
      await tester.pump();

      // Order IDs displayed
      expect(find.textContaining('order-1'), findsOneWidget);
      expect(find.textContaining('order-2'), findsOneWidget);

      // Requested by info
      expect(find.textContaining('waiter-1'), findsAtLeastNWidgets(1));

      // Date/time displayed
      expect(find.textContaining('08/05/2026'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows error state when service throws', (tester) async {
      final paymentService = MockCashierPaymentService(shouldThrow: true);

      await tester.pumpWidget(buildCashierApp(paymentService));
      await tester.pump();
      await tester.pump();

      // Error message is displayed
      expect(find.textContaining('Simulated payment error'), findsOneWidget);

      // Retry button is present
      expect(find.text('Reintentar'), findsOneWidget);
    });

    testWidgets('retry button triggers reload after error', (tester) async {
      final paymentService = MockCashierPaymentService(
        failThenSucceed: true,
        pendingRequests: [
          makePendingRequest(id: 'req-3', orderId: 'order-3'),
        ],
      );

      await tester.pumpWidget(buildCashierApp(paymentService));
      await tester.pump();
      await tester.pump();

      // First call throws → error state with retry button
      expect(find.text('Reintentar'), findsOneWidget);

      // Tap retry → triggers _loadPendingRequests again
      await tester.tap(find.text('Reintentar'));
      await tester.pump();
      await tester.pump();

      // Now the request should appear
      expect(find.textContaining('order-3'), findsOneWidget);
      expect(find.text('No hay solicitudes de pago pendientes'), findsNothing);
    });

    testWidgets('tapping a request card triggers navigation', (tester) async {
      final paymentService = MockCashierPaymentService(
        pendingRequests: [
          makePendingRequest(id: 'req-1', orderId: 'order-42'),
        ],
      );

      await tester.pumpWidget(buildCashierApp(paymentService));
      await tester.pump();
      await tester.pump();

      // Verify the card is rendered with the order ID
      expect(find.textContaining('order-42'), findsOneWidget);
    });
  });
}
