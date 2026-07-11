import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:dinnerhome/models/user.dart';
import 'package:dinnerhome/models/order.dart';
import 'package:dinnerhome/models/audit_entry.dart';
import 'package:dinnerhome/models/menu_item.dart';
import 'package:dinnerhome/services/auth_service.dart';
import 'package:dinnerhome/services/menu_service.dart';
import 'package:dinnerhome/services/order_service.dart';
import 'package:dinnerhome/services/cash_drawer_service.dart';
import 'package:dinnerhome/services/payment_service.dart';
import 'package:dinnerhome/services/socket_service.dart';
import 'package:dinnerhome/services/audit_service.dart';
import 'package:dinnerhome/services/in_memory/in_memory_auth_service.dart';
import 'package:dinnerhome/services/in_memory/in_memory_cash_drawer_service.dart';
import 'package:dinnerhome/services/in_memory/in_memory_menu_service.dart';
import 'package:dinnerhome/services/in_memory/in_memory_order_service.dart';
import 'package:dinnerhome/services/in_memory/in_memory_payment_service.dart';
import 'package:dinnerhome/services/in_memory/in_memory_socket_service.dart';
import 'package:dinnerhome/services/hive/hive_audit_service.dart';
import 'package:dinnerhome/models/table.dart';
import 'package:dinnerhome/services/table_service.dart';
import 'package:dinnerhome/services/in_memory/in_memory_table_service.dart';
// ──────────────────────────────────────────────
// Service Providers
// ──────────────────────────────────────────────

final socketServiceProvider = Provider<SocketService>((ref) {
  return InMemorySocketService();
});

final authServiceProvider = Provider<AuthService>((ref) {
  return InMemoryAuthService();
});

final menuServiceProvider = Provider<MenuService>((ref) {
  return InMemoryMenuService();
});

final menuItemsProvider = FutureProvider<List<MenuItem>>((ref) async {
  final menuService = ref.watch(menuServiceProvider);
  return menuService.fetchMenu();
});

final orderServiceProvider = Provider<OrderService>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  final menuService = ref.watch(menuServiceProvider);
  final auditService = ref.watch(auditServiceProvider);
  return InMemoryOrderService(socketService, menuService: menuService, auditService: auditService);
});

final activeOrdersProvider = StreamProvider<List<Order>>((ref) async* {
  final orderService = ref.watch(orderServiceProvider);
  yield await orderService.getActiveOrders();
  await for (final _ in orderService.watchOrders()) {
    yield await orderService.getActiveOrders();
  }
});

final allOrdersProvider = StreamProvider<List<Order>>((ref) async* {
  final orderService = ref.watch(orderServiceProvider);
  yield await orderService.getAllOrders();
  await for (final _ in orderService.watchOrders()) {
    yield await orderService.getAllOrders();
  }
});

final tableServiceProvider = Provider<TableService>((ref) {
  return InMemoryTableService();
});

final tablesProvider = StreamProvider<List<Table>>((ref) async* {
  final tableService = ref.watch(tableServiceProvider);
  yield await tableService.getTables();
  await for (final tables in tableService.watchTables()) {
    yield tables;
  }
});

final paymentServiceProvider = Provider<PaymentService>((ref) {
  final auditService = ref.watch(auditServiceProvider);
  return InMemoryPaymentService(auditService: auditService);
});

final cashDrawerServiceProvider = Provider<CashDrawerService>((ref) {
  final paymentService = ref.watch(paymentServiceProvider);
  final auditService = ref.watch(auditServiceProvider);
  return InMemoryCashDrawerService(paymentService, auditService: auditService);
});

final auditServiceProvider = Provider<AuditService>((ref) {
  final box = Hive.box<AuditEntry>('audit');
  return HiveAuditService(box);
});

// ──────────────────────────────────────────────
// Auth State (User)
// ──────────────────────────────────────────────

class CurrentUserNotifier extends StateNotifier<AsyncValue<User?>> {
  final AuthService _authService;

  CurrentUserNotifier(this._authService) : super(const AsyncValue.data(null));

  Future<void> login(String username, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.login(username, password);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loginWithTestUser(User user) async {
    state = const AsyncValue.loading();
    try {
      final result = await _authService.loginWithTestUser(user);
      state = AsyncValue.data(result);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    state = const AsyncValue.data(null);
  }
}

final currentUserProvider =
    StateNotifierProvider<CurrentUserNotifier, AsyncValue<User?>>((ref) {
  final authService = ref.watch(authServiceProvider);
  return CurrentUserNotifier(authService);
});
