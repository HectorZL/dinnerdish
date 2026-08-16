import 'dart:io';

import 'package:dinnerhome/models/global_additional.dart';
import 'package:dinnerhome/models/menu_item.dart';
import 'package:dinnerhome/models/menu_item_variation.dart';
import 'package:dinnerhome/models/modifier.dart';
import 'package:dinnerhome/services/hive/additional_assignment_repository.dart';
import 'package:dinnerhome/services/hive/hive_additional_service.dart';
import 'package:dinnerhome/services/hive/hive_menu_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory hiveDirectory;
  late Box<dynamic> settings;
  late Box<MenuItem> menuBox;

  setUpAll(() async {
    hiveDirectory = Directory(
      '${Directory.systemTemp.path}${Platform.pathSeparator}dinnerhome-repository-migration-task-26',
    );
    if (hiveDirectory.existsSync()) {
      hiveDirectory.deleteSync(recursive: true);
    }
    Hive.init(hiveDirectory.path);
    Hive.registerAdapter(MenuItemAdapter());
    Hive.registerAdapter(MenuItemVariationAdapter());
    Hive.registerAdapter(ModifierAdapter());
    settings = await Hive.openBox<dynamic>('settings');
    menuBox = await Hive.openBox<MenuItem>('menu_items_v1_migration_test');
  });

  setUp(() async {
    await settings.clear();
    await menuBox.clear();
  });

  tearDownAll(() async {
    await settings.deleteFromDisk();
    await menuBox.deleteFromDisk();
  });

  test(
    'deserializa un registro legacy y conserva los campos nuevos ausentes',
    () {
      final legacy = <String, dynamic>{
        'id': 'menu-legacy',
        'name': 'Plato legacy',
        'priceCents': 1500,
        'modifiers': <Map<String, dynamic>>[
          {'id': 'modifier-1', 'name': 'Sin cebolla', 'priceCents': 0},
        ],
        'available': true,
        'category': 'Principal',
      };

      final item = MenuItem.fromJson(legacy);

      expect(item.id, 'menu-legacy');
      expect(item.stock, 99);
      expect(item.variations, isEmpty);
      expect(item.additionalIds, isEmpty);
      expect(item.modifiers.single.name, 'Sin cebolla');
      expect(item.toJson(), containsPair('stock', 99));
      expect(item.toJson(), containsPair('variations', isEmpty));
      expect(item.toJson(), containsPair('additionalIds', isEmpty));
    },
  );

  test(
    'el adaptador Hive conserva stock, variaciones y relaciones existentes',
    () async {
      final item = MenuItem(
        id: 'menu-current',
        name: 'Plato actual',
        priceCents: 2200,
        modifiers: const [
          Modifier(id: 'modifier-1', name: 'Queso', priceCents: 100),
        ],
        available: true,
        category: 'Principal',
        stock: 0,
        variations: const [
          MenuItemVariation(
            id: 'variation-1',
            name: 'Grande',
            priceCents: 2500,
            stock: 4,
          ),
        ],
        additionalIds: const ['global-1'],
      );

      await menuBox.put(item.id, item);
      final restored = menuBox.get(item.id)!;

      expect(restored.id, item.id);
      expect(restored.stock, 0);
      expect(restored.variations.single.stock, 4);
      expect(restored.additionalIds, ['global-1']);
      expect(restored.toJson(), item.toJson());
    },
  );

  test(
    'el catálogo global lee legacy con stock, conserva otros globales y no lo vuelve a guardar',
    () async {
      await settings.put(HiveAdditionalService.storageKey, [
        {
          'id': 'global-1',
          'name': '  Queso  ',
          'priceCents': 125,
          'available': true,
          'stock': 14,
        },
        const GlobalAdditional(
          id: 'global-2',
          name: 'Arroz',
          priceCents: 200,
          available: false,
        ).toJson(),
      ]);

      final service = HiveAdditionalService(settingsBox: settings);
      final loaded = await service.fetchAdditions();

      expect(loaded.map((addition) => addition.id), ['global-2', 'global-1']);
      expect(
        loaded.firstWhere((addition) => addition.id == 'global-1').name,
        'Queso',
      );
      expect(
        loaded.every((addition) => !addition.toJson().containsKey('stock')),
        isTrue,
      );
      // Migration reads the legacy payload without destructive rewriting. A
      // subsequent write emits only the canonical stock-less representation.
      expect(
        (settings.get(HiveAdditionalService.storageKey) as List)
            .whereType<Map>()
            .firstWhere((row) => row['id'] == 'global-1'),
        containsPair('stock', 14),
      );
      await service.updateAdditional(
        'global-1',
        loaded.firstWhere((addition) => addition.id == 'global-1'),
      );
      expect(
        (settings.get(HiveAdditionalService.storageKey) as List)
            .whereType<Map>()
            .every((row) => !row.containsKey('stock')),
        isTrue,
      );
    },
  );

  test('una relación huérfana no elimina globales ni platos válidos', () async {
    final menu = MenuItem(
      id: 'menu-valid',
      name: 'Plato válido',
      priceCents: 1000,
      modifiers: const [],
      available: true,
      category: 'Principal',
      stock: 8,
    );
    await menuBox.put(menu.id, menu);
    await settings.put(HiveAdditionalService.storageKey, [
      const GlobalAdditional(
        id: 'global-valid',
        name: 'Salsa válida',
        priceCents: 50,
        available: true,
      ).toJson(),
    ]);
    await settings.put('menu_additional_assignments_v1', [
      {
        'id': 'orphan-assignment',
        'menuItemId': 'menu-missing',
        'source': 'global',
        'additionalId': 'global-valid',
      },
    ]);

    final additionalService = HiveAdditionalService(settingsBox: settings);
    final errors = <Object>[];
    final assignmentRepository = AdditionalAssignmentRepository(
      settingsBox: settings,
      validMenuItemIds: const {'menu-valid'},
      validGlobalAdditionalIds: const {'global-valid'},
      onRecoverableError: errors.add,
    );
    final menuService = HiveMenuService(box: menuBox);

    expect(await assignmentRepository.readAll(), isEmpty);
    expect(
      (await additionalService.fetchAdditions()).single.id,
      'global-valid',
    );
    expect((await menuService.fetchMenu()).single.id, 'menu-valid');
    expect((await menuService.getMenuItem('menu-valid'))!.stock, 8);
    expect(errors, hasLength(1));
    // Recovery is read-only: the invalid relationship remains available for a
    // later repair, while valid catalog/menu records remain untouched.
    expect(settings.get('menu_additional_assignments_v1'), hasLength(1));
  });
}
