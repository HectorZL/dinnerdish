import 'package:dinnerhome/exceptions/app_exception.dart';

class OrderException extends AppException {
  const OrderException(String message, {String code = 'ORDER_ERROR'})
    : super(message, code);
}

class OrderNotFoundException extends OrderException {
  OrderNotFoundException(String orderId)
    : super('Order not found: $orderId', code: 'ORDER_NOT_FOUND');
}

class EmptyOrderException extends OrderException {
  const EmptyOrderException()
    : super('Cannot send an empty order to the kitchen', code: 'ORDER_EMPTY');
}

class InvalidStateTransitionException extends OrderException {
  InvalidStateTransitionException(String from, String to)
    : super(
        'Cannot transition from $from to $to',
        code: 'ORDER_INVALID_TRANSITION',
      );
}

class OrderLockedException extends OrderException {
  OrderLockedException(String status)
    : super('Cannot modify order in state: $status', code: 'ORDER_LOCKED');
}
