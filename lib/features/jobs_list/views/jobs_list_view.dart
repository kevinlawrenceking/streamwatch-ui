import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../../data/models/job_model.dart';
import '../../../data/sources/job_data_source.dart';
import '../../../themes/app_theme.dart';
import '../bloc/jobs_list_bloc.dart';

/// Jobs list page using BLoC pattern.
class JobsListView extends StatelessWidget {
  const JobsListView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<JobsListBloc>(
      create: (_) => GetIt.instance<JobsListBloc>()..add(const LoadJobsEvent()),
      child: const _JobsListBody(),
    );
  }
}

class _JobsListBody extends StatelessWidget {
  const _JobsListBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TmzAppBar(
        app: WatchAppIdentity.streamWatch,
        customTitle: 'Recent Jobs',
      ),
      body: BlocBuilder<JobsListBloc, JobsListState>(
        builder: (context, state) {
          if (state is JobsListLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is JobsListError) {
            return _ErrorView(
              message: state.failure.message,
              onRetry: () {
                context.read<JobsListBloc>().add(const LoadJobsEvent());
              },
            );
          }

          if (state is JobsListLoaded || state is JobsListRefreshing) {
            final jobs = state is JobsListLoaded
                ? state.jobs
                : (state as JobsListRefreshing).jobs;

            if (jobs.isEmpty) {
              return const _EmptyView();
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<JobsListBloc>().add(const RefreshJobsEvent());
                // Wait for state change
                await context.read<JobsListBloc>().stream.firstWhere(
                      (s) => s is JobsListLoaded || s is JobsListError,
                    );
              },
              child: ListView.builder(
                itemCount: jobs.length,
                itemBuilder: (context, index) {
                  return _JobCard(job: jobs[index]);
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final JobModel job;

  const _JobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    final dataSource = GetIt.instance<IJobDataSource>();
    final thumbnailUrl = dataSource.getJobThumbnailUrl(job.jobId);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, '/job', arguments: job.jobId);
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                bottomLeft: Radius.circular(4),
              ),
              child: SizedBox(
                width: 120,
                height: 90,
                child: Image.network(
                  thumbnailUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: Icon(
                        Icons.videocam,
                        size: 40,
                        color: Colors.grey[500],
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            job.title ?? 'Job ${job.jobId.substring(0, 8)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusChip(status: job.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          job.source == 'url' ? Icons.link : Icons.upload_file,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            job.source == 'url'
                                ? job.sourceUrl ?? 'URL'
                                : job.filePath ?? 'Uploaded file',
                            style:
                                TextStyle(fontSize: 11, color: Colors.grey[600]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDateTime(job.createdAt),
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                        if (job.isProcessing)
                          Text(
                            '${job.progressPct}%',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                    if (job.isProcessing) ...[
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: job.progressPct / 100,
                        minHeight: 3,
                        backgroundColor: Colors.grey[300],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = getStatusColor(status);

    return Chip(
      label: Text(
        status.toUpperCase(),
        style: const TextStyle(fontSize: 11),
      ),
      backgroundColor: color.withOpacity(0.2),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.bold),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error: $message'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('No jobs found'),
        ],
      ),
    );
  }
}
