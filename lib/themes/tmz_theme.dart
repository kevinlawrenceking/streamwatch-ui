/// TMZ Watch Global Theme
///
/// This file defines the unified look and feel for ALL TMZ Watch applications.
/// Based on TMZ brand guidelines - bold, condensed, high-impact design.
///
/// Usage:
/// ```dart
/// MaterialApp(
///   theme: TmzTheme.dark,  // or TmzTheme.withAccent(YourColors.accent)
/// )
/// ```

import 'package:flutter/material.dart';

// ============================================================================
// TMZ BRAND COLORS
// ============================================================================

/// Global TMZ brand colors used across all Watch tools.
class TmzColors {
  // ============================================
  // BRAND COLORS (Do not change)
  // ============================================

  /// TMZ Red - Primary brand color
  /// ALWAYS use #cf0000 for primary red across all TMZ Watch apps
  static const Color tmzRed = Color(0xFFCF0000);
  static const Color tmzRedLight = Color(0xFFE53935);
  static const Color tmzRedDark = Color(0xFF8E0000);

  /// Near-black/off-white (softer than pure black/white for better readability)
  /// Material dark standard uses #121212, off-white is #FAFAFA
  static const Color black = Color(0xFF121212);
  static const Color white = Color(0xFFFAFAFA);

  // ============================================
  // GRAYSCALE (TMZ palette)
  // ============================================

  static const Color gray90 = Color(0xFF1A1A1A);
  static const Color gray80 = Color(0xFF2C2C2C);
  static const Color gray70 = Color(0xFF4D4D4D);
  static const Color gray50 = Color(0xFF7F7F7F);
  static const Color gray30 = Color(0xFFB3B3B3);
  static const Color gray10 = Color(0xFFE6E6E6);

  // ============================================
  // SURFACE COLORS (Dark theme)
  // ============================================

  /// Main background - pure black for TMZ impact
  static const Color background = black;

  /// Canvas (slightly lighter than background)
  static const Color canvas = gray90;

  /// Surface for cards, dialogs
  static const Color surface = gray90;

  /// Card background
  static const Color card = gray80;

  /// Elevated surface
  static const Color surfaceElevated = Color(0xFF353535);

  // ============================================
  // TEXT COLORS
  // ============================================

  /// Primary text (high emphasis)
  static const Color textPrimary = white;

  /// Secondary text (medium emphasis)
  static const Color textSecondary = gray30;

  /// Disabled text
  static const Color textDisabled = gray50;

  /// Text on primary color
  static const Color textOnPrimary = white;

  // ============================================
  // STATUS COLORS
  // ============================================

  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF2196F3);

  // ============================================
  // JOB STATUS COLORS
  // ============================================

  static const Color statusPending = gray50;
  static const Color statusQueued = Color(0xFFFFA726);
  static const Color statusProcessing = tmzRed;
  static const Color statusCompleted = success;
  static const Color statusFailed = error;

  // ============================================
  // DIVIDERS & BORDERS
  // ============================================

  static const Color divider = gray70;
  static const Color border = gray50;

  TmzColors._();
}

// ============================================================================
// WATCH APP ICONS & IDENTITIES
// ============================================================================

/// Icons and colors for each Watch application.
class WatchAppIdentity {
  final String name;
  final String shortName;
  final IconData icon;
  final Color accentColor;

  const WatchAppIdentity({
    required this.name,
    required this.shortName,
    required this.icon,
    required this.accentColor,
  });

  /// TMZ Watch Portal (magnifying glass for investigation/search)
  static const tmzWatch = WatchAppIdentity(
    name: 'TMZ Watch',
    shortName: 'TMZ',
    icon: Icons.search,
    accentColor: TmzColors.tmzRed,
  );

  /// StreamWatch - Video transcription & speaker diarization
  static const streamWatch = WatchAppIdentity(
    name: 'StreamWatch',
    shortName: 'StreamWatch',
    icon: Icons.videocam,
    accentColor: TmzColors.tmzRed,
  );

  /// DocuWatch - Document processing & analysis
  static const docuWatch = WatchAppIdentity(
    name: 'DocuWatch',
    shortName: 'Docu',
    icon: Icons.description,
    accentColor: Color(0xFFCF0000), // TMZ Red #cf0000
  );

  /// FaceWatch - Facial recognition
  static const faceWatch = WatchAppIdentity(
    name: 'FaceWatch',
    shortName: 'Face',
    icon: Icons.face,
    accentColor: Color(0xFF9C27B0), // Purple
  );

  /// DocketWatch - Court docket tracking
  static const docketWatch = WatchAppIdentity(
    name: 'DocketWatch',
    shortName: 'Docket',
    icon: Icons.gavel,
    accentColor: Color(0xFF795548), // Brown
  );

  /// HeatWatch - Social media monitoring
  static const heatWatch = WatchAppIdentity(
    name: 'HeatWatch',
    shortName: 'Heat',
    icon: Icons.local_fire_department,
    accentColor: Color(0xFFFF5722), // Deep Orange
  );

  /// Get all Watch apps
  static const List<WatchAppIdentity> all = [
    tmzWatch,
    streamWatch,
    docuWatch,
    faceWatch,
    docketWatch,
    heatWatch,
  ];
}

// ============================================================================
// SPACING & SIZING
// ============================================================================

/// Global spacing constants.
class TmzSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  /// Standard page padding
  static const EdgeInsets page = EdgeInsets.all(md);

  /// Card padding
  static const EdgeInsets card = EdgeInsets.all(md);

  /// List item padding
  static const EdgeInsets listItem = EdgeInsets.symmetric(horizontal: md, vertical: sm);

  TmzSpacing._();
}

/// Global border radius constants.
/// TMZ style uses sharp corners (zero radius) for impact.
class TmzRadius {
  static const double none = 0.0;
  static const double sm = 4.0;
  static const double md = 8.0;
  static const double lg = 12.0;
  static const double xl = 16.0;

  /// TMZ signature: Sharp corners
  static const BorderRadius zero = BorderRadius.zero;
  static const BorderRadius small = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius medium = BorderRadius.all(Radius.circular(md));
  static const BorderRadius large = BorderRadius.all(Radius.circular(lg));

  TmzRadius._();
}

// ============================================================================
// TYPOGRAPHY
// ============================================================================

/// Global text styles matching TMZ's bold, decisive voice.
/// Uses Roboto Condensed for headlines, Roboto for body.
class TmzTextStyles {
  /// Large headline - TMZ impact style
  static const TextStyle headline = TextStyle(
    fontFamily: 'RobotoCondensed',
    fontWeight: FontWeight.w700,
    fontSize: 28,
    height: 1.1,
    color: TmzColors.white,
  );

  static const TextStyle headline1 = TextStyle(
    fontFamily: 'RobotoCondensed',
    fontWeight: FontWeight.w700,
    fontSize: 32,
    height: 1.1,
    color: TmzColors.textPrimary,
  );

  static const TextStyle headline2 = TextStyle(
    fontFamily: 'RobotoCondensed',
    fontWeight: FontWeight.w700,
    fontSize: 24,
    height: 1.15,
    color: TmzColors.textPrimary,
  );

  static const TextStyle headline3 = TextStyle(
    fontFamily: 'RobotoCondensed',
    fontWeight: FontWeight.w600,
    fontSize: 20,
    height: 1.2,
    color: TmzColors.textPrimary,
  );

  static const TextStyle subhead = TextStyle(
    fontFamily: 'RobotoCondensed',
    fontWeight: FontWeight.w600,
    fontSize: 20,
    height: 1.2,
    color: TmzColors.white,
  );

  static const TextStyle body = TextStyle(
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w400,
    fontSize: 16,
    height: 1.35,
    color: TmzColors.white,
  );

  static const TextStyle body1 = body;

  static const TextStyle bodyBold = TextStyle(
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w600,
    fontSize: 16,
    height: 1.35,
    color: TmzColors.white,
  );

  static const TextStyle body2 = TextStyle(
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w400,
    fontSize: 14,
    height: 1.35,
    color: TmzColors.textSecondary,
  );

  static const TextStyle label = TextStyle(
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w600,
    fontSize: 14,
    letterSpacing: 0.6,
    color: TmzColors.white,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w400,
    fontSize: 12,
    color: TmzColors.textSecondary,
  );

  static const TextStyle button = TextStyle(
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w600,
    fontSize: 14,
    letterSpacing: 0.5,
  );

  TmzTextStyles._();
}

// ============================================================================
// THEME DATA
// ============================================================================

/// Main theme class for TMZ Watch applications.
class TmzTheme {
  /// Standard dark theme with TMZ Red as primary.
  static ThemeData get dark => _buildTheme(TmzColors.tmzRed);

  /// Dark theme with custom accent color (for per-project customization).
  static ThemeData withAccent(Color accent) => _buildTheme(accent);

  static ThemeData _buildTheme(Color primary) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Color scheme
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: TmzColors.white,
        surface: TmzColors.surface,
        background: TmzColors.background,
        error: TmzColors.error,
        onPrimary: TmzColors.textOnPrimary,
        onSecondary: TmzColors.black,
        onSurface: TmzColors.textPrimary,
        onBackground: TmzColors.textPrimary,
        onError: TmzColors.textOnPrimary,
      ),

      // Scaffold - pure black background
      scaffoldBackgroundColor: TmzColors.black,

      // AppBar - black with white text, no elevation
      appBarTheme: AppBarTheme(
        backgroundColor: TmzColors.black,
        foregroundColor: TmzColors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TmzTextStyles.headline,
      ),

      // Cards - dark gray with TMZ red left border accent
      cardTheme: CardThemeData(
        color: TmzColors.gray90,
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: TmzSpacing.sm),
        shape: const RoundedRectangleBorder(
          borderRadius: TmzRadius.zero, // Sharp corners
        ),
      ),

      // Elevated buttons - TMZ Red, sharp corners
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: TmzColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          textStyle: TmzTextStyles.label,
          shape: const RoundedRectangleBorder(
            borderRadius: TmzRadius.zero, // Sharp corners - TMZ signature
          ),
        ),
      ),

      // Text buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: TmzTextStyles.label,
        ),
      ),

      // Outlined buttons
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary),
          shape: const RoundedRectangleBorder(
            borderRadius: TmzRadius.zero,
          ),
        ),
      ),

      // Input decoration - filled, sharp corners
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: TmzColors.gray90,
        border: const OutlineInputBorder(
          borderRadius: TmzRadius.zero,
          borderSide: BorderSide(color: TmzColors.gray50),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: TmzRadius.zero,
          borderSide: BorderSide(color: TmzColors.gray50),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: TmzRadius.zero,
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: TmzRadius.zero,
          borderSide: BorderSide(color: TmzColors.error),
        ),
        labelStyle: TmzTextStyles.label,
        hintStyle: TextStyle(
          color: TmzColors.gray30,
          fontSize: 14,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      ),

      // Text theme
      textTheme: const TextTheme(
        headlineLarge: TmzTextStyles.headline,
        headlineMedium: TmzTextStyles.subhead,
        bodyLarge: TmzTextStyles.body,
        bodyMedium: TmzTextStyles.body,
        labelLarge: TmzTextStyles.label,
      ),

      // Progress indicators
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: TmzColors.gray90,
      ),

      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: TmzColors.gray90,
        selectedColor: primary,
        side: BorderSide.none,
        shape: const RoundedRectangleBorder(
          borderRadius: TmzRadius.zero,
        ),
      ),

      // Dialogs
      dialogTheme: const DialogThemeData(
        backgroundColor: TmzColors.gray90,
        shape: RoundedRectangleBorder(
          borderRadius: TmzRadius.zero,
        ),
      ),

      // Snackbars
      snackBarTheme: SnackBarThemeData(
        backgroundColor: TmzColors.gray80,
        contentTextStyle: TmzTextStyles.body,
        shape: const RoundedRectangleBorder(
          borderRadius: TmzRadius.zero,
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Dividers
      dividerColor: TmzColors.gray70,
      dividerTheme: const DividerThemeData(
        color: TmzColors.gray70,
        thickness: 1,
      ),

      // List tiles
      listTileTheme: const ListTileThemeData(
        contentPadding: TmzSpacing.listItem,
        iconColor: TmzColors.white,
      ),

      // Icons
      iconTheme: const IconThemeData(
        color: TmzColors.white,
        size: 22,
      ),

      // Floating action button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: TmzColors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: TmzRadius.zero,
        ),
      ),

      // Bottom navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: TmzColors.black,
        selectedItemColor: primary,
        unselectedItemColor: TmzColors.gray50,
      ),

      // Tab bar
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: TmzColors.gray50,
        indicatorColor: primary,
      ),
    );
  }

  TmzTheme._();
}

// ============================================================================
// TMZ UI COMPONENTS
// ============================================================================

/// TMZ "Headline Bar" - Red bar with uppercase text
class TmzHeadlineBar extends StatelessWidget {
  final String text;
  final Color? backgroundColor;

  const TmzHeadlineBar({
    super.key,
    required this.text,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor ?? TmzColors.tmzRed,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Text(
        text.toUpperCase(),
        style: TmzTextStyles.subhead.copyWith(color: TmzColors.white),
      ),
    );
  }
}

/// TMZ Card - Card with red left border accent
class TmzCard extends StatelessWidget {
  final Widget child;
  final Color? accentColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const TmzCard({
    super.key,
    required this.child,
    this.accentColor,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 8),
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TmzColors.gray90,
        border: Border(
          left: BorderSide(
            color: accentColor ?? TmzColors.tmzRed,
            width: 4,
          ),
        ),
      ),
      child: child,
    );
  }
}

/// TMZ Status Badge
class TmzStatusBadge extends StatelessWidget {
  final String status;
  final Color? color;

  const TmzStatusBadge({
    super.key,
    required this.status,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = color ?? getJobStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.2),
        border: Border.all(color: statusColor, width: 1),
      ),
      child: Text(
        status.toUpperCase(),
        style: TmzTextStyles.caption.copyWith(
          color: statusColor,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// TMZ App Icon Widget - Shows app icon with optional label
class TmzAppIcon extends StatelessWidget {
  final WatchAppIdentity app;
  final double size;
  final bool showLabel;
  final bool useAccentColor;

  const TmzAppIcon({
    super.key,
    required this.app,
    this.size = 48,
    this.showLabel = false,
    this.useAccentColor = true,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = useAccentColor ? app.accentColor : TmzColors.white;

    if (showLabel) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(app.icon, size: size, color: iconColor),
          const SizedBox(height: 4),
          Text(
            app.shortName,
            style: TmzTextStyles.caption.copyWith(color: iconColor),
          ),
        ],
      );
    }

    return Icon(app.icon, size: size, color: iconColor);
  }
}

/// Standard TMZ AppBar - TMZ logo + app icon + app name
/// Use this for all Watch apps for consistent look
///
/// Features:
/// - TMZ logo (tappable to go back to Portal/Master Panel)
/// - App icon + app name for identification
/// - Optional back button for sub-screens
/// - Optional home button for quick navigation
/// - Action buttons on the right
class TmzAppBar extends StatelessWidget implements PreferredSizeWidget {
  final WatchAppIdentity app;
  final List<Widget>? actions;
  final VoidCallback? onIconTap;
  final bool showBackButton;
  final bool showHomeButton;
  final String? customTitle;
  final bool showLogo;

  const TmzAppBar({
    super.key,
    required this.app,
    this.actions,
    this.onIconTap,
    this.showBackButton = false,
    this.showHomeButton = false,
    this.customTitle,
    this.showLogo = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  void _navigateToPortal(BuildContext context) {
    // TODO: Navigate to Master Panel when it's running
    // For now, show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('TMZ Watch Portal - Coming Soon'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _navigateToHome(BuildContext context) {
    // Navigate to app's home screen
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    // Build action buttons list
    final List<Widget> actionWidgets = [];

    // Add home button if requested and not on home
    if (showHomeButton) {
      actionWidgets.add(
        IconButton(
          icon: const Icon(Icons.home),
          tooltip: 'Home',
          onPressed: () => _navigateToHome(context),
        ),
      );
    }

    // Add custom actions
    if (actions != null) {
      actionWidgets.addAll(actions!);
    }

    return AppBar(
      backgroundColor: TmzColors.tmzRed,
      foregroundColor: TmzColors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Back',
              onPressed: () => Navigator.of(context).pop(),
            )
          : null,
      leadingWidth: showBackButton ? 56 : 0,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // TMZ Logo (black on red background) - tappable
          if (showLogo) ...[
            InkWell(
              onTap: () => _navigateToPortal(context),
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Image.asset(
                  'assets/logos/tmz_black.png',
                  height: 24,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 1,
              height: 24,
              color: TmzColors.white.withOpacity(0.3),
            ),
            const SizedBox(width: 12),
          ],
          // App icon (tappable to go to app home)
          InkWell(
            onTap: onIconTap ?? () => _navigateToHome(context),
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(app.icon, color: TmzColors.white, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    customTitle ?? app.shortName.toUpperCase(),
                    style: TmzTextStyles.subhead.copyWith(
                      color: TmzColors.white,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: actionWidgets.isNotEmpty ? actionWidgets : null,
    );
  }
}

/// Simple icon + title row for use in custom headers
class TmzAppTitle extends StatelessWidget {
  final WatchAppIdentity app;
  final double iconSize;
  final VoidCallback? onTap;

  const TmzAppTitle({
    super.key,
    required this.app,
    this.iconSize = 28,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: TmzColors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(app.icon, color: TmzColors.white, size: iconSize),
          ),
          const SizedBox(width: 12),
          Text(
            app.name.toUpperCase(),
            style: TmzTextStyles.headline.copyWith(
              color: TmzColors.white,
              letterSpacing: 3,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

/// Helper to get status color based on job status string.
Color getJobStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'pending':
      return TmzColors.statusPending;
    case 'queued':
      return TmzColors.statusQueued;
    case 'processing':
      return TmzColors.statusProcessing;
    case 'completed':
    case 'done':
      return TmzColors.statusCompleted;
    case 'failed':
    case 'error':
      return TmzColors.statusFailed;
    default:
      return TmzColors.textSecondary;
  }
}

/// Helper to get status icon based on job status string.
IconData getJobStatusIcon(String status) {
  switch (status.toLowerCase()) {
    case 'pending':
      return Icons.schedule;
    case 'queued':
      return Icons.queue;
    case 'processing':
      return Icons.sync;
    case 'completed':
    case 'done':
      return Icons.check_circle;
    case 'failed':
    case 'error':
      return Icons.error;
    default:
      return Icons.help_outline;
  }
}
