import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dinnerhome/models/audit_entry.dart';
import 'package:dinnerhome/models/user.dart';
import 'package:dinnerhome/presentation/screens/audit_log_screen.dart';
import 'package:dinnerhome/providers/providers.dart';
import 'package:dinnerhome/services/audit_service.dart';
import 'package:dinnerhome/services/user_service.dart';

class MockAuditService implements AuditService {
  final List<AuditEntry> _entries;
  MockAuditService(this._entries);

  @override
  Future<void> record({
    required String action,
    required String userId,
    Map<String, dynamic>? metadata,
    DateTime? timestamp,
  }) async {}

  @override
  Future<List<AuditEntry>> list({int limit = 100, int offset = 0}) async => _entries;
}

class MockUserService implements UserService {
  final List<User> _users;
  MockUserService(this._users);

  @override
  Future<List<User>> fetchUsers() async => _users;

  @override
  Future<User?> getUser(String id) async {
    try {
      return _users.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<User> createUser(User user) async => user;

  @override
  Future<User> updateUser(String id, User user) async => user;

  @override
  Future<void> deleteUser(String id) async {}
}

void main() {
  group('AuditLogScreen', () {
    late List<AuditEntry> mockEntries;
    late List<User> mockUsers;

    setUp(() {
      mockUsers = [
        const User(
          id: 'user-mesero-1',
          username: 'mesero',
          name: 'Juan Pérez',
          roles: [Role.mesero],
        ),
        const User(
          id: 'user-cajero-1',
          username: 'cajero',
          name: 'María García',
          roles: [Role.cajero],
        ),
      ];

      mockEntries = [
        AuditEntry(
          id: 'audit-1',
          action: 'order.item_added',
          userId: 'user-mesero-1',
          timestamp: DateTime.now(),
          metadata: {
            'orderId': 'order-1',
            'itemId': 'item-1',
            'name': 'Paella Valenciana',
            'quantity': 2,
            'tableId': '4',
          },
        ),
        AuditEntry(
          id: 'audit-2',
          action: 'order.cashier_additional_added',
          userId: 'user-cajero-1',
          timestamp: DateTime.now(),
          metadata: {
            'orderId': 'order-1',
            'additionalName': 'Pan Extra',
            'quantity': 1,
            'tableId': '4',
          },
        ),
      ];
    });

    testWidgets('renders personal audit logs with user/waiter identification and details', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            auditServiceProvider.overrideWithValue(MockAuditService(mockEntries)),
            userServiceProvider.overrideWithValue(MockUserService(mockUsers)),
          ],
          child: const MaterialApp(
            home: AuditLogScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Header & Filters
      expect(find.text('Registro de Auditoría Personal'), findsOneWidget);
      expect(find.text('Filtrar por Personal / Mesero'), findsOneWidget);
      expect(find.text('Tipo de Acción'), findsOneWidget);

      // Verify entries rendered with User Name and ID
      expect(find.text('Juan Pérez (ID: user-mesero-1)'), findsOneWidget);
      expect(find.text('María García (ID: user-cajero-1)'), findsOneWidget);

      // Verify Dish & table badges
      expect(find.text('Paella Valenciana (x2)'), findsOneWidget);
      expect(find.text('Pan Extra (x1)'), findsOneWidget);
      expect(find.text('Mesa 4'), findsNWidgets(2));
    });
  });
}
