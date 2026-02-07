import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'data/sources/auth_data_source.dart';
import 'shared/bloc/auth_session_bloc.dart';
import 'themes/app_theme.dart';
import 'features/home/views/home_view.dart';
import 'features/login/views/login_view.dart';
import 'features/upload/views/upload_view.dart';
import 'features/job_detail/views/job_detail_view.dart';
import 'features/scheduler/views/scheduler_view.dart';
import 'features/video_player/views/video_player_view.dart';

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

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final auth = GetIt.instance<IAuthDataSource>();
    final isAuth = await auth.isAuthenticated();
    if (isAuth) {
      GetIt.instance<AuthSessionBloc>().add(const SessionRestoredEvent());
    }
    setState(() {
      _initialRoute = isAuth ? '/' : '/login';
    });
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
          if (state is AuthSessionExpired || state is AuthSessionUnauthenticated) {
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
      case '/scheduler':
        // Scheduler screen (coming soon placeholder)
        return MaterialPageRoute(
          builder: (context) => const SchedulerView(),
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
