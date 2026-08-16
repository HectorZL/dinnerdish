import 'dart:io';

import 'package:dinnerhome/exceptions/validation_exception.dart';
import 'package:dinnerhome/models/global_additional.dart';
import 'package:dinnerhome/models/menu_additional_assignment.dart';
import 'package:dinnerhome/services/hive/additional_assignment_repository.dart';
import 'package:dinnerhome/services/hive/hive_additional_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory hiveDirectory;
  late Box<dynamic> settings;

  setUpAll(() async {
    hiveDirectory = Directory(
      '${Directory.systemTemp.path}${Platform.pathSeparator}dinnerhome-global-additional-service',
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

  test(
    'lee el formato legacy, normaliza nombres y nunca persiste stock',
    () async {
      await settings.put(HiveAdditionalService.storageKey, [
        {
          'id': 'global-1',
          'name': '  Salsa  ',
          'priceCents': 125,
          'available': true,
          'stock': 99,
        },
        {
          'id': 'global-duplicate',
          'name': 'sALSA',
          'priceCents': 200,
          'available': true,
        },
      ]);
      final errors = <Object>[];
      final service = HiveAdditionalService(
        settingsBox: settings,
        onRecoverableError: errors.add,
      );

      final additions = await service.fetchAdditions();

      expect(additions, hasLength(1));
      expect(additions.single.name, 'Salsa');
      expect(additions.single.toJson(), {
        'id': 'global-1',
        'name': 'Salsa',
        'priceCents': 125,
        'available': true,
      });
      expect(additions.single.toJson(), isNot(contains('stock')));
      expect(errors, hasLength(1));
      // Reading legacy data is non-destructive; normalization is guaranteed on
      // the next write rather than silently rewriting the source payload.
      expect(
        (settings.get(HiveAdditionalService.storageKey) as List)
            .whereType<Map>()
            .firstWhere((item) => item['id'] == 'global-1'),
        containsPair('stock', 99),
      );
    },
  );

  test(
    'rechaza duplicados sin distinguir mayúsculas y normaliza al guardar',
    () async {
      final service = HiveAdditionalService(settingsBox: settings);

      final created = await service.createAdditional(
        const GlobalAdditional(
          id: 'global-1',
          name: '  Extra Queso ',
          priceCents: 0,
          available: true,
        ),
      );

      expect(created.name, 'Extra Queso');
      final payload = (settings.get(HiveAdditionalService.storageKey) as List)
          .whereType<Map>();
      expect(
        payload.any(
          (item) =>
              item['id'] == 'global-1' &&
              item['name'] == 'Extra Queso' &&
              item['priceCents'] == 0 &&
              item['available'] == true,
        ),
        isTrue,
      );
      await expectLater(
        service.createAdditional(
          const GlobalAdditional(
            id: 'global-2',
            name: 'extra queso',
            priceCents: 100,
            available: true,
          ),
        ),
        throwsA(isA<DuplicateAdditionalException>()),
      );

      final updated = await service.updateAdditional(
        'global-1',
        created.copyWith(name: '  Salsa Verde  '),
      );
      expect(updated.name, 'Salsa Verde');
      expect(
        (await service.fetchAdditions())
            .firstWhere((addition) => addition.id == 'global-1')
            .name,
        'Salsa Verde',
      );
    },
  );

  test(
    'una clave ausente no crea asignaciones desde nombres ni registros externos',
    () async {
      final service = HiveAdditionalService(settingsBox: settings);

      await service.fetchAdditions();

      expect(settings.get(AdditionalAssignmentRepository.storageKey), isNull);
    },
  );

  test(
    'elimina global y relaciones solo después de confirmar la escritura',
    () async {
      final assignmentRepository = AdditionalAssignmentRepository(
        settingsBox: settings,
        validMenuItemIds: const {'menu-1'},
        validGlobalAdditionalIds: const {'global-1'},
      );
      await settings.put(HiveAdditionalService.storageKey, [
        {
          'id': 'global-1',
          'name': 'Salsa',
          'priceCents': 100,
          'available': true,
        },
        {
          'id': 'global-2',
          'name': 'Arroz',
          'priceCents': 200,
          'available': true,
        },
      ]);
      await assignmentRepository.assign(
        MenuAdditionalAssignment(
          menuItemId: 'menu-1',
          source: AdditionalSource.global,
          additionalId: 'global-1',
        ),
      );
      final service = HiveAdditionalService(
        settingsBox: settings,
        assignmentRepository: assignmentRepository,
      );

      await service.deleteAdditional('global-1');

      expect(await service.getAdditional('global-1'), isNull);
      expect((await service.fetchAdditions()).single.id, 'global-2');
      expect(await assignmentRepository.readAll(), isEmpty);
    },
  );

  test(
    'si la cascada falla, restaura la definición global para reintentar',
    () async {
      final service = HiveAdditionalService(
        settingsBox: settings,
        removeAssignmentsForGlobal: (_) async {
          throw StateError('fallo de relaciones');
        },
      );
      await service.createAdditional(
        const GlobalAdditional(
          id: 'global-1',
          name: 'Salsa',
          priceCents: 100,
          available: true,
        ),
      );

      await expectLater(
        service.deleteAdditional('global-1'),
        throwsA(isA<StateError>()),
      );
      expect(await service.getAdditional('global-1'), isNotNull);
    },
  );
}
