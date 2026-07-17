import 'package:dinnerhome/models/user.dart';

abstract class UserService {
  Future<List<User>> fetchUsers();
  Future<User?> getUser(String id);
  Future<User> createUser(User user);
  Future<User> updateUser(String id, User user);
  Future<void> deleteUser(String id);
}
