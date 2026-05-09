import 'package:dinnerhome/exceptions/auth_exception.dart';
import 'package:dinnerhome/models/user.dart';
import 'package:dinnerhome/services/auth_service.dart';

class InMemoryAuthService implements AuthService {
  User? _currentUser;

  static const _testUsers = <String, User>{
    'mesero': User(
      id: 'user-mesero-1',
      username: 'mesero',
      name: 'Juan Pérez',
      role: Role.mesero,
      token: 'mock-token-mesero',
    ),
    'cajero': User(
      id: 'user-cajero-1',
      username: 'cajero',
      name: 'María García',
      role: Role.cajero,
      token: 'mock-token-cajero',
    ),
    'cocinero': User(
      id: 'user-cocinero-1',
      username: 'cocinero',
      name: 'Carlos López',
      role: Role.cocinero,
      token: 'mock-token-cocinero',
    ),
    'admin': User(
      id: 'user-admin-1',
      username: 'admin',
      name: 'Ana Martínez',
      role: Role.admin,
      token: 'mock-token-admin',
    ),
  };

  @override
  Future<User> login(String username, String password) async {
    final user = _testUsers[username];
    if (user == null) {
      throw const InvalidCredentialsException();
    }
    _currentUser = user;
    return user;
  }

  @override
  Future<User> loginWithTestUser(User user) async {
    _currentUser = user;
    return user;
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
  }

  @override
  Future<User?> getCurrentUser() async {
    return _currentUser;
  }
}
