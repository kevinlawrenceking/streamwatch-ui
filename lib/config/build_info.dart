// Populated at build time via --dart-define=GIT_SHA=<short hash>
// Defaults to 'dev' for local runs without the flag.
class BuildInfo {
  static const String gitSha = String.fromEnvironment('GIT_SHA', defaultValue: 'dev');
}
