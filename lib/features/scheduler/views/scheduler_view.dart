import 'package:flutter/material.dart';
import '../../../themes/app_theme.dart';

/// Scheduler view - placeholder for future scheduled job management.
///
/// This is a scaffold for Phase 2 development. The scheduler will allow:
/// - Creating recurring jobs (e.g., monitor YouTube channel, Twitter account)
/// - Viewing scheduled job history
/// - Managing schedules (pause, resume, delete)
class SchedulerView extends StatelessWidget {
  const SchedulerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TmzAppBar(
        app: WatchAppIdentity.streamWatch,
        showBackButton: true,
        showHomeButton: true,
        customTitle: 'Scheduler',
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.schedule,
                size: 80,
                color: AppColors.primary.withOpacity(0.5),
              ),
              const SizedBox(height: 24),
              Text(
                'Scheduler Coming Soon',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'Automated job scheduling will allow you to:\n'
                '• Monitor YouTube channels for new videos\n'
                '• Track Twitter/X accounts for media posts\n'
                '• Schedule recurring transcription jobs\n'
                '• Set up RSS feed monitoring',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),
              // Placeholder schedule card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.videocam, color: Colors.red),
                          const SizedBox(width: 8),
                          const Text(
                            'Example: YouTube Channel Monitor',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'COMING SOON',
                              style: TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Automatically transcribe new uploads from @TMZ',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.repeat, size: 16, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            'Every 30 minutes',
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
