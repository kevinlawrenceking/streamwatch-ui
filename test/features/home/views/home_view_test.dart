import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:streamwatch_frontend/data/models/job_model.dart';
import 'package:streamwatch_frontend/data/sources/job_data_source.dart';
import 'package:streamwatch_frontend/features/home/bloc/home_bloc.dart';
import 'package:streamwatch_frontend/features/home/bloc/home_event.dart';
import 'package:streamwatch_frontend/features/home/bloc/home_state.dart';

class MockJobDataSource extends Mock implements IJobDataSource {}

class MockHomeBloc extends Mock implements HomeBloc {}

class FakeHomeEvent extends Fake implements HomeEvent {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeHomeEvent());
  });

  late MockJobDataSource mockDataSource;
  late JobModel testJob;

  setUp(() {
    mockDataSource = MockJobDataSource();

    // Register mock data source with GetIt
    final getIt = GetIt.instance;
    if (getIt.isRegistered<IJobDataSource>()) {
      getIt.unregister<IJobDataSource>();
    }
    getIt.registerSingleton<IJobDataSource>(mockDataSource);

    // Configure mock
    when(() => mockDataSource.getJobThumbnailUrl(any()))
        .thenReturn('https://example.com/thumbnail.jpg');

    testJob = JobModel(
      jobId: 'test-job-123',
      source: 'url',
      status: 'completed',
      progressPct: 100,
      completedChunks: 10,
      createdAt: DateTime.now(),
      isFlagged: false,
      pauseRequested: false,
      title: 'Test Video',
    );
  });

  tearDown(() {
    final getIt = GetIt.instance;
    if (getIt.isRegistered<IJobDataSource>()) {
      getIt.unregister<IJobDataSource>();
    }
  });

  group('Job Action Buttons', () {
    testWidgets('delete button shows confirmation dialog', (tester) async {
      // Create a mock bloc
      final mockBloc = MockHomeBloc();
      when(() => mockBloc.state).thenReturn(HomeLoaded(
        jobs: [testJob],
        filteredJobs: [testJob],
      ));
      when(() => mockBloc.stream).thenAnswer((_) => Stream.value(HomeLoaded(
            jobs: [testJob],
            filteredJobs: [testJob],
          )));

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<HomeBloc>.value(
            value: mockBloc,
            child: Scaffold(
              body: _TestJobCard(job: testJob),
            ),
          ),
        ),
      );

      // Find and tap the delete button
      final deleteButton = find.byIcon(Icons.delete_outline);
      expect(deleteButton, findsOneWidget);
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      // Verify dialog appears
      expect(find.text('Delete job?'), findsOneWidget);
      expect(find.text('This removes the job and its results.'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('delete confirmation triggers DeleteJobEvent', (tester) async {
      final mockBloc = MockHomeBloc();
      when(() => mockBloc.state).thenReturn(HomeLoaded(
        jobs: [testJob],
        filteredJobs: [testJob],
      ));
      when(() => mockBloc.stream).thenAnswer((_) => Stream.value(HomeLoaded(
            jobs: [testJob],
            filteredJobs: [testJob],
          )));
      when(() => mockBloc.add(any())).thenReturn(null);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<HomeBloc>.value(
            value: mockBloc,
            child: Scaffold(
              body: _TestJobCard(job: testJob),
            ),
          ),
        ),
      );

      // Find and tap the delete button
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      // Tap the Delete button in the dialog
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Verify DeleteJobEvent was added
      verify(() => mockBloc.add(DeleteJobEvent(testJob.jobId))).called(1);
    });

    testWidgets('cancel button closes dialog without action', (tester) async {
      final mockBloc = MockHomeBloc();
      when(() => mockBloc.state).thenReturn(HomeLoaded(
        jobs: [testJob],
        filteredJobs: [testJob],
      ));
      when(() => mockBloc.stream).thenAnswer((_) => Stream.value(HomeLoaded(
            jobs: [testJob],
            filteredJobs: [testJob],
          )));

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<HomeBloc>.value(
            value: mockBloc,
            child: Scaffold(
              body: _TestJobCard(job: testJob),
            ),
          ),
        ),
      );

      // Find and tap the delete button
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      // Tap the Cancel button
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Verify dialog is closed and no event was added
      expect(find.text('Delete job?'), findsNothing);
      verifyNever(() => mockBloc.add(any()));
    });

    testWidgets('delete button is disabled for processing jobs', (tester) async {
      final processingJob = testJob.copyWith(status: 'processing');
      final mockBloc = MockHomeBloc();
      when(() => mockBloc.state).thenReturn(HomeLoaded(
        jobs: [processingJob],
        filteredJobs: [processingJob],
      ));
      when(() => mockBloc.stream).thenAnswer((_) => Stream.value(HomeLoaded(
            jobs: [processingJob],
            filteredJobs: [processingJob],
          )));

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<HomeBloc>.value(
            value: mockBloc,
            child: Scaffold(
              body: _TestJobCard(job: processingJob),
            ),
          ),
        ),
      );

      // Find delete button and try to tap it
      final deleteButton = find.byIcon(Icons.delete_outline);
      expect(deleteButton, findsOneWidget);
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      // Dialog should NOT appear because button is disabled
      expect(find.text('Delete job?'), findsNothing);
    });

    testWidgets('delete button is disabled for flagged jobs', (tester) async {
      final flaggedJob = testJob.copyWith(isFlagged: true);
      final mockBloc = MockHomeBloc();
      when(() => mockBloc.state).thenReturn(HomeLoaded(
        jobs: [flaggedJob],
        filteredJobs: [flaggedJob],
      ));
      when(() => mockBloc.stream).thenAnswer((_) => Stream.value(HomeLoaded(
            jobs: [flaggedJob],
            filteredJobs: [flaggedJob],
          )));

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<HomeBloc>.value(
            value: mockBloc,
            child: Scaffold(
              body: _TestJobCard(job: flaggedJob),
            ),
          ),
        ),
      );

      // Find delete button and try to tap it
      final deleteButton = find.byIcon(Icons.delete_outline);
      expect(deleteButton, findsOneWidget);
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      // Dialog should NOT appear because button is disabled
      expect(find.text('Delete job?'), findsNothing);
    });
  });
}

/// Simplified job card for testing action buttons
class _TestJobCard extends StatelessWidget {
  final JobModel job;

  const _TestJobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Flag button
        IconButton(
          icon: Icon(job.isFlagged ? Icons.flag : Icons.flag_outlined),
          onPressed: () => _showFlagDialog(context),
        ),
        // Delete button
        IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: job.canDelete ? () => _showDeleteDialog(context) : null,
        ),
      ],
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete job?'),
        content: const Text('This removes the job and its results.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<HomeBloc>().add(DeleteJobEvent(job.jobId));
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showFlagDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(job.isFlagged ? 'Unflag job?' : 'Flag job?'),
        content: Text(
          job.isFlagged
              ? 'This will remove the flag from this job.'
              : 'This marks the job for review and prevents deletion.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<HomeBloc>().add(ToggleFlagJobEvent(
                    jobId: job.jobId,
                    isFlagged: !job.isFlagged,
                  ));
            },
            child: Text(job.isFlagged ? 'Unflag' : 'Flag'),
          ),
        ],
      ),
    );
  }
}
