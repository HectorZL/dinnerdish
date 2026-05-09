import 'package:dinnerhome/models/order.dart';
import 'package:dinnerhome/models/order_item.dart' hide OrderStatus;

class OrderEvent {
  final String orderId;
  final String eventType;
  final Order order;

  const OrderEvent({
    required this.orderId,
    required this.eventType,
    required this.order,
  });
}

abstract class OrderService {
  Future<Order> createDraft({required String waiterId, String? tableId});
  Future<Order> addItem({required String orderId, required OrderItem item});
  Future<Order> updateItem({
    required String orderId,
    required OrderItem item,
    required String byUserId,
  });
  Future<Order> removeItem({
    required String orderId,
    required String itemId,
    required String byUserId,
  });
  Future<Order> sendToKitchen({required String orderId, required String byUserId});
  Future<Order> updateStatus({
    required String orderId,
    required OrderStatus status,
    required String byUserId,
  });
  Future<Order?> getOrder(String orderId);
  Stream<OrderEvent> watchOrders();
}
