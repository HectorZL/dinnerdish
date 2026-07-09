import 'package:dinnerhome/models/user.dart';

class RouteGuard {
  static bool canAccessAdmin(User? user) {
    if (user == null) return false;
    return user.role == Role.admin;
  }

  static bool canAccessPayment(User? user) {
    if (user == null) return false;
    return user.role == Role.cajero || user.role == Role.admin;
  }

  static bool canAccessKds(User? user) {
    if (user == null) return false;
    return user.role == Role.cocinero || user.role == Role.admin;
  }

  static bool canAccessOrders(User? user) {
    if (user == null) return false;
    return user.role == Role.mesero ||
        user.role == Role.cajero ||
        user.role == Role.cocinero ||
        user.role == Role.admin;
  }

  static bool canAccessTables(User? user) {
    if (user == null) return false;
    return user.role == Role.mesero || user.role == Role.admin;
  }

  static bool canAccessMenuManagement(User? user) {
    if (user == null) return false;
    return user.role == Role.admin;
  }

  static bool canAccessCashDrawer(User? user) {
    if (user == null) return false;
    return user.role == Role.cajero || user.role == Role.admin;
  }

  static bool canAccessInventory(User? user) {
    if (user == null) return false;
    return user.role == Role.admin;
  }

  static bool canAccessReports(User? user) {
    if (user == null) return false;
    return user.role == Role.admin;
  }

  static bool canAccessRoute(User? user, String route) {
    if (route.startsWith('/kds')) return canAccessKds(user);
    if (route.startsWith('/audit')) return canAccessAdmin(user);
    if (route.startsWith('/orders/create') || route.startsWith('/orders/')) {
      return canAccessOrders(user);
    }
    if (route.startsWith('/tables')) return canAccessTables(user);
    if (route.startsWith('/cashier/')) return canAccessPayment(user);
    if (route.startsWith('/cash-drawer')) return canAccessCashDrawer(user);
    if (route.startsWith('/admin/menu')) return canAccessMenuManagement(user);
    if (route.startsWith('/admin/users')) return canAccessAdmin(user);
    if (route.startsWith('/admin/inventory')) return canAccessInventory(user);
    if (route.startsWith('/admin/ingredient-assignment')) return canAccessAdmin(user);
    if (route.startsWith('/admin/reports')) return canAccessReports(user);
    return true;
  }
}
