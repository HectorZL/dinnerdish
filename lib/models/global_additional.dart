class GlobalAdditional {
  final String id;
  final String name;
  final int priceCents;
  final bool available;

  const GlobalAdditional({
    required this.id,
    required this.name,
    required this.priceCents,
    required this.available,
  })  : assert(name != ''),
        assert(priceCents >= 0, 'priceCents must be >= 0');

  factory GlobalAdditional.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    final name = json['name'] as String?;
    final priceCents = json['priceCents'] as int?;
    final available = json['available'] as bool?;
    if (id == null || name == null || priceCents == null || available == null) {
      throw ArgumentError('Datos de adicional global incompletos.');
    }
    return GlobalAdditional(
      id: id,
      name: name,
      priceCents: priceCents,
      available: available,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'priceCents': priceCents,
        'available': available,
      };

  GlobalAdditional copyWith({
    String? id,
    String? name,
    int? priceCents,
    bool? available,
  }) {
    return GlobalAdditional(
      id: id ?? this.id,
      name: name ?? this.name,
      priceCents: priceCents ?? this.priceCents,
      available: available ?? this.available,
    );
  }
}

const globalAdditionalLinePrefix = 'global-additional:';

bool isGlobalAdditionalLine(String menuItemId) =>
    menuItemId.startsWith(globalAdditionalLinePrefix);

String globalAdditionalLineMenuItemId(String additionalId) =>
    '$globalAdditionalLinePrefix$additionalId';

String? globalAdditionalIdFromMenuItemId(String menuItemId) {
  if (!isGlobalAdditionalLine(menuItemId)) return null;
  final id = menuItemId.substring(globalAdditionalLinePrefix.length);
  return id.isEmpty ? null : id;
}
