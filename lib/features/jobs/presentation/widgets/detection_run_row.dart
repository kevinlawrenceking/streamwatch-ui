import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../themes/app_theme.dart';
import '../../data/models/detection_action.dart';
import '../../data/models/detection_run.dart';
import '../bloc/detection_bloc.dart';
import 'detection_action_list.dart';

/// One row for a detection run. Plan-Lock #5 alpha (inline expansion):
/// uses ExpansionTile, lazily fires LoadDetectionActionsEvent on first
/// expand, re-uses cached actions on subsequent expand-collapse cycles.
class DetectionRunRow extends StatefulWidget {
  final DetectionRun run;
  final Map<String, List<DetectionAction>> actionsByRunId;

  const DetectionRunRow({
    super.key,
    required this.run,
    required this.actionsByRunId,
  });

  @override
  State<DetectionRunRow> createState() => _DetectionRunRowState();
}

class _DetectionRunRowState extends State<DetectionRunRow> {
  bool _hasFetchedOnce = false;

  Color _statusColor() {
    switch (widget.run.status) {
      case 'succeeded':
        return AppColors.success;
      case 'queued':
      case 'running':
        return AppColors.warning;
      case 'failed':
        return AppColors.error;
      default:
        return AppColors.textGhost;
    }
  }

  void _onExpansionChanged(bool expanded) {
    if (expanded && !_hasFetchedOnce) {
      _hasFetchedOnce = true;
      context
          .read<DetectionBloc>()
          .add(LoadDetectionActionsEvent(widget.run.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor();
    final actions = widget.actionsByRunId[widget.run.id];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ExpansionTile(
        onExpansionChanged: _onExpansionChanged,
        title: Row(
          children: [
            Expanded(
              child: Text(
                'episode ${widget.run.episodeId}',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall!
                    .copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            _StatusBadge(label: widget.run.status, color: statusColor),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('run ${widget.run.id}',
                  style: Theme.of(context).textTheme.bodySmall),
              if (widget.run.errorMessage != null)
                Text(
                  '[${widget.run.errorCode ?? "ERROR"}] ${widget.run.errorMessage!}',
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: AppColors.error,
                      ),
                ),
            ],
          ),
        ),
        children: [
          DetectionActionList(actions: actions),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.zero,
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall!.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}
