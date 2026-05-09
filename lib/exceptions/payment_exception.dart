import 'package:dinnerhome/exceptions/app_exception.dart';

class PaymentException extends AppException {
  const PaymentException(String message, {String code = 'PAYMENT_ERROR'})
    : super(message, code);
}

class PaymentNotFoundException extends PaymentException {
  PaymentNotFoundException(String id)
    : super('Payment not found: $id', code: 'PAYMENT_NOT_FOUND');
}

class PaymentAlreadyRefundedException extends PaymentException {
  PaymentAlreadyRefundedException(String id)
    : super('Payment already refunded: $id', code: 'PAYMENT_ALREADY_REFUNDED');
}
