import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/change_status_request.dart';
import '../../data/models/guest_watchlist_entry.dart';
import '../bloc/watchlist_bloc.dart';
import 'episode_picker_dialog.dart';

/// Modal dialog for the active -> {matched | expired} flip.
///
/// Cross-field validation mirrored from KB section 18f.5 LOCK H:
///   * matched -> requires matched_episode_id, forbids expires_at
///   * expired -> forbids matched_episode_id, optional expires_at
///
/// For the matched path, a Pick episode button opens
/// [EpisodePickerDialog]. The user enters a podcast id first to scope
/// the picker (no global episode listing exists in the backend yet).
class WatchlistChangeStatusDialog extends StatefulWidget {
  final PodcastGuestWatchlistEntry entry;

  const WatchlistChangeStatusDialog({super.key, required this.entry});

  @override
  State<WatchlistChangeStatusDialog> createState() =>
      _WatchlistChangeStatusDialogState();
}

class _WatchlistChangeStatusDialogState
    extends State<WatchlistChangeStatusDialog> {
  String _target = 'matched';
  final _podcastIdCtrl = TextEditingController();
  String? _matchedEpisodeId;

  @override
  void dispose() {
    _podcastIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickEpisode() async {
    final podcastId = _podcastIdCtrl.text.trim();
    if (podcastId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a podcast id first')),
      );
      return;
    }
    final picked = await showDialog<String>(
      context: context,
      builder: (_) => EpisodePickerDialog(podcastId: podcastId),
    );
    if (picked != null) {
      setState(() => _matchedEpisodeId = picked);
    }
  }

  void _submit() {
    final ChangeWatchlistStatusRequest request;
    if (_target == 'matched') {
      if (_matchedEpisodeId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pick a matched episode first')),
        );
        return;
      }
      request = ChangeWatchlistStatusRequest(
        status: 'matched',
        matchedEpisodeId: _matchedEpisodeId,
      );
    } else {
      request = const ChangeWatchlistStatusRequest(status: 'expired');
    }
    context.read<WatchlistBloc>().add(ChangeWatchlistStatusEvent(
          entryId: widget.entry.id,
          request: request,
        ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Change status: ${widget.entry.guestName}'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Matched'),
              value: 'matched',
              groupValue: _target,
              onChanged: (v) => setState(() => _target = v ?? 'matched'),
            ),
            RadioListTile<String>(
              title: const Text('Expired'),
              value: 'expired',
              groupValue: _target,
              onChanged: (v) => setState(() => _target = v ?? 'matched'),
            ),
            if (_target == 'matched') ...[
              const SizedBox(height: 8),
              TextField(
                controller: _podcastIdCtrl,
                decoration:
                    const InputDecoration(labelText: 'Podcast id (for picker)'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.search),
                    onPressed: _pickEpisode,
                    label: const Text('Pick episode'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _matchedEpisodeId ?? 'No episode selected',
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
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
          onPressed: _submit,
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
