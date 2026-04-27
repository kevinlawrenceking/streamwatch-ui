import 'package:flutter/material.dart';

import '../../../../themes/app_theme.dart';
import '../../data/models/detection_action.dart';

/// Renders a per-run actions list ordered by sequence_index ASC.
/// Server already returns the rows in order (KB section 18g.2 amendment 7),
/// so no client-side sort is needed.
class DetectionActionList extends StatelessWidget {
  final List<DetectionAction>? actions;

  const DetectionActionList({super.key, this.actions});

  @override
  Widget build(BuildContext context) {
    if (actions == null) {
      return const Padding(
        padding: EdgeInsets.all(8),
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (actions!.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          'No actions for this run.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: actions!.map((a) => _ActionRow(action: a)).toList(),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final DetectionAction action;
  const _ActionRow({required this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceOverlay, width: 1),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '#${action.sequenceIndex}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall!
                  .copyWith(color: AppColors.textDim),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action.actionType,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (action.resultCode != null)
                  Text(
                    'result: ${action.resultCode}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          Text(
            _formatTime(action.createdAt),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, "0")}:${dt.minute.toString().padLeft(2, "0")}:${dt.second.toString().padLeft(2, "0")}';
}
