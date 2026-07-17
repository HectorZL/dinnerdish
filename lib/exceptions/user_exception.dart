import 'package:dinnerhome/exceptions/app_exception.dart';

class UserException extends AppException {
  UserException(String message, {String code = 'USER_ERROR'})
      : super(message, code);
}

class UserNotFoundException extends UserException {
  UserNotFoundException(String id)
      : super('User not found: $id', code: 'USER_NOT_FOUND');
}
