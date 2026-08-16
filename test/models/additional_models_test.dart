import 'package:dinnerhome/exceptions/validation_exception.dart';
import 'package:dinnerhome/models/menu_additional_assignment.dart';
import 'package:dinnerhome/models/selected_additional.dart';
import 'package:dinnerhome/models/special_additional.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SpecialAdditional', () {
    test('normaliza nombre, conserva propietario y no serializa stock', () {
      final additional = SpecialAdditional(
        id: 'special-1',
        ownerMenuItemId: 'menu-1',
        name: '  Salsa  ',
        priceCents: 0,
        available: true,
      );

      expect(additional.name, 'Salsa');
      expect(additional.ownerMenuItemId, 'menu-1');
      expect(additional.toJson(), isNot(contains('stock')));
      expect(
        SpecialAdditional.fromJson(additional.toJson()).toJson(),
        additional.toJson(),
      );
    });

    test('rechaza nombre, propietario y precio inválidos', () {
      expect(
        () => SpecialAdditional(
          id: 'special-1',
          ownerMenuItemId: 'menu-1',
          name: ' ',
          priceCents: 0,
          available: true,
        ),
        throwsA(isA<InvalidNameException>()),
      );
      expect(
        () => SpecialAdditional(
          id: 'special-1',
          ownerMenuItemId: 'menu-2',
          name: 'Salsa',
          priceCents: -1,
          available: true,
        ),
        throwsA(isA<InvalidPriceException>()),
      );
      expect(
        () => SpecialAdditional(
          id: 'special-1',
          ownerMenuItemId: 'menu-1',
          name: 'Salsa',
          priceCents: 0,
          available: true,
        ).validateOwner('menu-2'),
        throwsA(isA<InvalidAssignmentException>()),
      );
    });
  });

  group('MenuAdditionalAssignment', () {
    test('distingue origen y genera una clave estable', () {
      final global = MenuAdditionalAssignment(
        menuItemId: 'menu-1',
        source: AdditionalSource.global,
        additionalId: 'additional-1',
      );
      final sameKey = MenuAdditionalAssignment(
        menuItemId: 'menu-1',
        source: AdditionalSource.global,
        additionalId: 'additional-1',
      );
      final special = global.copyWith(source: AdditionalSource.special);

      expect(global.id, sameKey.id);
      expect(global.logicalKey, sameKey.logicalKey);
      expect(global.source, AdditionalSource.global);
      expect(special.source, AdditionalSource.special);
      expect(special.id, isNot(global.id));
      expect(
        MenuAdditionalAssignment.fromJson(global.toJson()).toJson(),
        global.toJson(),
      );
    });

    test('no serializa datos de definición ni stock', () {
      final assignment = MenuAdditionalAssignment(
        menuItemId: 'menu-1',
        source: AdditionalSource.special,
        additionalId: 'special-1',
      );
      expect(assignment.toJson(), isNot(contains('name')));
      expect(assignment.toJson(), isNot(contains('priceCents')));
      expect(assignment.toJson(), isNot(contains('stock')));
    });
  });

  test('round-trip de proyección y snapshot conserva el origen', () {
    final assignment = MenuAdditionalAssignment(
      menuItemId: 'menu-1',
      source: AdditionalSource.global,
      additionalId: 'global-1',
    );
    final projection = AssignedAdditional.fromAssignment(
      assignment: assignment,
      name: 'Queso',
      priceCents: 150,
      available: true,
    );
    final selected = SelectedAdditional(
      assignmentId: projection.assignmentId,
      additionalId: projection.additionalId,
      source: projection.source,
      nameSnapshot: projection.name,
      priceCentsSnapshot: projection.priceCents,
    );

    expect(
      SelectedAdditional.fromJson(selected.toJson()).toJson(),
      selected.toJson(),
    );
    expect(selected.source, AdditionalSource.global);
    expect(projection.source, AdditionalSource.global);
  });
}
