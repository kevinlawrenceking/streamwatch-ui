import 'package:flutter/material.dart';
import '../../../themes/app_theme.dart';

/// A summary stat card for the scheduler dashboard.
class SchedulerSummaryCard extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;

  const SchedulerSummaryCard({
    super.key,
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: AppColors.textDim,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
