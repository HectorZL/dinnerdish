import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:dinnerhome/models/user.dart';
import 'package:dinnerhome/models/role_permissions.dart';
import 'package:dinnerhome/models/order.dart';
import 'package:dinnerhome/models/audit_entry.dart';
import 'package:dinnerhome/models/menu_item.dart';
import 'package:dinnerhome/models/global_additional.dart';
import 'package:dinnerhome/services/auth_service.dart';
import 'package:dinnerhome/services/menu_service.dart';
import 'package:dinnerhome/services/stock_service.dart';
import 'package:dinnerhome/services/order_service.dart';
import 'package:dinnerhome/services/cash_drawer_service.dart';
import 'package:dinnerhome/services/payment_service.dart';
import 'package:dinnerhome/services/socket_service.dart';
import 'package:dinnerhome/services/audit_service.dart';
import 'package:dinnerhome/services/additional_service.dart';
import 'package:dinnerhome/models/table.dart';
import 'package:dinnerhome/services/user_service.dart';
import 'package:dinnerhome/services/table_service.dart';
import 'package:dinnerhome/services/role_permissions_service.dart';
import 'package:dinnerhome/services/hive/hive_audit_service.dart';
import 'package:dinnerhome/services/in_memory/in_memory_auth_service.dart';
import 'package:dinnerhome/services/in_memory/in_memory_user_service.dart';
import 'package:dinnerhome/services/in_memory/in_memory_order_service.dart';
import 'package:dinnerhome/services/in_memory/in_memory_table_service.dart';
import 'package:dinnerhome/services/in_memory/in_memory_payment_service.dart';
import 'package:dinnerhome/services/in_memory/in_memory_cash_drawer_service.dart';
import 'package:dinnerhome/services/in_memory/in_memory_socket_service.dart';
import 'package:dinnerhome/services/hive/hive_menu_service.dart';
import 'package:dinnerhome/services/hive/hive_additional_service.dart';
import 'package:dinnerhome/services/api/api_config.dart';
import 'package:dinnerhome/services/api/http_auth_service.dart';
import 'package:dinnerhome/services/api/http_user_service.dart';
import 'package:dinnerhome/services/api/http_menu_service.dart';
import 'package:dinnerhome/services/api/http_additional_service.dart';
import 'package:dinnerhome/services/api/http_order_service.dart';
import 'package:dinnerhome/services/api/http_table_service.dart';
import 'package:dinnerhome/services/api/http_payment_service.dart';
import 'package:dinnerhome/services/api/http_cash_drawer_service.dart';
import 'package:dinnerhome/services/api/ws_socket_service.dart';

// ──────────────────────────────────────────────
// Service Providers (Railway API & WebSockets with Test Mock fallback)
// ──────────────────────────────────────────────

final socketServiceProvider = Provider<SocketService>((ref) {
  if (ApiConfig.isTestEnvironment) {
    return InMemorySocketService();
  }
  final ws = WsSocketService();
  ref.onDispose(() => ws.dispose());
  return ws;
});

final rolePermissionsProvider =
    StateNotifierProvider<RolePermissionsNotifier, RolePermissions>((ref) {
      return RolePermissionsNotifier();
    });

final userServiceProvider = Provider<UserService>((ref) {
  if (ApiConfig.isTestEnvironment) {
    return InMemoryUserService();
  }
  return HttpUserService();
});

final authServiceProvider = Provider<AuthService>((ref) {
  if (ApiConfig.isTestEnvironment) {
    return InMemoryAuthService(ref.watch(userServiceProvider));
  }
  return HttpAuthService();
});

final menuServiceProvider = Provider<MenuService>((ref) {
  if (ApiConfig.isTestEnvironment) {
    return HiveMenuService();
  }
  return HttpMenuService();
});

final stockServiceProvider = Provider<StockService>((ref) {
  return MenuStockService(
    ref.watch(menuServiceProvider),
    auditService: ref.watch(auditServiceProvider),
  );
});

final additionalServiceProvider = Provider<AdditionalService>((ref) {
  if (ApiConfig.isTestEnvironment) {
    return HiveAdditionalService();
  }
  return HttpAdditionalService();
});

final availableAdditionsProvider = FutureProvider<List<GlobalAdditional>>((
  ref,
) {
  return ref
      .watch(additionalServiceProvider)
      .fetchAdditions(onlyAvailable: true);
});

final menuItemsProvider = FutureProvider<List<MenuItem>>((ref) async {
  final menuService = ref.watch(menuServiceProvider);
  return menuService.fetchMenu();
});

final orderServiceProvider = Provider<OrderService>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  if (ApiConfig.isTestEnvironment) {
    return InMemoryOrderService(
      socketService,
      menuService: ref.watch(menuServiceProvider),
      additionalService: ref.watch(additionalServiceProvider),
      auditService: ref.watch(auditServiceProvider),
    );
  }
  return HttpOrderService(socketService);
});

final activeOrdersProvider = StreamProvider<List<Order>>((ref) async* {
  final orderService = ref.watch(orderServiceProvider);
  try {
    yield await orderService.getActiveOrders();
  } catch (_) {
    yield [];
  }
  try {
    await for (final _ in orderService.watchOrders()) {
      try {
        yield await orderService.getActiveOrders();
      } catch (_) {}
    }
  } catch (_) {}
});

final allOrdersProvider = StreamProvider<List<Order>>((ref) async* {
  final orderService = ref.watch(orderServiceProvider);
  try {
    yield await orderService.getAllOrders();
  } catch (_) {
    yield [];
  }
  try {
    await for (final _ in orderService.watchOrders()) {
      try {
        yield await orderService.getAllOrders();
      } catch (_) {}
    }
  } catch (_) {}
});

final tableServiceProvider = Provider<TableService>((ref) {
  if (ApiConfig.isTestEnvironment) {
    return InMemoryTableService();
  }
  final socketService = ref.watch(socketServiceProvider);
  final service = HttpTableService(socketService: socketService);
  ref.onDispose(() => service.dispose());
  return service;
});

final tablesProvider = StreamProvider<List<Table>>((ref) async* {
  final tableService = ref.watch(tableServiceProvider);
  try {
    yield await tableService.getTables();
  } catch (_) {
    yield [];
  }
  try {
    await for (final tables in tableService.watchTables()) {
      yield tables;
    }
  } catch (_) {}
});

final paymentServiceProvider = Provider<PaymentService>((ref) {
  if (ApiConfig.isTestEnvironment) {
    return InMemoryPaymentService(auditService: ref.watch(auditServiceProvider));
  }
  return HttpPaymentService();
});

final cashDrawerServiceProvider = Provider<CashDrawerService>((ref) {
  if (ApiConfig.isTestEnvironment) {
    return InMemoryCashDrawerService(
      ref.watch(paymentServiceProvider),
      auditService: ref.watch(auditServiceProvider),
    );
  }
  return HttpCashDrawerService();
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
