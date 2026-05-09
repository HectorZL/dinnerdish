import 'package:dinnerhome/exceptions/payment_exception.dart';
import 'package:dinnerhome/models/cash_drawer_session.dart';
import 'package:dinnerhome/models/payment_method.dart';
import 'package:dinnerhome/services/audit_service.dart';
import 'package:dinnerhome/services/cash_drawer_service.dart';
import 'package:dinnerhome/services/payment_service.dart';

class InMemoryCashDrawerService implements CashDrawerService {
  final PaymentService _paymentService;
  final AuditService? auditService;

  final Map<String, CashDrawerSession> _sessions = {};
  int _sessionCounter = 0;

  InMemoryCashDrawerService(this._paymentService, {this.auditService});

  @override
  Future<CashDrawerSession> openDrawer({required String cashierId}) async {
    final current = await getCurrentSession();
    if (current != null) {
      throw const PaymentException(
        'A drawer session is already open',
        code: 'DRAWER_ALREADY_OPEN',
      );
    }

    _sessionCounter++;
    final session = CashDrawerSession(
      id: 'drawer-session-$_sessionCounter',
      cashierId: cashierId,
      openedAt: DateTime.now(),
    );
    _sessions[session.id] = session;

    auditService?.record(
      action: 'cash_drawer.opened',
      userId: cashierId,
      metadata: {'sessionId': session.id},
    );
    return session;
  }

  @override
  Future<CashDrawerSession> closeDrawer({
    required String sessionId,
    required int actualBalanceCents,
  }) async {
    final session = _sessions[sessionId];
    if (session == null) {
      throw PaymentNotFoundException(sessionId);
    }

    if (session.status != CashDrawerStatus.open) {
      throw const PaymentException(
        'Drawer session is not open',
        code: 'DRAWER_NOT_OPEN',
      );
    }

    final now = DateTime.now();
    final cashPayments = await _paymentService.getPaymentSummaryByMethod(
      startDate: session.openedAt,
      endDate: now,
    );

    final cashTotal = cashPayments
        .where((s) => s.method == PaymentMethod.cash)
        .fold(0, (sum, s) => sum + s.totalCents);

    final expectedBalanceCents = session.startingBalanceCents + cashTotal;
    final differenceCents = actualBalanceCents - expectedBalanceCents;

    final updated = session.copyWith(
      closedAt: now,
      expectedBalanceCents: expectedBalanceCents,
      actualBalanceCents: actualBalanceCents,
      differenceCents: differenceCents,
      status: CashDrawerStatus.closed,
    );
    _sessions[sessionId] = updated;

    auditService?.record(
      action: 'cash_drawer.closed',
      userId: session.cashierId,
      metadata: {
        'sessionId': sessionId,
        'expectedBalanceCents': expectedBalanceCents,
        'actualBalanceCents': actualBalanceCents,
        'differenceCents': differenceCents,
      },
    );
    return updated;
  }

  @override
  Future<CashDrawerSession?> getCurrentSession() async {
    final openSessions = _sessions.values
        .where((s) => s.status == CashDrawerStatus.open)
        .toList()
      ..sort((a, b) => b.openedAt.compareTo(a.openedAt));
    return openSessions.isNotEmpty ? openSessions.first : null;
  }

  @override
  Future<CashDrawerSession> reconcile({
    required String sessionId,
    required int actualBalanceCents,
  }) async {
    final session = _sessions[sessionId];
    if (session == null) {
      throw PaymentNotFoundException(sessionId);
    }

    if (session.status != CashDrawerStatus.closed) {
      throw const PaymentException(
        'Only closed drawer sessions can be reconciled',
        code: 'DRAWER_NOT_CLOSED',
      );
    }

    final recalculatedDifference =
        actualBalanceCents - session.expectedBalanceCents;

    final updated = session.copyWith(
      actualBalanceCents: actualBalanceCents,
      differenceCents: recalculatedDifference,
      status: CashDrawerStatus.reconciled,
    );
    _sessions[sessionId] = updated;

    auditService?.record(
      action: 'cash_drawer.reconciled',
      userId: session.cashierId,
      metadata: {
        'sessionId': sessionId,
        'expectedBalanceCents': session.expectedBalanceCents,
        'actualBalanceCents': actualBalanceCents,
        'differenceCents': recalculatedDifference,
      },
    );
    return updated;
  }

  @override
  Future<List<CashDrawerSession>> getSessionHistory({int limit = 10}) async {
    final all = _sessions.values.toList()
      ..sort((a, b) => b.openedAt.compareTo(a.openedAt));
    return all.take(limit).toList();
  }
}
