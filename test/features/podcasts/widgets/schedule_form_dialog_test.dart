import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:streamwatch_frontend/features/podcasts/data/models/podcast_schedule.dart';
import 'package:streamwatch_frontend/features/podcasts/presentation/widgets/schedule_form_dialog.dart';

// WO-112-RED / LSW-VER-T2 — Pattern A persistence guard for slot create (#9)
// and slot edit (#8d). Backend UpdateScheduleSlotRequest / CreateScheduleSlotRequest
// expose start_time_pt only; no end_time, no timezone. Pre-fix the form emitted
// start_time + end_time + timezone, all silently dropped by Go json.Decode.
// Post-fix the form emits start_time_pt only (+ day_of_week).

PodcastScheduleModel _slot() => const PodcastScheduleModel(
      id: 's-1',
      podcastId: 'p-1',
      dayOfWeek: 'tuesday',
      startTime: '19:00',
      endTime: '',
      timezone: 'America/Los_Angeles',
    );

Widget _harness({
  PodcastScheduleModel? existing,
  required ValueChanged<Map<String, dynamic>?> onResult,
}) =>
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () async {
              final result = await showDialog<Map<String, dynamic>>(
                context: ctx,
                builder: (_) => ScheduleFormDialog(existing: existing),
              );
              onResult(result);
            },
            child: const Text('open'),
          ),
        ),
      ),
    );

void main() {
  group('ScheduleFormDialog — Pattern A persistence guard', () {
    testWidgets('create mode: Add emits {day_of_week, start_time_pt} only',
        (tester) async {
      Map<String, dynamic>? captured;
      await tester.pumpWidget(_harness(onResult: (m) => captured = m));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(captured, isNotNull);
      expect(captured!.keys.toSet(), {'day_of_week', 'start_time_pt'});
      expect(captured!['day_of_week'], 'monday');
      expect(captured!['start_time_pt'], '09:00');
    });

    testWidgets('edit mode: Save emits {day_of_week, start_time_pt} only',
        (tester) async {
      Map<String, dynamic>? captured;
      await tester.pumpWidget(
          _harness(existing: _slot(), onResult: (m) => captured = m));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(captured, isNotNull);
      expect(captured!.keys.toSet(), {'day_of_week', 'start_time_pt'});
      expect(captured!['day_of_week'], 'tuesday');
      expect(captured!['start_time_pt'], '19:00');
    });

    testWidgets('form no longer renders end_time or timezone inputs',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ScheduleFormDialog(existing: _slot()),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('End Time'), findsNothing);
      expect(find.text('Timezone'), findsNothing);
      expect(find.text('Start Time (PT)'), findsOneWidget);
    });
  });
}
