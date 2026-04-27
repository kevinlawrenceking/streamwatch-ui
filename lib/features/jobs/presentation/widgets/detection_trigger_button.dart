import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/detection_bloc.dart';

/// Single-trigger CTA scoped to one episode_id. Dispatches
/// TriggerDetectionEvent. Disabled while DetectionBloc isMutating.
class DetectionTriggerButton extends StatelessWidget {
  final String episodeId;

  const DetectionTriggerButton({super.key, required this.episodeId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DetectionBloc, DetectionState>(
      buildWhen: (prev, curr) {
        final prevMut = prev is DetectionLoaded ? prev.isMutating : false;
        final currMut = curr is DetectionLoaded ? curr.isMutating : false;
        return prevMut != currMut;
      },
      builder: (context, state) {
        final disabled = state is DetectionLoaded ? state.isMutating : false;
        return FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
          icon: const Icon(Icons.play_arrow, size: 16),
          label: const Text('Trigger'),
          onPressed: disabled
              ? null
              : () => context
                  .read<DetectionBloc>()
                  .add(TriggerDetectionEvent(episodeId)),
        );
      },
    );
  }
}
