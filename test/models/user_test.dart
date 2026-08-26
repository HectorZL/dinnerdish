import 'package:flutter_test/flutter_test.dart';
import 'package:dinnerhome/models/user.dart';

void main() {
  group('User Model - Multi-Role Support', () {
    test('supports single and multiple roles', () {
      const userSingle = User(
        id: 'u1',
        username: 'juan',
        name: 'Juan Pérez',
        roles: [Role.mesero],
      );
      expect(userSingle.roles, [Role.mesero]);
      expect(userSingle.role, Role.mesero);
      expect(userSingle.hasRole(Role.mesero), isTrue);
      expect(userSingle.hasRole(Role.admin), isFalse);

      const userMulti = User(
        id: 'u2',
        username: 'ana',
        name: 'Ana Martínez',
        roles: [Role.admin, Role.cajero, Role.mesero],
      );
      expect(userMulti.roles.length, 3);
      expect(userMulti.role, Role.admin);
      expect(userMulti.hasRole(Role.admin), isTrue);
      expect(userMulti.hasRole(Role.cajero), isTrue);
      expect(userMulti.hasRole(Role.mesero), isTrue);
      expect(userMulti.hasRole(Role.cocinero), isFalse);
    });

    test('parses fromJson with multi-role array', () {
      final json = {
        'id': 'u3',
        'username': 'carlos',
        'name': 'Carlos Gomez',
        'roles': ['cajero', 'admin'],
        'isActive': true,
      };
      final user = User.fromJson(json);
      expect(user.roles, [Role.cajero, Role.admin]);
      expect(user.role, Role.cajero);
      expect(user.hasRole(Role.admin), isTrue);
      expect(user.hasRole(Role.cajero), isTrue);
    });

    test('parses fromJson with legacy single role string for backward compatibility', () {
      final legacyJson = {
        'id': 'u4',
        'username': 'luis',
        'name': 'Luis Mora',
        'role': 'cocinero',
        'isActive': true,
      };
      final user = User.fromJson(legacyJson);
      expect(user.roles, [Role.cocinero]);
      expect(user.role, Role.cocinero);
      expect(user.hasRole(Role.cocinero), isTrue);
    });

    test('serializes toJson containing roles list and role field', () {
      const user = User(
        id: 'u5',
        username: 'maria',
        name: 'María Ruiz',
        roles: [Role.admin, Role.mesero],
      );
      final json = user.toJson();
      expect(json['roles'], ['admin', 'mesero']);
      expect(json['role'], 'admin');
    });

    test('copyWith updates roles correctly', () {
      const user = User(
        id: 'u6',
        username: 'elena',
        name: 'Elena Cano',
        roles: [Role.mesero],
      );
      final updated = user.copyWith(roles: [Role.mesero, Role.cajero, Role.admin]);
      expect(updated.roles, [Role.mesero, Role.cajero, Role.admin]);
      expect(updated.hasRole(Role.admin), isTrue);
    });
  });
}
