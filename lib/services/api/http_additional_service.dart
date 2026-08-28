import 'package:dinnerhome/models/global_additional.dart';
import 'package:dinnerhome/services/additional_service.dart';
import 'api_client.dart';

class HttpAdditionalService implements AdditionalService {
  final ApiClient _client;

  HttpAdditionalService({ApiClient? client}) : _client = client ?? ApiClient();

  @override
  Future<List<GlobalAdditional>> fetchAdditions({bool onlyAvailable = false}) async {
    final res = await _client.get('/api/additionals', queryParams: {
      if (onlyAvailable) 'only_available': true,
    });
    return (res as List)
        .map((e) => GlobalAdditional.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<GlobalAdditional?> getAdditional(String id) async {
    try {
      final res = await _client.get('/api/additionals/$id');
      return GlobalAdditional.fromJson(res as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<GlobalAdditional> createAdditional(GlobalAdditional additional) async {
    final res = await _client.post('/api/additionals', body: additional.toJson());
    return GlobalAdditional.fromJson(res as Map<String, dynamic>);
  }

  @override
  Future<GlobalAdditional> updateAdditional(
    String id,
    GlobalAdditional additional,
  ) async {
    final res = await _client.put('/api/additionals/$id', body: additional.toJson());
    return GlobalAdditional.fromJson(res as Map<String, dynamic>);
  }

  @override
  Future<void> deleteAdditional(String id) async {
    await _client.delete('/api/additionals/$id');
  }
}
