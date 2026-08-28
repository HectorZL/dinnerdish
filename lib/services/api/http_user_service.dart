import 'package:dinnerhome/models/user.dart';
import 'package:dinnerhome/services/user_service.dart';
import 'api_client.dart';

class HttpUserService implements UserService {
  final ApiClient _client;

  HttpUserService({ApiClient? client}) : _client = client ?? ApiClient();

  @override
  Future<List<User>> fetchUsers() async {
    final res = await _client.get('/api/users');
    return (res as List)
        .map((e) => User.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<User?> getUser(String id) async {
    try {
      final res = await _client.get('/api/users/$id');
      return User.fromJson(res as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<User> createUser(User user) async {
    final res = await _client.post('/api/users', body: {
      'username': user.username,
      'name': user.name,
      'email': user.email,
      'password': user.password ?? '${user.username}123',
      'roles': user.roles.map((r) => r.name).toList(),
      'isActive': user.isActive,
    });
    return User.fromJson(res as Map<String, dynamic>);
  }

  @override
  Future<User> updateUser(String id, User user) async {
    final res = await _client.put('/api/users/$id', body: {
      'name': user.name,
      'email': user.email,
      if (user.password != null && user.password!.isNotEmpty)
        'password': user.password,
      'roles': user.roles.map((r) => r.name).toList(),
      'isActive': user.isActive,
    });
    return User.fromJson(res as Map<String, dynamic>);
  }

  @override
  Future<void> deleteUser(String id) async {
    await _client.delete('/api/users/$id');
  }
}
