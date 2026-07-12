import 'dart:async';
import 'package:dinnerhome/exceptions/order_exception.dart';
import 'package:dinnerhome/models/order.dart';
import 'package:dinnerhome/models/order_item.dart' show OrderItem;
import 'package:dinnerhome/models/order_item.dart' as oi;
import 'package:dinnerhome/services/audit_service.dart';
import 'package:dinnerhome/services/order_service.dart';
import 'package:dinnerhome/services/socket_service.dart';
import 'package:dinnerhome/services/menu_service.dart';

class InMemoryOrderService implements OrderService {
  final SocketService socketService;
  final MenuService? menuService;
  final AuditService? auditService;
  final Map<String, Order> _orders = {};
  int _orderCounter = 0;
  final _orderEventsController = StreamController<OrderEvent>.broadcast();

  InMemoryOrderService(this.socketService, {this.menuService, this.auditService});

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
  Future<Order> updateTable({required String orderId, required String tableId}) async {
    final order = _orders[orderId];
    if (order == null) {
      throw OrderNotFoundException(orderId);
    }
    final updatedOrder = order.copyWith(tableId: tableId);
    _orders[orderId] = updatedOrder;
    _emitEvent(updatedOrder, 'updated');
    auditService?.record(
      action: 'order.table_updated',
      userId: order.waiterId,
      metadata: {'orderId': orderId, 'tableId': tableId},
    );
    return updatedOrder;
  }

  @override
  Future<Order> addItem({required String orderId, required OrderItem item}) async {
    final order = _orders[orderId];
    if (order == null) {
      throw OrderNotFoundException(orderId);
    }

    if (order.status == OrderStatus.ready ||
        order.status == OrderStatus.billed ||
        order.status == OrderStatus.closed) {
      throw OrderLockedException(order.status.name);
    }

    // Decrementar stock si menuService está presente
    await menuService?.adjustStock(item.menuItemId, item.variationId, -item.quantity);

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

    final oldItem = order.items.firstWhere((i) => i.id == item.id, orElse: () => throw Exception('Item no encontrado en el pedido'));
    final diff = item.quantity - oldItem.quantity;

    // Ajustar stock si menuService está presente
    await menuService?.adjustStock(item.menuItemId, item.variationId, -diff);

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

    final item = order.items.firstWhere((i) => i.id == itemId, orElse: () => throw Exception('Item no encontrado en el pedido'));

    // Incrementar stock al remover si menuService está presente
    await menuService?.adjustStock(item.menuItemId, item.variationId, item.quantity);

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
      status: order.status == OrderStatus.prepping ? OrderStatus.prepping : OrderStatus.sentToKitchen,
      sentToKitchenAt: order.sentToKitchenAt ?? DateTime.now(),
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
      OrderStatus.draft: {OrderStatus.sentToKitchen, OrderStatus.closed},
      OrderStatus.sentToKitchen: {OrderStatus.prepping, OrderStatus.closed},
      OrderStatus.prepping: {OrderStatus.ready, OrderStatus.closed},
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
  Future<Order> updateItemStatus({
    required String orderId,
    required String itemId,
    required oi.OrderStatus status,
    required String byUserId,
  }) async {
    final order = _orders[orderId];
    if (order == null) {
      throw OrderNotFoundException(orderId);
    }

    final itemIndex = order.items.indexWhere((i) => i.id == itemId);
    if (itemIndex == -1) {
      throw OrderNotFoundException('Item $itemId not found in order $orderId'); // Could use ItemNotFound
    }

    // Actualizar el item
    final updatedItem = order.items[itemIndex].copyWith(status: status);
    final updatedItems = List<oi.OrderItem>.from(order.items);
    updatedItems[itemIndex] = updatedItem;

    var updatedOrder = order.copyWith(items: updatedItems);

    // Auto-promote: if all items ready, promote order to ready
    // Works from both sentToKitchen and prepping states
    if (status == oi.OrderStatus.ready &&
        (order.status == OrderStatus.prepping ||
         order.status == OrderStatus.sentToKitchen)) {
      final allReady = updatedItems.every(
        (item) => item.status == oi.OrderStatus.ready || item.status == oi.OrderStatus.served,
      );
      if (allReady) {
        updatedOrder = updatedOrder.copyWith(
          status: OrderStatus.ready,
          readyAt: DateTime.now(),
        );
        auditService?.record(
          action: 'order.status_updated',
          userId: byUserId,
          metadata: {
            'orderId': orderId,
            'fromStatus': order.status.name,
            'toStatus': OrderStatus.ready.name,
          },
        );
      }
    }

    _orders[orderId] = updatedOrder;
    _emitEvent(updatedOrder, 'item_status_updated');
    auditService?.record(
      action: 'order.item_status_updated',
      userId: byUserId,
      metadata: {
        'orderId': orderId,
        'itemId': itemId,
        'newStatus': status.name,
      },
    );
    return updatedOrder;
  }

  @override
  Future<Order?> getOrder(String orderId) async {
    return _orders[orderId];
  }

  @override
  Future<List<Order>> getActiveOrders() async {
    return _orders.values.where((o) => 
      o.status != OrderStatus.closed && o.status != OrderStatus.draft
    ).toList();
  }

  @override
  Future<List<Order>> getAllOrders() async {
    return _orders.values.toList();
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
