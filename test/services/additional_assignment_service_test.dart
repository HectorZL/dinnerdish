import 'package:dinnerhome/exceptions/validation_exception.dart';
import 'package:dinnerhome/models/additional_source.dart';
import 'package:dinnerhome/models/menu_additional_assignment.dart';
import 'package:dinnerhome/models/special_additional.dart';
import 'package:dinnerhome/services/additional_assignment_service.dart';
import 'package:dinnerhome/services/hive/additional_assignment_repository.dart';
import 'package:dinnerhome/services/hive/hive_additional_service.dart';
import 'package:dinnerhome/services/hive/special_additional_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late HiveAdditionalService globalService;
  late SpecialAdditionalRepository specialRepository;
  late AdditionalAssignmentRepository assignmentRepository;
  late InMemoryAdditionalAssignmentService service;

  setUp(() async {
    if (Hive.isBoxOpen('settings')) {
      await Hive.box<dynamic>('settings').clear();
    }
    globalService = HiveAdditionalService();
    specialRepository = SpecialAdditionalRepository(
      validMenuItemIds: const {'menu-1', 'menu-2'},
    );
    assignmentRepository = AdditionalAssignmentRepository(
      validMenuItemIds: const {'menu-1', 'menu-2'},
      validGlobalAdditionalIds: const {'additional-rice', 'additional-salad'},
      validSpecialAdditionalIds: const {'special-1'},
      specialAdditionalById: specialRepository.getById,
    );
    service = InMemoryAdditionalAssignmentService(
      additionalService: globalService,
      assignmentRepository: assignmentRepository,
      specialAdditionalRepository: specialRepository,
      validMenuItemIds: const {'menu-1', 'menu-2'},
    );
  });

  test(
    'aísla un global asignado a dos platos y hace el duplicado idempotente',
    () async {
      final first = await service.assignGlobal('menu-1', 'additional-rice');
      final duplicate = await service.assignGlobal('menu-1', 'additional-rice');
      await service.assignGlobal('menu-2', 'additional-rice');

      expect(duplicate.id, first.id);
      expect((await service.fetchForMenuItem('menu-1')), hasLength(1));
      expect((await service.fetchForMenuItem('menu-2')), hasLength(1));

      await service.remove('menu-1', first.id);
      expect(await service.fetchForMenuItem('menu-1'), isEmpty);
      expect(
        (await service.fetchForMenuItem('menu-2')).single.additionalId,
        'additional-rice',
      );
    },
  );

  test(
    'resuelve siempre el nombre, precio y disponibilidad actuales',
    () async {
      await service.assignGlobal('menu-1', 'additional-rice');
      final initial = (await service.fetchResolvedForMenuItem('menu-1')).single;
      expect(initial.name, 'Porción de arroz');

      final global = await globalService.getAdditional('additional-rice');
      await globalService.updateAdditional(
        'additional-rice',
        global!.copyWith(
          name: '  Arroz actualizado ',
          priceCents: 999,
          available: false,
        ),
      );

      final current = (await service.fetchResolvedForMenuItem('menu-1')).single;
      expect(current.name, 'Arroz actualizado');
      expect(current.priceCents, 999);
      expect(current.available, isFalse);
      expect(
        (await assignmentRepository.readAll()).single.toJson(),
        isNot(contains('name')),
      );
    },
  );

  test(
    'valida propietario de especial, agrupa sin mezclar y elimina cascada global',
    () async {
      await specialRepository.replaceAll([
        SpecialAdditional(
          id: 'special-1',
          ownerMenuItemId: 'menu-1',
          name: 'Salsa propia',
          priceCents: 150,
          available: true,
        ),
      ]);

      await service.assignSpecial('menu-1', 'special-1');
      await expectLater(
        service.assignSpecial('menu-2', 'special-1'),
        throwsA(isA<InvalidAssignmentException>()),
      );

      await service.assignGlobal('menu-2', 'additional-salad');
      final grouped = await service.fetchResolvedGroupedByMenuItem(const [
        'menu-1',
        'menu-2',
      ]);
      expect(grouped['menu-1']!.single.source, AdditionalSource.special);
      expect(grouped['menu-2']!.single.source, AdditionalSource.global);

      await service.removeAllForGlobal('additional-salad');
      expect(grouped['menu-1'], hasLength(1));
      expect(await service.fetchForMenuItem('menu-2'), isEmpty);
    },
  );
}
