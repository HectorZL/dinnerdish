import 'dart:io';

import 'package:dinnerhome/exceptions/validation_exception.dart';
import 'package:dinnerhome/models/menu_additional_assignment.dart';
import 'package:dinnerhome/models/special_additional.dart';
import 'package:dinnerhome/services/hive/additional_assignment_repository.dart';
import 'package:dinnerhome/services/hive/special_additional_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Box<dynamic> settings;
  late Directory hiveDirectory;

  setUpAll(() async {
    hiveDirectory = Directory(
      '${Directory.systemTemp.path}${Platform.pathSeparator}dinnerhome-additional-repositories',
    );
    if (hiveDirectory.existsSync()) hiveDirectory.deleteSync(recursive: true);
    Hive.init(hiveDirectory.path);
    settings = await Hive.openBox<dynamic>('settings');
  });

  setUp(() async {
    await settings.clear();
  });

  tearDownAll(() async {
    await settings.deleteFromDisk();
  });

  SpecialAdditional special({
    String id = 'special-1',
    String owner = 'menu-1',
  }) => SpecialAdditional(
    id: id,
    ownerMenuItemId: owner,
    name: 'Salsa',
    priceCents: 100,
    available: true,
  );

  MenuAdditionalAssignment assignment({
    String menuItemId = 'menu-1',
    AdditionalSource source = AdditionalSource.global,
    String additionalId = 'global-1',
  }) => MenuAdditionalAssignment(
    menuItemId: menuItemId,
    source: source,
    additionalId: additionalId,
  );

  group('SpecialAdditionalRepository', () {
    test(
      'interpreta clave ausente como lista vacía y hace round-trip sin stock',
      () async {
        final repository = SpecialAdditionalRepository(settingsBox: settings);

        expect(await repository.readAll(), isEmpty);

        await repository.replaceAll([special()]);
        final saved = await repository.fetchForMenuItem('menu-1');

        expect(saved.single.toJson(), special().toJson());
        expect(settings.get(SpecialAdditionalRepository.storageKey), [
          {
            'id': 'special-1',
            'ownerMenuItemId': 'menu-1',
            'name': 'Salsa',
            'priceCents': 100,
            'available': true,
          },
        ]);
        expect(saved.single.toJson(), isNot(contains('stock')));
      },
    );

    test(
      'omite JSON corrupto y propietarios huérfanos, registrando el error',
      () async {
        await settings.put(SpecialAdditionalRepository.storageKey, [
          special(owner: 'menu-1').toJson(),
          {'id': 'broken'},
          special(id: 'orphan', owner: 'missing').toJson(),
        ]);
        final errors = <Object>[];
        final repository = SpecialAdditionalRepository(
          settingsBox: settings,
          validMenuItemIds: const {'menu-1'},
          onRecoverableError: errors.add,
        );

        final loaded = await repository.readAll();

        expect(loaded.map((item) => item.id), ['special-1']);
        expect(errors, hasLength(2));
        // Reading recovery does not erase the valid global/menu data or rewrite
        // the source collection implicitly.
        expect(
          settings.get(SpecialAdditionalRepository.storageKey),
          hasLength(3),
        );
      },
    );

    test(
      'no reemplaza la colección si la nueva lista tiene una relación inválida',
      () async {
        final repository = SpecialAdditionalRepository(
          settingsBox: settings,
          validMenuItemIds: const {'menu-1'},
        );
        await repository.replaceAll([special()]);

        await expectLater(
          repository.replaceAll([
            special(),
            special(id: 'orphan', owner: 'menu-2'),
          ]),
          throwsA(isA<InvalidAssignmentException>()),
        );

        expect((await repository.readAll()).map((item) => item.id), [
          'special-1',
        ]);
      },
    );
  });

  group('AdditionalAssignmentRepository', () {
    test(
      'interpreta clave ausente como vacía y conserva origen sin stock',
      () async {
        final repository = AdditionalAssignmentRepository(
          settingsBox: settings,
          validMenuItemIds: const {'menu-1'},
          validGlobalAdditionalIds: const {'global-1'},
        );

        expect(await repository.readAll(), isEmpty);
        final saved = await repository.assign(assignment());

        expect(saved.source, AdditionalSource.global);
        expect(
          (await repository.fetchForMenuItem('menu-1')).single.toJson(),
          saved.toJson(),
        );
        expect(settings.get(AdditionalAssignmentRepository.storageKey), [
          saved.toJson(),
        ]);
        expect(saved.toJson(), isNot(contains('stock')));
      },
    );

    test(
      'omite corruptos, huérfanos y duplicados sin bloquear filas válidas',
      () async {
        final valid = assignment();
        await settings.put(AdditionalAssignmentRepository.storageKey, [
          valid.toJson(),
          valid.toJson(),
          assignment(menuItemId: 'missing').toJson(),
          {'id': 'invalid'},
        ]);
        final errors = <Object>[];
        final repository = AdditionalAssignmentRepository(
          settingsBox: settings,
          validMenuItemIds: const {'menu-1'},
          validGlobalAdditionalIds: const {'global-1'},
          onRecoverableError: errors.add,
        );

        final loaded = await repository.readAll();

        expect(loaded, hasLength(1));
        expect(loaded.single.logicalKey, valid.logicalKey);
        expect(errors, hasLength(3));
        expect(
          settings.get(AdditionalAssignmentRepository.storageKey),
          hasLength(4),
        );
      },
    );

    test(
      'asignar es idempotente y retirar no puede borrar otra relación',
      () async {
        final repository = AdditionalAssignmentRepository(
          settingsBox: settings,
          validMenuItemIds: const {'menu-1', 'menu-2'},
          validGlobalAdditionalIds: const {'global-1'},
        );
        final first = await repository.assign(assignment(menuItemId: 'menu-1'));
        final duplicate = await repository.assign(
          assignment(menuItemId: 'menu-1'),
        );
        await repository.assign(assignment(menuItemId: 'menu-2'));

        expect(duplicate.id, first.id);
        expect((await repository.readAll()), hasLength(2));

        await expectLater(
          repository.remove('menu-2', first.id),
          throwsA(isA<InvalidAssignmentException>()),
        );
        expect((await repository.readAll()), hasLength(2));

        await repository.remove('menu-1', first.id);
        final remaining = await repository.readAll();
        expect(remaining.single.menuItemId, 'menu-2');
      },
    );

    test('valida ownership de especiales antes de escribir', () async {
      final specialItem = special();
      final repository = AdditionalAssignmentRepository(
        settingsBox: settings,
        validMenuItemIds: const {'menu-1', 'menu-2'},
        validSpecialAdditionalIds: const {'special-1'},
        specialAdditionalById: (id) async =>
            id == specialItem.id ? specialItem : null,
      );
      final valid = assignment(
        source: AdditionalSource.special,
        additionalId: specialItem.id,
      );
      await repository.replaceAll([valid]);

      await expectLater(
        repository.replaceAll([
          valid,
          assignment(
            menuItemId: 'menu-2',
            source: AdditionalSource.special,
            additionalId: specialItem.id,
          ),
        ]),
        throwsA(isA<InvalidAssignmentException>()),
      );
      expect((await repository.readAll()).single.menuItemId, 'menu-1');
    });
  });
}
