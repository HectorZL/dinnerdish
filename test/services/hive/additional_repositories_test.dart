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
      '${Directory.systemTemp.path}${Platform.pathSeparator}dinnerhome-hive-repository-task-26',
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

  group('claves ausentes y round-trip', () {
    test('las claves ausentes se leen como listas vacías', () async {
      final specials = SpecialAdditionalRepository(settingsBox: settings);
      final assignments = AdditionalAssignmentRepository(settingsBox: settings);

      expect(await specials.readAll(), isEmpty);
      expect(await assignments.readAll(), isEmpty);
      expect(settings.get(SpecialAdditionalRepository.storageKey), isNull);
      expect(settings.get(AdditionalAssignmentRepository.storageKey), isNull);
    });

    test(
      'los especiales conservan propietario y hacen round-trip sin stock',
      () async {
        final repository = SpecialAdditionalRepository(
          settingsBox: settings,
          validMenuItemIds: const {'menu-1'},
        );

        await repository.replaceAll([special()]);
        final restored = await repository.fetchForMenuItem('menu-1');

        expect(restored.single.toJson(), special().toJson());
        expect(restored.single.toJson(), isNot(contains('stock')));
        expect(settings.get(SpecialAdditionalRepository.storageKey), [
          special().toJson(),
        ]);
      },
    );

    test(
      'las asignaciones conservan origen y hacen round-trip sin stock',
      () async {
        final repository = AdditionalAssignmentRepository(
          settingsBox: settings,
          validMenuItemIds: const {'menu-1'},
          validGlobalAdditionalIds: const {'global-1'},
        );
        final value = assignment();

        await repository.replaceAll([value]);
        final restored = await repository.readAll();

        expect(restored.single.toJson(), value.toJson());
        expect(restored.single.source, AdditionalSource.global);
        expect(restored.single.toJson(), isNot(contains('stock')));
      },
    );
  });

  group('lectura tolerante y migración no destructiva', () {
    test(
      'una lista corrupta conserva las filas válidas y no reescribe Hive',
      () async {
        final validSpecial = special();
        await settings.put(SpecialAdditionalRepository.storageKey, [
          validSpecial.toJson(),
          {'id': 'incompleto', 'ownerMenuItemId': 'menu-1'},
          'fila que no es un mapa',
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
        expect(
          settings.get(SpecialAdditionalRepository.storageKey),
          hasLength(3),
        );
      },
    );

    test(
      'relaciones corruptas o huérfanas no eliminan las filas válidas',
      () async {
        final valid = assignment();
        await settings.put(AdditionalAssignmentRepository.storageKey, [
          valid.toJson(),
          assignment(menuItemId: 'missing-menu').toJson(),
          assignment(additionalId: 'missing-global').toJson(),
          {'menuItemId': 'menu-1', 'source': 'global'},
        ]);
        final errors = <Object>[];
        final repository = AdditionalAssignmentRepository(
          settingsBox: settings,
          validMenuItemIds: const {'menu-1'},
          validGlobalAdditionalIds: const {'global-1'},
          onRecoverableError: errors.add,
        );

        final loaded = await repository.readAll();

        expect(loaded.single.toJson(), valid.toJson());
        expect(errors, hasLength(3));
        expect(
          settings.get(AdditionalAssignmentRepository.storageKey),
          hasLength(4),
        );
      },
    );

    test(
      'especiales huérfanos no impiden leer los especiales válidos',
      () async {
        await settings.put(SpecialAdditionalRepository.storageKey, [
          special().toJson(),
          special(id: 'orphan', owner: 'missing-menu').toJson(),
        ]);
        final errors = <Object>[];
        final repository = SpecialAdditionalRepository(
          settingsBox: settings,
          validMenuItemIds: const {'menu-1'},
          onRecoverableError: errors.add,
        );

        final loaded = await repository.readAll();

        expect(loaded.single.id, 'special-1');
        expect(errors.single, isA<InvalidAssignmentException>());
        expect(
          settings.get(SpecialAdditionalRepository.storageKey),
          hasLength(2),
        );
      },
    );
  });

  group('sustitución atómica lógica', () {
    test(
      'no sustituye especiales si el candidato contiene una referencia inválida',
      () async {
        final repository = SpecialAdditionalRepository(
          settingsBox: settings,
          validMenuItemIds: const {'menu-1'},
        );
        await repository.replaceAll([special()]);
        final before = List<dynamic>.from(
          settings.get(SpecialAdditionalRepository.storageKey) as List,
        );

        await expectLater(
          repository.replaceAll([
            special(),
            special(id: 'orphan', owner: 'menu-missing'),
          ]),
          throwsA(isA<InvalidAssignmentException>()),
        );

        expect(settings.get(SpecialAdditionalRepository.storageKey), before);
        expect((await repository.readAll()).map((item) => item.id), [
          'special-1',
        ]);
      },
    );

    test(
      'no sustituye asignaciones si el candidato contiene un huérfano',
      () async {
        final repository = AdditionalAssignmentRepository(
          settingsBox: settings,
          validMenuItemIds: const {'menu-1', 'menu-2'},
          validGlobalAdditionalIds: const {'global-1'},
        );
        final first = assignment();
        await repository.replaceAll([first]);
        final before = List<dynamic>.from(
          settings.get(AdditionalAssignmentRepository.storageKey) as List,
        );

        await expectLater(
          repository.replaceAll([
            first,
            assignment(menuItemId: 'menu-2', additionalId: 'global-missing'),
          ]),
          throwsA(isA<InvalidAssignmentException>()),
        );

        expect(settings.get(AdditionalAssignmentRepository.storageKey), before);
        expect((await repository.readAll()).single.toJson(), first.toJson());
      },
    );
  });
}
