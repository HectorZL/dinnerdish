import 'package:hive/hive.dart';

import 'modifier.dart';
import 'menu_item_variation.dart';

part 'menu_item.g.dart';

@HiveType(typeId: 1)
class MenuItem {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int priceCents;

  @HiveField(3)
  final List<Modifier> modifiers;

  @HiveField(4)
  final bool available;

  @HiveField(5)
  final String category;

  @HiveField(6)
  final int stock;

  @HiveField(7)
  final List<MenuItemVariation> variations;

  /// IDs del catálogo global habilitados para este plato.
  /// Los adicionales no tienen stock; solo se guarda esta relación.
  @HiveField(8)
  final List<String> additionalIds;

  const MenuItem({
    required this.id,
    required this.name,
    required this.priceCents,
    required this.modifiers,
    required this.available,
    required this.category,
    this.stock = 99,
    this.variations = const [],
    this.additionalIds = const [],
  }) : assert(priceCents >= 0, 'priceCents must be >= 0'),
       assert(stock >= 0, 'stock must be >= 0');

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    if (id == null) {
      throw ArgumentError('Missing required field: id');
    }
    final name = json['name'] as String?;
    if (name == null) {
      throw ArgumentError('Missing required field: name');
    }
    final priceCents = json['priceCents'] as int?;
    if (priceCents == null) {
      throw ArgumentError('Missing required field: priceCents');
    }
    final modifiersRaw = json['modifiers'] as List<dynamic>?;
    if (modifiersRaw == null) {
      throw ArgumentError('Missing required field: modifiers');
    }
    final available = json['available'] as bool?;
    if (available == null) {
      throw ArgumentError('Missing required field: available');
    }
    final category = json['category'] as String?;
    if (category == null) {
      throw ArgumentError('Missing required field: category');
    }
    final stock = json['stock'] as int? ?? 99;
    final variationsRaw = json['variations'] as List<dynamic>? ?? [];
    final additionalIds = (json['additionalIds'] as List<dynamic>? ?? [])
        .whereType<String>()
        .toList();
    final variations = variationsRaw
        .map((e) => MenuItemVariation.fromJson(e as Map<String, dynamic>))
        .toList();

    return MenuItem(
      id: id,
      name: name,
      priceCents: priceCents,
      modifiers: modifiersRaw
          .map((e) => Modifier.fromJson(e as Map<String, dynamic>))
          .toList(),
      available: available,
      category: category,
      stock: stock,
      variations: variations,
      additionalIds: additionalIds,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'priceCents': priceCents,
    'modifiers': modifiers.map((e) => e.toJson()).toList(),
    'available': available,
    'category': category,
    'stock': stock,
    'variations': variations.map((e) => e.toJson()).toList(),
    'additionalIds': additionalIds,
  };

  MenuItem copyWith({
    String? id,
    String? name,
    int? priceCents,
    List<Modifier>? modifiers,
    bool? available,
    String? category,
    int? stock,
    List<MenuItemVariation>? variations,
    List<String>? additionalIds,
  }) {
    return MenuItem(
      id: id ?? this.id,
      name: name ?? this.name,
      priceCents: priceCents ?? this.priceCents,
      modifiers: modifiers ?? this.modifiers,
      available: available ?? this.available,
      category: category ?? this.category,
      stock: stock ?? this.stock,
      variations: variations ?? this.variations,
      additionalIds: additionalIds ?? this.additionalIds,
    );
  }
}
