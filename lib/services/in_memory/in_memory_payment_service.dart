import 'package:dinnerhome/exceptions/payment_exception.dart';
import 'package:dinnerhome/models/payment_method.dart';
import 'package:dinnerhome/models/payment_status.dart';
import 'package:dinnerhome/models/payment_summary.dart';
import 'package:dinnerhome/models/payment_transaction.dart';
import 'package:dinnerhome/services/audit_service.dart';
import 'package:dinnerhome/services/payment_service.dart';

/// Record for tracking payment requests without requiring an amount.
class PendingPaymentRequest {
  final String id;
  final String orderId;
  final String requestedBy;
  final DateTime requestedAt;
  final String? reason;

  const PendingPaymentRequest({
    required this.id,
    required this.orderId,
    required this.requestedBy,
    required this.requestedAt,
    this.reason,
  });
}

class InMemoryPaymentService implements PaymentService {
  final AuditService? auditService;

  final List<PendingPaymentRequest> _paymentRequests = [];
  final List<PaymentTransaction> _transactions = [];
  int _requestCounter = 0;
  int _transactionCounter = 0;

  InMemoryPaymentService({this.auditService});

  /// Returns a snapshot of pending payment requests for the CashierScreen.
  List<PendingPaymentRequest> get pendingRequests =>
      List.unmodifiable(_paymentRequests);

  @override
  Future<void> requestPayment({
    required String orderId,
    required String requestedBy,
    String? reason,
  }) async {
    _requestCounter++;
    final request = PendingPaymentRequest(
      id: 'payment-req-$_requestCounter',
      orderId: orderId,
      requestedBy: requestedBy,
      requestedAt: DateTime.now(),
      reason: reason,
    );
    _paymentRequests.add(request);

    auditService?.record(
      action: 'payment.requested',
      userId: requestedBy,
      metadata: {'orderId': orderId, 'reason': reason},
    );
  }

  @override
  Future<PaymentTransaction> processPayment({
    required String orderId,
    required int amountCents,
    required PaymentMethod method,
    required String processedBy,
  }) async {
    if (amountCents < 0) {
      throw const PaymentException(
        'Amount cannot be negative',
        code: 'INVALID_AMOUNT',
      );
    }

    _transactionCounter++;
    final transaction = PaymentTransaction(
      id: 'payment-txn-$_transactionCounter',
      orderId: orderId,
      processedBy: processedBy,
      amountCents: amountCents,
      method: method,
      status: PaymentStatus.completed,
      createdAt: DateTime.now(),
    );
    _transactions.add(transaction);

    auditService?.record(
      action: 'payment.processed',
      userId: processedBy,
      metadata: {
        'orderId': orderId,
        'transactionId': transaction.id,
        'amountCents': amountCents,
        'method': method.name,
      },
    );
    return transaction;
  }

  @override
  Future<List<PaymentTransaction>> getPaymentHistory(String orderId) async {
    return _transactions.where((t) => t.orderId == orderId).toList();
  }

  @override
  Future<List<PaymentTransaction>> splitPayment({
    required String orderId,
    required List<int> splitAmountsCents,
    required String processedBy,
  }) async {
    if (splitAmountsCents.isEmpty) {
      throw const PaymentException(
        'Split amounts must not be empty',
        code: 'SPLIT_EMPTY',
      );
    }

    if (splitAmountsCents.any((a) => a <= 0)) {
      throw const PaymentException(
        'Each split amount must be greater than zero',
        code: 'SPLIT_INVALID_AMOUNT',
      );
    }

    final transactions = <PaymentTransaction>[];
    for (final amount in splitAmountsCents) {
      _transactionCounter++;
      final txn = PaymentTransaction(
        id: 'payment-txn-$_transactionCounter',
        orderId: orderId,
        processedBy: processedBy,
        amountCents: amount,
        method: PaymentMethod.split,
        status: PaymentStatus.completed,
        createdAt: DateTime.now(),
      );
      _transactions.add(txn);
      transactions.add(txn);
    }

    auditService?.record(
      action: 'payment.split',
      userId: processedBy,
      metadata: {
        'orderId': orderId,
        'splitCount': splitAmountsCents.length,
        'totalCents':
            splitAmountsCents.fold(0, (sum, a) => sum + a),
      },
    );
    return transactions;
  }

  @override
  Future<PaymentTransaction> refundPayment(String transactionId) async {
    final index = _transactions.indexWhere((t) => t.id == transactionId);
    if (index == -1) {
      throw PaymentNotFoundException(transactionId);
    }

    final existing = _transactions[index];
    if (existing.status == PaymentStatus.refunded) {
      throw PaymentAlreadyRefundedException(transactionId);
    }

    final refunded = existing.copyWith(status: PaymentStatus.refunded);
    _transactions[index] = refunded;

    auditService?.record(
      action: 'payment.refunded',
      userId: existing.processedBy,
      metadata: {
        'transactionId': transactionId,
        'orderId': existing.orderId,
        'amountCents': existing.amountCents,
      },
    );
    return refunded;
  }

  @override
  List<PaymentTransaction> watchPendingRequests() {
    return _paymentRequests.map((req) => PaymentTransaction(
      id: req.id,
      orderId: req.orderId,
      processedBy: req.requestedBy,
      amountCents: 1,
      method: PaymentMethod.cash,
      status: PaymentStatus.requested,
      createdAt: req.requestedAt,
      notes: req.reason,
    )).toList();
  }

  @override
  Future<List<PaymentSummary>> getPaymentSummaryByMethod({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final completed = _transactions.where(
      (t) =>
          t.status == PaymentStatus.completed &&
          !t.createdAt.isBefore(startDate) &&
          t.createdAt.isBefore(endDate),
    );

    final groups = <PaymentMethod, List<PaymentTransaction>>{};
    for (final txn in completed) {
      groups.putIfAbsent(txn.method, () => []).add(txn);
    }

    return groups.entries.map((entry) {
      final total = entry.value.fold(0, (sum, t) => sum + t.amountCents);
      return PaymentSummary(
        method: entry.key,
        count: entry.value.length,
        totalCents: total,
      );
    }).toList();
  }
}
