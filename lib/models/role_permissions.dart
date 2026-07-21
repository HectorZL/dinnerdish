import 'user.dart';

/// Acciones que se pueden conceder a un rol dentro de la aplicación.
enum AppPermission {
  manageOrders,
  manageTables,
  useKitchenDisplay,
  processPayments,
  manageMenu,
  manageUsers,
  viewReports,
  viewAudit,
}

/// Configuración de permisos por rol.
///
/// El rol administrador siempre conserva todos los permisos para evitar que
/// una configuración deje a la aplicación sin una cuenta administradora.
class RolePermissions {
  final Map<Role, Set<AppPermission>> _grants;

  RolePermissions(Map<Role, Set<AppPermission>> grants)
    : _grants = {
        for (final role in Role.values)
          role: Set<AppPermission>.unmodifiable(grants[role] ?? const {}),
      };

  factory RolePermissions.defaults() => RolePermissions({
    Role.mesero: {AppPermission.manageOrders, AppPermission.manageTables},
    Role.cajero: {AppPermission.manageOrders, AppPermission.processPayments},
    Role.cocinero: {
      AppPermission.manageOrders,
      AppPermission.useKitchenDisplay,
    },
    Role.admin: AppPermission.values.toSet(),
  });

  bool allows(Role role, AppPermission permission) {
    if (role == Role.admin) {
      return true;
    }
    return _grants[role]?.contains(permission) ?? false;
  }

  Set<AppPermission> permissionsFor(Role role) {
    if (role == Role.admin) {
      return Set<AppPermission>.unmodifiable(AppPermission.values.toSet());
    }
    return _grants[role] ?? const {};
  }

  RolePermissions withPermissions(Role role, Set<AppPermission> permissions) {
    if (role == Role.admin) {
      return this;
    }
    return RolePermissions({
      ..._grants,
      role: Set<AppPermission>.from(permissions),
    });
  }

  Map<String, dynamic> toJson() => {
    for (final role in Role.values)
      role.name: permissionsFor(
        role,
      ).map((permission) => permission.name).toList(),
  };

  factory RolePermissions.fromJson(Object? raw) {
    if (raw is! Map) return RolePermissions.defaults();

    final defaults = RolePermissions.defaults();
    final grants = <Role, Set<AppPermission>>{};
    for (final role in Role.values) {
      final values = raw[role.name];
      if (values is! Iterable) {
        grants[role] = defaults.permissionsFor(role);
        continue;
      }
      grants[role] = values
          .whereType<String>()
          .map((name) {
            try {
              return AppPermission.values.byName(name);
            } catch (_) {
              return null;
            }
          })
          .whereType<AppPermission>()
          .toSet();
    }
    return RolePermissions(grants);
  }
}
