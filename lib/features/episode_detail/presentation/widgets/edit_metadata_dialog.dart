import 'package:flutter/material.dart';

import '../../../podcasts/data/models/podcast_episode.dart';

/// Dialog form for the Edit Metadata action. Submits a PATCH map containing
/// only fields that changed from the current episode (server is authoritative
/// for unchanged fields). Returns null on cancel; non-null Map<String,dynamic>
/// on submit.
class EditMetadataDialog extends StatefulWidget {
  final PodcastEpisodeModel episode;

  const EditMetadataDialog({super.key, required this.episode});

  @override
  State<EditMetadataDialog> createState() => _EditMetadataDialogState();
}

class _EditMetadataDialogState extends State<EditMetadataDialog> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _platformUrlCtrl;
  late final TextEditingController _platformTypeCtrl;
  late final TextEditingController _guestNamesCtrl;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.episode.title);
    _descCtrl =
        TextEditingController(text: widget.episode.episodeDescription ?? '');
    _platformUrlCtrl =
        TextEditingController(text: widget.episode.platformEpisodeUrl ?? '');
    _platformTypeCtrl =
        TextEditingController(text: widget.episode.platformType ?? '');
    _guestNamesCtrl = TextEditingController(
      text: (widget.episode.guestNames ?? const <String>[]).join(', '),
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _platformUrlCtrl.dispose();
    _platformTypeCtrl.dispose();
    _guestNamesCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildPatch() {
    final patch = <String, dynamic>{};
    final ep = widget.episode;

    if (_titleCtrl.text != ep.title) {
      patch['title'] = _titleCtrl.text;
    }
    if (_descCtrl.text != (ep.episodeDescription ?? '')) {
      patch['episode_description'] = _descCtrl.text;
    }
    if (_platformUrlCtrl.text != (ep.platformEpisodeUrl ?? '')) {
      patch['platform_episode_url'] = _platformUrlCtrl.text;
    }
    if (_platformTypeCtrl.text != (ep.platformType ?? '')) {
      patch['platform_type'] = _platformTypeCtrl.text;
    }
    final guestRaw = _guestNamesCtrl.text.trim();
    final guestList = guestRaw.isEmpty
        ? <String>[]
        : guestRaw
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
    final priorGuests = ep.guestNames ?? const <String>[];
    final guestsChanged = guestList.length != priorGuests.length ||
        !List.generate(guestList.length, (i) => guestList[i] == priorGuests[i])
            .every((b) => b);
    if (guestsChanged) {
      patch['guest_names'] = guestList;
    }
    return patch;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Episode Metadata'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('edit_metadata_dialog.title'),
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('edit_metadata_dialog.description'),
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('edit_metadata_dialog.platform_url'),
              controller: _platformUrlCtrl,
              decoration:
                  const InputDecoration(labelText: 'Platform Episode URL'),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('edit_metadata_dialog.platform_type'),
              controller: _platformTypeCtrl,
              decoration: const InputDecoration(labelText: 'Platform Type'),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('edit_metadata_dialog.guest_names'),
              controller: _guestNamesCtrl,
              decoration: const InputDecoration(
                labelText: 'Guest Names (comma separated)',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_buildPatch()),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
