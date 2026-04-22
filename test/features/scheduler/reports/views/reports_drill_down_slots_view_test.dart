import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:streamwatch_frontend/features/scheduler/reports/bloc/reported_slots_bloc.dart';
import 'package:streamwatch_frontend/features/scheduler/reports/data/models/podcast_schedule_slot.dart';
import 'package:streamwatch_frontend/features/scheduler/reports/views/reports_drill_down_slots_view.dart';
import 'package:streamwatch_frontend/features/scheduler/reports/widgets/reported_slot_card.dart';
import 'package:streamwatch_frontend/themes/app_theme.dart';

class FakeReportedSlotsBloc extends Bloc<ReportedSlotsEvent, ReportedSlotsState>
    implements ReportedSlotsBloc {
  FakeReportedSlotsBloc(super.seed) {
    on<FetchReportedSlotsEvent>((e, emit) {});
  }
}

PodcastScheduleSlot _slot(String id) => PodcastScheduleSlot(
      id: id,
      podcastId: 'p',
      source: 'csv_import',
      isActive: true,
      createdAt: DateTime(2026, 4, 20),
      updatedAt: DateTime(2026, 4, 20),
    );

Widget _host(ReportedSlotsState seed) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(
      body: BlocProvider<ReportedSlotsBloc>(
        create: (_) => FakeReportedSlotsBloc(seed),
        child: const ReportsDrillDownSlotsView(
          reportKey: 'expected-today',
          label: 'Expected Today',
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('renders loading spinner for Initial/Loading',
      (tester) async {
    await tester.pumpWidget(_host(const ReportedSlotsLoading()));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('renders empty state when slots list is empty', (tester) async {
    await tester.pumpWidget(_host(const ReportedSlotsLoaded(
      reportKey: 'expected-today',
      slots: [],
      hasMore: false,
    )));
    expect(find.text('No slots match this report.'), findsOneWidget);
  });

  testWidgets('renders ReportedSlotCard for each slot', (tester) async {
    await tester.pumpWidget(_host(ReportedSlotsLoaded(
      reportKey: 'expected-today',
      slots: [_slot('s1'), _slot('s2'), _slot('s3')],
      hasMore: false,
    )));
    expect(find.byType(ReportedSlotCard), findsNWidgets(3));
  });

  testWidgets('renders trailing spinner when hasMore is true',
      (tester) async {
    await tester.pumpWidget(_host(ReportedSlotsLoaded(
      reportKey: 'expected-today',
      slots: [_slot('s1')],
      hasMore: true,
    )));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows error panel on ReportedSlotsError', (tester) async {
    await tester
        .pumpWidget(_host(const ReportedSlotsError('network broke')));
    expect(find.text('network broke'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
