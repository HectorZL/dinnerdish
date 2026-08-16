import 'package:dinnerhome/exceptions/app_exception.dart';

class MenuException extends AppException {
  MenuException(String message, {String code = 'MENU_ERROR'})
    : super(message, code);
}

class MenuItemNotFoundException extends MenuException {
  MenuItemNotFoundException(String id)
    : super('El plato no existe: $id.', code: 'MENU_ITEM_NOT_FOUND');
}

class MenuItemVariationNotFoundException extends MenuException {
  MenuItemVariationNotFoundException(String itemId, String variationId)
    : super(
        'La variación no existe: $variationId para el plato $itemId.',
        code: 'MENU_VARIATION_NOT_FOUND',
      );
}

class StockAdjustmentNegativeException extends MenuException {
  StockAdjustmentNegativeException()
    : super(
        'El ajuste dejaría el stock en un valor negativo.',
        code: 'STOCK_ADJUSTMENT_NEGATIVE',
      );
}
