import 'package:hive/hive.dart';

part 'table.g.dart';

@HiveType(typeId: 7)
enum TableStatus {
  @HiveField(0)
  available,
  @HiveField(1)
  occupied,
  @HiveField(2)
  reserved,
}

@HiveType(typeId: 8)
class Table {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final int number;

  @HiveField(2)
  final int seats;

  @HiveField(3)
  final TableStatus status;

  @HiveField(4)
  final String? section;

  const Table({
    required this.id,
    required this.number,
    required this.seats,
    required this.status,
    this.section,
  }) : assert(seats > 0, 'seats must be > 0');

  factory Table.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    if (id == null) {
      throw ArgumentError('Missing required field: id');
    }
    final number = json['number'] as int?;
    if (number == null) {
      throw ArgumentError('Missing required field: number');
    }
    final seats = json['seats'] as int?;
    if (seats == null) {
      throw ArgumentError('Missing required field: seats');
    }
    final statusRaw = json['status'] as String?;
    if (statusRaw == null) {
      throw ArgumentError('Missing required field: status');
    }
    final section = json['section'] as String?;

    return Table(
      id: id,
      number: number,
      seats: seats,
      status: TableStatus.values.byName(statusRaw),
      section: section,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'number': number,
        'seats': seats,
        'status': status.name,
        'section': section,
      };
}
