class Config {
  final String apiBaseUrl;
  final String environment;
  final bool authRequired;
  final bool _devAssumeAdminFlag;

  const Config._({
    required this.apiBaseUrl,
    required this.environment,
    required this.authRequired,
    required bool devAssumeAdmin,
  }) : _devAssumeAdminFlag = devAssumeAdmin;

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
        defaultValue: 'https://u0o3w9ciwh.execute-api.us-east-1.amazonaws.com',
      ),
      environment: String.fromEnvironment(
        'ENV',
        defaultValue: 'production',
      ),
      authRequired: bool.fromEnvironment(
        'AUTH_REQUIRED',
        defaultValue: true,
      ),
      devAssumeAdmin: bool.fromEnvironment(
        'DEV_ASSUME_ADMIN',
        defaultValue: false,
      ),
    );
  }

  /// Whether running in development mode.
  bool get isDevelopment => environment == 'development';

  /// Whether running in production mode.
  bool get isProduction => environment == 'production';

  /// Whether running in staging mode.
  bool get isStaging => environment == 'staging';

  /// DEV ONLY: When true and in development mode, stubs an admin session
  /// so admin-gated UI (Users, Type Control) is visible without real auth.
  /// Always false in production regardless of the flag value.
  bool get devAssumeAdmin => isDevelopment && _devAssumeAdminFlag;

  /// WebSocket base URL derived from API URL.
  String get wsBaseUrl => apiBaseUrl.replaceFirst('http', 'ws');
}
