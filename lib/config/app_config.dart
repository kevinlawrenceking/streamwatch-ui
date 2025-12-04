/// Application configuration
///
/// In development, the API runs on localhost:8080
/// In production, the API runs on localhost:8081
/// For custom builds, use --dart-define=API_BASE_URL=https://your-api.com
class AppConfig {
  /// API base URL - configurable via --dart-define=API_BASE_URL=...
  /// Default: http://localhost:8081 for production
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8081',
  );

  /// WebSocket base URL (derived from API URL)
  static String get wsBaseUrl => apiBaseUrl.replaceFirst('http', 'ws');
}
