import 'package:hive/hive.dart';

part 'payment_request.g.dart';

@HiveType(typeId: 11)
class PaymentRequest {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String orderId;

  @HiveField(2)
  final String requestedBy;

  @HiveField(3)
  final int amountCents;

  @HiveField(4)
  final DateTime requestedAt;

  @HiveField(5)
  final String? reason;

  const PaymentRequest({
    required this.id,
    required this.orderId,
    required this.requestedBy,
    required this.amountCents,
    required this.requestedAt,
    this.reason,
  }) : assert(amountCents > 0, 'amountCents must be > 0');

  factory PaymentRequest.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    if (id == null) {
      throw ArgumentError('Missing required field: id');
    }
    final orderId = json['orderId'] as String?;
    if (orderId == null) {
      throw ArgumentError('Missing required field: orderId');
    }
    final requestedBy = json['requestedBy'] as String?;
    if (requestedBy == null) {
      throw ArgumentError('Missing required field: requestedBy');
    }
    final amountCents = json['amountCents'] as int?;
    if (amountCents == null) {
      throw ArgumentError('Missing required field: amountCents');
    }
    final requestedAtRaw = json['requestedAt'] as String?;
    if (requestedAtRaw == null) {
      throw ArgumentError('Missing required field: requestedAt');
    }
    final reason = json['reason'] as String?;

    return PaymentRequest(
      id: id,
      orderId: orderId,
      requestedBy: requestedBy,
      amountCents: amountCents,
      requestedAt: DateTime.parse(requestedAtRaw),
      reason: reason,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderId': orderId,
        'requestedBy': requestedBy,
        'amountCents': amountCents,
        'requestedAt': requestedAt.toIso8601String(),
        'reason': reason,
      };
}
