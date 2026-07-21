import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../models/role_permissions.dart';
import '../models/user.dart';

class RolePermissionsNotifier extends StateNotifier<RolePermissions> {
  RolePermissionsNotifier() : super(_load());

  static const _boxName = 'settings';
  static const _storageKey = 'role_permissions';

  static RolePermissions _load() {
    if (!Hive.isBoxOpen(_boxName)) return RolePermissions.defaults();
    return RolePermissions.fromJson(Hive.box(_boxName).get(_storageKey));
  }

  Future<void> setPermissions(Role role, Set<AppPermission> permissions) async {
    if (role == Role.admin) return;
    state = state.withPermissions(role, permissions);
    if (Hive.isBoxOpen(_boxName)) {
      await Hive.box(_boxName).put(_storageKey, state.toJson());
    }
  }

  Future<void> reset() async {
    state = RolePermissions.defaults();
    if (Hive.isBoxOpen(_boxName)) {
      await Hive.box(_boxName).put(_storageKey, state.toJson());
    }
  }
}
