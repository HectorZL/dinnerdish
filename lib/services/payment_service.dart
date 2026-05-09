import 'package:dinnerhome/models/payment_transaction.dart';
import 'package:dinnerhome/models/payment_method.dart';
import 'package:dinnerhome/models/payment_summary.dart';

abstract class PaymentService {
  Future<void> requestPayment({
    required String orderId,
    required String requestedBy,
    String? reason,
  });

  Future<PaymentTransaction> processPayment({
    required String orderId,
    required int amountCents,
    required PaymentMethod method,
    required String processedBy,
  });

  Future<List<PaymentTransaction>> getPaymentHistory(String orderId);

  Future<List<PaymentTransaction>> splitPayment({
    required String orderId,
    required List<int> splitAmountsCents,
    required String processedBy,
  });

  Future<PaymentTransaction> refundPayment(String transactionId);

  Future<List<PaymentSummary>> getPaymentSummaryByMethod({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Returns all payment requests that have been requested but not yet processed.
  List<PaymentTransaction> watchPendingRequests();
}
