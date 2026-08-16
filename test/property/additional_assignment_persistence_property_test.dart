import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dinnerhome/models/menu_additional_assignment.dart';
import 'package:dinnerhome/services/hive/additional_assignment_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Box<dynamic> settings;
  late Directory hiveDirectory;

  setUpAll(() async {
    hiveDirectory = Directory(
      '${Directory.systemTemp.path}${Platform.pathSeparator}dinnerhome-additional-assignment-property',
    );
    if (hiveDirectory.existsSync()) {
      hiveDirectory.deleteSync(recursive: true);
    }
    Hive.init(hiveDirectory.path);
    settings = await Hive.openBox<dynamic>('settings');
  });

  setUp(() async {
    await settings.clear();
  });

  tearDownAll(() async {
    await settings.deleteFromDisk();
  });

  test(
    'Feature: ajuste-platos-variaciones-adicionales, Property 12: Persistencia de actualización parcial',
    () async {
      // Validates: Requirements 7.1, 7.2, 7.3
      const iterations = 120;
      final random = Random(12);

      expect(iterations, greaterThanOrEqualTo(100));

      for (var iteration = 0; iteration < iterations; iteration++) {
        final dishCount = 2 + random.nextInt(5);
        final menuItemIds = [
          for (var dish = 0; dish < dishCount; dish++)
            'menu-$iteration-$dish',
        ];
        final initialAssignments = <MenuAdditionalAssignment>[];
        final additionalIds = <String>{};

        // Every generated relationship refers to an existing menu item and a
        // known global additional. Each dish receives multiple relationships
        // so an update cannot accidentally replace the dish's whole group.
        for (var dish = 0; dish < dishCount; dish++) {
          for (var slot = 0; slot < 2; slot++) {
            final additionalId = 'global-$iteration-$dish-$slot';
            additionalIds.add(additionalId);
            initialAssignments.add(
              MenuAdditionalAssignment(
                menuItemId: menuItemIds[dish],
                source: AdditionalSource.global,
                additionalId: additionalId,
              ),
            );
          }
        }

        final targetDishIndex = random.nextInt(dishCount);
        final targetDishId = menuItemIds[targetDishIndex];
        final replacementAdditionalId =
            'global-$iteration-$targetDishIndex-replacement';
        additionalIds.add(replacementAdditionalId);

        final repository = AdditionalAssignmentRepository(
          settingsBox: settings,
          validMenuItemIds: menuItemIds,
          validGlobalAdditionalIds: additionalIds,
        );
        await repository.replaceAll(initialAssignments);
        final beforeReload = await repository.readAll();
        final before = _snapshotByMenuItem(beforeReload, menuItemIds);

        final targetAssignment = initialAssignments.firstWhere(
          (assignment) => assignment.menuItemId == targetDishId,
        );
        final updatedAssignments = initialAssignments
            .map(
              (assignment) => assignment.id == targetAssignment.id
                  ? assignment.copyWith(
                      additionalId: replacementAdditionalId,
                    )
                  : assignment,
            )
            .toList(growable: false);
        await repository.replaceAll(updatedAssignments);

        // Recreate the repository to force the assertion through persisted
        // Hive data rather than through the previous in-memory projection.
        final reloadedRepository = AdditionalAssignmentRepository(
          settingsBox: settings,
          validMenuItemIds: menuItemIds,
          validGlobalAdditionalIds: additionalIds,
        );
        final afterReload = await reloadedRepository.readAll();
        final after = _snapshotByMenuItem(afterReload, menuItemIds);

        final expected = _snapshotByMenuItem(updatedAssignments, menuItemIds);
        expect(after, expected);

        final changedMenuItems = menuItemIds
            .where((menuItemId) => before[menuItemId] != after[menuItemId])
            .toList(growable: false);
        expect(changedMenuItems, [targetDishId]);

        for (final menuItemId in menuItemIds) {
          if (menuItemId == targetDishId) continue;
          expect(after[menuItemId], before[menuItemId]);
        }

        final targetRows = jsonDecode(after[targetDishId]!) as List<dynamic>;
        expect(
          targetRows.whereType<Map<String, dynamic>>().singleWhere(
            (row) => row['id'] == targetAssignment.id,
          )['additionalId'],
          replacementAdditionalId,
        );
      }
    },
  );
}

Map<String, String> _snapshotByMenuItem(
  Iterable<MenuAdditionalAssignment> assignments,
  Iterable<String> menuItemIds,
) {
  final grouped = <String, List<Map<String, dynamic>>>{
    for (final menuItemId in menuItemIds) menuItemId: <Map<String, dynamic>>[],
  };
  for (final assignment in assignments) {
    grouped.putIfAbsent(assignment.menuItemId, () => []).add(assignment.toJson());
  }
  return {
    for (final menuItemId in menuItemIds)
      menuItemId: jsonEncode(
        grouped[menuItemId]!..sort((left, right) =>
            (left['id'] as String).compareTo(right['id'] as String)),
      ),
  };
}
