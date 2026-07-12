import 'package:hive/hive.dart';
import 'payment_method.dart';
import 'payment_status.dart';

part 'payment_transaction.g.dart';

@HiveType(typeId: 15)
class PaymentTransaction {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String orderId;
  @HiveField(2)
  final String processedBy;
  @HiveField(3)
  final int amountCents;
  @HiveField(4)
  final PaymentMethod method;
  @HiveField(5)
  final PaymentStatus status;
  @HiveField(6)
  final DateTime createdAt;
  @HiveField(7)
  final String? notes;

  const PaymentTransaction({
    required this.id,
    required this.orderId,
    required this.processedBy,
    required this.amountCents,
    required this.method,
    required this.status,
    required this.createdAt,
    this.notes,
  }) : assert(amountCents >= 0, 'amountCents must be >= 0');

  PaymentTransaction copyWith({
    PaymentStatus? status,
    String? notes,
  }) {
    return PaymentTransaction(
      id: id,
      orderId: orderId,
      processedBy: processedBy,
      amountCents: amountCents,
      method: method,
      status: status ?? this.status,
      createdAt: createdAt,
      notes: notes ?? this.notes,
    );
  }

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    if (id == null) {
      throw ArgumentError('Missing required field: id');
    }
    final orderId = json['orderId'] as String?;
    if (orderId == null) {
      throw ArgumentError('Missing required field: orderId');
    }
    final processedBy = json['processedBy'] as String?;
    if (processedBy == null) {
      throw ArgumentError('Missing required field: processedBy');
    }
    final amountCents = json['amountCents'] as int?;
    if (amountCents == null) {
      throw ArgumentError('Missing required field: amountCents');
    }
    final methodRaw = json['method'] as String?;
    if (methodRaw == null) {
      throw ArgumentError('Missing required field: method');
    }
    final statusRaw = json['status'] as String?;
    if (statusRaw == null) {
      throw ArgumentError('Missing required field: status');
    }
    final createdAtRaw = json['createdAt'] as String?;
    if (createdAtRaw == null) {
      throw ArgumentError('Missing required field: createdAt');
    }

    return PaymentTransaction(
      id: id,
      orderId: orderId,
      processedBy: processedBy,
      amountCents: amountCents,
      method: PaymentMethod.values.byName(methodRaw),
      status: PaymentStatus.values.byName(statusRaw),
      createdAt: DateTime.parse(createdAtRaw),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderId': orderId,
        'processedBy': processedBy,
        'amountCents': amountCents,
        'method': method.name,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'notes': notes,
      };
}
