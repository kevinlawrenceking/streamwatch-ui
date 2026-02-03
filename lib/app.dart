import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'shared/bloc/auth_session_bloc.dart';
import 'themes/app_theme.dart';
import 'features/home/views/home_view.dart';
import 'features/upload/views/upload_view.dart';
import 'features/job_detail/views/job_detail_view.dart';
import 'features/scheduler/views/scheduler_view.dart';
import 'features/video_player/views/video_player_view.dart';

/// Root application widget.
///
/// Provides global BLoC providers and configures routing.
///
/// Routes:
/// - `/` - Home screen (search/browse jobs)
/// - `/ingest` - Ingest new video (URL or file upload)
/// - `/jobs` - Recent jobs list (legacy, redirects to home)
/// - `/job` - Job detail view (requires jobId argument)
/// - `/scheduler` - Scheduled jobs (coming soon)
class StreamWatchApp extends StatelessWidget {
  const StreamWatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Global auth session BLoC
        BlocProvider<AuthSessionBloc>.value(
          value: GetIt.instance<AuthSessionBloc>(),
        ),
      ],
      child: BlocListener<AuthSessionBloc, AuthSessionState>(
        listener: (context, state) {
          // Handle global auth state changes
          if (state is AuthSessionExpired) {
            // TODO: Navigate to login when auth is implemented
            // For now, just show a snackbar
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Session expired'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        },
        child: MaterialApp(
          title: 'StreamWatch',
          theme: AppTheme.dark,
          initialRoute: '/',
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
