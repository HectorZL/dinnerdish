import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Hashes local/demo passwords. A production backend must still own password
/// storage and authentication, but this prevents plaintext credentials from
/// being kept by the local user service.
class PasswordHasher {
  PasswordHasher._();

  static final Random _random = Random.secure();

  static String hash(String password) {
    final saltBytes = List<int>.generate(16, (_) => _random.nextInt(256));
    final salt = base64UrlEncode(saltBytes);
    final digest = sha256.convert(utf8.encode('$salt:$password')).toString();
    return '$salt:$digest';
  }

  static bool isHash(String? value) {
    if (value == null) return false;
    final parts = value.split(':');
    return parts.length == 2 && parts[0].isNotEmpty && parts[1].length == 64;
  }

  static bool verify(String password, String? storedValue) {
    if (storedValue == null || storedValue.isEmpty) return false;
    if (!isHash(storedValue)) return _constantTimeEquals(password, storedValue);

    final parts = storedValue.split(':');
    final candidate = sha256
        .convert(utf8.encode('${parts[0]}:$password'))
        .toString();
    return _constantTimeEquals(candidate, parts[1]);
  }

  /// Contraseña inicial asignada por el alta administrativa de personal.
  ///
  /// Debe comunicarse de forma segura al empleado y cambiarse en cuanto se
  /// incorpore una política de cambio obligatorio de contraseña.
  static const initialStaffPassword = '123456789';

  static bool isStrong(String password) {
    return password.length >= 8 &&
        RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'\d').hasMatch(password);
  }

  static bool isAllowedForNewStaffAccount(String password) {
    return password == initialStaffPassword || isStrong(password);
  }

  static bool _constantTimeEquals(String left, String right) {
    if (left.length != right.length) return false;
    var difference = 0;
    for (var index = 0; index < left.length; index++) {
      difference |= left.codeUnitAt(index) ^ right.codeUnitAt(index);
    }
    return difference == 0;
  }
}
