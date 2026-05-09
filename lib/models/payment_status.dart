import 'package:hive/hive.dart';

part 'payment_status.g.dart';

@HiveType(typeId: 14)
enum PaymentStatus {
  @HiveField(0)
  requested,
  @HiveField(1)
  processing,
  @HiveField(2)
  completed,
  @HiveField(3)
  failed,
  @HiveField(4)
  refunded,
}
