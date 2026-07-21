import '../models/role_permissions.dart';
import '../models/user.dart';

class RouteGuard {
  static bool _has(
    User? user,
    AppPermission permission, [
    RolePermissions? permissions,
  ]) {
    if (user == null) return false;
    return (permissions ?? RolePermissions.defaults()).allows(
      user.role,
      permission,
    );
  }

  static bool _hasRole(User? user, Set<Role> allowedRoles) {
    return user != null && allowedRoles.contains(user.role);
  }

  /// Administración siempre requiere una cuenta administradora, aunque la
  /// configuración de permisos se haya modificado para otro rol.
  static bool canAccessAdmin(User? user, [RolePermissions? permissions]) {
    return _hasRole(user, {Role.admin}) &&
        _has(user, AppPermission.manageUsers, permissions);
  }

  static bool canAccessPayment(User? user, [RolePermissions? permissions]) {
    return _hasRole(user, {Role.cajero, Role.admin}) &&
        _has(user, AppPermission.processPayments, permissions);
  }

  static bool canAccessKds(User? user, [RolePermissions? permissions]) {
    return _hasRole(user, {Role.cocinero, Role.admin}) &&
        _has(user, AppPermission.useKitchenDisplay, permissions);
  }

  static bool canAccessOrders(User? user, [RolePermissions? permissions]) {
    return _hasRole(user, {
          Role.mesero,
          Role.cajero,
          Role.cocinero,
          Role.admin,
        }) &&
        _has(user, AppPermission.manageOrders, permissions);
  }

  static bool canAccessTables(User? user, [RolePermissions? permissions]) {
    return _hasRole(user, {Role.mesero, Role.admin}) &&
        _has(user, AppPermission.manageTables, permissions);
  }

  static bool canAccessMenuManagement(
    User? user, [
    RolePermissions? permissions,
  ]) {
    return _hasRole(user, {Role.admin}) &&
        _has(user, AppPermission.manageMenu, permissions);
  }

  static bool canAccessCashDrawer(User? user, [RolePermissions? permissions]) {
    return canAccessPayment(user, permissions);
  }

  static bool canAccessReports(User? user, [RolePermissions? permissions]) {
    return _hasRole(user, {Role.admin}) &&
        _has(user, AppPermission.viewReports, permissions);
  }

  static bool canAccessAudit(User? user, [RolePermissions? permissions]) {
    return _hasRole(user, {Role.admin}) &&
        _has(user, AppPermission.viewAudit, permissions);
  }

  static bool canAccessRoute(
    User? user,
    String route, [
    RolePermissions? permissions,
  ]) {
    if (route.startsWith('/kds')) {
      return canAccessKds(user, permissions);
    }
    if (route.startsWith('/audit')) {
      return canAccessAudit(user, permissions);
    }
    if (route.startsWith('/orders/create') || route.startsWith('/orders/')) {
      return canAccessOrders(user, permissions);
    }
    if (route.startsWith('/tables')) {
      return canAccessTables(user, permissions);
    }
    if (route.startsWith('/cashier/')) {
      return canAccessPayment(user, permissions);
    }
    if (route.startsWith('/cash-drawer')) {
      return canAccessCashDrawer(user, permissions);
    }
    if (route.startsWith('/admin/menu') ||
        route.startsWith('/admin/additionals') ||
        route.startsWith('/admin/ingredient-assignment')) {
      return canAccessMenuManagement(user, permissions);
    }
    if (route.startsWith('/admin/users')) {
      return canAccessAdmin(user, permissions);
    }
    if (route.startsWith('/admin/reports')) {
      return canAccessReports(user, permissions);
    }
    return true;
  }
}
