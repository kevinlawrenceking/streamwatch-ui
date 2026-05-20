import 'package:flutter/material.dart';

import '../../../../themes/app_theme.dart';
import '../../data/models/podcast_schedule.dart';

const _daysOfWeek = [
  'monday',
  'tuesday',
  'wednesday',
  'thursday',
  'friday',
  'saturday',
  'sunday',
];

/// Dialog for creating or editing a podcast schedule slot.
class ScheduleFormDialog extends StatefulWidget {
  final PodcastScheduleModel? existing;

  const ScheduleFormDialog({super.key, this.existing});

  @override
  State<ScheduleFormDialog> createState() => _ScheduleFormDialogState();
}

class _ScheduleFormDialogState extends State<ScheduleFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _selectedDay;
  late TimeOfDay _startTime;

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.existing?.dayOfWeek ?? 'monday';
    _startTime = _parseTime(widget.existing?.startTime ?? '09:00');
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 0,
      minute: parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0,
    );
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return AlertDialog(
      title: Text(isEdit ? 'Edit Schedule' : 'Add Schedule'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedDay,
              decoration: const InputDecoration(labelText: 'Day of Week'),
              items: _daysOfWeek
                  .map((d) => DropdownMenuItem(
                        value: d,
                        child: Text(_capitalize(d)),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedDay = value);
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickStartTime,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Start Time (PT)'),
                child: Text(
                  _formatTime(_startTime),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
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
        TextButton(
          style: TextButton.styleFrom(foregroundColor: AppColors.tmzRed),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop(<String, dynamic>{
                'day_of_week': _selectedDay,
                'start_time_pt': _formatTime(_startTime),
              });
            }
          },
          child: Text(isEdit ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}
