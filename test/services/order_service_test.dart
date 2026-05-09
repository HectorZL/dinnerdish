import 'package:flutter_test/flutter_test.dart';
import 'package:dinnerhome/exceptions/order_exception.dart';
import 'package:dinnerhome/models/order.dart';
import 'package:dinnerhome/models/order_item.dart' as order_item;
import 'package:dinnerhome/services/order_service.dart';
import 'package:dinnerhome/services/in_memory/in_memory_order_service.dart';
import 'package:dinnerhome/services/in_memory/in_memory_socket_service.dart';

void main() {
  group('InMemoryOrderService', () {
    // ---------------------------------------------------------------------------
    // Test 1: Create a draft order
    // ---------------------------------------------------------------------------
    test('createDraft returns a valid draft order with default values', () async {
      final socketService = InMemorySocketService();
      final orderService = InMemoryOrderService(socketService);

      final order = await orderService.createDraft(
        waiterId: 'waiter-1',
        tableId: 'table-5',
      );

      expect(order.id, isNotEmpty);
      expect(order.waiterId, 'waiter-1');
      expect(order.tableId, 'table-5');
      expect(order.status, OrderStatus.draft);
      expect(order.items, isEmpty);
      expect(order.subtotalCents, 0);
      expect(order.taxCents, 0);
      expect(order.totalCents, 0);
    });

    // ---------------------------------------------------------------------------
    // Test 2: Add items to draft
    // ---------------------------------------------------------------------------
    test('addItem adds an item to a draft order and recalculates totals', () async {
      final socketService = InMemorySocketService();
      final orderService = InMemoryOrderService(socketService);

      final draft = await orderService.createDraft(
        waiterId: 'waiter-1',
        tableId: 'table-5',
      );

      final item = order_item.OrderItem(
        id: 'item-1',
        menuItemId: 'menu-pizza',
        quantity: 2,
        status: order_item.OrderStatus.pending,
        modifierIds: [],
        priceCents: 1500,
      );

      await orderService.addItem(orderId: draft.id, item: item);

      final order = await orderService.getOrder(draft.id);
      expect(order, isNotNull);
      expect(order!.items.length, 1);
      expect(order.items.first.id, 'item-1');
      expect(order.items.first.quantity, 2);
      expect(order.items.first.menuItemId, 'menu-pizza');
      expect(order.items.first.priceCents, 1500);
      expect(order.items.first.status, order_item.OrderStatus.pending);

      // Totals recalculated: 1500 * 2 = 3000 subtotal, 300 tax, 3300 total
      expect(order.subtotalCents, 3000);
      expect(order.taxCents, 300);
      expect(order.totalCents, 3300);
    });

    // ---------------------------------------------------------------------------
    // Test 3: Send to kitchen (success)
    // ---------------------------------------------------------------------------
    test('sendToKitchen transitions order to sentToKitchen with timestamp', () async {
      final socketService = InMemorySocketService();
      final orderService = InMemoryOrderService(socketService);

      final draft = await orderService.createDraft(
        waiterId: 'waiter-1',
        tableId: 'table-5',
      );

      await orderService.addItem(
        orderId: draft.id,
        item: order_item.OrderItem(
          id: 'item-1',
          menuItemId: 'menu-burger',
          quantity: 1,
          status: order_item.OrderStatus.pending,
          modifierIds: [],
          priceCents: 1200,
        ),
      );

      await orderService.sendToKitchen(
        orderId: draft.id,
        byUserId: 'waiter-1',
      );

      final order = await orderService.getOrder(draft.id);
      expect(order, isNotNull);
      expect(order!.status, OrderStatus.sentToKitchen);
      expect(order.sentToKitchenAt, isNotNull);
    });

    // ---------------------------------------------------------------------------
    // Test 4: Send to kitchen (fail - empty order)
    // ---------------------------------------------------------------------------
    test('sendToKitchen throws EmptyOrderException for empty order', () async {
      final socketService = InMemorySocketService();
      final orderService = InMemoryOrderService(socketService);

      final draft = await orderService.createDraft(
        waiterId: 'waiter-1',
        tableId: 'table-5',
      );

      expect(
        () => orderService.sendToKitchen(
          orderId: draft.id,
          byUserId: 'waiter-1',
        ),
        throwsA(
          isA<EmptyOrderException>().having(
            (e) => e.message,
            'message',
            contains('empty'),
          ),
        ),
      );
    });

    // ---------------------------------------------------------------------------
    // Test 5: Add item after sending to kitchen (reopening with audit)
    // ---------------------------------------------------------------------------
    test('addItem succeeds after sendToKitchen (reopening with audit)', () async {
      final socketService = InMemorySocketService();
      final orderService = InMemoryOrderService(socketService);

      final draft = await orderService.createDraft(
        waiterId: 'waiter-1',
        tableId: 'table-5',
      );

      await orderService.addItem(
        orderId: draft.id,
        item: order_item.OrderItem(
          id: 'item-1',
          menuItemId: 'menu-burger',
          quantity: 1,
          status: order_item.OrderStatus.pending,
          modifierIds: [],
          priceCents: 1200,
        ),
      );

      await orderService.sendToKitchen(
        orderId: draft.id,
        byUserId: 'waiter-1',
      );

      // Per spec, Mesero CAN edit after sending - this should succeed
      await orderService.addItem(
        orderId: draft.id,
        item: order_item.OrderItem(
          id: 'item-2',
          menuItemId: 'menu-soda',
          quantity: 3,
          status: order_item.OrderStatus.pending,
          modifierIds: [],
          priceCents: 500,
        ),
      );

      final order = await orderService.getOrder(draft.id);
      expect(order, isNotNull);
      expect(order!.items.length, 2);
      expect(order.items[1].id, 'item-2');
      expect(order.items[1].menuItemId, 'menu-soda');
      expect(order.items[1].quantity, 3);
    });

    // ---------------------------------------------------------------------------
    // Test 6: Update order status (valid transition)
    // ---------------------------------------------------------------------------
    test('updateStatus follows valid state transitions', () async {
      final socketService = InMemorySocketService();
      final orderService = InMemoryOrderService(socketService);

      final draft = await orderService.createDraft(
        waiterId: 'waiter-1',
        tableId: 'table-5',
      );

      await orderService.addItem(
        orderId: draft.id,
        item: order_item.OrderItem(
          id: 'item-1',
          menuItemId: 'menu-pasta',
          quantity: 1,
          status: order_item.OrderStatus.pending,
          modifierIds: [],
          priceCents: 1800,
        ),
      );

      await orderService.sendToKitchen(
        orderId: draft.id,
        byUserId: 'waiter-1',
      );

      // sentToKitchen → prepping
      await orderService.updateStatus(
        orderId: draft.id,
        status: OrderStatus.prepping,
        byUserId: 'chef-1',
      );
      var order = await orderService.getOrder(draft.id);
      expect(order!.status, OrderStatus.prepping);

      // prepping → ready
      await orderService.updateStatus(
        orderId: draft.id,
        status: OrderStatus.ready,
        byUserId: 'chef-1',
      );
      order = await orderService.getOrder(draft.id);
      expect(order!.status, OrderStatus.ready);
      expect(order.readyAt, isNotNull);

      // ready → billed
      await orderService.updateStatus(
        orderId: draft.id,
        status: OrderStatus.billed,
        byUserId: 'cashier-1',
      );
      order = await orderService.getOrder(draft.id);
      expect(order!.status, OrderStatus.billed);

      // billed → closed
      await orderService.updateStatus(
        orderId: draft.id,
        status: OrderStatus.closed,
        byUserId: 'cashier-1',
      );
      order = await orderService.getOrder(draft.id);
      expect(order!.status, OrderStatus.closed);
    });

    // ---------------------------------------------------------------------------
    // Test 7: Update order status (invalid transition)
    // ---------------------------------------------------------------------------
    test('updateStatus throws InvalidStateTransitionException for invalid transitions', () async {
      final socketService = InMemorySocketService();
      final orderService = InMemoryOrderService(socketService);

      final draft = await orderService.createDraft(
        waiterId: 'waiter-1',
        tableId: 'table-5',
      );

      await orderService.addItem(
        orderId: draft.id,
        item: order_item.OrderItem(
          id: 'item-1',
          menuItemId: 'menu-salad',
          quantity: 1,
          status: order_item.OrderStatus.pending,
          modifierIds: [],
          priceCents: 900,
        ),
      );

      // draft → ready is invalid (must go through sentToKitchen → prepping → ready)
      expect(
        () => orderService.updateStatus(
          orderId: draft.id,
          status: OrderStatus.ready,
          byUserId: 'waiter-1',
        ),
        throwsA(
          isA<InvalidStateTransitionException>().having(
            (e) => e.message,
            'message',
            contains('Cannot transition'),
          ),
        ),
      );
    });

    // ---------------------------------------------------------------------------
    // Test 8: Watch orders stream
    // ---------------------------------------------------------------------------
    test('watchOrders emits OrderEvents on order mutations', () async {
      final socketService = InMemorySocketService();
      final orderService = InMemoryOrderService(socketService);

      // Subscribe before mutations
      final stream = orderService.watchOrders();
      final events = <OrderEvent>[];
      final subscription = stream.listen(events.add);
      addTearDown(() => subscription.cancel());

      // Create draft → emits 'created'
      final draft = await orderService.createDraft(
        waiterId: 'waiter-1',
        tableId: 'table-5',
      );
      expect(events.length, 1);
      expect(events[0].eventType, 'created');
      expect(events[0].orderId, draft.id);
      expect(events[0].order.id, draft.id);

      // Add item → emits 'item_added'
      await orderService.addItem(
        orderId: draft.id,
        item: order_item.OrderItem(
          id: 'item-1',
          menuItemId: 'menu-fish',
          quantity: 1,
          status: order_item.OrderStatus.pending,
          modifierIds: [],
          priceCents: 2200,
        ),
      );
      expect(events.length, 2);
      expect(events[1].eventType, 'item_added');

      // Send to kitchen → emits 'sent_to_kitchen'
      await orderService.sendToKitchen(
        orderId: draft.id,
        byUserId: 'waiter-1',
      );
      expect(events.length, 3);
      expect(events[2].eventType, 'sent_to_kitchen');

      // Update status → emits 'status_updated'
      await orderService.updateStatus(
        orderId: draft.id,
        status: OrderStatus.prepping,
        byUserId: 'chef-1',
      );
      expect(events.length, 4);
      expect(events[3].eventType, 'status_updated');
    });
  });
}
