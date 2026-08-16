import 'package:hive/hive.dart';
import 'package:dinnerhome/exceptions/validation_exception.dart';
import 'package:dinnerhome/validation/menu_validators.dart';

import 'additional_source.dart';

export 'additional_source.dart';

part 'selected_additional.g.dart';

/// Historical snapshot of an additional selected inside an order item.
///
/// This is deliberately separate from [MenuAdditionalAssignment]: later
/// catalog edits must not rewrite the name or price shown on a closed order.
@HiveType(typeId: 20)
class SelectedAdditional {
  @HiveField(0)
  final String assignmentId;

  @HiveField(1)
  final String additionalId;

  @HiveField(2)
  final AdditionalSource source;

  @HiveField(3)
  final String nameSnapshot;

  @HiveField(4)
  final int priceCentsSnapshot;

  factory SelectedAdditional({
    required String assignmentId,
    required String additionalId,
    required AdditionalSource source,
    required String nameSnapshot,
    required int priceCentsSnapshot,
  }) {
    _requiredId(assignmentId, 'El identificador de la asignación');
    _requiredId(additionalId, 'El identificador del adicional');
    final normalizedName = MenuValidators.ensureName(nameSnapshot);
    final normalizedPrice = MenuValidators.ensurePrice(priceCentsSnapshot);
    return SelectedAdditional._validated(
      assignmentId: assignmentId,
      additionalId: additionalId,
      source: source,
      nameSnapshot: normalizedName,
      priceCentsSnapshot: normalizedPrice,
    );
  }

  const SelectedAdditional._validated({
    required this.assignmentId,
    required this.additionalId,
    required this.source,
    required this.nameSnapshot,
    required this.priceCentsSnapshot,
  });

  factory SelectedAdditional.fromJson(Map<String, dynamic> json) {
    final assignmentId = json['assignmentId'];
    final additionalId = json['additionalId'];
    final nameSnapshot = json['nameSnapshot'];
    final priceCentsSnapshot = json['priceCentsSnapshot'];
    if (assignmentId is! String ||
        additionalId is! String ||
        nameSnapshot is! String ||
        priceCentsSnapshot is! int) {
      throw ArgumentError('Datos de adicional seleccionado incompletos.');
    }
    return SelectedAdditional(
      assignmentId: assignmentId,
      additionalId: additionalId,
      source: additionalSourceFromJson(json['source']),
      nameSnapshot: nameSnapshot,
      priceCentsSnapshot: priceCentsSnapshot,
    );
  }

  Map<String, dynamic> toJson() => {
    'assignmentId': assignmentId,
    'additionalId': additionalId,
    'source': source.name,
    'nameSnapshot': nameSnapshot,
    'priceCentsSnapshot': priceCentsSnapshot,
  };

  SelectedAdditional copyWith({
    String? assignmentId,
    String? additionalId,
    AdditionalSource? source,
    String? nameSnapshot,
    int? priceCentsSnapshot,
  }) {
    return SelectedAdditional(
      assignmentId: assignmentId ?? this.assignmentId,
      additionalId: additionalId ?? this.additionalId,
      source: source ?? this.source,
      nameSnapshot: nameSnapshot ?? this.nameSnapshot,
      priceCentsSnapshot: priceCentsSnapshot ?? this.priceCentsSnapshot,
    );
  }

  static void _requiredId(String value, String field) {
    if (value.trim().isEmpty) {
      throw InvalidAssignmentException('$field es obligatorio.');
    }
  }
}
