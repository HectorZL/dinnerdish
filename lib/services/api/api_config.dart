class ApiConfig {
  static const String baseUrl = 'https://dinnerdish-production.up.railway.app';
  static const String wsUrl = 'wss://dinnerdish-production.up.railway.app/ws';

  static String? authToken;
  static bool isTestEnvironment = false;

  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (authToken != null && authToken!.isNotEmpty)
          'Authorization': 'Bearer $authToken',
      };
}
