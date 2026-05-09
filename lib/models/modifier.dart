import 'package:hive/hive.dart';

part 'modifier.g.dart';

@HiveType(typeId: 2)
class Modifier {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int priceCents;

  const Modifier({
    required this.id,
    required this.name,
    required this.priceCents,
  }) : assert(priceCents >= 0, 'priceCents must be >= 0');

  factory Modifier.fromJson(Map<String, dynamic> json) {
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
    return Modifier(
      id: id,
      name: name,
      priceCents: priceCents,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'priceCents': priceCents,
      };
}
