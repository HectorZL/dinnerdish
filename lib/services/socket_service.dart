import 'package:dinnerhome/services/order_service.dart';

abstract class SocketService {
  Stream<OrderEvent> get orderEvents;
  void emitOrderEvent(OrderEvent event);
  void dispose();
}
