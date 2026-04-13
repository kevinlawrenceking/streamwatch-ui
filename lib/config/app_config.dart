class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://u0o3w9ciwh.execute-api.us-east-1.amazonaws.com',
  );

  /// WebSocket base URL (derived from API URL)
  static String get wsBaseUrl => apiBaseUrl.replaceFirst('http', 'ws');
}
