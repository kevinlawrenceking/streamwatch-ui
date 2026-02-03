/// StreamWatch Theme
///
/// This file wraps the global TMZ theme with StreamWatch-specific customizations.
/// Import this in your StreamWatch pages.

import 'package:flutter/material.dart';
import 'tmz_theme.dart';

// Re-export TMZ theme classes for convenience
export 'tmz_theme.dart';

/// StreamWatch-specific colors (uses TmzColors under the hood)
class AppColors {
  // Brand colors
  static const Color primary = TmzColors.tmzRed;
  static const Color primaryLight = TmzColors.tmzRedLight;
  static const Color primaryDark = TmzColors.tmzRedDark;

  // Text colors
  static const Color textPrimary = TmzColors.textPrimary;
  static const Color textSecondary = TmzColors.textSecondary;
  static const Color textOnPrimary = TmzColors.textOnPrimary;

  // Surface colors
  static const Color surface = TmzColors.surface;
  static const Color canvas = TmzColors.canvas;
  static const Color card = TmzColors.card;

  // Status colors
  static const Color success = TmzColors.success;
  static const Color error = TmzColors.error;
  static const Color warning = TmzColors.warning;
  static const Color info = TmzColors.info;

  // Job status colors
  static const Color statusQueued = TmzColors.statusQueued;
  static const Color statusProcessing = TmzColors.statusProcessing;
  static const Color statusCompleted = TmzColors.statusCompleted;
  static const Color statusFailed = TmzColors.statusFailed;

  AppColors._();
}

/// Application theme configuration.
class AppTheme {
  /// Dark theme configuration - uses global TMZ theme.
  static ThemeData get dark => TmzTheme.dark;

  /// Light theme configuration (if needed in future).
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
      ),
    );
  }

  AppTheme._();
}

/// Helper to get status color based on job status string.
Color getStatusColor(String status) {
  return getJobStatusColor(status);
}
