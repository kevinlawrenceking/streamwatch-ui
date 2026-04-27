import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../themes/app_theme.dart';
import '../../data/data_sources/detection_data_source.dart';
import '../bloc/detection_bloc.dart';

/// Batch-trigger detection dialog (Plan-Lock #6).
///
/// User pastes one episode id per line (or comma-separated). Live count
/// is shown; submit is disabled when count exceeds
/// [IDetectionDataSource.detectionBatchMaxItems] = 50, with the L-5
/// warning text "Maximum 50 episodes per batch" sourced from the const,
/// not a magic number.
class BatchTriggerDialog extends StatefulWidget {
  const BatchTriggerDialog({super.key});

  @override
  State<BatchTriggerDialog> createState() => _BatchTriggerDialogState();
}

class _BatchTriggerDialogState extends State<BatchTriggerDialog> {
  final _ctrl = TextEditingController();
  List<String> _ids = const [];

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_recompute);
  }

  @override
  void dispose() {
    _ctrl.removeListener(_recompute);
    _ctrl.dispose();
    super.dispose();
  }

  void _recompute() {
    final ids = _ctrl.text
        .split(RegExp(r'[\s,]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    setState(() => _ids = ids);
  }

  void _submit() {
    if (_ids.length > IDetectionDataSource.detectionBatchMaxItems) return;
    if (_ids.isEmpty) return;
    context.read<DetectionBloc>().add(BatchTriggerEvent(_ids));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cap = IDetectionDataSource.detectionBatchMaxItems;
    final overCap = _ids.length > cap;
    return AlertDialog(
      title: const Text('Batch trigger detection'),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paste episode ids -- one per line or comma-separated.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _ctrl,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'Episode ids',
                hintText: 'ep-1\nep-2\nep-3',
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${_ids.length} / $cap',
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: overCap ? AppColors.error : AppColors.textDim,
                      ),
                ),
                if (overCap) ...[
                  const SizedBox(width: 12),
                  Text(
                    'Maximum 50 episodes per batch',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall!
                        .copyWith(color: AppColors.error),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
          onPressed: (overCap || _ids.isEmpty) ? null : _submit,
          child: Text('Trigger ${_ids.length}'),
        ),
      ],
    );
  }
}
