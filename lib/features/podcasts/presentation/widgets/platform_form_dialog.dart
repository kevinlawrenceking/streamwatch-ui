import 'package:flutter/material.dart';

import '../../../../themes/app_theme.dart';
import '../../data/models/podcast_platform.dart';

/// Dialog for creating or editing a podcast platform link.
class PlatformFormDialog extends StatefulWidget {
  final PodcastPlatformModel? existing;

  const PlatformFormDialog({super.key, this.existing});

  @override
  State<PlatformFormDialog> createState() => _PlatformFormDialogState();
}

class _PlatformFormDialogState extends State<PlatformFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.existing?.platformName ?? '');
    _urlController =
        TextEditingController(text: widget.existing?.platformUrl ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return AlertDialog(
      title: Text(isEdit ? 'Edit Platform' : 'Add Platform'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Platform Name',
                hintText: 'e.g. Spotify, Apple Podcasts',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Platform name is required';
                }
                return null;
              },
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Platform URL',
                hintText: 'https://...',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'URL is required';
                }
                final uri = Uri.tryParse(value.trim());
                if (uri == null || !uri.hasScheme) {
                  return 'Enter a valid URL';
                }
                return null;
              },
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
              Navigator.of(context).pop(<String, dynamic>{
                'platform_name': _nameController.text.trim(),
                'platform_url': _urlController.text.trim(),
              });
            }
          },
          child: Text(isEdit ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}
