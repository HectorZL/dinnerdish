import 'package:dinnerhome/models/user.dart';

abstract class AuthService {
  Future<User> login(String username, String password);
  Future<User> loginWithTestUser(User user);
  Future<void> logout();
  Future<User?> getCurrentUser();
}
