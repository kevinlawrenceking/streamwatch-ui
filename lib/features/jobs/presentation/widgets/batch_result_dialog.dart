import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../themes/app_theme.dart';
import '../../data/models/batch_trigger_result.dart';
import '../bloc/detection_bloc.dart';

/// Renders the per-item results of a 207 Multi-Status batch-trigger
/// response. AC-14 verifies mixed (success + 409 + 404) render. Close
/// dispatches BatchResultAcknowledgedEvent which clears the result and
/// fires LoadDetectionRunsEvent for refetch (toast L-6 close path).
class BatchResultDialog extends StatelessWidget {
  final List<BatchTriggerItemResult> results;

  const BatchResultDialog({super.key, required this.results});

  Color _colorFor(int status) {
    if (status == 202) return AppColors.success;
    if (status == 409 || status == 404) return AppColors.warning;
    return AppColors.error;
  }

  IconData _iconFor(int status) {
    if (status == 202) return Icons.check_circle;
    if (status == 409) return Icons.lock_clock;
    if (status == 404) return Icons.search_off;
    return Icons.error_outline;
  }

  @override
  Widget build(BuildContext context) {
    final successes = results.where((r) => r.isSuccess).length;
    return AlertDialog(
      title: Text('Batch result: $successes / ${results.length} queued'),
      content: SizedBox(
        width: 520,
        height: 420,
        child: ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final r = results[index];
            final color = _colorFor(r.status);
            return ListTile(
              leading: Icon(_iconFor(r.status), color: color),
              title: Text(r.episodeId),
              subtitle: Text(
                r.isSuccess
                    ? 'run ${r.runId ?? "?"}'
                    : '[${r.errorCode ?? "ERROR"}] HTTP ${r.status}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  border: Border.all(color: color, width: 1),
                ),
                child: Text(
                  '${r.status}',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall!
                      .copyWith(color: color, fontWeight: FontWeight.w700),
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
          onPressed: () {
            context
                .read<DetectionBloc>()
                .add(const BatchResultAcknowledgedEvent());
            Navigator.of(context).pop();
          },
          child: const Text('Close'),
        ),
      ],
    );
  }
}
