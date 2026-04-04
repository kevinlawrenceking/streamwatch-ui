import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/job.dart';
import '../themes/app_theme.dart';

class JobsListPage extends StatefulWidget {
  const JobsListPage({super.key});

  @override
  State<JobsListPage> createState() => _JobsListPageState();
}

class _JobsListPageState extends State<JobsListPage> {
  final ApiService _apiService = ApiService();

  List<Job> _jobs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    try {
      final jobsData = await _apiService.getRecentJobs();

      setState(() {
        _jobs = jobsData.map((j) => Job.fromJson(j)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent Jobs'),
        backgroundColor: AppColors.tmzRed,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: AppColors.error),
                      const SizedBox(height: 16),
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isLoading = true;
                            _error = null;
                          });
                          _loadJobs();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _jobs.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox, size: 64, color: AppColors.textGhost),
                          SizedBox(height: 16),
                          Text('No jobs found'),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadJobs,
                      child: ListView.builder(
                        itemCount: _jobs.length,
                        itemBuilder: (context, index) {
                          final job = _jobs[index];
                          return _buildJobCard(job);
                        },
                      ),
                    ),
    );
  }

  Widget _buildJobCard(Job job) {
    final thumbnailUrl = _apiService.getJobThumbnailUrl(job.jobId);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, '/job', arguments: job.jobId);
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail on the left
            ClipRRect(
              borderRadius: BorderRadius.zero,
              child: SizedBox(
                width: 120,
                height: 90,
                child: Image.network(
                  thumbnailUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppColors.textGhost,
                      child: Icon(
                        Icons.videocam,
                        size: 40,
                        color: AppColors.textGhost,
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: AppColors.surfaceOverlay,
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
            // Content on the right
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
                            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusChip(job.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          job.source == 'url' ? Icons.link : Icons.upload_file,
                          size: 14,
                          color: AppColors.textGhost,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            job.source == 'url'
                                ? job.sourceUrl ?? 'URL'
                                : job.filePath ?? 'Uploaded file',
                            style: Theme.of(context).textTheme.labelSmall!.copyWith(color: AppColors.textGhost),
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
                          style: Theme.of(context).textTheme.labelSmall!.copyWith(color: AppColors.textGhost),
                        ),
                        if (job.isProcessing)
                          Text(
                            '${job.progressPct}%',
                            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                              color: AppColors.tmzRed,
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
                        backgroundColor: Theme.of(context).colorScheme.outline,
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

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'completed':
        color = AppColors.success;
        break;
      case 'processing':
        color = AppColors.tmzRed;
        break;
      case 'failed':
        color = AppColors.error;
        break;
      case 'queued':
        color = AppColors.warning;
        break;
      default:
        color = AppColors.textGhost;
    }

    return Chip(
      label: Text(
        status.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall!,
      ),
      backgroundColor: color.withValues(alpha: 0.2),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.bold),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
