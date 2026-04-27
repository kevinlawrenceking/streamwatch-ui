import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_ui/shared_ui.dart';

import '../../config/build_info.dart';
import '../../data/sources/auth_data_source.dart';
import '../../shared/bloc/auth_session_bloc.dart';

/// Main application shell wrapping TmzShell with persistent nav rail.
///
/// All feature views render as body-only widgets inside this shell.
/// Login is the only route that bypasses the shell.
class MainShell extends StatelessWidget {
  final Widget body;
  final String? activeRoute;
  final String? title;
  final bool showBackButton;

  const MainShell({
    super.key,
    required this.body,
    this.activeRoute,
    this.title,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthSessionBloc, AuthSessionState>(
      builder: (context, authState) {
        final profile = authState is AuthSessionAuthenticated
            ? authState.userProfile
            : null;
        final isAdmin = profile?.isAdmin ?? false;

        return TmzShell(
          productName: 'STREAMWATCH',
          topBarTitle: title,
          activeRoute: activeRoute,
          navLogo: Image.asset(
            'assets/logos/tmz_red.png',
            fit: BoxFit.contain,
          ),
          topBarLeading: showBackButton
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Back',
                  onPressed: () => Navigator.of(context).pop(),
                )
              : null,
          onNavigate: (route) {
            if (ModalRoute.of(context)?.settings.name == route) return;
            Navigator.pushNamedAndRemoveUntil(context, route, (r) => false);
          },
          navSections: [
            const TmzNavSection(
              title: 'Main',
              items: [
                TmzNavItem(icon: Icons.home, label: 'All Videos', route: '/'),
                TmzNavItem(
                    icon: Icons.add_circle_outline,
                    label: 'Ingest',
                    route: '/ingest'),
                TmzNavItem(
                    icon: Icons.folder,
                    label: 'Collections',
                    route: '/collections'),
              ],
            ),
            const TmzNavSection(
              title: 'Tools',
              items: [
                TmzNavItem(
                    icon: Icons.schedule,
                    label: 'Scheduler',
                    route: '/scheduler'),
                TmzNavItem(
                    icon: Icons.podcasts,
                    label: 'Podcasts',
                    route: '/podcasts'),
                TmzNavItem(
                    icon: Icons.person_search,
                    label: 'Watchlist',
                    route: '/watchlist'),
                TmzNavItem(
                    icon: Icons.category,
                    label: 'Type Control',
                    route: '/type-control'),
              ],
            ),
            if (isAdmin)
              const TmzNavSection(
                title: 'Admin',
                items: [
                  TmzNavItem(
                      icon: Icons.people, label: 'Users', route: '/users'),
                  TmzNavItem(
                      icon: Icons.work_outline, label: 'Jobs', route: '/jobs'),
                ],
              ),
          ],
          navFooter: _LogoutFooter(
              isAdmin: isAdmin, displayName: profile?.displayName),
          body: body,
        );
      },
    );
  }
}

class _LogoutFooter extends StatelessWidget {
  final bool isAdmin;
  final String? displayName;

  const _LogoutFooter({required this.isAdmin, this.displayName});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          child: Text(
            'build ${BuildInfo.gitSha}',
            style: const TextStyle(color: AppColors.textGhost, fontSize: 10),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (displayName != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.person, size: 16, color: AppColors.textGhost),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    displayName!,
                    style: const TextStyle(
                        color: AppColors.textGhost, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        InkWell(
          onTap: () async {
            final auth = GetIt.instance<IAuthDataSource>();
            await auth.logout();
            if (context.mounted) {
              GetIt.instance<AuthSessionBloc>()
                  .add(const LogoutRequestedEvent());
            }
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.logout, size: 20, color: AppColors.textDim),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Logout',
                    style: TextStyle(color: AppColors.textDim, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
