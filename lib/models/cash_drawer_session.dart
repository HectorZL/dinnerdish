import 'package:hive/hive.dart';

part 'cash_drawer_session.g.dart';

@HiveType(typeId: 16)
enum CashDrawerStatus {
  @HiveField(0)
  open,
  @HiveField(1)
  closed,
  @HiveField(2)
  reconciled,
}

@HiveType(typeId: 17)
class CashDrawerSession {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String cashierId;
  @HiveField(2)
  final DateTime openedAt;
  @HiveField(3)
  final DateTime? closedAt;
  @HiveField(4)
  final int startingBalanceCents;
  @HiveField(5)
  final int expectedBalanceCents;
  @HiveField(6)
  final int actualBalanceCents;
  @HiveField(7)
  final int differenceCents;
  @HiveField(8)
  final CashDrawerStatus status;

  const CashDrawerSession({
    required this.id,
    required this.cashierId,
    required this.openedAt,
    this.closedAt,
    this.startingBalanceCents = 0,
    this.expectedBalanceCents = 0,
    this.actualBalanceCents = 0,
    this.differenceCents = 0,
    this.status = CashDrawerStatus.open,
  }) : assert(startingBalanceCents >= 0, 'startingBalanceCents must be >= 0'),
       assert(expectedBalanceCents >= 0, 'expectedBalanceCents must be >= 0'),
       assert(actualBalanceCents >= 0, 'actualBalanceCents must be >= 0');

  CashDrawerSession copyWith({
    DateTime? closedAt,
    int? expectedBalanceCents,
    int? actualBalanceCents,
    int? differenceCents,
    CashDrawerStatus? status,
  }) {
    return CashDrawerSession(
      id: id,
      cashierId: cashierId,
      openedAt: openedAt,
      closedAt: closedAt ?? this.closedAt,
      startingBalanceCents: startingBalanceCents,
      expectedBalanceCents: expectedBalanceCents ?? this.expectedBalanceCents,
      actualBalanceCents: actualBalanceCents ?? this.actualBalanceCents,
      differenceCents: differenceCents ?? this.differenceCents,
      status: status ?? this.status,
    );
  }
}
