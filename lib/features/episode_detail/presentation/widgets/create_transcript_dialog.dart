import 'package:flutter/material.dart';

/// Dialog form for creating a new transcript. Required: variant + source_type.
/// Optional: text (free-form), language_code.
class CreateTranscriptDialog extends StatefulWidget {
  const CreateTranscriptDialog({super.key});

  @override
  State<CreateTranscriptDialog> createState() => _CreateTranscriptDialogState();
}

class _CreateTranscriptDialogState extends State<CreateTranscriptDialog> {
  final _variantCtrl = TextEditingController();
  final _sourceTypeCtrl = TextEditingController();
  final _textCtrl = TextEditingController();
  final _langCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _variantCtrl.dispose();
    _sourceTypeCtrl.dispose();
    _textCtrl.dispose();
    _langCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final body = <String, dynamic>{
      'variant': _variantCtrl.text.trim(),
      'source_type': _sourceTypeCtrl.text.trim(),
      if (_textCtrl.text.trim().isNotEmpty) 'text': _textCtrl.text.trim(),
      if (_langCtrl.text.trim().isNotEmpty)
        'language_code': _langCtrl.text.trim(),
    };
    Navigator.of(context).pop(body);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Transcript'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const Key('create_transcript.variant'),
                controller: _variantCtrl,
                decoration: const InputDecoration(labelText: 'Variant'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('create_transcript.source_type'),
                controller: _sourceTypeCtrl,
                decoration: const InputDecoration(labelText: 'Source Type'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('create_transcript.text'),
                controller: _textCtrl,
                decoration: const InputDecoration(labelText: 'Text (optional)'),
                maxLines: 4,
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('create_transcript.language_code'),
                controller: _langCtrl,
                decoration: const InputDecoration(
                    labelText: 'Language Code (optional)'),
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
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Create'),
        ),
      ],
    );
  }
}
