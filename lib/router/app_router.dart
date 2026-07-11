import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../login_screen.dart';
import '../providers/providers.dart';
import '../presentation/screens/main_menu_dashboard.dart';
import '../presentation/screens/create_order_screen.dart';
import '../presentation/screens/order_detail_screen.dart';
import '../presentation/screens/kds_screen.dart';
import '../presentation/screens/audit_log_screen.dart';
import '../presentation/screens/payment_processing_screen.dart';
import '../presentation/screens/cash_drawer_screen.dart';
import '../presentation/screens/menu_management_screen.dart';
import '../presentation/screens/cashier_pending_screen.dart';
import '../presentation/screens/table_management_screen.dart';
import '../presentation/screens/order_tracking_screen.dart';
import '../presentation/screens/user_management_screen.dart';
import '../presentation/screens/reports_screen.dart';
import 'route_guards.dart';

class RouterNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final goRouterProvider = Provider<GoRouter>((ref) {
  final routerNotifier = RouterNotifier();

  ref.onDispose(() => routerNotifier.dispose());

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    refreshListenable: routerNotifier,
    initialLocation: '/login',
    redirect: (context, state) {
      final currentUser = ref.read(currentUserProvider).value;
      final isLoggedIn = currentUser != null;
      final uri = state.uri.toString();
      final isOnLogin = uri == '/login';
      final isOnRoot = uri == '/';

      if (isOnRoot) return '/login';

      if (!isLoggedIn && !isOnLogin) return '/login';
      if (isLoggedIn && isOnLogin) return '/menu';

      if (!RouteGuard.canAccessRoute(currentUser, uri)) return '/menu';

      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(child: Text('Ruta no encontrada: ${state.uri}')),
    ),
    routes: [
      GoRoute(path: '/login', builder: (ctx, state) => const LoginScreen()),
      GoRoute(path: '/menu', builder: (ctx, state) => const MainMenuDashboardScreen()),
      GoRoute(path: '/orders/create', builder: (ctx, state) => const CreateOrderScreen()),
      GoRoute(
        path: '/orders/:id/edit',
        builder: (ctx, state) => CreateOrderScreen(
          existingOrderId: state.pathParameters['id'],
        ),
      ),
      GoRoute(path: '/orders/tracking', builder: (ctx, state) => const OrderTrackingScreen()),
      GoRoute(path: '/orders/:id', builder: (ctx, state) => OrderDetailScreen(
        orderId: state.pathParameters['id']!,
      )),
      GoRoute(path: '/tables', builder: (ctx, state) => const TableManagementScreen()),
      GoRoute(path: '/kds', builder: (ctx, state) => const KdsScreen()),
      GoRoute(path: '/audit', builder: (ctx, state) => const AuditLogScreen()),
      GoRoute(path: '/cashier/pending', builder: (ctx, state) => const CashierPendingScreen()),
      GoRoute(
        path: '/orders/:id/payment',
        builder: (ctx, state) => PaymentProcessingScreen(
          orderId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(path: '/cash-drawer', builder: (ctx, state) => const CashDrawerScreen()),
      GoRoute(path: '/admin/menu', builder: (ctx, state) => const MenuManagementScreen()),
      GoRoute(path: '/admin/users', builder: (ctx, state) => const UserManagementScreen()),
      GoRoute(path: '/admin/reports', builder: (ctx, state) => const ReportsScreen()),
    ],
  );
});
