import 'package:dinnerhome/exceptions/validation_exception.dart';

/// A UI-safe validation error shared by forms and application services.
class ValidationError {
  final String code;
  final String message;

  const ValidationError(this.code, this.message);

  String get errorText => message;
  String get snackBarText => message;

  @override
  String toString() => '[$code] $message';
}

/// Result type for callers that need both a parsed value and an error.
class ValidationResult<T> {
  final T? value;
  final ValidationError? error;

  const ValidationResult.valid(this.value) : error = null;
  const ValidationResult.invalid(this.error) : value = null;

  bool get isValid => error == null;
  String? get errorText => error?.message;
}

/// Shared menu input rules.
///
/// The `...Error` methods are suitable for Flutter `FormField.validator`.
/// The `ensure...` and `parse...` methods expose the same rules to services
/// and throw typed domain exceptions instead of relying on assertions.
abstract final class MenuValidators {
  static const String invalidNameMessage = 'El nombre es obligatorio.';
  static const String invalidStockMessage =
      'Stock inicial inválido. Ingresa un número entero mayor o igual a cero.';
  static const String invalidPriceMessage =
      'Precio inválido. Ingresa un número mayor o igual a cero.';
  static const String duplicateAdditionalMessage =
      'Ya existe un adicional con ese nombre.';

  static String normalizeName(String? value) => value?.trim() ?? '';

  static ValidationError? nameError(Object? value) {
    if (value is! String || normalizeName(value).isEmpty) {
      return const ValidationError('INVALID_NAME', invalidNameMessage);
    }
    return null;
  }

  static ValidationError? stockError(Object? value) {
    if (value is int) {
      return value < 0
          ? const ValidationError('INVALID_STOCK', invalidStockMessage)
          : null;
    }
    if (value is! String) {
      return const ValidationError('INVALID_STOCK', invalidStockMessage);
    }

    final input = value.trim();
    if (!RegExp(r'^\d+$').hasMatch(input)) {
      return const ValidationError('INVALID_STOCK', invalidStockMessage);
    }
    return null;
  }

  static ValidationError? priceError(Object? value) {
    if (value is int) {
      return value < 0
          ? const ValidationError('INVALID_PRICE', invalidPriceMessage)
          : null;
    }
    if (value is double || value is num) {
      final number = value as num;
      return !number.isFinite || number < 0
          ? const ValidationError('INVALID_PRICE', invalidPriceMessage)
          : null;
    }
    if (value is! String) {
      return const ValidationError('INVALID_PRICE', invalidPriceMessage);
    }

    final input = value.trim();
    if (!RegExp(r'^\d+(?:[.,]\d{1,2})?$').hasMatch(input)) {
      return const ValidationError('INVALID_PRICE', invalidPriceMessage);
    }
    return null;
  }

  /// Returns a duplicate error when [candidate] matches an existing name
  /// after trimming and case folding. [excludedName] is useful when editing.
  static ValidationError? uniqueNameError(
    String? candidate,
    Iterable<String> existingNames, {
    String? excludedName,
  }) {
    final nameErrorResult = nameError(candidate);
    if (nameErrorResult != null) return nameErrorResult;

    final normalizedCandidate = normalizeName(candidate).toLowerCase();
    final normalizedExcluded = normalizeName(excludedName).toLowerCase();
    final duplicate = existingNames.any((existing) {
      final normalized = normalizeName(existing).toLowerCase();
      return normalized == normalizedCandidate &&
          normalized != normalizedExcluded;
    });
    return duplicate
        ? const ValidationError(
            'DUPLICATE_ADDITIONAL',
            duplicateAdditionalMessage,
          )
        : null;
  }

  // Aliases with names convenient for Flutter validators and service code.
  static String? validateName(Object? value) => nameError(value)?.message;
  static String? validateStock(Object? value) => stockError(value)?.message;
  static String? validatePrice(Object? value) => priceError(value)?.message;
  static String? validateUniqueName(
    String? candidate,
    Iterable<String> existingNames, {
    String? excludedName,
  }) => uniqueNameError(
    candidate,
    existingNames,
    excludedName: excludedName,
  )?.message;

  static String ensureName(Object? value) {
    final error = nameError(value);
    if (error != null) throw InvalidNameException();
    return normalizeName(value as String);
  }

  static int parseStock(Object? value) {
    final error = stockError(value);
    if (error != null) throw InvalidStockException(value);
    if (value is int) return value;
    return int.parse((value as String).trim());
  }

  static int ensureStock(Object? value) => parseStock(value);

  /// Parses a non-negative price expressed with either decimal separator into
  /// integer cents. Inputs with more than two decimal places are rejected.
  static int parsePriceCents(Object? value) {
    final error = priceError(value);
    if (error != null) throw InvalidPriceException(value);
    if (value is int) return value;
    if (value is num) return (value * 100).round();

    final normalized = (value as String).trim().replaceFirst(',', '.');
    final parts = normalized.split('.');
    final whole = int.parse(parts[0]);
    final decimals = parts.length == 1 ? '' : parts[1].padRight(2, '0');
    return whole * 100 + (decimals.isEmpty ? 0 : int.parse(decimals));
  }

  static int ensurePrice(Object? value) => parsePriceCents(value);

  static String ensureUniqueName(
    String? candidate,
    Iterable<String> existingNames, {
    String? excludedName,
  }) {
    final error = uniqueNameError(
      candidate,
      existingNames,
      excludedName: excludedName,
    );
    if (error?.code == 'INVALID_NAME') throw InvalidNameException();
    if (error != null) throw DuplicateAdditionalException(candidate);
    return normalizeName(candidate);
  }

  static ValidationResult<String> nameResult(Object? value) {
    final error = nameError(value);
    return error == null
        ? ValidationResult.valid(normalizeName(value as String))
        : ValidationResult.invalid(error);
  }

  static ValidationResult<int> stockResult(Object? value) {
    final error = stockError(value);
    return error == null
        ? ValidationResult.valid(
            value is int ? value : int.parse((value as String).trim()),
          )
        : ValidationResult.invalid(error);
  }

  static ValidationResult<int> priceResult(Object? value) {
    final error = priceError(value);
    return error == null
        ? ValidationResult.valid(parsePriceCents(value))
        : ValidationResult.invalid(error);
  }
}

/// Short alias for callers that use the generic validation terminology.
abstract final class InputValidators {
  static String normalizeName(String? value) =>
      MenuValidators.normalizeName(value);
  static String? validateName(Object? value) =>
      MenuValidators.validateName(value);
  static String? validateStock(Object? value) =>
      MenuValidators.validateStock(value);
  static String? validatePrice(Object? value) =>
      MenuValidators.validatePrice(value);
  static String? validateUniqueName(
    String? candidate,
    Iterable<String> existingNames, {
    String? excludedName,
  }) => MenuValidators.validateUniqueName(
    candidate,
    existingNames,
    excludedName: excludedName,
  );
}

String? validateName(Object? value) => MenuValidators.validateName(value);
String? validateStock(Object? value) => MenuValidators.validateStock(value);
String? validatePrice(Object? value) => MenuValidators.validatePrice(value);
