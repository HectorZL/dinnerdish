import 'package:dinnerhome/validation/menu_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MenuValidators: nombres', () {
    test('normaliza espacios y conserva el nombre significativo', () {
      expect(MenuValidators.normalizeName('  Extra queso  '), 'Extra queso');
      expect(MenuValidators.ensureName('\t Salsa picante\n'), 'Salsa picante');
      expect(
        MenuValidators.nameResult('  Plato del día ').value,
        'Plato del día',
      );
    });

    test('rechaza vacío, espacios, null y tipos que no son texto', () {
      for (final value in <Object?>['', '   ', '\t\n', null, 12]) {
        final error = MenuValidators.nameError(value);
        expect(error, isNotNull, reason: 'Valor inválido: $value');
        expect(error!.code, 'INVALID_NAME');
        expect(error.message, 'El nombre es obligatorio.');
      }
    });
  });

  group('MenuValidators: stock', () {
    test('acepta cero, enteros y texto entero con espacios', () {
      expect(MenuValidators.stockError(0), isNull);
      expect(MenuValidators.stockError('0'), isNull);
      expect(MenuValidators.stockError(' 42 '), isNull);
      expect(MenuValidators.parseStock(' 42 '), 42);
      expect(MenuValidators.stockResult(0).value, 0);
    });

    test('rechaza vacío, decimal, negativo, texto, null y tipos no enteros', () {
      for (final value in <Object?>[
        '',
        '   ',
        '1.5',
        '1,5',
        '-1',
        'texto',
        null,
        1.5,
      ]) {
        final error = MenuValidators.stockError(value);
        expect(error, isNotNull, reason: 'Valor inválido: $value');
        expect(error!.code, 'INVALID_STOCK');
        expect(
          error.message,
          'Stock inicial inválido. Ingresa un número entero mayor o igual a cero.',
        );
      }
    });
  });

  group('MenuValidators: precio', () {
    test('acepta cero y normaliza coma o punto a céntimos', () {
      expect(MenuValidators.priceError(0), isNull);
      expect(MenuValidators.parsePriceCents('0'), 0);
      expect(MenuValidators.parsePriceCents('12,50'), 1250);
      expect(MenuValidators.parsePriceCents('12.5'), 1250);
      expect(MenuValidators.parsePriceCents(' 3,2 '), 320);
      expect(MenuValidators.parsePriceCents(4.25), 425);
      expect(MenuValidators.priceResult('9.99').value, 999);
    });

    test('rechaza vacío, negativo, texto y más de dos decimales', () {
      for (final value in <Object?>[
        '',
        '   ',
        '-1',
        '-0,01',
        'texto',
        '1.234',
        null,
      ]) {
        final error = MenuValidators.priceError(value);
        expect(error, isNotNull, reason: 'Valor inválido: $value');
        expect(error!.code, 'INVALID_PRICE');
        expect(
          error.message,
          'Precio inválido. Ingresa un número mayor o igual a cero.',
        );
      }
    });
  });

  group('MenuValidators: nombres únicos', () {
    test('compara sin distinguir mayúsculas ni espacios extremos', () {
      expect(MenuValidators.uniqueNameError(' salsa ', ['Salsa']), isNotNull);
      expect(
        MenuValidators.validateUniqueName(' salsa ', ['Salsa']),
        'Ya existe un adicional con ese nombre.',
      );
      expect(
        MenuValidators.validateUniqueName(' salsa ', [
          'Salsa',
        ], excludedName: 'Salsa'),
        isNull,
      );
      expect(
        MenuValidators.ensureUniqueName('  Nueva salsa  ', ['Salsa']),
        'Nueva salsa',
      );
    });
  });

  test('los resultados válidos e inválidos exponen una forma estable', () {
    final valid = MenuValidators.priceResult('1,25');
    final invalid = MenuValidators.stockResult('1.2');

    expect(valid.isValid, isTrue);
    expect(valid.value, 125);
    expect(valid.error, isNull);
    expect(invalid.isValid, isFalse);
    expect(invalid.value, isNull);
    expect(invalid.error!.code, 'INVALID_STOCK');
    expect(invalid.errorText, contains('Stock inicial inválido'));
    expect(invalid.errorText, isNot(contains('Invalid')));
  });
}
