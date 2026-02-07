import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/job_model.dart';
import '../../../data/sources/job_data_source.dart';
import '../../../themes/tmz_theme.dart';

/// Status badge overlay for grid card thumbnails.
/// Positioned in top-right corner with semi-transparent background.
class StreamStatusBadge extends StatelessWidget {
  final String status;
  final bool isCompact;

  const StreamStatusBadge({
    super.key,
    required this.status,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = getJobStatusColor(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 8,
        vertical: isCompact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.9),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: isCompact ? 9 : 10,
          fontWeight: FontWeight.w700,
          color: TmzColors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Type badge (TV_CLIP, PODCAST, etc.) with color coding.
class StreamTypeBadge extends StatelessWidget {
  final String typeCode;

  const StreamTypeBadge({super.key, required this.typeCode});

  @override
  Widget build(BuildContext context) {
    final color = _getTypeColor(typeCode);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.15),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: color.withValues(alpha:0.5), width: 1),
      ),
      child: Text(
        typeCode.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Color _getTypeColor(String code) {
    switch (code.toLowerCase()) {
      case 'tv_clip':
        return Colors.blue;
      case 'interview':
        return Colors.cyan;
      case 'news':
        return Colors.orange;
      case 'documentary':
        return Colors.purple;
      case 'podcast':
        return Colors.green;
      case 'press':
        return Colors.teal;
      case 'sports':
        return Colors.red;
      case 'entertainment':
        return Colors.pink;
      case 'commercial':
        return Colors.amber;
      default:
        return TmzColors.gray50;
    }
  }
}

/// Celebrity chips row with overflow handling.
/// Shows max 2 celebs as chips + "+N" chip if more remain.
class StreamCelebChips extends StatelessWidget {
  final List<String> celebs;
  final int maxVisible;

  const StreamCelebChips({
    super.key,
    required this.celebs,
    this.maxVisible = 2,
  });

  @override
  Widget build(BuildContext context) {
    if (celebs.isEmpty) return const SizedBox.shrink();

    final visible = celebs.take(maxVisible).toList();
    final overflow = celebs.length - maxVisible;

    return SizedBox(
      height: 24,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: visible.length + (overflow > 0 ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(width: 4),
        itemBuilder: (context, index) {
          if (index < visible.length) {
            return _CelebChip(label: visible[index]);
          }
          return _CelebChip(label: '+$overflow', isOverflow: true);
        },
      ),
    );
  }
}

/// Individual celeb pill/chip.
class _CelebChip extends StatelessWidget {
  final String label;
  final bool isOverflow;

  const _CelebChip({required this.label, this.isOverflow = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isOverflow
            ? TmzColors.gray70.withValues(alpha: 0.6)
            : TmzColors.gray70,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isOverflow ? FontWeight.w400 : FontWeight.w600,
          color: TmzColors.white,
          height: 1.2,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// People list with icon rows and tap-to-expand overflow handling.
/// Shows max 2 people rows by default + tappable "+N more" that expands inline.
class StreamPeopleList extends StatefulWidget {
  final List<String> people;
  final int maxVisible;

  const StreamPeopleList({
    super.key,
    required this.people,
    this.maxVisible = 2,
  });

  @override
  State<StreamPeopleList> createState() => _StreamPeopleListState();
}

class _StreamPeopleListState extends State<StreamPeopleList> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.people.isEmpty) return const SizedBox.shrink();

    final showAll = _expanded || widget.people.length <= widget.maxVisible;
    final visible = showAll ? widget.people : widget.people.take(widget.maxVisible).toList();
    final overflow = widget.people.length - widget.maxVisible;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final name in visible)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              children: [
                const Icon(
                  Icons.person,
                  size: 12,
                  color: TmzColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: TmzColors.white,
                      height: 1.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        // Show "+N more" tap target when collapsed, or "Show less" when expanded
        if (overflow > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 12,
                    color: TmzColors.tmzRed,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _expanded ? 'Show less' : '+$overflow more',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: TmzColors.tmzRed,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Compact metadata row showing date, type, source.
class StreamMetaRow extends StatelessWidget {
  final DateTime date;
  final String? typeCode;
  final String? source;

  const StreamMetaRow({
    super.key,
    required this.date,
    this.typeCode,
    this.source,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Date
        Text(
          _formatDate(date),
          style: TmzTextStyles.caption.copyWith(fontSize: 10),
        ),
        if (typeCode != null) ...[
          const SizedBox(width: 8),
          StreamTypeBadge(typeCode: typeCode!),
        ],
        if (source != null) ...[
          const Spacer(),
          _SourceLabel(source: source!),
        ],
      ],
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

/// Source label (URL/File indicator).
class _SourceLabel extends StatelessWidget {
  final String source;

  const _SourceLabel({required this.source});

  @override
  Widget build(BuildContext context) {
    final isUrl = source == 'url';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isUrl ? Icons.link : Icons.upload_file,
          size: 10,
          color: TmzColors.textSecondary,
        ),
        const SizedBox(width: 2),
        Text(
          isUrl ? 'URL' : 'File',
          style: TmzTextStyles.caption.copyWith(
            fontSize: 9,
            color: TmzColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Action row with icon buttons for downloads and external link.
class StreamActionRow extends StatelessWidget {
  final JobModel job;
  final bool showDetails;

  const StreamActionRow({
    super.key,
    required this.job,
    this.showDetails = true,
  });

  Future<void> _downloadSummary(BuildContext context) async {
    final dataSource = GetIt.instance<IJobDataSource>();
    final url = dataSource.getSummaryDownloadUrl(job.jobId);
    await _launchUrl(context, url, 'summary');
  }

  Future<void> _downloadSrt(BuildContext context) async {
    final dataSource = GetIt.instance<IJobDataSource>();
    final url = dataSource.getSrtDownloadUrl(job.jobId);
    await _launchUrl(context, url, 'SRT');
  }

  Future<void> _openExternalLink(BuildContext context) async {
    if (job.sourceUrl != null) {
      final uri = Uri.tryParse(job.sourceUrl!);
      if (uri != null) {
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Could not open link'),
                backgroundColor: TmzColors.error,
              ),
            );
          }
        }
      }
    }
  }

  Future<void> _launchUrl(BuildContext context, String url, String type) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not download $type'),
              backgroundColor: TmzColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = job.isCompleted;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Summary download
        _ActionIconButton(
          icon: Icons.summarize_outlined,
          tooltip: isCompleted ? 'Download Summary' : 'Summary (not ready)',
          enabled: isCompleted,
          onTap: () => _downloadSummary(context),
        ),
        // SRT download
        _ActionIconButton(
          icon: Icons.subtitles_outlined,
          tooltip: isCompleted ? 'Download SRT' : 'SRT (not ready)',
          enabled: isCompleted,
          onTap: () => _downloadSrt(context),
        ),
        // External link (only if URL source)
        if (job.source == 'url' && job.sourceUrl != null)
          _ActionIconButton(
            icon: Icons.open_in_new,
            tooltip: 'Open Source URL',
            enabled: true,
            onTap: () => _openExternalLink(context),
          ),
      ],
    );
  }
}

/// Individual action icon button with hover feedback.
class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onTap;

  const _ActionIconButton({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 18,
            color: enabled ? TmzColors.textSecondary : TmzColors.gray70,
          ),
        ),
      ),
    );
  }
}

/// Progress overlay for processing jobs.
class StreamProgressOverlay extends StatelessWidget {
  final int progressPct;

  const StreamProgressOverlay({super.key, required this.progressPct});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: Colors.black.withValues(alpha:0.7),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '$progressPct%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          LinearProgressIndicator(
            value: progressPct / 100,
            minHeight: 3,
            backgroundColor: Colors.black38,
            valueColor: const AlwaysStoppedAnimation<Color>(TmzColors.tmzRed),
          ),
        ],
      ),
    );
  }
}

/// Skeleton loader for grid card thumbnail.
class StreamCardSkeleton extends StatelessWidget {
  const StreamCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      color: TmzColors.gray90,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail skeleton
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(color: TmzColors.gray80),
          ),
          // Content skeleton
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title skeleton
                  Container(
                    height: 14,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: TmzColors.gray80,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 14,
                    width: 120,
                    decoration: BoxDecoration(
                      color: TmzColors.gray80,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Spacer(),
                  // Meta skeleton
                  Container(
                    height: 10,
                    width: 80,
                    decoration: BoxDecoration(
                      color: TmzColors.gray80,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Flag indicator overlay for flagged jobs.
class StreamFlagIndicator extends StatelessWidget {
  const StreamFlagIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha:0.6),
        borderRadius: BorderRadius.circular(2),
      ),
      child: const Icon(
        Icons.flag,
        size: 14,
        color: Colors.orange,
      ),
    );
  }
}

/// Helper to extract executive summary from JSON summary.
String? extractExecutiveSummary(String? raw) {
  if (raw == null) return null;
  if (raw.trimLeft().startsWith('{')) {
    try {
      final parsed = jsonDecode(raw) as Map<String, dynamic>;
      final execSummary = parsed['executive_summary'] as String?;
      if (execSummary != null && execSummary.isNotEmpty) {
        return execSummary;
      }
    } catch (_) {
      // Not valid JSON
    }
  }
  return raw;
}
