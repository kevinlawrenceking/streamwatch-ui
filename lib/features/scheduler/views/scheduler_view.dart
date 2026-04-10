import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/job_model.dart';
import '../../../themes/app_theme.dart';
import '../bloc/scheduler_dashboard_bloc.dart';
import '../widgets/scheduler_job_card.dart';
import '../widgets/summary_card.dart';

/// Scheduler dashboard view.
/// Shows summary stats and recent podcast-originated jobs.
class SchedulerView extends StatelessWidget {
  const SchedulerView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SchedulerDashboardBloc, SchedulerDashboardState>(
      builder: (context, state) {
        return Scaffold(
          appBar: TmzAppBar(
            app: WatchAppIdentity.streamWatch,
            showBackButton: true,
            showHomeButton: true,
            customTitle: 'Scheduler',
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
                onPressed: () => context
                    .read<SchedulerDashboardBloc>()
                    .add(const RefreshSchedulerDashboard()),
              ),
            ],
          ),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, SchedulerDashboardState state) {
    if (state is SchedulerDashboardLoading ||
        state is SchedulerDashboardInitial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is SchedulerDashboardError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(state.message),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context
                  .read<SchedulerDashboardBloc>()
                  .add(const LoadSchedulerDashboard()),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state is SchedulerDashboardLoaded) {
      return RefreshIndicator(
        onRefresh: () async {
          context
              .read<SchedulerDashboardBloc>()
              .add(const RefreshSchedulerDashboard());
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryRow(context, state),
              const SizedBox(height: 24),
              _buildJobSection(
                context,
                title: 'Processing',
                icon: Icons.sync,
                jobs: state.processingJobs,
              ),
              _buildJobSection(
                context,
                title: 'Queued',
                icon: Icons.schedule,
                jobs: state.queuedJobs,
              ),
              _buildJobSection(
                context,
                title: 'Recently Completed',
                icon: Icons.check_circle_outline,
                jobs: state.completedJobs,
              ),
              if (state.failedJobs.isNotEmpty)
                _buildJobSection(
                  context,
                  title: 'Failed',
                  icon: Icons.error_outline,
                  jobs: state.failedJobs,
                ),
              if (state.recentJobs.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.inbox_outlined,
                          size: 48,
                          color: AppColors.textGhost,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No scheduled jobs yet',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium!
                              .copyWith(color: AppColors.textGhost),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Jobs from YouTube WebSub and RSS polling will appear here.',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall!
                              .copyWith(color: AppColors.textDim),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildSummaryRow(
      BuildContext context, SchedulerDashboardLoaded state) {
    return Row(
      children: [
        Expanded(
          child: SchedulerSummaryCard(
            label: 'Queued',
            count: state.queuedJobs.length,
            icon: Icons.schedule,
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SchedulerSummaryCard(
            label: 'Processing',
            count: state.processingJobs.length,
            icon: Icons.sync,
            color: AppColors.tmzRed,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SchedulerSummaryCard(
            label: 'Completed',
            count: state.completedJobs.length,
            icon: Icons.check_circle_outline,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SchedulerSummaryCard(
            label: 'Failed',
            count: state.failedJobs.length,
            icon: Icons.error_outline,
            color: AppColors.error,
          ),
        ),
      ],
    );
  }

  Widget _buildJobSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<JobModel> jobs,
  }) {
    if (jobs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textDim),
            const SizedBox(width: 8),
            Text(
              '$title (${jobs.length})',
              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...jobs.map((job) => SchedulerJobCard(
              job: job,
              onTap: () => Navigator.of(context).pushNamed(
                '/job',
                arguments: {'jobId': job.jobId},
              ),
            )),
        const SizedBox(height: 16),
      ],
    );
  }
}
