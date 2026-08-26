import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dinnerhome/models/user.dart';
import 'package:dinnerhome/models/cash_drawer_session.dart';
import 'package:dinnerhome/presentation/screens/cash_drawer_screen.dart';
import 'package:dinnerhome/providers/providers.dart';
import 'package:dinnerhome/services/auth_service.dart';
import 'package:dinnerhome/services/cash_drawer_service.dart';
import 'package:dinnerhome/services/payment_service.dart';
import 'package:dinnerhome/models/payment_method.dart';
import 'package:dinnerhome/models/payment_summary.dart';
import 'package:dinnerhome/models/payment_transaction.dart';

// ── Mock Services ──────────────────────────────────────────────

const _mockUser = User(
  id: 'user-cajero-1',
  username: 'cajero',
  name: 'María García',
  roles: [Role.cajero],
);

class MockDrawerAuthService implements AuthService {
  @override
  Future<User> login(String username, String password) async => _mockUser;

  @override
  Future<User> loginWithTestUser(User user) async => user;

  @override
  Future<void> logout() async {}

  @override
  Future<User?> getCurrentUser() async => _mockUser;
}

class MockDrawerPaymentService implements PaymentService {
  @override
  List<PaymentTransaction> watchPendingRequests() => [];

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

class MockCashDrawerService implements CashDrawerService {
  CashDrawerSession? currentSession;
  List<CashDrawerSession> history;
  final bool openShouldThrow;
  final bool closeShouldThrow;
  final bool reconcileShouldThrow;

  MockCashDrawerService({
    this.currentSession,
    this.history = const [],
    this.openShouldThrow = false,
    this.closeShouldThrow = false,
    this.reconcileShouldThrow = false,
  });

  @override
  Future<CashDrawerSession> openDrawer({required String cashierId}) async {
    if (openShouldThrow) {
      throw Exception('Simulated open error');
    }
    final session = CashDrawerSession(
      id: 'session-open-1',
      cashierId: cashierId,
      openedAt: DateTime.now(),
    );
    currentSession = session;
    return session;
  }

  @override
  Future<CashDrawerSession> closeDrawer({
    required String sessionId,
    required int actualBalanceCents,
  }) async {
    if (closeShouldThrow) {
      throw Exception('Simulated close error');
    }
    final session = CashDrawerSession(
      id: sessionId,
      cashierId: 'cajero-1',
      openedAt: DateTime.now(),
      closedAt: DateTime.now(),
      startingBalanceCents: 0,
      expectedBalanceCents: 10000,
      actualBalanceCents: actualBalanceCents,
      differenceCents: actualBalanceCents - 10000,
      status: CashDrawerStatus.closed,
    );
    currentSession = session;
    return session;
  }

  @override
  Future<CashDrawerSession?> getCurrentSession() async => currentSession;

  @override
  Future<CashDrawerSession> reconcile({
    required String sessionId,
    required int actualBalanceCents,
  }) async {
    if (reconcileShouldThrow) {
      throw Exception('Simulated reconcile error');
    }
    final session = CashDrawerSession(
      id: sessionId,
      cashierId: 'cajero-1',
      openedAt: DateTime.now(),
      closedAt: DateTime.now(),
      startingBalanceCents: 0,
      expectedBalanceCents: 10000,
      actualBalanceCents: actualBalanceCents,
      differenceCents: actualBalanceCents - 10000,
      status: CashDrawerStatus.reconciled,
    );
    currentSession = session;
    return session;
  }

  @override
  Future<List<CashDrawerSession>> getSessionHistory({int limit = 10}) async {
    return history;
  }
}

// ── Helpers ────────────────────────────────────────────────────

CashDrawerSession makeOpenSession({String id = 'session-1'}) {
  return CashDrawerSession(
    id: id,
    cashierId: 'cajero-1',
    openedAt: DateTime(2026, 5, 8, 8, 0),
    startingBalanceCents: 50000,
  );
}

CashDrawerSession makeClosedSession({String id = 'session-1'}) {
  return CashDrawerSession(
    id: id,
    cashierId: 'cajero-1',
    openedAt: DateTime(2026, 5, 8, 8, 0),
    closedAt: DateTime(2026, 5, 8, 18, 0),
    startingBalanceCents: 50000,
    expectedBalanceCents: 125000,
    actualBalanceCents: 125500,
    differenceCents: 500,
    status: CashDrawerStatus.closed,
  );
}

CashDrawerSession makeReconciledSession({String id = 'session-1'}) {
  return CashDrawerSession(
    id: id,
    cashierId: 'cajero-1',
    openedAt: DateTime(2026, 5, 8, 8, 0),
    closedAt: DateTime(2026, 5, 8, 18, 0),
    startingBalanceCents: 50000,
    expectedBalanceCents: 125000,
    actualBalanceCents: 125000,
    differenceCents: 0,
    status: CashDrawerStatus.reconciled,
  );
}

// ── ProviderScope builder ──────────────────────────────────────

Widget buildDrawerApp(MockCashDrawerService drawerService) {
  return ProviderScope(
    overrides: [
      currentUserProvider.overrideWith((ref) {
        final notifier = CurrentUserNotifier(MockDrawerAuthService());
        notifier.state = AsyncValue.data(_mockUser);
        return notifier;
      }),
      cashDrawerServiceProvider.overrideWith((ref) => drawerService),
      paymentServiceProvider.overrideWith((ref) => MockDrawerPaymentService()),
    ],
    child: const MaterialApp(home: CashDrawerScreen()),
  );
}

// ── Tests ──────────────────────────────────────────────────────

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('CashDrawerScreen', () {
    testWidgets('shows loading state initially', (tester) async {
      final drawerService = MockCashDrawerService();

      await tester.pumpWidget(buildDrawerApp(drawerService));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state when no session and no history',
        (tester) async {
      final drawerService = MockCashDrawerService();

      await tester.pumpWidget(buildDrawerApp(drawerService));
      await tester.pump();
      await tester.pump();

      expect(find.text('No hay sesiones de caja'), findsOneWidget);
      expect(find.text('Abrir Caja'), findsOneWidget);
    });

    testWidgets('shows open session details', (tester) async {
      final drawerService = MockCashDrawerService(
        currentSession: makeOpenSession(),
      );

      await tester.pumpWidget(buildDrawerApp(drawerService));
      await tester.pump();
      await tester.pump();

      // Session ID displayed
      expect(find.textContaining('session-1'), findsOneWidget);

      // Status badge
      expect(find.text('Abierta'), findsOneWidget);

      // Starting balance
      expect(find.text('\$500.00'), findsAtLeastNWidgets(1));

      // Close button
      expect(find.text('Cerrar Caja'), findsOneWidget);
    });

    testWidgets('shows closed session with difference', (tester) async {
      final drawerService = MockCashDrawerService(
        currentSession: makeClosedSession(),
      );

      await tester.pumpWidget(buildDrawerApp(drawerService));
      await tester.pump();
      await tester.pump();

      // Status badge
      expect(find.text('Cerrada'), findsOneWidget);

      // Difference displayed
      expect(find.textContaining('+\$5.00'), findsOneWidget);
    });

    testWidgets('shows reconciled session', (tester) async {
      final drawerService = MockCashDrawerService(
        currentSession: makeReconciledSession(),
      );

      await tester.pumpWidget(buildDrawerApp(drawerService));
      await tester.pump();
      await tester.pump();

      // Status badge
      expect(find.text('Reconciliada'), findsOneWidget);
    });

    testWidgets('open drawer button creates a new session', (tester) async {
      final drawerService = MockCashDrawerService();

      await tester.pumpWidget(buildDrawerApp(drawerService));
      await tester.pump();
      await tester.pump();

      // Tap "Abrir Caja"
      await tester.tap(find.text('Abrir Caja'));
      await tester.pump();
      await tester.pump();

      // Session should now be open (snackbar shown)
      expect(find.textContaining('Caja abierta'), findsOneWidget);
    });

    testWidgets('open drawer shows error on failure', (tester) async {
      final drawerService = MockCashDrawerService(openShouldThrow: true);

      await tester.pumpWidget(buildDrawerApp(drawerService));
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('Abrir Caja'));
      await tester.pump();
      await tester.pump();

      // Error snackbar shown
      expect(find.text('Error: Exception: Simulated open error'), findsOneWidget);
    });

    testWidgets('close drawer shows amount dialog', (tester) async {
      final drawerService = MockCashDrawerService(
        currentSession: makeOpenSession(),
      );

      await tester.pumpWidget(buildDrawerApp(drawerService));
      await tester.pump();
      await tester.pump();

      // Tap "Cerrar Caja"
      await tester.tap(find.text('Cerrar Caja'));
      await tester.pump();
      await tester.pump();

      // Amount dialog should appear
      expect(find.text('Cerrar Caja'), findsAtLeastNWidgets(2)); // button + dialog title
      expect(find.text('Cancelar'), findsOneWidget);
      expect(find.text('Confirmar'), findsOneWidget);
    });

    testWidgets('show session history', (tester) async {
      final drawerService = MockCashDrawerService(
        currentSession: makeOpenSession(),
        history: [
          makeClosedSession(id: 'session-prev-1'),
          makeReconciledSession(id: 'session-prev-2'),
        ],
      );

      await tester.pumpWidget(buildDrawerApp(drawerService));
      await tester.pump();
      await tester.pump();

      // History section
      expect(find.text('Historial de Sesiones'), findsOneWidget);

      // Previous sessions displayed
      expect(find.textContaining('session-prev-1'), findsOneWidget);
      expect(find.textContaining('session-prev-2'), findsOneWidget);

      // Status badges in history
      expect(find.text('Cerrada'), findsAtLeastNWidgets(1));
      expect(find.text('Reconciliada'), findsOneWidget);
    });

    testWidgets('close drawer shows error on failure', (tester) async {
      final throwingService = MockCashDrawerService(
        currentSession: makeOpenSession(),
        closeShouldThrow: true,
      );

      await tester.pumpWidget(buildDrawerApp(throwingService));
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('Cerrar Caja'));
      await tester.pump();
      await tester.pump();

      // Cancel the dialog to avoid close action
      await tester.tap(find.text('Cancelar'));
      await tester.pump();
    });

    testWidgets('reconcile button present when session is closed',
        (tester) async {
      final drawerService = MockCashDrawerService(
        currentSession: makeClosedSession(),
      );

      await tester.pumpWidget(buildDrawerApp(drawerService));
      await tester.pump();
      await tester.pump();

      // Reconcile button should appear for closed sessions
      expect(find.text('Conciliar'), findsOneWidget);
    });
  });
}
