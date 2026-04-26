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
import 'features/scheduler/reports/bloc/reported_episodes_bloc.dart';
import 'features/scheduler/reports/bloc/reported_slots_bloc.dart';
import 'features/scheduler/reports/bloc/reports_dashboard_bloc.dart';
import 'features/scheduler/reports/views/reports_drill_down_episodes_view.dart';
import 'features/scheduler/reports/views/reports_drill_down_slots_view.dart';
import 'features/scheduler/views/scheduler_view.dart';
import 'features/shell/main_shell.dart';
import 'features/users/views/users_view.dart';
import 'features/video_player/views/video_player_view.dart';
import 'features/collections/views/collections_manager_view.dart';
import 'features/type_control/views/type_list_view.dart';
import 'features/type_control/views/type_detail_view.dart';
import 'features/podcasts/presentation/views/podcast_list_view.dart';
import 'features/podcasts/presentation/views/podcast_detail_view.dart';
import 'features/podcasts/presentation/views/episode_list_view.dart';
import 'features/episode_detail/presentation/views/episode_detail_view.dart';

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

      final apiAuthLive = await _probeApiAuth();
      if (!apiAuthLive) {
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
      _authActive = true;
      setState(() {
        _initialRoute = '/login';
      });
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final userDS = GetIt.instance<IUserDataSource>();
      final result = await userDS.getMe();
      result.fold(
        (_) {},
        (profile) {
          GetIt.instance<AuthSessionBloc>()
              .add(UserProfileLoadedEvent(profile));
        },
      );
    } catch (_) {
      // Best effort
    }
  }

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
        BlocProvider<AuthSessionBloc>.value(
          value: GetIt.instance<AuthSessionBloc>(),
        ),
      ],
      child: BlocListener<AuthSessionBloc, AuthSessionState>(
        listener: (context, state) {
          if (state is AuthSessionAuthenticated && state.userProfile == null) {
            _loadUserProfile();
          }
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

  Route<dynamic> _shellRoute(
    RouteSettings settings,
    String? activeRoute,
    Widget body, {
    String? title,
    bool showBackButton = false,
  }) {
    return MaterialPageRoute(
      settings: settings,
      builder: (context) => MainShell(
        activeRoute: activeRoute,
        title: title,
        showBackButton: showBackButton,
        body: Scaffold(
          backgroundColor: Colors.transparent,
          body: body,
        ),
      ),
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return _shellRoute(settings, '/', const HomeView());
      case '/login':
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => const LoginView(),
        );
      case '/ingest':
        return _shellRoute(settings, '/ingest', const UploadView(),
            title: 'Ingest');
      case '/jobs':
        return _shellRoute(settings, '/', const HomeView());
      case '/job':
        final jobId = settings.arguments as String;
        return _shellRoute(settings, null, JobDetailView(jobId: jobId),
            showBackButton: true);
      case '/users':
        return _shellRoute(settings, '/users', const UsersView(),
            title: 'Users');
      case '/collections':
        return _shellRoute(
            settings, '/collections', const CollectionsManagerView(),
            title: 'Collections');
      case '/scheduler':
        return _shellRoute(
          settings,
          '/scheduler',
          MultiBlocProvider(
            providers: [
              BlocProvider<SchedulerDashboardBloc>(
                create: (_) => GetIt.instance<SchedulerDashboardBloc>()
                  ..add(const LoadSchedulerDashboard()),
              ),
              BlocProvider<ReportsDashboardBloc>.value(
                value: GetIt.instance<ReportsDashboardBloc>()
                  ..add(const LoadReportsDashboard()),
              ),
            ],
            child: const SchedulerView(),
          ),
          title: 'Scheduler',
        );
      case '/scheduler/reports':
        final args = settings.arguments as Map<String, String>;
        final reportKey = args['reportKey']!;
        final label = args['label'] ?? 'Report';
        final isSlotReport =
            reportKey == 'expected-today' || reportKey == 'late';
        return _shellRoute(
          settings,
          '/scheduler',
          isSlotReport
              ? BlocProvider<ReportedSlotsBloc>(
                  create: (_) => GetIt.instance<ReportedSlotsBloc>()
                    ..add(FetchReportedSlotsEvent(reportKey: reportKey)),
                  child: ReportsDrillDownSlotsView(
                    reportKey: reportKey,
                    label: label,
                  ),
                )
              : BlocProvider<ReportedEpisodesBloc>(
                  create: (_) => GetIt.instance<ReportedEpisodesBloc>()
                    ..add(FetchReportedEpisodesEvent(reportKey: reportKey)),
                  child: ReportsDrillDownEpisodesView(
                    reportKey: reportKey,
                    label: label,
                  ),
                ),
          title: label,
          showBackButton: true,
        );
      case '/type-control':
        return _shellRoute(settings, '/type-control', const TypeListView(),
            title: 'Type Control');
      case '/type-control/detail':
        final videoTypeId = settings.arguments as String;
        return _shellRoute(
            settings, '/type-control', TypeDetailView(videoTypeId: videoTypeId),
            showBackButton: true);
      case '/podcasts':
        return _shellRoute(settings, '/podcasts', const PodcastListView(),
            title: 'Podcasts');
      case '/podcasts/detail':
        final podcastId = settings.arguments as String;
        return _shellRoute(
            settings, '/podcasts', PodcastDetailView(podcastId: podcastId),
            showBackButton: true);
      case '/episodes':
        final podcastId = settings.arguments as String;
        return _shellRoute(
            settings, '/podcasts', EpisodeListView(podcastId: podcastId),
            showBackButton: true, title: 'Episodes');
      case '/episodes/detail':
        final episodeId = settings.arguments as String;
        return _shellRoute(
            settings, '/podcasts', EpisodeDetailView(episodeId: episodeId),
            showBackButton: true);
      case '/video':
        final args = settings.arguments as Map<String, String>;
        return _shellRoute(
          settings,
          null,
          VideoPlayerView(
            videoUrl: args['videoUrl']!,
            title: args['title'] ?? 'Video',
          ),
          showBackButton: true,
        );
      default:
        return _shellRoute(settings, '/', const HomeView());
    }
  }
}
