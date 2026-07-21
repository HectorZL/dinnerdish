import 'package:dinnerhome/exceptions/app_exception.dart';

class UserException extends AppException {
  UserException(String message, {String code = 'USER_ERROR'})
    : super(message, code);
}

class UserNotFoundException extends UserException {
  UserNotFoundException(String id)
    : super('Usuario no encontrado: $id', code: 'USER_NOT_FOUND');
}

class DuplicateUsernameException extends UserException {
  DuplicateUsernameException(String username)
    : super(
        'El usuario "$username" ya está registrado.',
        code: 'USERNAME_TAKEN',
      );
}

class DuplicateEmailException extends UserException {
  DuplicateEmailException(String email)
    : super('El correo "$email" ya está registrado.', code: 'EMAIL_TAKEN');
}

class InvalidUsernameException extends UserException {
  InvalidUsernameException()
    : super(
        'El usuario debe tener entre 3 y 32 caracteres: letras, números, punto, guion o guion bajo.',
        code: 'INVALID_USERNAME',
      );
}

class InvalidEmailException extends UserException {
  InvalidEmailException()
    : super('El correo electrónico no es válido.', code: 'INVALID_EMAIL');
}

class WeakPasswordException extends UserException {
  WeakPasswordException()
    : super(
        'La contraseña debe tener al menos 8 caracteres e incluir mayúscula, minúscula y número.',
        code: 'WEAK_PASSWORD',
      );
}

class LastActiveAdminException extends UserException {
  LastActiveAdminException()
    : super(
        'Debe mantenerse al menos un administrador activo.',
        code: 'LAST_ACTIVE_ADMIN',
      );
}
