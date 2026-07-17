import 'package:dinnerhome/exceptions/user_exception.dart';
import 'package:dinnerhome/models/user.dart';
import 'package:dinnerhome/services/user_service.dart';

class InMemoryUserService implements UserService {
  final List<User> _users = [
    // Standard test users from AuthService
    const User(
      id: 'user-mesero-1',
      username: 'mesero',
      name: 'Juan Pérez',
      role: Role.mesero,
      token: 'mock-token-mesero',
      email: 'juan.p@sabor-y-hogar.com',
      lastLogin: 'Hoy, 10:30 AM',
      isActive: true,
      password: 'mesero',
    ),
    const User(
      id: 'user-cajero-1',
      username: 'cajero',
      name: 'María García',
      role: Role.cajero,
      token: 'mock-token-cajero',
      email: 'maria.g@sabor-y-hogar.com',
      lastLogin: 'Hoy, 08:15 AM',
      isActive: true,
      password: 'cajero',
    ),
    const User(
      id: 'user-cocinero-1',
      username: 'cocinero',
      name: 'Carlos López',
      role: Role.cocinero,
      token: 'mock-token-cocinero',
      email: 'carlos.l@sabor-y-hogar.com',
      lastLogin: 'Ayer, 09:00 PM',
      isActive: true,
      password: 'cocinero',
    ),
    const User(
      id: 'user-admin-1',
      username: 'admin',
      name: 'Ana Martínez',
      role: Role.admin,
      token: 'mock-token-admin',
      email: 'ana.m@sabor-y-hogar.com',
      lastLogin: 'Hoy, 09:15 AM',
      isActive: true,
      password: 'admin',
    ),
    // Additional users from screen mock data
    const User(
      id: 'user-carlos-1',
      username: 'carlos.m',
      name: 'Carlos Mendez',
      role: Role.admin,
      token: 'mock-token-carlos',
      email: 'carlos.m@sabor-y-hogar.com',
      lastLogin: 'Hoy, 09:15 AM',
      isActive: true,
      password: 'admin',
    ),
    const User(
      id: 'user-lucia-1',
      username: 'lucia.f',
      name: 'Lucia Ferrero',
      role: Role.mesero,
      token: 'mock-token-lucia',
      email: 'lucia.f@sabor-y-hogar.com',
      lastLogin: 'Ayer, 11:30 PM',
      isActive: true,
      password: 'mesero',
    ),
    const User(
      id: 'user-jorge-1',
      username: 'jruiz',
      name: 'Jorge Ruiz',
      role: Role.cocinero,
      token: 'mock-token-jorge',
      email: 'jruiz@sabor-y-hogar.com',
      lastLogin: 'Hoy, 06:45 AM',
      isActive: true,
      password: 'cocinero',
    ),
    const User(
      id: 'user-elena-1',
      username: 'elena.b',
      name: 'Elena Blanco',
      role: Role.cajero,
      token: 'mock-token-elena',
      email: 'elena.b@sabor-y-hogar.com',
      lastLogin: 'Hace 3 dias',
      isActive: false,
      password: 'cajero',
    ),
  ];

  @override
  Future<List<User>> fetchUsers() async => List.from(_users);

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
    if (index == -1) {
      throw UserNotFoundException(id);
    }
    _users[index] = user;
    return user;
  }

  @override
  Future<void> deleteUser(String id) async {
    final index = _users.indexWhere((u) => u.id == id);
    if (index == -1) {
      throw UserNotFoundException(id);
    }
    _users.removeAt(index);
  }
}
