import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'data/providers/rest_client.dart';
import 'data/sources/auth_data_source.dart';
import 'shared/bloc/auth_session_bloc.dart';
import 'themes/app_theme.dart';
import 'utils/config.dart';
import 'data/sources/user_data_source.dart';
import 'features/home/views/home_view.dart';
import 'features/login/views/login_view.dart';
import 'features/upload/views/upload_view.dart';
import 'features/job_detail/views/job_detail_view.dart';
import 'features/scheduler/bloc/scheduler_dashboard_bloc.dart';
import 'features/scheduler/views/scheduler_view.dart';
import 'features/users/views/users_view.dart';
import 'features/video_player/views/video_player_view.dart';
import 'features/collections/views/collections_manager_view.dart';
import 'features/type_control/views/type_list_view.dart';
import 'features/type_control/views/type_detail_view.dart';
import 'features/podcasts/presentation/views/podcast_list_view.dart';
import 'features/podcasts/presentation/views/podcast_detail_view.dart';
import 'features/podcasts/presentation/views/episode_list_view.dart';

/// Root application widget.
///
/// Provides global BLoC providers and configures routing.
/// Checks auth state on startup and gates access behind login.
///
/// Routes:
/// - `/` - Home screen (search/browse jobs)
/// - `/login` - Login screen
/// - `/ingest` - Ingest new video (URL or file upload)
/// - `/jobs` - Recent jobs list (legacy, redirects to home)
/// - `/job` - Job detail view (requires jobId argument)
/// - `/scheduler` - Scheduled jobs (coming soon)
class StreamWatchApp extends StatefulWidget {
  const StreamWatchApp({super.key});

  @override
  State<StreamWatchApp> createState() => _StreamWatchAppState();
}

class _StreamWatchAppState extends State<StreamWatchApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  String? _initialRoute;
  bool _authActive = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      // When auth is not required, skip login entirely
      if (!Config.instance.authRequired) {
        setState(() {
          _initialRoute = '/';
        });
        return;
      }

      final auth = GetIt.instance<IAuthDataSource>();
      final isAuth = await auth.isAuthenticated();
      if (isAuth) {
        _authActive = true;
        GetIt.instance<AuthSessionBloc>().add(const SessionRestoredEvent());
        _loadUserProfile();
        setState(() {
          _initialRoute = '/';
        });
        return;
      }

      // Not authenticated — verify the API actually enforces auth before
      // showing login. This prevents a dead-login screen when AUTH_ENABLED
      // is false on the API or auth tables haven't been migrated yet.
      final apiAuthLive = await _probeApiAuth();
      if (!apiAuthLive) {
        // API auth not enforced — bypass login, let requests through
        setState(() {
          _initialRoute = '/';
        });
        return;
      }

      _authActive = true;
      setState(() {
        _initialRoute = '/login';
      });
    } catch (_) {
      // Safety net: if anything throws, show login rather than spin forever
      _authActive = true;
      setState(() {
        _initialRoute = '/login';
      });
    }
  }

  /// Loads the current user profile from GET /api/v1/me and dispatches
  /// [UserProfileLoadedEvent] to the global auth session BLoC.
  Future<void> _loadUserProfile() async {
    try {
      final userDS = GetIt.instance<IUserDataSource>();
      final result = await userDS.getMe();
      result.fold(
        (_) {}, // Silently ignore errors - user can still use the app
        (profile) {
          GetIt.instance<AuthSessionBloc>()
              .add(UserProfileLoadedEvent(profile));
        },
      );
    } catch (_) {
      // Best effort - profile display is non-critical
    }
  }

  /// Probes a protected API endpoint to check if auth middleware is active.
  /// Returns true only if the API returns 401 (auth enforced).
  /// Returns false for 200 (auth disabled), 500 (tables missing), or errors.
  Future<bool> _probeApiAuth() async {
    try {
      final client = GetIt.instance<IRestClient>();
      final response = await client.get(
        endPoint: '/api/v1/jobs',
        queryParams: {'limit': '1'},
      );
      return response.statusCode == 401;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading splash while checking auth
    if (_initialRoute == null) {
      return MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MultiBlocProvider(
      providers: [
        // Global auth session BLoC
        BlocProvider<AuthSessionBloc>.value(
          value: GetIt.instance<AuthSessionBloc>(),
        ),
      ],
      child: BlocListener<AuthSessionBloc, AuthSessionState>(
        listener: (context, state) {
          if (state is AuthSessionAuthenticated && state.userProfile == null) {
            // Authenticated but no profile yet - load it
            _loadUserProfile();
          }
          // Only redirect to login when auth is actually active
          if (_authActive &&
              (state is AuthSessionExpired ||
                  state is AuthSessionUnauthenticated)) {
            _navigatorKey.currentState?.pushNamedAndRemoveUntil(
              '/login',
              (route) => false,
            );
          }
        },
        child: MaterialApp(
          navigatorKey: _navigatorKey,
          title: 'StreamWatch',
          theme: AppTheme.dark,
          initialRoute: _initialRoute,
          onGenerateRoute: _onGenerateRoute,
          builder: Config.instance.devAssumeAdmin
              ? (context, child) => Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        color: AppColors.warning,
                        child: Text(
                          'DEV ADMIN SESSION',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.labelSmall!.copyWith(
                                    color: AppColors.bg,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                        ),
                      ),
                      Expanded(child: child ?? const SizedBox.shrink()),
                    ],
                  )
              : null,
        ),
      ),
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        // Home screen - main landing page with search and job list
        return MaterialPageRoute(
          builder: (context) => const HomeView(),
        );
      case '/login':
        // Login screen
        return MaterialPageRoute(
          builder: (context) => const LoginView(),
        );
      case '/ingest':
        // Ingest screen - upload new video
        return MaterialPageRoute(
          builder: (context) => const UploadView(),
        );
      case '/jobs':
        // Legacy route - redirect to home
        return MaterialPageRoute(
          builder: (context) => const HomeView(),
        );
      case '/job':
        // Job detail screen
        final jobId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (context) => JobDetailView(jobId: jobId),
        );
      case '/users':
        // Users management screen (admin-only)
        return MaterialPageRoute(
          builder: (context) => const UsersView(),
        );
      case '/collections':
        // Collections manager screen
        return MaterialPageRoute(
          builder: (context) => const CollectionsManagerView(),
        );
      case '/scheduler':
        return MaterialPageRoute(
          builder: (context) => BlocProvider(
            create: (_) => GetIt.instance<SchedulerDashboardBloc>()
              ..add(const LoadSchedulerDashboard()),
            child: const SchedulerView(),
          ),
        );
      case '/type-control':
        // TypeControl - video type list (admin-only)
        return MaterialPageRoute(
          builder: (context) => const TypeListView(),
        );
      case '/type-control/detail':
        // TypeControl - type detail with versions/rules/prompt
        final videoTypeId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (context) => TypeDetailView(videoTypeId: videoTypeId),
        );
      case '/podcasts':
        // Podcast list (admin-only)
        return MaterialPageRoute(
          builder: (context) => const PodcastListView(),
        );
      case '/podcasts/detail':
        // Podcast detail with platforms/schedules
        final podcastId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (context) => PodcastDetailView(podcastId: podcastId),
        );
      case '/episodes':
        // Episode list for a podcast
        final podcastId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (context) => EpisodeListView(podcastId: podcastId),
        );
      case '/video':
        // Video player screen
        final args = settings.arguments as Map<String, String>;
        return MaterialPageRoute(
          builder: (context) => VideoPlayerView(
            videoUrl: args['videoUrl']!,
            title: args['title'] ?? 'Video',
          ),
        );
      default:
        // Unknown route - go to home
        return MaterialPageRoute(
          builder: (context) => const HomeView(),
        );
    }
  }
}
