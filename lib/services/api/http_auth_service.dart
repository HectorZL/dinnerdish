import 'package:dinnerhome/models/user.dart';
import 'package:dinnerhome/services/auth_service.dart';
import 'api_client.dart';
import 'api_config.dart';

class HttpAuthService implements AuthService {
  final ApiClient _client;
  User? _currentUser;

  HttpAuthService({ApiClient? client}) : _client = client ?? ApiClient();

  @override
  Future<User> login(String username, String password) async {
    final res = await _client.post('/api/auth/login', body: {
      'username': username,
      'password': password,
    });

    final token = res['access_token'] as String?;
    ApiConfig.authToken = token;

    final userJson = res['user'] as Map<String, dynamic>;
    if (token != null) {
      userJson['token'] = token;
    }
    _currentUser = User.fromJson(userJson);
    return _currentUser!;
  }

  @override
  Future<User> loginWithTestUser(User user) async {
    // Attempt real login with test user credentials, fallback to test user with token
    try {
      final pwd = user.password ?? '${user.username}123';
      return await login(user.username, pwd);
    } catch (_) {
      _currentUser = user;
      return user;
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _client.post('/api/auth/logout');
    } catch (_) {
      // Ignore network errors on logout
    } finally {
      ApiConfig.authToken = null;
      _currentUser = null;
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    if (_currentUser != null) return _currentUser;
    if (ApiConfig.authToken == null) return null;

    try {
      final res = await _client.get('/api/auth/me');
      _currentUser = User.fromJson(res as Map<String, dynamic>);
      return _currentUser;
    } catch (_) {
      ApiConfig.authToken = null;
      _currentUser = null;
      return null;
    }
  }
}
