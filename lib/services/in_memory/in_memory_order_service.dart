import 'dart:async';
import 'package:dinnerhome/exceptions/order_exception.dart';
import 'package:dinnerhome/models/order.dart';
import 'package:dinnerhome/models/order_item.dart' show OrderItem;
import 'package:dinnerhome/services/audit_service.dart';
import 'package:dinnerhome/services/order_service.dart';
import 'package:dinnerhome/services/socket_service.dart';

class InMemoryOrderService implements OrderService {
  final SocketService socketService;
  final AuditService? auditService;
  final Map<String, Order> _orders = {};
  int _orderCounter = 0;
  final _orderEventsController = StreamController<OrderEvent>.broadcast();

  InMemoryOrderService(this.socketService, {this.auditService});

  @override
  Future<Order> createDraft({required String waiterId, String? tableId}) async {
    _orderCounter++;
    final orderId = 'order-$_orderCounter';
    final order = Order(
      id: orderId,
      tableId: tableId ?? '',
      waiterId: waiterId,
      items: [],
      status: OrderStatus.draft,
      subtotalCents: 0,
      taxCents: 0,
      totalCents: 0,
      createdAt: DateTime.now(),
    );
    _orders[orderId] = order;
    _emitEvent(order, 'created');
    auditService?.record(
      action: 'order.created',
      userId: waiterId,
      metadata: {'orderId': orderId},
    );
    return order;
  }

  @override
  Future<Order> addItem({required String orderId, required OrderItem item}) async {
    final order = _orders[orderId];
    if (order == null) {
      throw OrderNotFoundException(orderId);
    }

    if (order.status == OrderStatus.prepping ||
        order.status == OrderStatus.ready ||
        order.status == OrderStatus.billed ||
        order.status == OrderStatus.closed) {
      throw OrderLockedException(order.status.name);
    }

    final updatedItems = [...order.items, item];
    final updatedOrder = _recalculateOrder(order.copyWith(items: updatedItems));
    _orders[orderId] = updatedOrder;
    _emitEvent(updatedOrder, 'item_added');
    auditService?.record(
      action: 'order.item_added',
      userId: order.waiterId,
      metadata: {'orderId': orderId, 'itemId': item.id},
    );
    return updatedOrder;
  }

  @override
  Future<Order> updateItem({
    required String orderId,
    required OrderItem item,
    required String byUserId,
  }) async {
    final order = _orders[orderId];
    if (order == null) {
      throw OrderNotFoundException(orderId);
    }

    final items = order.items.map((i) => i.id == item.id ? item : i).toList();
    final updatedOrder = _recalculateOrder(order.copyWith(items: items));
    _orders[orderId] = updatedOrder;
    _emitEvent(updatedOrder, 'item_updated');
    auditService?.record(
      action: 'order.item_updated',
      userId: byUserId,
      metadata: {'orderId': orderId, 'itemId': item.id},
    );
    return updatedOrder;
  }

  @override
  Future<Order> removeItem({
    required String orderId,
    required String itemId,
    required String byUserId,
  }) async {
    final order = _orders[orderId];
    if (order == null) {
      throw OrderNotFoundException(orderId);
    }

    final updatedItems = order.items.where((i) => i.id != itemId).toList();
    final updatedOrder = _recalculateOrder(order.copyWith(items: updatedItems));
    _orders[orderId] = updatedOrder;
    _emitEvent(updatedOrder, 'item_removed');
    auditService?.record(
      action: 'order.item_removed',
      userId: byUserId,
      metadata: {'orderId': orderId, 'itemId': itemId},
    );
    return updatedOrder;
  }

  @override
  Future<Order> sendToKitchen({required String orderId, required String byUserId}) async {
    final order = _orders[orderId];
    if (order == null) {
      throw OrderNotFoundException(orderId);
    }

    if (order.items.isEmpty) {
      throw const EmptyOrderException();
    }

    final updatedOrder = order.copyWith(
      status: OrderStatus.sentToKitchen,
      sentToKitchenAt: DateTime.now(),
    );
    _orders[orderId] = updatedOrder;
    _emitEvent(updatedOrder, 'sent_to_kitchen');
    auditService?.record(
      action: 'order.sent_to_kitchen',
      userId: byUserId,
      metadata: {'orderId': orderId},
    );
    return updatedOrder;
  }

  @override
  Future<Order> updateStatus({
    required String orderId,
    required OrderStatus status,
    required String byUserId,
  }) async {
    final order = _orders[orderId];
    if (order == null) {
      throw OrderNotFoundException(orderId);
    }

    const validTransitions = <OrderStatus, Set<OrderStatus>>{
      OrderStatus.sentToKitchen: {OrderStatus.prepping},
      OrderStatus.prepping: {OrderStatus.ready},
      OrderStatus.ready: {OrderStatus.billed},
      OrderStatus.billed: {OrderStatus.closed},
    };

    final allowed = validTransitions[order.status];
    if (allowed == null || !allowed.contains(status)) {
      throw InvalidStateTransitionException(order.status.name, status.name);
    }

    final updatedOrder = order.copyWith(
      status: status,
      readyAt: status == OrderStatus.ready ? DateTime.now() : order.readyAt,
    );
    _orders[orderId] = updatedOrder;
    _emitEvent(updatedOrder, 'status_updated');
    auditService?.record(
      action: 'order.status_updated',
      userId: byUserId,
      metadata: {
        'orderId': orderId,
        'fromStatus': order.status.name,
        'toStatus': status.name,
      },
    );
    return updatedOrder;
  }

  @override
  Future<Order?> getOrder(String orderId) async {
    return _orders[orderId];
  }

  @override
  Stream<OrderEvent> watchOrders() => _orderEventsController.stream;

  void _emitEvent(Order order, String eventType) {
    final event = OrderEvent(orderId: order.id, eventType: eventType, order: order);
    _orderEventsController.add(event);
    socketService.emitOrderEvent(event);
  }

  Order _recalculateOrder(Order order) {
    var subtotal = 0;
    for (final item in order.items) {
      subtotal += item.priceCents * item.quantity;
    }
    final tax = (subtotal * 0.10).toInt();
    return order.copyWith(
      subtotalCents: subtotal,
      taxCents: tax,
      totalCents: subtotal + tax,
    );
  }
}
