import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  final http.Client _client;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  Uri _uri(String path, [Map<String, dynamic>? queryParams]) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final urlStr = '${ApiConfig.baseUrl}$cleanPath';
    final uri = Uri.parse(urlStr);
    if (queryParams != null && queryParams.isNotEmpty) {
      final stringParams = queryParams.map(
        (key, value) => MapEntry(key, value.toString()),
      );
      return uri.replace(queryParameters: stringParams);
    }
    return uri;
  }

  dynamic _handleResponse(http.Response response) {
    final bodyString = utf8.decode(response.bodyBytes);
    dynamic body;
    if (bodyString.isNotEmpty) {
      try {
        body = jsonDecode(bodyString);
      } catch (_) {
        body = bodyString;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    String message = 'Error en el servidor (${response.statusCode})';
    if (body is Map && body.containsKey('detail')) {
      final detail = body['detail'];
      if (detail is String) {
        message = detail;
      } else if (detail is List && detail.isNotEmpty) {
        message = detail.map((e) => e['msg'] ?? e.toString()).join(', ');
      }
    }

    throw ApiException(statusCode: response.statusCode, message: message);
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? queryParams}) async {
    final response = await _client.get(
      _uri(path, queryParams),
      headers: ApiConfig.headers,
    );
    return _handleResponse(response);
  }

  Future<dynamic> post(String path, {dynamic body}) async {
    final response = await _client.post(
      _uri(path),
      headers: ApiConfig.headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<dynamic> put(String path, {dynamic body}) async {
    final response = await _client.put(
      _uri(path),
      headers: ApiConfig.headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<dynamic> patch(String path, {dynamic body}) async {
    final response = await _client.patch(
      _uri(path),
      headers: ApiConfig.headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<dynamic> delete(String path, {Map<String, dynamic>? queryParams}) async {
    final response = await _client.delete(
      _uri(path, queryParams),
      headers: ApiConfig.headers,
    );
    return _handleResponse(response);
  }

  void close() {
    _client.close();
  }
}
