import 'package:dinnerhome/exceptions/app_exception.dart';

class AuthException extends AppException {
  const AuthException(String message, {String code = 'AUTH_ERROR'})
    : super(message, code);
}

class InvalidCredentialsException extends AuthException {
  const InvalidCredentialsException()
    : super('Invalid username or password', code: 'AUTH_INVALID_CREDENTIALS');
}
