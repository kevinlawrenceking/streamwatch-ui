import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:streamwatch_frontend/features/jobs/data/models/batch_trigger_result.dart';
import 'package:streamwatch_frontend/features/jobs/presentation/bloc/detection_bloc.dart';
import 'package:streamwatch_frontend/features/jobs/presentation/widgets/batch_result_dialog.dart';
import 'package:streamwatch_frontend/themes/app_theme.dart';

class MockDetectionBloc extends MockBloc<DetectionEvent, DetectionState>
    implements DetectionBloc {}

Widget _harness(DetectionBloc bloc, List<BatchTriggerItemResult> results) =>
    MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: BlocProvider<DetectionBloc>.value(
          value: bloc,
          child: BatchResultDialog(results: results),
        ),
      ),
    );

void main() {
  setUpAll(() {
    registerFallbackValue(const BatchResultAcknowledgedEvent());
  });

  late MockDetectionBloc bloc;
  setUp(() {
    bloc = MockDetectionBloc();
    when(() => bloc.state).thenReturn(const DetectionLoaded(runs: []));
  });

  testWidgets('mixed results render success / 409 / 404 rows', (tester) async {
    await tester.pumpWidget(_harness(bloc, const [
      BatchTriggerItemResult(episodeId: 'ep-1', status: 202, runId: 'r-1'),
      BatchTriggerItemResult(
          episodeId: 'ep-2', status: 409, errorCode: 'ALREADY_ACTIVE'),
      BatchTriggerItemResult(
          episodeId: 'ep-3', status: 404, errorCode: 'EPISODE_NOT_FOUND'),
    ]));
    expect(find.text('Batch result: 1 / 3 queued'), findsOneWidget);
    expect(find.text('ep-1'), findsOneWidget);
    expect(find.text('ep-2'), findsOneWidget);
    expect(find.text('ep-3'), findsOneWidget);
    expect(find.textContaining('ALREADY_ACTIVE'), findsOneWidget);
    expect(find.textContaining('EPISODE_NOT_FOUND'), findsOneWidget);
  });

  testWidgets('all-success render shows N / N queued', (tester) async {
    await tester.pumpWidget(_harness(bloc, const [
      BatchTriggerItemResult(episodeId: 'ep-1', status: 202, runId: 'r-1'),
      BatchTriggerItemResult(episodeId: 'ep-2', status: 202, runId: 'r-2'),
    ]));
    expect(find.text('Batch result: 2 / 2 queued'), findsOneWidget);
  });

  testWidgets('all-error render shows 0 / N queued', (tester) async {
    await tester.pumpWidget(_harness(bloc, const [
      BatchTriggerItemResult(
          episodeId: 'ep-1', status: 409, errorCode: 'ALREADY_ACTIVE'),
      BatchTriggerItemResult(
          episodeId: 'ep-2', status: 404, errorCode: 'EPISODE_NOT_FOUND'),
    ]));
    expect(find.text('Batch result: 0 / 2 queued'), findsOneWidget);
  });
}
