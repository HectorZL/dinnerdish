import 'package:hive/hive.dart';

import 'order_item.dart';

part 'order.g.dart';

@HiveType(typeId: 5)
enum OrderStatus {
  @HiveField(0)
  draft,
  @HiveField(1)
  sentToKitchen,
  @HiveField(2)
  prepping,
  @HiveField(3)
  ready,
  @HiveField(4)
  billed,
  @HiveField(5)
  closed,
}

@HiveType(typeId: 6)
class Order {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String tableId;

  @HiveField(2)
  final String waiterId;

  @HiveField(3)
  final List<OrderItem> items;

  @HiveField(4)
  final OrderStatus status;

  @HiveField(5)
  final int subtotalCents;

  @HiveField(6)
  final int taxCents;

  @HiveField(7)
  final int totalCents;

  @HiveField(8)
  final DateTime createdAt;

  @HiveField(9)
  final DateTime? sentToKitchenAt;

  @HiveField(10)
  final DateTime? readyAt;

  @HiveField(11)
  final String? notes;

  const Order({
    required this.id,
    required this.tableId,
    required this.waiterId,
    required this.items,
    required this.status,
    required this.subtotalCents,
    required this.taxCents,
    required this.totalCents,
    required this.createdAt,
    this.sentToKitchenAt,
    this.readyAt,
    this.notes,
  })  : assert(subtotalCents >= 0, 'subtotalCents must be >= 0'),
        assert(taxCents >= 0, 'taxCents must be >= 0'),
        assert(totalCents >= 0, 'totalCents must be >= 0');

  factory Order.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    if (id == null) {
      throw ArgumentError('Missing required field: id');
    }
    final tableId = json['tableId'] as String?;
    if (tableId == null) {
      throw ArgumentError('Missing required field: tableId');
    }
    final waiterId = json['waiterId'] as String?;
    if (waiterId == null) {
      throw ArgumentError('Missing required field: waiterId');
    }
    final itemsRaw = json['items'] as List<dynamic>?;
    if (itemsRaw == null) {
      throw ArgumentError('Missing required field: items');
    }
    final statusRaw = json['status'] as String?;
    if (statusRaw == null) {
      throw ArgumentError('Missing required field: status');
    }
    final subtotalCents = json['subtotalCents'] as int?;
    if (subtotalCents == null) {
      throw ArgumentError('Missing required field: subtotalCents');
    }
    final taxCents = json['taxCents'] as int?;
    if (taxCents == null) {
      throw ArgumentError('Missing required field: taxCents');
    }
    final totalCents = json['totalCents'] as int?;
    if (totalCents == null) {
      throw ArgumentError('Missing required field: totalCents');
    }
    final createdAtRaw = json['createdAt'] as String?;
    if (createdAtRaw == null) {
      throw ArgumentError('Missing required field: createdAt');
    }
    final sentToKitchenAtRaw = json['sentToKitchenAt'] as String?;
    final readyAtRaw = json['readyAt'] as String?;
    final notes = json['notes'] as String?;

    return Order(
      id: id,
      tableId: tableId,
      waiterId: waiterId,
      items: itemsRaw
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      status: OrderStatus.values.byName(statusRaw),
      subtotalCents: subtotalCents,
      taxCents: taxCents,
      totalCents: totalCents,
      createdAt: DateTime.parse(createdAtRaw),
      sentToKitchenAt:
          sentToKitchenAtRaw != null ? DateTime.parse(sentToKitchenAtRaw) : null,
      readyAt: readyAtRaw != null ? DateTime.parse(readyAtRaw) : null,
      notes: notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tableId': tableId,
        'waiterId': waiterId,
        'items': items.map((e) => e.toJson()).toList(),
        'status': status.name,
        'subtotalCents': subtotalCents,
        'taxCents': taxCents,
        'totalCents': totalCents,
        'createdAt': createdAt.toIso8601String(),
        'sentToKitchenAt': sentToKitchenAt?.toIso8601String(),
        'readyAt': readyAt?.toIso8601String(),
        'notes': notes,
      };

  Order copyWith({
    String? id,
    String? tableId,
    String? waiterId,
    List<OrderItem>? items,
    OrderStatus? status,
    int? subtotalCents,
    int? taxCents,
    int? totalCents,
    DateTime? createdAt,
    DateTime? sentToKitchenAt,
    DateTime? readyAt,
    String? notes,
  }) {
    return Order(
      id: id ?? this.id,
      tableId: tableId ?? this.tableId,
      waiterId: waiterId ?? this.waiterId,
      items: items ?? this.items,
      status: status ?? this.status,
      subtotalCents: subtotalCents ?? this.subtotalCents,
      taxCents: taxCents ?? this.taxCents,
      totalCents: totalCents ?? this.totalCents,
      createdAt: createdAt ?? this.createdAt,
      sentToKitchenAt: sentToKitchenAt ?? this.sentToKitchenAt,
      readyAt: readyAt ?? this.readyAt,
      notes: notes ?? this.notes,
    );
  }
}
