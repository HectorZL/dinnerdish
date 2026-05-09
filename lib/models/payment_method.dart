import 'package:hive/hive.dart';

part 'payment_method.g.dart';

@HiveType(typeId: 13)
enum PaymentMethod {
  @HiveField(0)
  cash,
  @HiveField(1)
  creditCard,
  @HiveField(2)
  debitCard,
  @HiveField(3)
  transfer,
  @HiveField(4)
  split,
  @HiveField(5)
  qr,
}
