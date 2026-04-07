import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:streamwatch_frontend/features/podcasts/data/models/podcast_schedule.dart';
import 'package:streamwatch_frontend/features/podcasts/presentation/widgets/schedule_slot_card.dart';

void main() {
  const testSchedule = PodcastScheduleModel(
    id: 's1',
    podcastId: 'p1',
    dayOfWeek: 'monday',
    startTime: '09:00',
    endTime: '10:00',
    timezone: 'America/Los_Angeles',
  );

  Widget buildTestWidget({VoidCallback? onEdit, VoidCallback? onDelete}) {
    return MaterialApp(
      home: Scaffold(
        body: ScheduleSlotCard(
          schedule: testSchedule,
          onEdit: onEdit,
          onDelete: onDelete,
        ),
      ),
    );
  }

  group('ScheduleSlotCard', () {
    testWidgets('displays day of week capitalized', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      expect(find.text('Monday'), findsOneWidget);
    });

    testWidgets('displays time range', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      expect(find.text('09:00 - 10:00'), findsOneWidget);
    });

    testWidgets('displays timezone', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      expect(find.text('America/Los_Angeles'), findsOneWidget);
    });

    testWidgets('calls onEdit when edit button is pressed',
        (tester) async {
      var edited = false;
      await tester
          .pumpWidget(buildTestWidget(onEdit: () => edited = true));
      await tester.tap(find.byTooltip('Edit'));
      expect(edited, isTrue);
    });

    testWidgets('calls onDelete when delete button is pressed',
        (tester) async {
      var deleted = false;
      await tester
          .pumpWidget(buildTestWidget(onDelete: () => deleted = true));
      await tester.tap(find.byTooltip('Delete'));
      expect(deleted, isTrue);
    });
  });
}
