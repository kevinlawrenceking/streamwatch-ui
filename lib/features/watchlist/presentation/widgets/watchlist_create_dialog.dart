import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/watchlist_bloc.dart';

/// Modal dialog for creating a new watchlist entry. 4 fields:
/// guest_name (required), aliases (comma-separated), reason, priority.
/// Server forces status='active' and populates created_by from auth.
class WatchlistCreateDialog extends StatefulWidget {
  const WatchlistCreateDialog({super.key});

  @override
  State<WatchlistCreateDialog> createState() => _WatchlistCreateDialogState();
}

class _WatchlistCreateDialogState extends State<WatchlistCreateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _guestNameCtrl = TextEditingController();
  final _aliasesCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  String _priority = 'medium';

  @override
  void dispose() {
    _guestNameCtrl.dispose();
    _aliasesCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final aliases = _aliasesCtrl.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final body = <String, dynamic>{
      'guest_name': _guestNameCtrl.text.trim(),
      'aliases': aliases,
      if (_reasonCtrl.text.trim().isNotEmpty) 'reason': _reasonCtrl.text.trim(),
      'priority': _priority,
    };
    context.read<WatchlistBloc>().add(CreateWatchlistEntryEvent(body));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add watchlist entry'),
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
                onChanged: (v) => setState(() => _priority = v ?? 'medium'),
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
          child: const Text('Create'),
        ),
      ],
    );
  }
}
