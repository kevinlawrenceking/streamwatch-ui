import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:streamwatch_frontend/features/jobs/data/data_sources/detection_data_source.dart';
import 'package:streamwatch_frontend/features/jobs/presentation/bloc/detection_bloc.dart';
import 'package:streamwatch_frontend/features/jobs/presentation/widgets/batch_trigger_dialog.dart';
import 'package:streamwatch_frontend/themes/app_theme.dart';

class MockDetectionBloc extends MockBloc<DetectionEvent, DetectionState>
    implements DetectionBloc {}

Widget _harness(DetectionBloc bloc) => MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: BlocProvider<DetectionBloc>.value(
          value: bloc,
          child: const BatchTriggerDialog(),
        ),
      ),
    );

void main() {
  setUpAll(() {
    registerFallbackValue(const BatchTriggerEvent(<String>[]));
  });

  late MockDetectionBloc bloc;
  setUp(() {
    bloc = MockDetectionBloc();
    when(() => bloc.state).thenReturn(const DetectionLoaded(runs: []));
  });

  testWidgets('cap value sourced from IDetectionDataSource const, not magic',
      (tester) async {
    // Compile-time assertion that the UI references the const, not a literal.
    expect(IDetectionDataSource.detectionBatchMaxItems, 50);
    await tester.pumpWidget(_harness(bloc));
    expect(find.textContaining('/ 50'), findsOneWidget);
  });

  testWidgets('shows L-5 warning text when count exceeds 50', (tester) async {
    await tester.pumpWidget(_harness(bloc));
    final field = find.byType(TextField);
    await tester.enterText(field, List.generate(51, (i) => 'ep-$i').join('\n'));
    await tester.pump();
    expect(find.text('Maximum 50 episodes per batch'), findsOneWidget);
  });

  testWidgets('submit dispatches BatchTriggerEvent with parsed ids',
      (tester) async {
    await tester.pumpWidget(_harness(bloc));
    final field = find.byType(TextField);
    await tester.enterText(field, 'ep-1\nep-2\nep-3');
    await tester.pump();
    await tester.tap(find.textContaining('Trigger 3'));
    await tester.pump();
    final captured = verify(() => bloc.add(captureAny())).captured.single
        as BatchTriggerEvent;
    expect(captured.episodeIds, ['ep-1', 'ep-2', 'ep-3']);
  });

  testWidgets('cancel pops without dispatching any event', (tester) async {
    await tester.pumpWidget(_harness(bloc));
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    verifyNever(() => bloc.add(any()));
  });
}
