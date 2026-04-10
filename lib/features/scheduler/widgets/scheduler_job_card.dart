import 'package:flutter/material.dart';
import '../../../data/models/job_model.dart';
import '../../../themes/app_theme.dart';

/// A compact job card for the scheduler job list.
class SchedulerJobCard extends StatelessWidget {
  final JobModel job;
  final VoidCallback? onTap;

  const SchedulerJobCard({
    super.key,
    required this.job,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildStatusIndicator(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title ?? job.filename ?? job.jobId,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium!
                          .copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (job.sourceProvider != null) ...[
                          Icon(
                            _providerIcon(job.sourceProvider!),
                            size: 14,
                            color: AppColors.textDim,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            job.sourceProvider!,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall!
                                .copyWith(fontSize: 11),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          _formatTime(job.createdAt),
                          style:
                              Theme.of(context).textTheme.bodySmall!.copyWith(
                                    fontSize: 11,
                                    color: AppColors.textDim,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _buildStatusChip(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Container(
      width: 4,
      height: 40,
      decoration: BoxDecoration(
        color: _statusColor(),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _statusColor().withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        job.status.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall!.copyWith(
              color: _statusColor(),
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Color _statusColor() {
    switch (job.status) {
      case 'completed':
        return AppColors.success;
      case 'processing':
      case 'transcribing':
        return AppColors.tmzRed;
      case 'queued':
        return AppColors.warning;
      case 'failed':
      case 'error':
        return AppColors.error;
      case 'paused':
        return AppColors.textDim;
      default:
        return AppColors.textGhost;
    }
  }

  IconData _providerIcon(String provider) {
    switch (provider) {
      case 'youtube':
        return Icons.play_circle_outline;
      default:
        return Icons.link;
    }
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}';
  }
}
