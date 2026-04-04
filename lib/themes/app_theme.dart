/// StreamWatch Theme Configuration
///
/// Delegates to TmzTheme.dark() from shared_ui with StreamWatch product accent.
/// All tokens (AppColors, TmzSpacing, TmzTextStyles, ProductAccent) are
/// re-exported from tmz_theme.dart which re-exports shared_ui/tokens/tokens.dart.

import 'package:flutter/material.dart';
import 'tmz_theme.dart';

// Re-export everything from tmz_theme.dart (which re-exports shared_ui tokens)
export 'tmz_theme.dart';

/// Application theme configuration.
class AppTheme {
  /// Dark theme — canonical DS-001 theme with StreamWatch product accent.
  static ThemeData get dark =>
      TmzTheme.dark(productAccent: ProductAccent.streamWatch);

  AppTheme._();
}

/// Helper to get status color based on job status string.
/// Delegates to getJobStatusColor from tmz_theme.dart.
Color getStatusColor(String status) {
  return getJobStatusColor(status);
}
