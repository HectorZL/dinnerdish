import 'package:dinnerhome/exceptions/validation_exception.dart';
import 'package:dinnerhome/validation/menu_validators.dart';

import 'additional_source.dart';

export 'additional_source.dart';

/// The logical uniqueness key for an additional assignment.
class AdditionalAssignmentKey {
  final String menuItemId;
  final AdditionalSource source;
  final String additionalId;

  const AdditionalAssignmentKey({
    required this.menuItemId,
    required this.source,
    required this.additionalId,
  });

  String get stableId => MenuAdditionalAssignment.stableIdFor(
    menuItemId: menuItemId,
    source: source,
    additionalId: additionalId,
  );

  @override
  bool operator ==(Object other) =>
      other is AdditionalAssignmentKey &&
      other.menuItemId == menuItemId &&
      other.source == source &&
      other.additionalId == additionalId;

  @override
  int get hashCode => Object.hash(menuItemId, source, additionalId);
}

/// A relationship between a menu item and an additional definition.
///
/// Names and prices are deliberately not stored here. They are resolved from
/// the global or special definition when the UI builds [AssignedAdditional].
class MenuAdditionalAssignment {
  final String id;
  final String menuItemId;
  final AdditionalSource source;
  final String additionalId;

  /// [id] defaults to a deterministic value derived from the logical key.
  /// Explicit IDs remain accepted for loading previously persisted records.
  factory MenuAdditionalAssignment({
    String? id,
    required String menuItemId,
    required AdditionalSource source,
    required String additionalId,
  }) {
    _validatePart(menuItemId, 'El Plato de la asignación');
    _validatePart(additionalId, 'El adicional de la asignación');
    final stableId = stableIdFor(
      menuItemId: menuItemId,
      source: source,
      additionalId: additionalId,
    );
    final effectiveId = id ?? stableId;
    _validatePart(effectiveId, 'El identificador de la asignación');
    return MenuAdditionalAssignment._validated(
      id: effectiveId,
      menuItemId: menuItemId,
      source: source,
      additionalId: additionalId,
    );
  }

  const MenuAdditionalAssignment._validated({
    required this.id,
    required this.menuItemId,
    required this.source,
    required this.additionalId,
  });

  factory MenuAdditionalAssignment.fromJson(Map<String, dynamic> json) {
    final menuItemId = json['menuItemId'];
    final additionalId = json['additionalId'];
    if (menuItemId is! String || additionalId is! String) {
      throw ArgumentError('Datos de asignación de adicional incompletos.');
    }
    final source = additionalSourceFromJson(json['source']);
    final rawId = json['id'];
    if (rawId != null && rawId is! String) {
      throw ArgumentError('El identificador de la asignación no es válido.');
    }
    return MenuAdditionalAssignment(
      id: rawId as String?,
      menuItemId: menuItemId,
      source: source,
      additionalId: additionalId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'menuItemId': menuItemId,
    'source': source.name,
    'additionalId': additionalId,
  };

  MenuAdditionalAssignment copyWith({
    String? id,
    String? menuItemId,
    AdditionalSource? source,
    String? additionalId,
  }) {
    final nextMenuItemId = menuItemId ?? this.menuItemId;
    final nextSource = source ?? this.source;
    final nextAdditionalId = additionalId ?? this.additionalId;
    final keyChanged =
        nextMenuItemId != this.menuItemId ||
        nextSource != this.source ||
        nextAdditionalId != this.additionalId;
    return MenuAdditionalAssignment(
      id:
          id ??
          (keyChanged
              ? stableIdFor(
                  menuItemId: nextMenuItemId,
                  source: nextSource,
                  additionalId: nextAdditionalId,
                )
              : this.id),
      menuItemId: nextMenuItemId,
      source: nextSource,
      additionalId: nextAdditionalId,
    );
  }

  AdditionalAssignmentKey get logicalKey => AdditionalAssignmentKey(
    menuItemId: menuItemId,
    source: source,
    additionalId: additionalId,
  );

  bool matchesKey({
    required String menuItemId,
    required AdditionalSource source,
    required String additionalId,
  }) =>
      this.menuItemId == menuItemId &&
      this.source == source &&
      this.additionalId == additionalId;

  /// Length-prefixing makes the ID deterministic without delimiter collisions
  /// when user/imported IDs contain punctuation.
  static String stableIdFor({
    required String menuItemId,
    required AdditionalSource source,
    required String additionalId,
  }) =>
      'menu-additional-assignment:'
      '${menuItemId.length}:$menuItemId:'
      '${source.name.length}:${source.name}:'
      '${additionalId.length}:$additionalId';

  static String idFor({
    required String menuItemId,
    required AdditionalSource source,
    required String additionalId,
  }) => stableIdFor(
    menuItemId: menuItemId,
    source: source,
    additionalId: additionalId,
  );

  static void _validatePart(String value, String field) {
    if (value.trim().isEmpty) {
      throw InvalidAssignmentException('$field es obligatorio.');
    }
  }
}

/// UI projection of an assignment and its current definition.
class AssignedAdditional {
  final String assignmentId;
  final String additionalId;
  final AdditionalSource source;
  final String name;
  final int priceCents;
  final bool available;

  factory AssignedAdditional({
    required String assignmentId,
    required String additionalId,
    required AdditionalSource source,
    required String name,
    required int priceCents,
    required bool available,
  }) {
    MenuAdditionalAssignment._validatePart(
      assignmentId,
      'El identificador de la asignación',
    );
    MenuAdditionalAssignment._validatePart(
      additionalId,
      'El adicional de la asignación',
    );
    final normalizedName = MenuValidators.ensureName(name);
    final normalizedPrice = MenuValidators.ensurePrice(priceCents);
    return AssignedAdditional._validated(
      assignmentId: assignmentId,
      additionalId: additionalId,
      source: source,
      name: normalizedName,
      priceCents: normalizedPrice,
      available: available,
    );
  }

  const AssignedAdditional._validated({
    required this.assignmentId,
    required this.additionalId,
    required this.source,
    required this.name,
    required this.priceCents,
    required this.available,
  });

  String get id => assignmentId;

  factory AssignedAdditional.fromJson(Map<String, dynamic> json) {
    final assignmentId = json['assignmentId'] ?? json['id'];
    final additionalId = json['additionalId'];
    final name = json['name'];
    final priceCents = json['priceCents'];
    final available = json['available'];
    if (assignmentId is! String ||
        additionalId is! String ||
        name is! String ||
        priceCents is! int ||
        available is! bool) {
      throw ArgumentError('Datos de adicional asignado incompletos.');
    }
    return AssignedAdditional(
      assignmentId: assignmentId,
      additionalId: additionalId,
      source: additionalSourceFromJson(json['source']),
      name: name,
      priceCents: priceCents,
      available: available,
    );
  }

  Map<String, dynamic> toJson() => {
    'assignmentId': assignmentId,
    'additionalId': additionalId,
    'source': source.name,
    'name': name,
    'priceCents': priceCents,
    'available': available,
  };

  AssignedAdditional copyWith({
    String? assignmentId,
    String? additionalId,
    AdditionalSource? source,
    String? name,
    int? priceCents,
    bool? available,
  }) {
    return AssignedAdditional(
      assignmentId: assignmentId ?? this.assignmentId,
      additionalId: additionalId ?? this.additionalId,
      source: source ?? this.source,
      name: name ?? this.name,
      priceCents: priceCents ?? this.priceCents,
      available: available ?? this.available,
    );
  }

  factory AssignedAdditional.fromAssignment({
    required MenuAdditionalAssignment assignment,
    required String name,
    required int priceCents,
    required bool available,
  }) => AssignedAdditional(
    assignmentId: assignment.id,
    additionalId: assignment.additionalId,
    source: assignment.source,
    name: name,
    priceCents: priceCents,
    available: available,
  );
}
