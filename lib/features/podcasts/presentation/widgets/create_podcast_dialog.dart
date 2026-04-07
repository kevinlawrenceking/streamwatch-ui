import 'package:flutter/material.dart';

import '../../../../themes/app_theme.dart';

/// Dialog for creating a new podcast.
class CreatePodcastDialog extends StatefulWidget {
  const CreatePodcastDialog({super.key});

  @override
  State<CreatePodcastDialog> createState() => _CreatePodcastDialogState();
}

class _CreatePodcastDialogState extends State<CreatePodcastDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Podcast'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Podcast Name',
                hintText: 'Enter podcast name',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Name is required';
                }
                return null;
              },
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Enter description (optional)',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: AppColors.tmzRed),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final body = <String, dynamic>{
                'name': _nameController.text.trim(),
              };
              final desc = _descriptionController.text.trim();
              if (desc.isNotEmpty) {
                body['description'] = desc;
              }
              Navigator.of(context).pop(body);
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}
