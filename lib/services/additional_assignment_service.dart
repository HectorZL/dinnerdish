import 'dart:async';

import 'package:dinnerhome/exceptions/menu_exception.dart';
import 'package:dinnerhome/exceptions/validation_exception.dart';
import 'package:dinnerhome/models/global_additional.dart';
import 'package:dinnerhome/models/menu_additional_assignment.dart';
import 'package:dinnerhome/models/special_additional.dart';
import 'package:dinnerhome/services/additional_service.dart';
import 'package:dinnerhome/services/hive/additional_assignment_repository.dart';
import 'package:dinnerhome/services/hive/special_additional_repository.dart';
import 'package:dinnerhome/services/menu_service.dart';

/// Application contract for relationships between a menu item and an
/// additional definition.
///
/// The methods returning [MenuAdditionalAssignment] deliberately expose only
/// relationship data. Definitions are resolved through [fetchResolvedForMenuItem]
/// when a caller needs the current name, price or availability.
abstract class AdditionalAssignmentService {
  Future<List<MenuAdditionalAssignment>> fetchForMenuItem(String menuItemId);

  Future<Map<String, List<MenuAdditionalAssignment>>> fetchGroupedByMenuItem(
    Iterable<String> menuItemIds,
  );

  Future<MenuAdditionalAssignment> assignGlobal(
    String menuItemId,
    String additionalId,
  );

  Future<MenuAdditionalAssignment> assignSpecial(
    String menuItemId,
    String specialId,
  );

  Future<void> remove(String menuItemId, String assignmentId);

  Future<void> removeAllForGlobal(String additionalId);

  /// Resolves a relationship against the canonical definition currently in
  /// the global catalog or special-additional repository.
  Future<AssignedAdditional> resolve(MenuAdditionalAssignment assignment);

  Future<List<AssignedAdditional>> fetchResolvedForMenuItem(String menuItemId);

  Future<Map<String, List<AssignedAdditional>>> fetchResolvedGroupedByMenuItem(
    Iterable<String> menuItemIds,
  );
}

/// Shared service implementation used by both the in-memory and Hive-backed
/// variants. Persistence is delegated to the injected repositories, so the
/// business rules remain identical in tests and production.
class AdditionalAssignmentServiceImpl implements AdditionalAssignmentService {
  final AdditionalAssignmentRepository assignmentRepository;
  final AdditionalService additionalService;
  final SpecialAdditionalRepository specialAdditionalRepository;
  final MenuService? menuService;
  final Set<String>? validMenuItemIds;
  final FutureOr<bool> Function(String menuItemId)? menuItemExists;

  AdditionalAssignmentServiceImpl({
    required this.additionalService,
    AdditionalAssignmentRepository? assignmentRepository,
    SpecialAdditionalRepository? specialAdditionalRepository,
    this.menuService,
    Iterable<String>? validMenuItemIds,
    this.menuItemExists,
  }) : assignmentRepository =
           assignmentRepository ??
           AdditionalAssignmentRepository(validMenuItemIds: validMenuItemIds),
       specialAdditionalRepository =
           specialAdditionalRepository ??
           SpecialAdditionalRepository(validMenuItemIds: validMenuItemIds),
       validMenuItemIds = validMenuItemIds?.toSet();

  @override
  Future<List<MenuAdditionalAssignment>> fetchForMenuItem(
    String menuItemId,
  ) async {
    await _requireMenuItem(menuItemId);
    return assignmentRepository.fetchForMenuItem(menuItemId);
  }

  @override
  Future<Map<String, List<MenuAdditionalAssignment>>> fetchGroupedByMenuItem(
    Iterable<String> menuItemIds,
  ) async {
    final ids = menuItemIds.toList(growable: false);
    for (final id in ids) {
      await _requireMenuItem(id);
    }

    // Re-filter the repository result here. A repository may contain legacy
    // rows for a menu item that was not requested, and a grouped projection
    // must never leak those rows into another dish's section.
    final requested = ids.toSet();
    final all = await assignmentRepository.readAll();
    final grouped = <String, List<MenuAdditionalAssignment>>{
      for (final id in ids) id: <MenuAdditionalAssignment>[],
    };
    for (final assignment in all) {
      if (requested.contains(assignment.menuItemId)) {
        grouped[assignment.menuItemId]!.add(assignment);
      }
    }
    return {
      for (final entry in grouped.entries)
        entry.key: List<MenuAdditionalAssignment>.unmodifiable(entry.value),
    };
  }

  @override
  Future<MenuAdditionalAssignment> assignGlobal(
    String menuItemId,
    String additionalId,
  ) async {
    await _requireMenuItem(menuItemId);
    final additional = await additionalService.getAdditional(additionalId);
    if (additional == null) {
      throw AdditionalNotFoundException(additionalId);
    }

    final assignment = MenuAdditionalAssignment(
      menuItemId: menuItemId,
      source: AdditionalSource.global,
      additionalId: additional.id,
    );
    // The repository also enforces the logical key and performs an atomic
    // collection replacement. Calling it repeatedly is therefore idempotent.
    return assignmentRepository.assign(assignment);
  }

  @override
  Future<MenuAdditionalAssignment> assignSpecial(
    String menuItemId,
    String specialId,
  ) async {
    await _requireMenuItem(menuItemId);
    final special = await specialAdditionalRepository.getById(specialId);
    if (special == null) {
      throw AdditionalNotFoundException(specialId);
    }
    if (!special.belongsTo(menuItemId)) {
      throw InvalidAssignmentException(
        'El adicional especial solo puede asignarse a su Plato propietario.',
      );
    }

    final assignment = MenuAdditionalAssignment(
      menuItemId: menuItemId,
      source: AdditionalSource.special,
      additionalId: special.id,
    );
    return assignmentRepository.assign(assignment);
  }

  @override
  Future<void> remove(String menuItemId, String assignmentId) async {
    await _requireMenuItem(menuItemId);
    await assignmentRepository.remove(menuItemId, assignmentId);
  }

  @override
  Future<void> removeAllForGlobal(String additionalId) async {
    if (additionalId.trim().isEmpty) {
      throw AdditionalNotFoundException(additionalId);
    }
    // This operation is intentionally usable after a global definition has
    // already been deleted. The confirmed catalog deletion calls it as its
    // cascade, so requiring the definition to still exist would leave rows.
    await assignmentRepository.removeAllForGlobal(additionalId);
  }

  @override
  Future<AssignedAdditional> resolve(
    MenuAdditionalAssignment assignment,
  ) async {
    final definition = await _definitionFor(assignment);
    return AssignedAdditional.fromAssignment(
      assignment: assignment,
      name: definition.name,
      priceCents: definition.priceCents,
      available: definition.available,
    );
  }

  @override
  Future<List<AssignedAdditional>> fetchResolvedForMenuItem(
    String menuItemId,
  ) async {
    final assignments = await fetchForMenuItem(menuItemId);
    final resolved = <AssignedAdditional>[];
    for (final assignment in assignments) {
      resolved.add(await resolve(assignment));
    }
    return List<AssignedAdditional>.unmodifiable(resolved);
  }

  @override
  Future<Map<String, List<AssignedAdditional>>> fetchResolvedGroupedByMenuItem(
    Iterable<String> menuItemIds,
  ) async {
    final grouped = await fetchGroupedByMenuItem(menuItemIds);
    final result = <String, List<AssignedAdditional>>{};
    for (final entry in grouped.entries) {
      final resolved = <AssignedAdditional>[];
      for (final assignment in entry.value) {
        resolved.add(await resolve(assignment));
      }
      result[entry.key] = List<AssignedAdditional>.unmodifiable(resolved);
    }
    return result;
  }

  Future<void> _requireMenuItem(String menuItemId) async {
    if (menuItemId.trim().isEmpty) {
      throw MenuItemNotFoundException(menuItemId);
    }
    final knownIds = validMenuItemIds;
    if (knownIds != null && !knownIds.contains(menuItemId)) {
      throw MenuItemNotFoundException(menuItemId);
    }
    final callback = menuItemExists;
    if (callback != null && !await callback(menuItemId)) {
      throw MenuItemNotFoundException(menuItemId);
    }
    if (menuService != null &&
        await menuService!.getMenuItem(menuItemId) == null) {
      throw MenuItemNotFoundException(menuItemId);
    }
  }

  Future<_AdditionalDefinition> _definitionFor(
    MenuAdditionalAssignment assignment,
  ) async {
    if (assignment.source == AdditionalSource.global) {
      final global = await additionalService.getAdditional(
        assignment.additionalId,
      );
      if (global == null) {
        throw AdditionalNotFoundException(assignment.additionalId);
      }
      return _AdditionalDefinition.fromGlobal(global);
    }

    final special = await specialAdditionalRepository.getById(
      assignment.additionalId,
    );
    if (special == null) {
      throw AdditionalNotFoundException(assignment.additionalId);
    }
    if (!special.belongsTo(assignment.menuItemId)) {
      throw InvalidAssignmentException(
        'El adicional especial solo puede asignarse a su Plato propietario.',
      );
    }
    return _AdditionalDefinition.fromSpecial(special);
  }
}

/// In-memory implementation. Omitting a box makes both repositories keep the
/// collection in memory, which is useful for unit/widget tests.
class InMemoryAdditionalAssignmentService
    extends AdditionalAssignmentServiceImpl {
  InMemoryAdditionalAssignmentService({
    required super.additionalService,
    super.assignmentRepository,
    super.specialAdditionalRepository,
    super.menuService,
    super.validMenuItemIds,
    super.menuItemExists,
  });
}

/// Hive implementation. The supplied repositories should be backed by the
/// application `settings` box; no relationship data is duplicated here.
class HiveAdditionalAssignmentService extends AdditionalAssignmentServiceImpl {
  HiveAdditionalAssignmentService({
    required super.additionalService,
    super.assignmentRepository,
    super.specialAdditionalRepository,
    super.menuService,
    super.validMenuItemIds,
    super.menuItemExists,
  });
}

class _AdditionalDefinition {
  final String name;
  final int priceCents;
  final bool available;

  const _AdditionalDefinition({
    required this.name,
    required this.priceCents,
    required this.available,
  });

  factory _AdditionalDefinition.fromGlobal(GlobalAdditional additional) =>
      _AdditionalDefinition(
        name: additional.name,
        priceCents: additional.priceCents,
        available: additional.available,
      );

  factory _AdditionalDefinition.fromSpecial(SpecialAdditional additional) =>
      _AdditionalDefinition(
        name: additional.name,
        priceCents: additional.priceCents,
        available: additional.available,
      );
}
