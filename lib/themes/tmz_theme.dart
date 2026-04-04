/// StreamWatch UI Components & Helpers
///
/// Shared widgets and utilities used across StreamWatch views.
/// Theme and color tokens are now provided by shared_ui/tokens/tokens.dart.

import 'package:flutter/material.dart';
import 'package:shared_ui/tokens/tokens.dart';

// Re-export tokens so existing imports of tmz_theme.dart still resolve
export 'package:shared_ui/tokens/tokens.dart';

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

  static const tmzWatch = WatchAppIdentity(
    name: 'TMZ Filtered',
    shortName: 'TMZ',
    icon: Icons.search,
    accentColor: AppColors.tmzRed,
  );

  static const streamWatch = WatchAppIdentity(
    name: 'StreamWatch',
    shortName: 'StreamWatch',
    icon: Icons.videocam,
    accentColor: AppColors.tmzRed,
  );

  static const docuWatch = WatchAppIdentity(
    name: 'DocuWatch',
    shortName: 'Docu',
    icon: Icons.description,
    accentColor: Color(0xFF3B82F6), // DS-001 DocuWatch accent
  );

  static const faceWatch = WatchAppIdentity(
    name: 'FaceWatch',
    shortName: 'Face',
    icon: Icons.face,
    accentColor: Color(0xFF9C27B0), // DS-001 FaceWatch accent
  );

  static const docketWatch = WatchAppIdentity(
    name: 'DocketWatch',
    shortName: 'Docket',
    icon: Icons.gavel,
    accentColor: Color(0xFF8B5CF6), // DS-001 DocketWatch accent
  );

  static const heatWatch = WatchAppIdentity(
    name: 'HeatWatch',
    shortName: 'Heat',
    icon: Icons.local_fire_department,
    accentColor: Color(0xFFFF5722), // Deep Orange (no DS-001 entry)
  );

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
// STREAMWATCH SPACING HELPERS (EdgeInsets conveniences not in DS-001)
// ============================================================================

class SwSpacing {
  static const EdgeInsets page = EdgeInsets.all(TmzSpacing.md);
  static const EdgeInsets card = EdgeInsets.all(TmzSpacing.md);
  static const EdgeInsets listItem = EdgeInsets.symmetric(
    horizontal: TmzSpacing.md,
    vertical: TmzSpacing.sm,
  );

  SwSpacing._();
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
      color: backgroundColor ?? AppColors.tmzRed,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.headlineSmall!.copyWith(
          color: AppColors.textMax,
        ),
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
        color: AppColors.surfaceElevated,
        border: Border(
          left: BorderSide(
            color: accentColor ?? AppColors.tmzRed,
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
        color: statusColor.withValues(alpha: 0.2),
        border: Border.all(color: statusColor, width: 1),
      ),
      child: Text(
        status.toUpperCase(),
        style: Theme.of(context).textTheme.bodySmall!.copyWith(
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
    final iconColor = useAccentColor ? app.accentColor : AppColors.textMax;

    if (showLabel) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(app.icon, size: size, color: iconColor),
          const SizedBox(height: 4),
          Text(
            app.shortName,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: iconColor,
            ),
          ),
        ],
      );
    }

    return Icon(app.icon, size: size, color: iconColor);
  }
}

/// Standard TMZ AppBar - TMZ logo + app icon + app name
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('TMZ Filtered Portal - Coming Soon'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _navigateToHome(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> actionWidgets = [];

    if (showHomeButton) {
      actionWidgets.add(
        IconButton(
          icon: const Icon(Icons.home),
          tooltip: 'Home',
          onPressed: () => _navigateToHome(context),
        ),
      );
    }

    if (actions != null) {
      actionWidgets.addAll(actions!);
    }

    return AppBar(
      backgroundColor: AppColors.tmzRed,
      foregroundColor: AppColors.textMax,
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
              color: AppColors.textMax.withValues(alpha: 0.3),
            ),
            const SizedBox(width: 12),
          ],
          InkWell(
            onTap: onIconTap ?? () => _navigateToHome(context),
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(app.icon, color: AppColors.textMax, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    customTitle ?? app.shortName.toUpperCase(),
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      color: AppColors.textMax,
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
              color: AppColors.textMax.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(app.icon, color: AppColors.textMax, size: iconSize),
          ),
          const SizedBox(width: 12),
          Text(
            app.name.toUpperCase(),
            style: Theme.of(context).textTheme.headlineMedium!.copyWith(
              color: AppColors.textMax,
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
      return AppColors.textGhost;
    case 'queued':
      return AppColors.warning;
    case 'processing':
      return AppColors.tmzRed;
    case 'completed':
    case 'done':
      return AppColors.success;
    case 'failed':
    case 'error':
      return AppColors.error;
    default:
      return AppColors.textDim;
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
