import 'package:dinnerhome/models/payment_transaction.dart';
import 'package:dinnerhome/models/payment_method.dart';
import 'package:dinnerhome/models/payment_summary.dart';
import 'package:dinnerhome/services/payment_service.dart';
import 'api_client.dart';

class HttpPaymentService implements PaymentService {
  final ApiClient _client;
  final List<PaymentTransaction> _pendingRequests = [];

  HttpPaymentService({ApiClient? client}) : _client = client ?? ApiClient();

  @override
  Future<void> requestPayment({
    required String orderId,
    required String requestedBy,
    String? reason,
  }) async {
    // Local tracking or notification
  }

  @override
  Future<PaymentTransaction> processPayment({
    required String orderId,
    required int amountCents,
    required PaymentMethod method,
    required String processedBy,
  }) async {
    final res = await _client.post('/api/payments/process', body: {
      'orderId': orderId,
      'amountCents': amountCents,
      'method': method.name,
      'processedBy': processedBy,
    });
    return PaymentTransaction.fromJson(res as Map<String, dynamic>);
  }

  @override
  Future<List<PaymentTransaction>> getPaymentHistory(String orderId) async {
    final res = await _client.get('/api/payments/history/$orderId');
    return (res as List)
        .map((e) => PaymentTransaction.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<PaymentTransaction>> splitPayment({
    required String orderId,
    required List<int> splitAmountsCents,
    required String processedBy,
  }) async {
    final res = await _client.post('/api/payments/split', body: {
      'orderId': orderId,
      'splitAmountsCents': splitAmountsCents,
      'processedBy': processedBy,
    });
    return (res as List)
        .map((e) => PaymentTransaction.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<PaymentTransaction> refundPayment(String transactionId) async {
    final res = await _client.post('/api/payments/$transactionId/refund');
    return PaymentTransaction.fromJson(res as Map<String, dynamic>);
  }

  @override
  Future<List<PaymentSummary>> getPaymentSummaryByMethod({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final res = await _client.get('/api/payments/summary', queryParams: {
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    });
    return (res as List)
        .map((e) => PaymentSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  List<PaymentTransaction> watchPendingRequests() => List.unmodifiable(_pendingRequests);
}
