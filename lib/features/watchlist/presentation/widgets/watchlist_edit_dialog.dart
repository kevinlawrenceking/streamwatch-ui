import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/guest_watchlist_entry.dart';
import '../../data/models/patch_guest_watchlist_request.dart';
import '../bloc/watchlist_bloc.dart';

/// Modal dialog for editing a watchlist entry's allowlisted fields.
/// Per KB section 18f.6: only guest_name, aliases, reason, priority
/// are exposed. Forbidden fields (status, matched_episode_id, matched_at,
/// expires_at) are NOT present in this form -- AC-5 verifies this.
class WatchlistEditDialog extends StatefulWidget {
  final PodcastGuestWatchlistEntry entry;

  const WatchlistEditDialog({super.key, required this.entry});

  @override
  State<WatchlistEditDialog> createState() => _WatchlistEditDialogState();
}

class _WatchlistEditDialogState extends State<WatchlistEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _guestNameCtrl;
  late final TextEditingController _aliasesCtrl;
  late final TextEditingController _reasonCtrl;
  late String _priority;

  @override
  void initState() {
    super.initState();
    _guestNameCtrl = TextEditingController(text: widget.entry.guestName);
    _aliasesCtrl = TextEditingController(text: widget.entry.aliases.join(', '));
    _reasonCtrl = TextEditingController(text: widget.entry.reason ?? '');
    _priority = widget.entry.priority;
  }

  @override
  void dispose() {
    _guestNameCtrl.dispose();
    _aliasesCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final newGuest = _guestNameCtrl.text.trim();
    final newAliases = _aliasesCtrl.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final newReason = _reasonCtrl.text.trim();

    final request = PatchGuestWatchlistEntryRequest(
      guestName: newGuest != widget.entry.guestName ? newGuest : null,
      aliases:
          !_listsEqual(newAliases, widget.entry.aliases) ? newAliases : null,
      reason: newReason != (widget.entry.reason ?? '')
          ? (newReason.isEmpty ? null : newReason)
          : null,
      priority: _priority != widget.entry.priority ? _priority : null,
    );
    if (!request.hasAnyField) {
      Navigator.of(context).pop();
      return;
    }
    context.read<WatchlistBloc>().add(PatchWatchlistEntryEvent(
          entryId: widget.entry.id,
          request: request,
        ));
    Navigator.of(context).pop();
  }

  bool _listsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit watchlist entry'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _guestNameCtrl,
                decoration: const InputDecoration(labelText: 'Guest name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _aliasesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Aliases (comma-separated)',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _reasonCtrl,
                decoration: const InputDecoration(labelText: 'Reason'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _priority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: const [
                  DropdownMenuItem(value: 'high', child: Text('High')),
                  DropdownMenuItem(value: 'medium', child: Text('Medium')),
                  DropdownMenuItem(value: 'low', child: Text('Low')),
                ],
                onChanged: (v) => setState(() => _priority = v ?? _priority),
              ),
            ],
          ),
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
          child: const Text('Save'),
        ),
      ],
    );
  }
}
