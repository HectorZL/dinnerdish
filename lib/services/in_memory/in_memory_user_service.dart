import 'package:dinnerhome/exceptions/user_exception.dart';
import 'package:dinnerhome/models/user.dart';
import 'package:dinnerhome/services/password_hasher.dart';
import 'package:dinnerhome/services/user_service.dart';

class InMemoryUserService implements UserService {
  final List<User> _users = [
    User(
      id: 'user-mesero-1',
      username: 'mesero',
      name: 'Juan Pérez',
      roles: [Role.mesero],
      token: 'mock-token-mesero',
      email: 'juan.p@sabor-y-hogar.com',
      lastLogin: 'Hoy, 10:30 AM',
      isActive: true,
      password: PasswordHasher.hash('Mesero123'),
    ),
    User(
      id: 'user-cajero-1',
      username: 'cajero',
      name: 'María García',
      roles: [Role.cajero],
      token: 'mock-token-cajero',
      email: 'maria.g@sabor-y-hogar.com',
      lastLogin: 'Hoy, 08:15 AM',
      isActive: true,
      password: PasswordHasher.hash('Cajero123'),
    ),
    User(
      id: 'user-cocinero-1',
      username: 'cocinero',
      name: 'Carlos López',
      roles: [Role.cocinero],
      token: 'mock-token-cocinero',
      email: 'carlos.l@sabor-y-hogar.com',
      lastLogin: 'Ayer, 09:00 PM',
      isActive: true,
      password: PasswordHasher.hash('Cocinero123'),
    ),
    User(
      id: 'user-admin-1',
      username: 'admin',
      name: 'Ana Martínez',
      roles: [Role.admin],
      token: 'mock-token-admin',
      email: 'ana.m@sabor-y-hogar.com',
      lastLogin: 'Hoy, 09:15 AM',
      isActive: true,
      password: PasswordHasher.hash('Admin123'),
    ),
    User(
      id: 'user-carlos-1',
      username: 'carlos.m',
      name: 'Carlos Mendez',
      roles: [Role.admin],
      token: 'mock-token-carlos',
      email: 'carlos.m@sabor-y-hogar.com',
      lastLogin: 'Hoy, 09:15 AM',
      isActive: true,
      password: PasswordHasher.hash('Carlos123'),
    ),
    User(
      id: 'user-lucia-1',
      username: 'lucia.f',
      name: 'Lucia Ferrero',
      roles: [Role.mesero],
      token: 'mock-token-lucia',
      email: 'lucia.f@sabor-y-hogar.com',
      lastLogin: 'Ayer, 11:30 PM',
      isActive: true,
      password: PasswordHasher.hash('Lucia123'),
    ),
    User(
      id: 'user-jorge-1',
      username: 'jruiz',
      name: 'Jorge Ruiz',
      roles: [Role.cocinero],
      token: 'mock-token-jorge',
      email: 'jruiz@sabor-y-hogar.com',
      lastLogin: 'Hoy, 06:45 AM',
      isActive: true,
      password: PasswordHasher.hash('Jorge123'),
    ),
    User(
      id: 'user-elena-1',
      username: 'elena.b',
      name: 'Elena Blanco',
      roles: [Role.cajero],
      token: 'mock-token-elena',
      email: 'elena.b@sabor-y-hogar.com',
      lastLogin: 'Hace 3 dias',
      isActive: false,
      password: PasswordHasher.hash('Elena123'),
    ),
  ];

  @override
  Future<List<User>> fetchUsers() async => List.unmodifiable(_users);

  @override
  Future<User?> getUser(String id) async {
    try {
      return _users.firstWhere((user) => user.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<User> createUser(User user) async {
    final prepared = _prepareUser(user, isNewUser: true);
    _ensureUnique(prepared);
    _users.add(prepared);
    return prepared;
  }

  @override
  Future<User> updateUser(String id, User user) async {
    final index = _users.indexWhere((entry) => entry.id == id);
    if (index == -1) throw UserNotFoundException(id);

    final existing = _users[index];
    final prepared = _prepareUser(user.copyWith(id: id), isNewUser: false);
    _ensureUnique(prepared, excludingId: id);
    _ensureAnActiveAdminRemains(existing, prepared);
    _users[index] = prepared;
    return prepared;
  }

  @override
  Future<void> deleteUser(String id) async {
    final index = _users.indexWhere((user) => user.id == id);
    if (index == -1) throw UserNotFoundException(id);

    final user = _users[index];
    if (user.hasRole(Role.admin) && user.isActive && _activeAdminCount <= 1) {
      throw LastActiveAdminException();
    }
    _users.removeAt(index);
  }

  int get _activeAdminCount =>
      _users.where((user) => user.hasRole(Role.admin) && user.isActive).length;

  User _prepareUser(User user, {required bool isNewUser}) {
    final username = user.username.trim().toLowerCase();
    final email = user.email?.trim().toLowerCase();
    if (!RegExp(r'^[a-z0-9._-]{3,32}$').hasMatch(username)) {
      throw InvalidUsernameException();
    }
    if (email == null ||
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      throw InvalidEmailException();
    }

    final password = user.password?.trim();
    if (isNewUser && (password == null || password.isEmpty)) {
      throw WeakPasswordException();
    }
    if (password != null &&
        password.isNotEmpty &&
        !PasswordHasher.isHash(password)) {
      final isAllowedPassword = isNewUser
          ? PasswordHasher.isAllowedForNewStaffAccount(password)
          : PasswordHasher.isStrong(password);
      if (!isAllowedPassword) throw WeakPasswordException();
      return user.copyWith(
        username: username,
        email: email,
        password: PasswordHasher.hash(password),
      );
    }
    return user.copyWith(username: username, email: email);
  }

  void _ensureUnique(User user, {String? excludingId}) {
    final duplicateUsername = _users.any(
      (entry) => entry.id != excludingId && entry.username == user.username,
    );
    if (duplicateUsername) throw DuplicateUsernameException(user.username);

    final duplicateEmail = _users.any(
      (entry) => entry.id != excludingId && entry.email == user.email,
    );
    if (duplicateEmail) throw DuplicateEmailException(user.email!);
  }

  void _ensureAnActiveAdminRemains(User existing, User updated) {
    final removesAdminAccess =
        existing.hasRole(Role.admin) &&
        existing.isActive &&
        (!updated.hasRole(Role.admin) || !updated.isActive);
    if (removesAdminAccess && _activeAdminCount <= 1) {
      throw LastActiveAdminException();
    }
  }
}
