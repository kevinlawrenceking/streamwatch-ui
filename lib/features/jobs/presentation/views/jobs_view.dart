import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../themes/app_theme.dart';
import '../bloc/detection_bloc.dart';
import '../bloc/jobs_bloc.dart';
import '../widgets/batch_result_dialog.dart';
import '../widgets/batch_trigger_dialog.dart';
import '../widgets/detection_filter_bar.dart';
import '../widgets/detection_run_row.dart';
import '../widgets/job_filter_bar.dart';
import '../widgets/job_row.dart';

/// Top-level Jobs surface (LSW-016 / WO-078, Plan-Lock #9 top-level
/// route). Tabbed shell: Tab 1 = podcast jobs (JobsBloc), Tab 2 =
/// detection runs (DetectionBloc). Each tab subscribes to its own bloc.
class JobsView extends StatelessWidget {
  const JobsView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: AppColors.surfaceElevated,
            child: const TabBar(
              tabs: [
                Tab(text: 'Jobs'),
                Tab(text: 'Detection'),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                _JobsTab(),
                _DetectionTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JobsTab extends StatefulWidget {
  const _JobsTab();

  @override
  State<_JobsTab> createState() => _JobsTabState();
}

class _JobsTabState extends State<_JobsTab> {
  String? _selectedStatus;
  final _podcastCtrl = TextEditingController();
  String? _retryingJobId;

  @override
  void dispose() {
    _podcastCtrl.dispose();
    super.dispose();
  }

  void _apply() {
    final podcast = _podcastCtrl.text.trim();
    context.read<JobsBloc>().add(JobsFilterChangedEvent(
          status: _selectedStatus,
          podcastId: podcast.isEmpty ? null : podcast,
        ));
  }

  void _clear() {
    setState(() => _selectedStatus = null);
    _podcastCtrl.clear();
    context.read<JobsBloc>().add(const JobsFilterChangedEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<JobsBloc, JobsState>(
      listenWhen: (prev, curr) =>
          curr is JobsLoaded &&
          (curr.lastActionError != null || curr.lastActionMessage != null),
      listener: (context, state) {
        if (state is! JobsLoaded) return;
        if (state.lastActionError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.lastActionError!),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.read<JobsBloc>().add(const JobsErrorAcknowledged());
        } else if (state.lastActionMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.lastActionMessage!),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
          context.read<JobsBloc>().add(const JobsErrorAcknowledged());
        }
        setState(() => _retryingJobId = null);
      },
      builder: (context, state) {
        if (state is JobsInitial || state is JobsLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is JobsError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    size: 64, color: AppColors.error),
                const SizedBox(height: 12),
                Text(state.message),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      context.read<JobsBloc>().add(const LoadJobsEvent()),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        final loaded = state as JobsLoaded;
        return Column(
          children: [
            JobFilterBar(
              selectedStatus: _selectedStatus,
              podcastCtrl: _podcastCtrl,
              onStatusChanged: (s) => setState(() => _selectedStatus = s),
              onApply: _apply,
              onClear: _clear,
            ),
            Expanded(
              child: loaded.jobs.isEmpty
                  ? const Center(child: Text('No jobs.'))
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: loaded.jobs.length,
                      itemBuilder: (context, index) {
                        final job = loaded.jobs[index];
                        return JobRow(
                          job: job,
                          isRetrying: _retryingJobId == job.jobId,
                          onRetry: () {
                            setState(() => _retryingJobId = job.jobId);
                            context
                                .read<JobsBloc>()
                                .add(RetryJobEvent(job.jobId));
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _DetectionTab extends StatefulWidget {
  const _DetectionTab();

  @override
  State<_DetectionTab> createState() => _DetectionTabState();
}

class _DetectionTabState extends State<_DetectionTab> {
  String? _selectedStatus;
  final _episodeCtrl = TextEditingController();

  @override
  void dispose() {
    _episodeCtrl.dispose();
    super.dispose();
  }

  void _apply() {
    final ep = _episodeCtrl.text.trim();
    context.read<DetectionBloc>().add(DetectionFilterChangedEvent(
          status: _selectedStatus,
          episodeId: ep.isEmpty ? null : ep,
        ));
  }

  void _clear() {
    setState(() => _selectedStatus = null);
    _episodeCtrl.clear();
    context.read<DetectionBloc>().add(const DetectionFilterChangedEvent());
  }

  void _openBatch() {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<DetectionBloc>(),
        child: const BatchTriggerDialog(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DetectionBloc, DetectionState>(
      listenWhen: (prev, curr) {
        if (curr is! DetectionLoaded) return false;
        return curr.lastActionError != null ||
            curr.lastActionMessage != null ||
            curr.lastBatchResult != null;
      },
      listener: (context, state) {
        if (state is! DetectionLoaded) return;
        if (state.lastBatchResult != null) {
          showDialog(
            context: context,
            builder: (_) => BlocProvider.value(
              value: context.read<DetectionBloc>(),
              child: BatchResultDialog(results: state.lastBatchResult!),
            ),
          );
          return;
        }
        if (state.lastActionError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.lastActionError!),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.read<DetectionBloc>().add(const DetectionErrorAcknowledged());
        } else if (state.lastActionMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.lastActionMessage!),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
          context.read<DetectionBloc>().add(const DetectionErrorAcknowledged());
        }
      },
      builder: (context, state) {
        if (state is DetectionInitial || state is DetectionLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is DetectionError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    size: 64, color: AppColors.error),
                const SizedBox(height: 12),
                Text(state.message),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context
                      .read<DetectionBloc>()
                      .add(const LoadDetectionRunsEvent()),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        final loaded = state as DetectionLoaded;
        return Column(
          children: [
            DetectionFilterBar(
              selectedStatus: _selectedStatus,
              episodeCtrl: _episodeCtrl,
              onStatusChanged: (s) => setState(() => _selectedStatus = s),
              onApply: _apply,
              onClear: _clear,
              onBatchTrigger: _openBatch,
            ),
            Expanded(
              child: loaded.runs.isEmpty
                  ? const Center(child: Text('No detection runs.'))
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: loaded.runs.length,
                      itemBuilder: (context, index) {
                        final run = loaded.runs[index];
                        return DetectionRunRow(
                          run: run,
                          actionsByRunId: loaded.actionsByRunId,
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
