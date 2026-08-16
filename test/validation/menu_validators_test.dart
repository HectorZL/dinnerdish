import 'package:dinnerhome/exceptions/validation_exception.dart';
import 'package:dinnerhome/validation/menu_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MenuValidators', () {
    test('acepta cero como stock y precio', () {
      expect(MenuValidators.validateStock('0'), isNull);
      expect(MenuValidators.parseStock('0'), 0);
      expect(MenuValidators.validatePrice('0'), isNull);
      expect(MenuValidators.parsePriceCents('0'), 0);
    });

    test('acepta precios con coma o punto y los convierte a céntimos', () {
      expect(MenuValidators.parsePriceCents('12,50'), 1250);
      expect(MenuValidators.parsePriceCents('12.5'), 1250);
    });

    test('rechaza nombre vacío, stock no entero y precio inválido', () {
      expect(MenuValidators.validateName('   '), isNotNull);
      expect(MenuValidators.validateStock('1.5'), isNotNull);
      expect(MenuValidators.validateStock('-1'), isNotNull);
      expect(MenuValidators.validateStock('texto'), isNotNull);
      expect(MenuValidators.validatePrice('-1'), isNotNull);
      expect(MenuValidators.validatePrice('texto'), isNotNull);
    });

    test('normaliza nombre y detecta duplicados sin distinguir mayúsculas', () {
      expect(MenuValidators.ensureName('  Extra queso  '), 'Extra queso');
      expect(
        MenuValidators.validateUniqueName(' extra QUESO ', ['Extra queso']),
        'Ya existe un adicional con ese nombre.',
      );
      expect(
        MenuValidators.validateUniqueName(' extra queso ', [
          'Extra queso',
        ], excludedName: 'Extra queso'),
        isNull,
      );
    });

    test('servicios reciben excepciones tipadas y mensajes reutilizables', () {
      expect(
        () => MenuValidators.ensureStock('-1'),
        throwsA(
          isA<InvalidStockException>().having(
            (exception) => exception.errorText,
            'errorText',
            contains('entero mayor o igual a cero'),
          ),
        ),
      );
      expect(
        () => MenuValidators.ensurePrice('-1'),
        throwsA(isA<InvalidPriceException>()),
      );
      expect(
        () => MenuValidators.ensureUniqueName('Queso', [' queso ']),
        throwsA(isA<DuplicateAdditionalException>()),
      );
    });
  });
}
