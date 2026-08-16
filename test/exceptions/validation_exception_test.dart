import 'package:dinnerhome/exceptions/app_exception.dart';
import 'package:dinnerhome/exceptions/validation_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'las excepciones de validación conservan tipo, código y mensaje en español',
    () {
      final exceptions = <AppException>[
        InvalidNameException(),
        const InvalidStockException(),
        const InvalidPriceException(),
        DuplicateAdditionalException('Queso'),
        InvalidAssignmentException('El Plato es obligatorio.'),
        AdditionalNotFoundException('additional-1'),
      ];

      final expectedCodes = <String>[
        'INVALID_NAME',
        'INVALID_STOCK',
        'INVALID_PRICE',
        'DUPLICATE_ADDITIONAL',
        'INVALID_ASSIGNMENT',
        'ADDITIONAL_NOT_FOUND',
      ];

      for (var index = 0; index < exceptions.length; index++) {
        final exception = exceptions[index];
        expect(exception, isA<ValidationException>());
        expect(exception.code, expectedCodes[index]);
        expect(exception.message, isNotEmpty);
        expect(exception.errorText, exception.message);
        expect(exception.snackBarText, exception.message);
        expect(exception.toString(), startsWith('[${expectedCodes[index]}] '));
        expect(exception.message, isNot(contains('Invalid')));
        expect(exception.message, isNot(contains('must')));
      }
    },
  );

  test('los mensajes específicos permanecen estables', () {
    expect(InvalidNameException().message, 'El nombre es obligatorio.');
    expect(
      const InvalidStockException().message,
      'Stock inicial inválido. Ingresa un número entero mayor o igual a cero.',
    );
    expect(
      const InvalidPriceException().message,
      'Precio inválido. Ingresa un número mayor o igual a cero.',
    );
    expect(
      DuplicateAdditionalException().message,
      'Ya existe un adicional con ese nombre.',
    );
    expect(
      InvalidAssignmentException().message,
      'La asignación de adicional no es válida.',
    );
    expect(AdditionalNotFoundException().message, 'El adicional no existe.');
  });
}
