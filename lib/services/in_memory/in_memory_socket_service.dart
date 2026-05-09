import 'dart:async';
import 'package:dinnerhome/services/order_service.dart';
import 'package:dinnerhome/services/socket_service.dart';

class InMemorySocketService implements SocketService {
  final _eventController = StreamController<OrderEvent>.broadcast();

  @override
  Stream<OrderEvent> get orderEvents => _eventController.stream;

  @override
  void emitOrderEvent(OrderEvent event) {
    _eventController.add(event);
  }

  @override
  void dispose() {
    _eventController.close();
  }
}
