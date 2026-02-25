import 'dart:html' as html;

/// Web implementation using browser localStorage.
void write({required String key, required String value}) {
  html.window.localStorage[key] = value;
}

String? read({required String key}) {
  return html.window.localStorage[key];
}

void delete({required String key}) {
  html.window.localStorage.remove(key);
}
