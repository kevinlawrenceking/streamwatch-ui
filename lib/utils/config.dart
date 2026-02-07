/// Application configuration loaded from environment variables.
///
/// Configure at build time using:
/// ```bash
/// flutter run --dart-define=API_BASE_URL=http://localhost:8081 --dart-define=ENV=development
/// flutter build web --dart-define=AUTH_REQUIRED=false  # disable auth gate
/// ```
class Config {
  final String apiBaseUrl;
  final String environment;
  final bool authRequired;

  const Config._({
    required this.apiBaseUrl,
    required this.environment,
    required this.authRequired,
  });

  static Config? _instance;

  /// Singleton instance of the configuration.
  static Config get instance {
    _instance ??= Config._init();
    return _instance!;
  }

  factory Config._init() {
    return const Config._(
      apiBaseUrl: String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://localhost:8081',
      ),
      environment: String.fromEnvironment(
        'ENV',
        defaultValue: 'development',
      ),
      authRequired: bool.fromEnvironment(
        'AUTH_REQUIRED',
        defaultValue: true,
      ),
    );
  }

  /// Whether running in development mode.
  bool get isDevelopment => environment == 'development';

  /// Whether running in production mode.
  bool get isProduction => environment == 'production';

  /// Whether running in staging mode.
  bool get isStaging => environment == 'staging';

  /// WebSocket base URL derived from API URL.
  String get wsBaseUrl => apiBaseUrl.replaceFirst('http', 'ws');
}
