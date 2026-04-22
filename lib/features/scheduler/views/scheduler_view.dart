import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/job_model.dart';
import '../../../themes/app_theme.dart';
import '../bloc/scheduler_dashboard_bloc.dart';
import '../reports/bloc/reports_dashboard_bloc.dart';
import '../reports/constants/report_keys.dart';
import '../reports/widgets/report_count_card.dart';
import '../widgets/scheduler_job_card.dart';
import '../widgets/summary_card.dart';

/// Scheduler dashboard view.
///
/// Layout (top-level Column, per E8):
///   1. Summary row    — SchedulerDashboardBloc state branches
///   2. Reports row    — independent BlocBuilder on ReportsDashboardBloc;
///                       renders even when jobs fail (graceful degradation)
///   3. Job sections   — SchedulerDashboardBloc state branches
class SchedulerView extends StatelessWidget {
  const SchedulerView({super.key});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        context
            .read<SchedulerDashboardBloc>()
            .add(const RefreshSchedulerDashboard());
        context
            .read<ReportsDashboardBloc>()
            .add(const RefreshReportsDashboard());
      },
      child: const SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SummarySection(),
            SizedBox(height: 24),
            _ReportsRow(),
            SizedBox(height: 24),
            _JobsSection(),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Summary section (LSW-010)
// =============================================================================

class _SummarySection extends StatelessWidget {
  const _SummarySection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SchedulerDashboardBloc, SchedulerDashboardState>(
      builder: (context, state) {
        if (state is SchedulerDashboardLoaded) {
          return _summaryRow(
            queued: state.queuedJobs.length,
            processing: state.processingJobs.length,
            completed: state.completedJobs.length,
            failed: state.failedJobs.length,
          );
        }
        // Placeholder cards while loading or on error — keeps the row
        // footprint stable so the reports row below does not jump.
        return _summaryRow(
          queued: 0,
          processing: 0,
          completed: 0,
          failed: 0,
        );
      },
    );
  }

  Widget _summaryRow({
    required int queued,
    required int processing,
    required int completed,
    required int failed,
  }) {
    return Row(
      children: [
        Expanded(
          child: SchedulerSummaryCard(
            label: 'Queued',
            count: queued,
            icon: Icons.schedule,
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SchedulerSummaryCard(
            label: 'Processing',
            count: processing,
            icon: Icons.sync,
            color: AppColors.tmzRed,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SchedulerSummaryCard(
            label: 'Completed',
            count: completed,
            icon: Icons.check_circle_outline,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SchedulerSummaryCard(
            label: 'Failed',
            count: failed,
            icon: Icons.error_outline,
            color: AppColors.error,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Reports row (WO-076 / LSW-014)
// =============================================================================

class _ReportsRow extends StatelessWidget {
  const _ReportsRow();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReportsDashboardBloc, ReportsDashboardState>(
      builder: (context, state) {
        final isLoading = state is ReportsDashboardInitial ||
            state is ReportsDashboardLoading;
        Map<String, int> counts = const {};
        Map<String, String> errors = const {};
        if (state is ReportsDashboardLoaded) {
          counts = state.counts;
          errors = state.errors;
        }
        return SizedBox(
          height: 116,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: kReports.length,
            itemBuilder: (context, index) {
              final meta = kReports[index];
              return ReportCountCard(
                meta: meta,
                loading: isLoading,
                count: counts[meta.key],
                error: errors[meta.key],
              );
            },
          ),
        );
      },
    );
  }
}

// =============================================================================
// Jobs section (LSW-010)
// =============================================================================

class _JobsSection extends StatelessWidget {
  const _JobsSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SchedulerDashboardBloc, SchedulerDashboardState>(
      builder: (context, state) {
        if (state is SchedulerDashboardLoading ||
            state is SchedulerDashboardInitial) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is SchedulerDashboardError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: AppColors.error),
                  const SizedBox(height: 12),
                  Text(state.message),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context
                        .read<SchedulerDashboardBloc>()
                        .add(const LoadSchedulerDashboard()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is SchedulerDashboardLoaded) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
          );
        }

        return const SizedBox.shrink();
      },
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
