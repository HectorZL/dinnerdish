import 'package:dinnerhome/models/order.dart';
import 'package:dinnerhome/models/order_item.dart' hide OrderStatus;
import 'package:dinnerhome/models/order_item.dart' as oi;
import 'package:dinnerhome/services/order_service.dart';
import 'package:dinnerhome/services/socket_service.dart';
import 'api_client.dart';

class HttpOrderService implements OrderService {
  final ApiClient _client;
  final SocketService _socketService;

  HttpOrderService(
    this._socketService, {
    ApiClient? client,
  }) : _client = client ?? ApiClient();

  @override
  Future<Order> createDraft({required String waiterId, String? tableId}) async {
    final res = await _client.post('/api/orders/draft', body: {
      'waiterId': waiterId,
      'tableId': tableId,
    });
    final order = Order.fromJson(res as Map<String, dynamic>);
    _socketService.emitOrderEvent(OrderEvent(
      orderId: order.id,
      eventType: 'order_created',
      order: order,
    ));
    return order;
  }

  @override
  Future<Order> updateTable({
    required String orderId,
    required String tableId,
  }) async {
    final res = await _client.put('/api/orders/$orderId/table', body: {
      'tableId': tableId,
    });
    final order = Order.fromJson(res as Map<String, dynamic>);
    _socketService.emitOrderEvent(OrderEvent(
      orderId: order.id,
      eventType: 'order_updated',
      order: order,
    ));
    return order;
  }

  @override
  Future<Order> addItem({
    required String orderId,
    required OrderItem item,
  }) async {
    final res = await _client.post('/api/orders/$orderId/items', body: {
      'item': item.toJson(),
    });
    final order = Order.fromJson(res as Map<String, dynamic>);
    _socketService.emitOrderEvent(OrderEvent(
      orderId: order.id,
      eventType: 'order_updated',
      order: order,
    ));
    return order;
  }

  @override
  Future<Order> addCashierAdditional({
    required String orderId,
    required String additionalId,
    required int quantity,
    required String byUserId,
  }) async {
    final res = await _client.post('/api/orders/$orderId/cashier-additional', body: {
      'additionalId': additionalId,
      'quantity': quantity,
      'byUserId': byUserId,
    });
    final order = Order.fromJson(res as Map<String, dynamic>);
    _socketService.emitOrderEvent(OrderEvent(
      orderId: order.id,
      eventType: 'order_updated',
      order: order,
    ));
    return order;
  }

  @override
  Future<Order> updateItem({
    required String orderId,
    required OrderItem item,
    required String byUserId,
  }) async {
    final res = await _client.put('/api/orders/$orderId/items', body: {
      'item': item.toJson(),
      'byUserId': byUserId,
    });
    final order = Order.fromJson(res as Map<String, dynamic>);
    _socketService.emitOrderEvent(OrderEvent(
      orderId: order.id,
      eventType: 'order_updated',
      order: order,
    ));
    return order;
  }

  @override
  Future<Order> removeItem({
    required String orderId,
    required String itemId,
    required String byUserId,
  }) async {
    final res = await _client.delete(
      '/api/orders/$orderId/items/$itemId',
      queryParams: {'byUserId': byUserId},
    );
    final order = Order.fromJson(res as Map<String, dynamic>);
    _socketService.emitOrderEvent(OrderEvent(
      orderId: order.id,
      eventType: 'order_updated',
      order: order,
    ));
    return order;
  }

  @override
  Future<Order> sendToKitchen({
    required String orderId,
    required String byUserId,
  }) async {
    final res = await _client.post('/api/orders/$orderId/send-to-kitchen');
    final order = Order.fromJson(res as Map<String, dynamic>);
    _socketService.emitOrderEvent(OrderEvent(
      orderId: order.id,
      eventType: 'order_sent_to_kitchen',
      order: order,
    ));
    return order;
  }

  @override
  Future<Order> updateStatus({
    required String orderId,
    required OrderStatus status,
    required String byUserId,
  }) async {
    final res = await _client.put('/api/orders/$orderId/status', body: {
      'status': status.name,
      'byUserId': byUserId,
    });
    final order = Order.fromJson(res as Map<String, dynamic>);
    _socketService.emitOrderEvent(OrderEvent(
      orderId: order.id,
      eventType: 'order_updated',
      order: order,
    ));
    return order;
  }

  @override
  Future<Order> updateItemStatus({
    required String orderId,
    required String itemId,
    required oi.OrderStatus status,
    required String byUserId,
  }) async {
    final res = await _client.put(
      '/api/orders/$orderId/items/$itemId/status',
      body: {
        'status': status.name,
        'byUserId': byUserId,
      },
    );
    final order = Order.fromJson(res as Map<String, dynamic>);
    _socketService.emitOrderEvent(OrderEvent(
      orderId: order.id,
      eventType: 'order_item_status_updated',
      order: order,
    ));
    return order;
  }

  @override
  Future<Order?> getOrder(String orderId) async {
    try {
      final res = await _client.get('/api/orders/$orderId');
      return Order.fromJson(res as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Order>> getActiveOrders() async {
    final res = await _client.get('/api/orders/active');
    return (res as List)
        .map((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Order>> getAllOrders() async {
    final res = await _client.get('/api/orders');
    return (res as List)
        .map((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Stream<OrderEvent> watchOrders() => _socketService.orderEvents;
}
