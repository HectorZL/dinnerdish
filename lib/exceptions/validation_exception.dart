import 'package:dinnerhome/exceptions/app_exception.dart';

/// Base class for input and domain validation failures.
///
/// The message is intentionally user-facing in Spanish so the same exception
/// can be rendered by a form field, a SnackBar, or a service boundary.
abstract class ValidationException extends AppException {
  const ValidationException(super.message, super.code);
}

class InvalidNameException extends ValidationException {
  InvalidNameException({String field = 'nombre'})
    : super('El $field es obligatorio.', 'INVALID_NAME');
}

class InvalidStockException extends ValidationException {
  const InvalidStockException([Object? value])
    : super(
        'Stock inicial inválido. Ingresa un número entero mayor o igual a cero.',
        'INVALID_STOCK',
      );
}

class InvalidPriceException extends ValidationException {
  const InvalidPriceException([Object? value])
    : super(
        'Precio inválido. Ingresa un número mayor o igual a cero.',
        'INVALID_PRICE',
      );
}

class DuplicateAdditionalException extends ValidationException {
  DuplicateAdditionalException([String? name])
    : super('Ya existe un adicional con ese nombre.', 'DUPLICATE_ADDITIONAL');
}

class InvalidAssignmentException extends ValidationException {
  InvalidAssignmentException([String? detail])
    : super(
        detail == null || detail.trim().isEmpty
            ? 'La asignación de adicional no es válida.'
            : detail,
        'INVALID_ASSIGNMENT',
      );
}

class AdditionalNotFoundException extends ValidationException {
  AdditionalNotFoundException([String? additionalId])
    : super(
        additionalId == null || additionalId.trim().isEmpty
            ? 'El adicional no existe.'
            : 'El adicional no existe: $additionalId.',
        'ADDITIONAL_NOT_FOUND',
      );
}

/// More specific alias for callers operating on the reusable global catalog.
/// It preserves the generic [AdditionalNotFoundException] contract for older
/// callers while making the domain intent explicit at service boundaries.
class GlobalAdditionalNotFoundException extends AdditionalNotFoundException {
  GlobalAdditionalNotFoundException([super.additionalId]);
}
