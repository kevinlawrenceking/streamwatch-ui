import 'package:flutter/material.dart';

import '../../../../themes/app_theme.dart';

/// Filter bar for the Detection tab. Status dropdown + episode id input.
class DetectionFilterBar extends StatelessWidget {
  final String? selectedStatus;
  final TextEditingController episodeCtrl;
  final ValueChanged<String?> onStatusChanged;
  final VoidCallback onApply;
  final VoidCallback onClear;
  final VoidCallback onBatchTrigger;

  const DetectionFilterBar({
    super.key,
    required this.selectedStatus,
    required this.episodeCtrl,
    required this.onStatusChanged,
    required this.onApply,
    required this.onClear,
    required this.onBatchTrigger,
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
                DropdownMenuItem(value: 'succeeded', child: Text('Succeeded')),
                DropdownMenuItem(value: 'failed', child: Text('Failed')),
              ],
              onChanged: onStatusChanged,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: TextField(
              controller: episodeCtrl,
              decoration: const InputDecoration(
                labelText: 'Episode id',
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(onPressed: onApply, child: const Text('Apply')),
          const SizedBox(width: 8),
          TextButton(onPressed: onClear, child: const Text('Clear')),
          const SizedBox(width: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            icon: const Icon(Icons.layers, size: 16),
            label: const Text('Batch trigger'),
            onPressed: onBatchTrigger,
          ),
        ],
      ),
    );
  }
}
