import 'package:hive/hive.dart';
import 'payment_method.dart';

part 'payment_summary.g.dart';

@HiveType(typeId: 18)
class PaymentSummary {
  @HiveField(0)
  final PaymentMethod method;
  @HiveField(1)
  final int count;
  @HiveField(2)
  final int totalCents;

  const PaymentSummary({
    required this.method,
    required this.count,
    required this.totalCents,
  }) : assert(count >= 0, 'count must be >= 0'),
       assert(totalCents >= 0, 'totalCents must be >= 0');
}
