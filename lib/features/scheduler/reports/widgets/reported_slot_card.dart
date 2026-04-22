import 'package:flutter/material.dart';

import '../../../../themes/app_theme.dart';
import '../data/models/podcast_schedule_slot.dart';

/// Row presentation for a PodcastScheduleSlot in a slot-valued drill-down.
class ReportedSlotCard extends StatelessWidget {
  final PodcastScheduleSlot slot;
  final Color accentColor;

  const ReportedSlotCard({
    super.key,
    required this.slot,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _statusBar(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _primaryLine(),
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _secondaryLine(),
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: AppColors.textDim,
                          fontSize: 11,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!slot.isActive)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  'INACTIVE',
                  style: Theme.of(context).textTheme.labelSmall!.copyWith(
                        color: AppColors.textGhost,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statusBar() {
    return Container(
      width: 4,
      height: 40,
      decoration: BoxDecoration(
        color: accentColor,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  String _primaryLine() {
    final day = slot.dayOfWeek ?? '-';
    final time = slot.startTimePt ?? slot.timeTextRaw ?? '-';
    return '$day  $time PT';
  }

  String _secondaryLine() {
    final pieces = <String>[];
    pieces.add('src: ${slot.source.isEmpty ? 'unknown' : slot.source}');
    if (slot.latenessGraceMinutes != null) {
      pieces.add('grace ${slot.latenessGraceMinutes}m');
    }
    if (slot.scheduleConfidence != null && slot.scheduleConfidence!.isNotEmpty) {
      pieces.add('conf ${slot.scheduleConfidence}');
    }
    return pieces.join('  •  ');
  }
}
