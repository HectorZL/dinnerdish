import 'package:hive/hive.dart';

import 'selected_additional.dart';

part 'order_item.g.dart';

@HiveType(typeId: 3)
enum OrderStatus {
  @HiveField(0)
  pending,
  @HiveField(1)
  sent,
  @HiveField(2)
  preparing,
  @HiveField(3)
  ready,
  @HiveField(4)
  served,
}

@HiveType(typeId: 4)
class OrderItem {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String menuItemId;

  @HiveField(2)
  final int quantity;

  @HiveField(3)
  final String? notes;

  @HiveField(4)
  final OrderStatus status;

  @HiveField(5)
  final List<String> modifierIds;

  @HiveField(6)
  final int priceCents;

  @HiveField(7)
  final String? name;

  @HiveField(8)
  final String? variationId;

  /// Additionales selected for this dish, stored as snapshots rather than
  /// independent menu lines. This field is append-only for Hive compatibility.
  @HiveField(9)
  final List<SelectedAdditional> selectedAdditionals;

  const OrderItem({
    required this.id,
    required this.menuItemId,
    required this.quantity,
    this.notes,
    required this.status,
    required this.modifierIds,
    this.priceCents = 0,
    this.name,
    this.variationId,
    this.selectedAdditionals = const [],
  }) : assert(quantity > 0, 'quantity must be > 0'),
       assert(priceCents >= 0, 'priceCents must be >= 0');

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    if (id == null) {
      throw ArgumentError('Missing required field: id');
    }
    final menuItemId = json['menuItemId'] as String?;
    if (menuItemId == null) {
      throw ArgumentError('Missing required field: menuItemId');
    }
    final quantity = json['quantity'] as int?;
    if (quantity == null) {
      throw ArgumentError('Missing required field: quantity');
    }
    final notes = json['notes'] as String?;
    final statusRaw = json['status'] as String?;
    if (statusRaw == null) {
      throw ArgumentError('Missing required field: status');
    }
    final modifierIdsRaw = json['modifierIds'] as List<dynamic>?;
    if (modifierIdsRaw == null) {
      throw ArgumentError('Missing required field: modifierIds');
    }
    final priceCents = json['priceCents'] as int? ?? 0;
    final name = json['name'] as String?;
    final variationId = json['variationId'] as String?;
    final selectedAdditionalsRaw =
        json['selectedAdditionals'] as List<dynamic>?;

    return OrderItem(
      id: id,
      menuItemId: menuItemId,
      quantity: quantity,
      notes: notes,
      status: OrderStatus.values.byName(statusRaw),
      modifierIds: modifierIdsRaw.map((e) => e as String).toList(),
      priceCents: priceCents,
      name: name,
      variationId: variationId,
      selectedAdditionals: selectedAdditionalsRaw == null
          ? const []
          : selectedAdditionalsRaw
                .map(
                  (e) => SelectedAdditional.fromJson(e as Map<String, dynamic>),
                )
                .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'menuItemId': menuItemId,
    'quantity': quantity,
    'notes': notes,
    'status': status.name,
    'modifierIds': modifierIds,
    'priceCents': priceCents,
    'name': name,
    'variationId': variationId,
    'selectedAdditionals': selectedAdditionals
        .map((additional) => additional.toJson())
        .toList(),
  };

  OrderItem copyWith({
    String? id,
    String? menuItemId,
    int? quantity,
    String? notes,
    OrderStatus? status,
    List<String>? modifierIds,
    int? priceCents,
    String? name,
    String? variationId,
    List<SelectedAdditional>? selectedAdditionals,
  }) {
    return OrderItem(
      id: id ?? this.id,
      menuItemId: menuItemId ?? this.menuItemId,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      modifierIds: modifierIds ?? this.modifierIds,
      priceCents: priceCents ?? this.priceCents,
      name: name ?? this.name,
      variationId: variationId ?? this.variationId,
      selectedAdditionals: selectedAdditionals ?? this.selectedAdditionals,
    );
  }
}
