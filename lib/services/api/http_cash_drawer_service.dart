import 'package:dinnerhome/models/cash_drawer_session.dart';
import 'package:dinnerhome/services/cash_drawer_service.dart';
import 'api_client.dart';

class HttpCashDrawerService implements CashDrawerService {
  final ApiClient _client;

  HttpCashDrawerService({ApiClient? client}) : _client = client ?? ApiClient();

  @override
  Future<CashDrawerSession> openDrawer({required String cashierId}) async {
    final res = await _client.post('/api/cash-drawer/open', body: {
      'cashierId': cashierId,
    });
    return CashDrawerSession.fromJson(res as Map<String, dynamic>);
  }

  @override
  Future<CashDrawerSession> closeDrawer({
    required String sessionId,
    required int actualBalanceCents,
  }) async {
    final res = await _client.post('/api/cash-drawer/close', body: {
      'sessionId': sessionId,
      'actualBalanceCents': actualBalanceCents,
    });
    return CashDrawerSession.fromJson(res as Map<String, dynamic>);
  }

  @override
  Future<CashDrawerSession?> getCurrentSession() async {
    try {
      final res = await _client.get('/api/cash-drawer/current');
      if (res == null) return null;
      return CashDrawerSession.fromJson(res as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<CashDrawerSession> reconcile({
    required String sessionId,
    required int actualBalanceCents,
  }) async {
    final res = await _client.post('/api/cash-drawer/reconcile', body: {
      'sessionId': sessionId,
      'actualBalanceCents': actualBalanceCents,
    });
    return CashDrawerSession.fromJson(res as Map<String, dynamic>);
  }

  @override
  Future<List<CashDrawerSession>> getSessionHistory({int limit = 10}) async {
    final res = await _client.get('/api/cash-drawer/history', queryParams: {
      'limit': limit,
    });
    return (res as List)
        .map((e) => CashDrawerSession.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
