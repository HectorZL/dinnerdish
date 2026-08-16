import 'package:dinnerhome/models/global_additional.dart';
import 'package:dinnerhome/models/menu_item.dart';
import 'package:dinnerhome/models/menu_item_variation.dart';
import 'package:dinnerhome/models/modifier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MenuItem y MenuItemVariation: compatibilidad JSON', () {
    test(
      'lee un plato legacy sin stock, variaciones ni adicionales nuevos',
      () {
        final legacyJson = <String, dynamic>{
          'id': 'menu-legacy',
          'name': 'Plato legacy',
          'priceCents': 1500,
          'modifiers': <Map<String, dynamic>>[
            {'id': 'modifier-1', 'name': 'Sin cebolla', 'priceCents': 0},
          ],
          'available': true,
          'category': 'Principal',
        };

        final item = MenuItem.fromJson(legacyJson);

        expect(item.stock, 99);
        expect(item.variations, isEmpty);
        expect(item.additionalIds, isEmpty);
        expect(item.modifiers.single.name, 'Sin cebolla');
        expect(item.toJson()['stock'], 99);
        expect(item.toJson()['variations'], isEmpty);
        expect(item.toJson()['additionalIds'], isEmpty);
      },
    );

    test(
      'conserva stock base, stocks de variaciones y relaciones en round-trip',
      () {
        final item = MenuItem(
          id: 'menu-1',
          name: 'Hamburguesa',
          priceCents: 2500,
          modifiers: const [
            Modifier(id: 'modifier-1', name: 'Queso', priceCents: 150),
          ],
          available: true,
          category: 'Principal',
          stock: 0,
          variations: const [
            MenuItemVariation(
              id: 'variation-small',
              name: 'Pequeña',
              priceCents: 2000,
              stock: 3,
            ),
            MenuItemVariation(
              id: 'variation-large',
              name: 'Grande',
              priceCents: 3000,
              stock: 0,
            ),
          ],
          additionalIds: const ['global-1'],
        );

        final restored = MenuItem.fromJson(item.toJson());

        expect(restored.toJson(), item.toJson());
        expect(restored.stock, 0);
        expect(restored.variations.map((variation) => variation.stock), [3, 0]);
        expect(restored.additionalIds, ['global-1']);
      },
    );

    test('la variación conserva stock cero y precio cero en JSON', () {
      const variation = MenuItemVariation(
        id: 'variation-1',
        name: 'Sin costo',
        priceCents: 0,
        stock: 0,
      );

      expect(
        MenuItemVariation.fromJson(variation.toJson()).toJson(),
        variation.toJson(),
      );
    });
  });

  group('GlobalAdditional: compatibilidad JSON', () {
    test('lee formato existente y no agrega stock al catálogo global', () {
      final legacyJson = <String, dynamic>{
        'id': 'global-1',
        'name': '  Queso  ',
        'priceCents': 0,
        'available': true,
        // Datos ajenos que una versión previa pudiera haber guardado.
        'stock': 12,
      };

      final additional = GlobalAdditional.fromJson(legacyJson);

      expect(additional.name, '  Queso  ');
      expect(additional.priceCents, 0);
      expect(additional.toJson(), {
        'id': 'global-1',
        'name': '  Queso  ',
        'priceCents': 0,
        'available': true,
      });
      expect(additional.toJson(), isNot(contains('stock')));
      expect(
        GlobalAdditional.fromJson(additional.toJson()).toJson(),
        additional.toJson(),
      );
    });
  });
}
