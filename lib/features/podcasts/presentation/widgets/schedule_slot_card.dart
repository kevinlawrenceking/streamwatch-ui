import 'package:flutter/material.dart';

import '../../../../themes/app_theme.dart';
import '../../data/models/podcast_schedule.dart';

/// Card widget for displaying a podcast schedule slot.
class ScheduleSlotCard extends StatelessWidget {
  final PodcastScheduleModel schedule;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ScheduleSlotCard({
    super.key,
    required this.schedule,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(
              Icons.schedule,
              color: AppColors.warning,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _capitalize(schedule.dayOfWeek),
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${schedule.startTime} - ${schedule.endTime}',
                    style: Theme.of(context).textTheme.bodySmall!,
                  ),
                  Text(
                    schedule.timezone,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: AppColors.textDim,
                          fontSize: 10,
                        ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              tooltip: 'Edit',
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              tooltip: 'Delete',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
