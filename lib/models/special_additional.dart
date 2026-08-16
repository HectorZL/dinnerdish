import 'package:dinnerhome/exceptions/validation_exception.dart';
import 'package:dinnerhome/validation/menu_validators.dart';

/// An additional that belongs exclusively to one menu item.
///
/// A special additional intentionally has no stock field. Its owner is part
/// of the definition so it cannot be reassigned by treating it as a global.
class SpecialAdditional {
  final String id;
  final String ownerMenuItemId;
  final String name;
  final int priceCents;
  final bool available;

  factory SpecialAdditional({
    required String id,
    required String ownerMenuItemId,
    required String name,
    required int priceCents,
    required bool available,
  }) {
    final normalizedId = _requiredId(
      id,
      'El identificador del adicional especial',
    );
    final normalizedOwner = _requiredId(
      ownerMenuItemId,
      'El propietario del adicional especial',
    );
    return SpecialAdditional._validated(
      id: normalizedId,
      ownerMenuItemId: normalizedOwner,
      name: MenuValidators.ensureName(name),
      priceCents: MenuValidators.ensurePrice(priceCents),
      available: available,
    );
  }

  const SpecialAdditional._validated({
    required this.id,
    required this.ownerMenuItemId,
    required this.name,
    required this.priceCents,
    required this.available,
  });

  factory SpecialAdditional.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final ownerMenuItemId = json['ownerMenuItemId'];
    final name = json['name'];
    final priceCents = json['priceCents'];
    final available = json['available'];
    if (id is! String ||
        ownerMenuItemId is! String ||
        name is! String ||
        priceCents is! int ||
        available is! bool) {
      throw ArgumentError('Datos de adicional especial incompletos.');
    }
    return SpecialAdditional(
      id: id,
      ownerMenuItemId: ownerMenuItemId,
      name: name,
      priceCents: priceCents,
      available: available,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'ownerMenuItemId': ownerMenuItemId,
    'name': name,
    'priceCents': priceCents,
    'available': available,
  };

  SpecialAdditional copyWith({
    String? id,
    String? ownerMenuItemId,
    String? name,
    int? priceCents,
    bool? available,
  }) {
    return SpecialAdditional(
      id: id ?? this.id,
      ownerMenuItemId: ownerMenuItemId ?? this.ownerMenuItemId,
      name: name ?? this.name,
      priceCents: priceCents ?? this.priceCents,
      available: available ?? this.available,
    );
  }

  bool belongsTo(String menuItemId) => ownerMenuItemId == menuItemId;

  void validateOwner(String menuItemId) {
    if (!belongsTo(menuItemId)) {
      throw InvalidAssignmentException(
        'El adicional especial solo puede asignarse a su Plato propietario.',
      );
    }
  }

  static String _requiredId(String value, String field) {
    if (value.trim().isEmpty) {
      throw InvalidAssignmentException('$field es obligatorio.');
    }
    return value;
  }
}
