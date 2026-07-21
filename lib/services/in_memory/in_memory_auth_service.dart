import 'package:dinnerhome/exceptions/auth_exception.dart';
import 'package:dinnerhome/models/user.dart';
import 'package:dinnerhome/services/auth_service.dart';
import 'package:dinnerhome/services/password_hasher.dart';
import 'package:dinnerhome/services/user_service.dart';
import 'package:dinnerhome/services/in_memory/in_memory_user_service.dart';

class InMemoryAuthService implements AuthService {
  final UserService _userService;
  User? _currentUser;

  InMemoryAuthService([UserService? userService])
    : _userService = userService ?? InMemoryUserService();

  @override
  Future<User> login(String username, String password) async {
    final users = await _userService.fetchUsers();
    try {
      final identifier = username.trim().toLowerCase();
      final user = users.firstWhere(
        (candidate) =>
            (candidate.username.toLowerCase() == identifier ||
                candidate.email?.toLowerCase() == identifier) &&
            candidate.isActive &&
            PasswordHasher.verify(password, candidate.password),
      );
      _currentUser = user;
      return user;
    } catch (_) {
      throw const InvalidCredentialsException();
    }
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
  Future<User?> getCurrentUser() async => _currentUser;
}
