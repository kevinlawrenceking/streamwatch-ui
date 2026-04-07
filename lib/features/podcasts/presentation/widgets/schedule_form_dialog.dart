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

const _timezones = [
  'America/Los_Angeles',
  'America/Denver',
  'America/Chicago',
  'America/New_York',
  'UTC',
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
  late TimeOfDay _endTime;
  late String _selectedTimezone;

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.existing?.dayOfWeek ?? 'monday';
    _startTime = _parseTime(widget.existing?.startTime ?? '09:00');
    _endTime = _parseTime(widget.existing?.endTime ?? '10:00');
    _selectedTimezone =
        widget.existing?.timezone ?? 'America/Los_Angeles';
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

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null) {
      setState(() => _endTime = picked);
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
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickStartTime,
                    child: InputDecorator(
                      decoration:
                          const InputDecoration(labelText: 'Start Time'),
                      child: Text(
                        _formatTime(_startTime),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: _pickEndTime,
                    child: InputDecorator(
                      decoration:
                          const InputDecoration(labelText: 'End Time'),
                      child: Text(
                        _formatTime(_endTime),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedTimezone,
              decoration: const InputDecoration(labelText: 'Timezone'),
              items: _timezones
                  .map((tz) => DropdownMenuItem(
                        value: tz,
                        child: Text(tz),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedTimezone = value);
                }
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
              final startStr = _formatTime(_startTime);
              final endStr = _formatTime(_endTime);

              if (startStr.compareTo(endStr) >= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('End time must be after start time'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              Navigator.of(context).pop(<String, dynamic>{
                'day_of_week': _selectedDay,
                'start_time': startStr,
                'end_time': endStr,
                'timezone': _selectedTimezone,
              });
            }
          },
          child: Text(isEdit ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}
