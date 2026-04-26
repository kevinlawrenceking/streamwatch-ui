import 'package:flutter/material.dart';

/// Dialog form for creating a new notification. Required: channel, subject,
/// body. Optional: recipient (overrides default for slack channel; required
/// for ses channel server-side -- 400 surfaced if missing).
class CreateNotificationDialog extends StatefulWidget {
  const CreateNotificationDialog({super.key});

  @override
  State<CreateNotificationDialog> createState() =>
      _CreateNotificationDialogState();
}

class _CreateNotificationDialogState extends State<CreateNotificationDialog> {
  String _channel = 'slack';
  final _recipientCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _recipientCtrl.dispose();
    _subjectCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final body = <String, dynamic>{
      'channel': _channel,
      if (_recipientCtrl.text.trim().isNotEmpty)
        'recipient': _recipientCtrl.text.trim(),
      'subject': _subjectCtrl.text.trim(),
      'body': _bodyCtrl.text.trim(),
    };
    Navigator.of(context).pop(body);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Notification'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                key: const Key('create_notification.channel'),
                value: _channel,
                items: const [
                  DropdownMenuItem(value: 'slack', child: Text('Slack')),
                  DropdownMenuItem(value: 'ses', child: Text('Email (SES)')),
                ],
                decoration: const InputDecoration(labelText: 'Channel'),
                onChanged: (v) {
                  if (v != null) setState(() => _channel = v);
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('create_notification.recipient'),
                controller: _recipientCtrl,
                decoration: InputDecoration(
                  labelText: _channel == 'ses'
                      ? 'Recipient Email'
                      : 'Recipient (optional - uses default Slack webhook)',
                ),
                validator: (v) {
                  if (_channel == 'ses' && (v == null || v.trim().isEmpty)) {
                    return 'Required for SES';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('create_notification.subject'),
                controller: _subjectCtrl,
                decoration: const InputDecoration(labelText: 'Subject'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('create_notification.body'),
                controller: _bodyCtrl,
                decoration: const InputDecoration(labelText: 'Body'),
                maxLines: 4,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
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
