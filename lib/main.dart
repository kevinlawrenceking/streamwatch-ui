import 'package:flutter/material.dart';
import 'app.dart';
import 'utils/service_locator.dart';

/// Application entry point.
///
/// Initializes dependencies before running the app.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize service locator with all dependencies
  await initServiceLocator();

  runApp(const StreamWatchApp());
}
