import 'package:dinnerhome/exceptions/app_exception.dart';

class MenuException extends AppException {
  MenuException(String message, {String code = 'MENU_ERROR'})
    : super(message, code);
}

class MenuItemNotFoundException extends MenuException {
  MenuItemNotFoundException(String id)
    : super('MenuItem not found: $id', code: 'MENU_ITEM_NOT_FOUND');
}
