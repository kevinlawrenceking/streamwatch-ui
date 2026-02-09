import 'dart:html' as html;

/// Simple token storage for Flutter web using browser localStorage.
///
/// On web, FlutterSecureStorage uses method channels that often fail with
/// MissingPluginException. This class provides reliable localStorage-backed
/// token persistence. Suitable for web deployments where "secure storage"
/// is inherently limited to what the browser provides.
class TokenStore {
  /// Writes a value to localStorage.
  Future<void> write({required String key, required String value}) async {
    html.window.localStorage[key] = value;
  }

  /// Reads a value from localStorage. Returns null if not found.
  Future<String?> read({required String key}) async {
    return html.window.localStorage[key];
  }

  /// Deletes a value from localStorage.
  Future<void> delete({required String key}) async {
    html.window.localStorage.remove(key);
  }
}
