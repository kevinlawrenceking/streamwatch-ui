import 'token_store_stub.dart'
    if (dart.library.js_interop) 'token_store_web.dart' as impl;

/// Simple token storage for Flutter web using browser localStorage.
///
/// Uses conditional imports so that unit tests can compile on VM (non-web)
/// platforms. In production (web), delegates to localStorage.
class TokenStore {
  /// Writes a value to localStorage.
  Future<void> write({required String key, required String value}) async {
    impl.write(key: key, value: value);
  }

  /// Reads a value from localStorage. Returns null if not found.
  Future<String?> read({required String key}) async {
    return impl.read(key: key);
  }

  /// Deletes a value from localStorage.
  Future<void> delete({required String key}) async {
    impl.delete(key: key);
  }
}
