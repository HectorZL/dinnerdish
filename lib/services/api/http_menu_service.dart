import 'package:dinnerhome/models/menu_item.dart';
import 'package:dinnerhome/services/menu_service.dart';
import 'api_client.dart';

class HttpMenuService implements MenuService {
  final ApiClient _client;

  HttpMenuService({ApiClient? client}) : _client = client ?? ApiClient();

  @override
  Future<List<MenuItem>> fetchMenu() async {
    final res = await _client.get('/api/menu');
    return (res as List)
        .map((e) => MenuItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<MenuItem?> getMenuItem(String id) async {
    try {
      final res = await _client.get('/api/menu/$id');
      return MenuItem.fromJson(res as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<MenuItem> createMenuItem(MenuItem item) async {
    final res = await _client.post('/api/menu', body: item.toJson());
    return MenuItem.fromJson(res as Map<String, dynamic>);
  }

  @override
  Future<MenuItem> updateMenuItem(String id, MenuItem item) async {
    final res = await _client.put('/api/menu/$id', body: item.toJson());
    return MenuItem.fromJson(res as Map<String, dynamic>);
  }

  @override
  Future<void> deleteMenuItem(String id) async {
    await _client.delete('/api/menu/$id');
  }

  @override
  Future<List<String>> getCategories() async {
    final res = await _client.get('/api/menu/categories');
    return (res as List).map((e) => e.toString()).toList();
  }

  @override
  Future<void> adjustStock(
    String itemId,
    String? variationId,
    int quantityChange,
  ) async {
    await _client.post('/api/menu/$itemId/stock', body: {
      'quantityChange': quantityChange,
      'variationId': ?variationId,
    });
  }
}
