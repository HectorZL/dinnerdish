import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dinnerhome/models/user.dart';
import 'package:dinnerhome/presentation/screens/user_management_screen.dart';
import 'package:dinnerhome/providers/providers.dart';
import 'package:dinnerhome/services/user_service.dart';

// ── Mock Service ──────────────────────────────────────────────

class MockUserService implements UserService {
  final List<User> _users;
  final bool shouldThrow;
  int callCount = 0;

  MockUserService({
    List<User>? users,
    this.shouldThrow = false,
  }) : _users = users ?? [];

  @override
  Future<List<User>> fetchUsers() async {
    callCount++;
    if (shouldThrow) {
      throw Exception('Simulated user error');
    }
    return _users;
  }

  @override
  Future<User?> getUser(String id) async {
    try {
      return _users.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<User> createUser(User user) async {
    _users.add(user);
    return user;
  }

  @override
  Future<User> updateUser(String id, User user) async {
    final index = _users.indexWhere((u) => u.id == id);
    if (index != -1) {
      _users[index] = user;
    }
    return user;
  }

  @override
  Future<void> deleteUser(String id) async {
    _users.removeWhere((u) => u.id == id);
  }
}

// ── Helpers ────────────────────────────────────────────────────

Widget buildUserApp(MockUserService userService) {
  GoogleFonts.config.allowRuntimeFetching = false;
  return ProviderScope(
    overrides: [
      userServiceProvider.overrideWith((ref) => userService),
    ],
    child: const MaterialApp(home: UserManagementScreen()),
  );
}

// ── Tests ──────────────────────────────────────────────────────

void main() {
  late MockUserService userService;

  group('UserManagementScreen', () {
    testWidgets('shows loading state initially', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      userService = MockUserService();

      await tester.pumpWidget(buildUserApp(userService));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state when no users', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      userService = MockUserService(users: []);

      await tester.pumpWidget(buildUserApp(userService));
      await tester.pumpAndSettle();

      expect(find.text('No hay usuarios registrados'), findsOneWidget);
      expect(find.text('Nuevo Usuario'), findsWidgets);
    });

    testWidgets('renders list with users and stats', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      userService = MockUserService(
        users: [
          const User(
            id: '1',
            username: 'carlos.m',
            name: 'Carlos Mendez',
            role: Role.admin,
            email: 'carlos.m@sabor-y-hogar.com',
            isActive: true,
          ),
          const User(
            id: '2',
            username: 'lucia.f',
            name: 'Lucia Ferrero',
            role: Role.mesero,
            email: 'lucia.f@sabor-y-hogar.com',
            isActive: false,
          ),
        ],
      );

      await tester.pumpWidget(buildUserApp(userService));
      await tester.pumpAndSettle();

      // Check users rendered
      expect(find.text('Carlos Mendez'), findsOneWidget);
      expect(find.text('Lucia Ferrero'), findsOneWidget);

      // Check stats: Total=2, Activos Ahora=1
      expect(find.text('Total Usuarios'), findsOneWidget);
      final totalCard = find.ancestor(of: find.text('Total Usuarios'), matching: find.byType(Container));
      expect(find.descendant(of: totalCard.first, matching: find.text('2')), findsOneWidget);

      expect(find.text('Activos Ahora'), findsOneWidget);
      final activeCard = find.ancestor(of: find.text('Activos Ahora'), matching: find.byType(Container));
      expect(find.descendant(of: activeCard.first, matching: find.text('1')), findsOneWidget);
    });

    testWidgets('opens and saves create dialog', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      userService = MockUserService(users: []);

      await tester.pumpWidget(buildUserApp(userService));
      await tester.pumpAndSettle();

      // Tap "Nuevo Usuario" button (either mobile or desktop variant)
      final nuevoUsuarioFinder = find.text('Nuevo Usuario');
      
      await tester.tap(nuevoUsuarioFinder.first);
      await tester.pumpAndSettle();

      // Dialog should be open
      expect(find.text('Datos de Cuenta'), findsOneWidget);

      // Fill in details
      await tester.enterText(find.widgetWithText(TextFormField, 'Nombre completo'), 'Nuevo Empleado');
      await tester.enterText(find.widgetWithText(TextFormField, 'Nombre de usuario (Login)'), 'new.emp');
      await tester.enterText(find.widgetWithText(TextFormField, 'Correo electrónico'), 'new@email.com');
      await tester.enterText(find.widgetWithText(TextFormField, 'Contraseña'), 'mypassword');

      // Save
      final saveBtn = find.text('Crear Usuario');
      await tester.ensureVisible(saveBtn);
      await tester.pumpAndSettle();
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Check if user is created and dialog closed
      expect(find.text('Datos de Cuenta'), findsNothing);
      expect(find.text('Nuevo Empleado'), findsOneWidget);
    });
  });
}
