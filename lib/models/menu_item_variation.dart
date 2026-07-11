import 'package:hive/hive.dart';

part 'menu_item_variation.g.dart';

@HiveType(typeId: 19)
class MenuItemVariation {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int priceCents;

  @HiveField(3)
  final int stock;

  const MenuItemVariation({
    required this.id,
    required this.name,
    required this.priceCents,
    required this.stock,
  }) : assert(priceCents >= 0, 'priceCents must be >= 0'),
       assert(stock >= 0, 'stock must be >= 0');

  factory MenuItemVariation.fromJson(Map<String, dynamic> json) {
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
    final stock = json['stock'] as int?;
    if (stock == null) {
      throw ArgumentError('Missing required field: stock');
    }
    return MenuItemVariation(
      id: id,
      name: name,
      priceCents: priceCents,
      stock: stock,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'priceCents': priceCents,
        'stock': stock,
      };

  MenuItemVariation copyWith({
    String? id,
    String? name,
    int? priceCents,
    int? stock,
  }) {
    return MenuItemVariation(
      id: id ?? this.id,
      name: name ?? this.name,
      priceCents: priceCents ?? this.priceCents,
      stock: stock ?? this.stock,
    );
  }
}
