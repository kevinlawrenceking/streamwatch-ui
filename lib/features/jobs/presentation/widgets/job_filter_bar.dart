import 'package:flutter/material.dart';

import '../../../../themes/app_theme.dart';

/// Filter bar for the Jobs tab. Status dropdown + podcast id input.
class JobFilterBar extends StatelessWidget {
  final String? selectedStatus;
  final TextEditingController podcastCtrl;
  final ValueChanged<String?> onStatusChanged;
  final VoidCallback onApply;
  final VoidCallback onClear;

  const JobFilterBar({
    super.key,
    required this.selectedStatus,
    required this.podcastCtrl,
    required this.onStatusChanged,
    required this.onApply,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        border: const Border(
          bottom: BorderSide(color: AppColors.textGhost, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String?>(
              value: selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Status',
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('All')),
                DropdownMenuItem(value: 'queued', child: Text('Queued')),
                DropdownMenuItem(value: 'running', child: Text('Running')),
                DropdownMenuItem(value: 'completed', child: Text('Completed')),
                DropdownMenuItem(value: 'failed', child: Text('Failed')),
              ],
              onChanged: onStatusChanged,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: TextField(
              controller: podcastCtrl,
              decoration: const InputDecoration(
                labelText: 'Podcast id',
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(onPressed: onApply, child: const Text('Apply')),
          const SizedBox(width: 8),
          TextButton(onPressed: onClear, child: const Text('Clear')),
        ],
      ),
    );
  }
}
