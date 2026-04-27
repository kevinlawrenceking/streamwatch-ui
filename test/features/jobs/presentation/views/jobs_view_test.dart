import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:streamwatch_frontend/features/jobs/data/models/detection_run.dart';
import 'package:streamwatch_frontend/features/jobs/data/models/podcast_job.dart';
import 'package:streamwatch_frontend/features/jobs/presentation/bloc/detection_bloc.dart';
import 'package:streamwatch_frontend/features/jobs/presentation/bloc/jobs_bloc.dart';
import 'package:streamwatch_frontend/features/jobs/presentation/views/jobs_view.dart';
import 'package:streamwatch_frontend/themes/app_theme.dart';

class MockJobsBloc extends MockBloc<JobsEvent, JobsState> implements JobsBloc {}

class MockDetectionBloc extends MockBloc<DetectionEvent, DetectionState>
    implements DetectionBloc {}

PodcastJob _job(String id) => PodcastJob(
      jobId: id,
      status: 'failed',
      title: 'Job $id',
      createdAt: DateTime.utc(2026, 4, 25),
    );

DetectionRun _run(String id) => DetectionRun(
      id: id,
      episodeId: 'ep-1',
      status: 'queued',
      createdAt: DateTime.utc(2026, 4, 25),
      updatedAt: DateTime.utc(2026, 4, 25),
    );

Widget _harness({required JobsBloc jobs, required DetectionBloc detection}) =>
    MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: MultiBlocProvider(
          providers: [
            BlocProvider<JobsBloc>.value(value: jobs),
            BlocProvider<DetectionBloc>.value(value: detection),
          ],
          child: const JobsView(),
        ),
      ),
    );

void main() {
  late MockJobsBloc jobsBloc;
  late MockDetectionBloc detectionBloc;

  setUp(() {
    jobsBloc = MockJobsBloc();
    detectionBloc = MockDetectionBloc();
  });

  testWidgets('Loading scaffold when both blocs are loading', (tester) async {
    when(() => jobsBloc.state).thenReturn(const JobsLoading());
    when(() => detectionBloc.state).thenReturn(const DetectionLoading());
    await tester.pumpWidget(_harness(jobs: jobsBloc, detection: detectionBloc));
    expect(find.byType(CircularProgressIndicator), findsWidgets);
  });

  testWidgets('renders both Jobs and Detection tabs in the tab bar',
      (tester) async {
    when(() => jobsBloc.state).thenReturn(JobsLoaded(jobs: const []));
    when(() => detectionBloc.state).thenReturn(const DetectionLoaded(runs: []));
    await tester.pumpWidget(_harness(jobs: jobsBloc, detection: detectionBloc));
    expect(find.text('Jobs'), findsWidgets);
    expect(find.text('Detection'), findsWidgets);
  });

  testWidgets('Jobs tab renders jobs list rows', (tester) async {
    when(() => jobsBloc.state).thenReturn(JobsLoaded(jobs: [_job('j-1')]));
    when(() => detectionBloc.state).thenReturn(const DetectionLoaded(runs: []));
    await tester.pumpWidget(_harness(jobs: jobsBloc, detection: detectionBloc));
    await tester.pumpAndSettle();
    expect(find.text('Job j-1'), findsOneWidget);
  });

  testWidgets('Detection tab renders run rows when active', (tester) async {
    // DetectionFilterBar packs 6 horizontal widgets (status dropdown +
    // episode input + Apply + Clear + Batch trigger) -- needs >=1280
    // logical pixels to render without RenderFlex overflow in tests.
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    when(() => jobsBloc.state).thenReturn(JobsLoaded(jobs: const []));
    when(() => detectionBloc.state)
        .thenReturn(DetectionLoaded(runs: [_run('r-1')]));
    await tester.pumpWidget(_harness(jobs: jobsBloc, detection: detectionBloc));
    await tester.pumpAndSettle();
    // Switch to Detection tab.
    await tester.tap(find.text('Detection').last);
    await tester.pumpAndSettle();
    expect(find.text('episode ep-1'), findsOneWidget);
  });
}
