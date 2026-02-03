import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:streamwatch_frontend/data/models/job_model.dart';
import 'package:streamwatch_frontend/data/sources/job_data_source.dart';
import 'package:streamwatch_frontend/features/home/bloc/home_bloc.dart';
import 'package:streamwatch_frontend/features/home/bloc/home_event.dart';
import 'package:streamwatch_frontend/features/home/bloc/home_state.dart';
import 'package:streamwatch_frontend/shared/errors/failures/failure.dart';

class MockJobDataSource extends Mock implements IJobDataSource {}

void main() {
  late MockJobDataSource mockDataSource;
  late JobModel testJob;
  late JobModel processingJob;
  late JobModel flaggedJob;

  setUp(() {
    mockDataSource = MockJobDataSource();

    testJob = JobModel(
      jobId: 'test-job-123',
      source: 'url',
      status: 'completed',
      progressPct: 100,
      completedChunks: 10,
      createdAt: DateTime.now(),
      isFlagged: false,
      pauseRequested: false,
    );

    processingJob = JobModel(
      jobId: 'processing-job-456',
      source: 'url',
      status: 'processing',
      progressPct: 50,
      completedChunks: 5,
      createdAt: DateTime.now(),
      isFlagged: false,
      pauseRequested: false,
    );

    flaggedJob = JobModel(
      jobId: 'flagged-job-789',
      source: 'url',
      status: 'completed',
      progressPct: 100,
      completedChunks: 10,
      createdAt: DateTime.now(),
      isFlagged: true,
      pauseRequested: false,
    );
  });

  group('HomeBloc Job Actions', () {
    group('DeleteJobEvent', () {
      blocTest<HomeBloc, HomeState>(
        'emits in-flight state then removes job on successful delete',
        build: () {
          when(() => mockDataSource.getRecentJobs(limit: any(named: 'limit')))
              .thenAnswer((_) async => Right([testJob]));
          when(() => mockDataSource.deleteJob(testJob.jobId))
              .thenAnswer((_) async => const Right(null));
          return HomeBloc(jobDataSource: mockDataSource);
        },
        seed: () => HomeLoaded(
          jobs: [testJob],
          filteredJobs: [testJob],
        ),
        act: (bloc) => bloc.add(DeleteJobEvent(testJob.jobId)),
        expect: () => [
          // In-flight state
          isA<HomeLoaded>()
              .having(
                (s) => s.inFlightActions[testJob.jobId],
                'inFlightAction',
                JobActionType.delete,
              )
              .having((s) => s.jobs.length, 'jobs length', 1),
          // Success state - job removed
          isA<HomeLoaded>()
              .having((s) => s.inFlightActions.isEmpty, 'inFlightActions empty', true)
              .having((s) => s.jobs.isEmpty, 'jobs empty', true)
              .having((s) => s.actionSuccess, 'actionSuccess', 'Job deleted'),
        ],
        verify: (_) {
          verify(() => mockDataSource.deleteJob(testJob.jobId)).called(1);
        },
      );

      blocTest<HomeBloc, HomeState>(
        'shows error and restores state on 409 Conflict (processing job)',
        build: () {
          when(() => mockDataSource.deleteJob(processingJob.jobId)).thenAnswer(
            (_) async => const Left(HttpFailure(
              statusCode: 409,
              message: 'Cannot delete processing job',
            )),
          );
          return HomeBloc(jobDataSource: mockDataSource);
        },
        seed: () => HomeLoaded(
          jobs: [processingJob],
          filteredJobs: [processingJob],
        ),
        act: (bloc) => bloc.add(DeleteJobEvent(processingJob.jobId)),
        expect: () => [
          // In-flight state
          isA<HomeLoaded>().having(
            (s) => s.inFlightActions[processingJob.jobId],
            'inFlightAction',
            JobActionType.delete,
          ),
          // Error state - job still in list
          isA<HomeLoaded>()
              .having((s) => s.inFlightActions.isEmpty, 'inFlightActions empty', true)
              .having((s) => s.jobs.length, 'jobs length', 1)
              .having((s) => s.actionError, 'actionError',
                  'Cannot delete while job is processing or flagged'),
        ],
      );
    });

    group('ToggleFlagJobEvent', () {
      blocTest<HomeBloc, HomeState>(
        'flags a job and updates state on success',
        build: () {
          final flaggedJobResult = testJob.copyWith(isFlagged: true);
          when(() => mockDataSource.updateJobFlag(
                jobId: testJob.jobId,
                isFlagged: true,
                flagNote: null,
              )).thenAnswer((_) async => Right(flaggedJobResult));
          return HomeBloc(jobDataSource: mockDataSource);
        },
        seed: () => HomeLoaded(
          jobs: [testJob],
          filteredJobs: [testJob],
        ),
        act: (bloc) => bloc.add(ToggleFlagJobEvent(
          jobId: testJob.jobId,
          isFlagged: true,
        )),
        expect: () => [
          // In-flight state
          isA<HomeLoaded>().having(
            (s) => s.inFlightActions[testJob.jobId],
            'inFlightAction',
            JobActionType.flag,
          ),
          // Success state
          isA<HomeLoaded>()
              .having((s) => s.inFlightActions.isEmpty, 'inFlightActions empty', true)
              .having((s) => s.jobs.first.isFlagged, 'job is flagged', true)
              .having((s) => s.actionSuccess, 'actionSuccess', 'Job flagged'),
        ],
      );

      blocTest<HomeBloc, HomeState>(
        'unflags a job and updates state on success',
        build: () {
          final unflaggedJobResult = flaggedJob.copyWith(isFlagged: false);
          when(() => mockDataSource.updateJobFlag(
                jobId: flaggedJob.jobId,
                isFlagged: false,
                flagNote: null,
              )).thenAnswer((_) async => Right(unflaggedJobResult));
          return HomeBloc(jobDataSource: mockDataSource);
        },
        seed: () => HomeLoaded(
          jobs: [flaggedJob],
          filteredJobs: [flaggedJob],
        ),
        act: (bloc) => bloc.add(ToggleFlagJobEvent(
          jobId: flaggedJob.jobId,
          isFlagged: false,
        )),
        expect: () => [
          // In-flight state
          isA<HomeLoaded>().having(
            (s) => s.inFlightActions[flaggedJob.jobId],
            'inFlightAction',
            JobActionType.flag,
          ),
          // Success state
          isA<HomeLoaded>()
              .having((s) => s.inFlightActions.isEmpty, 'inFlightActions empty', true)
              .having((s) => s.jobs.first.isFlagged, 'job is unflagged', false)
              .having((s) => s.actionSuccess, 'actionSuccess', 'Job unflagged'),
        ],
      );
    });

    group('PauseJobEvent', () {
      blocTest<HomeBloc, HomeState>(
        'pauses a job and updates state on success',
        build: () {
          final pausedJob = processingJob.copyWith(pauseRequested: true);
          when(() => mockDataSource.pauseJob(processingJob.jobId))
              .thenAnswer((_) async => Right(pausedJob));
          return HomeBloc(jobDataSource: mockDataSource);
        },
        seed: () => HomeLoaded(
          jobs: [processingJob],
          filteredJobs: [processingJob],
        ),
        act: (bloc) => bloc.add(PauseJobEvent(processingJob.jobId)),
        expect: () => [
          // In-flight state
          isA<HomeLoaded>().having(
            (s) => s.inFlightActions[processingJob.jobId],
            'inFlightAction',
            JobActionType.pause,
          ),
          // Success state
          isA<HomeLoaded>()
              .having((s) => s.inFlightActions.isEmpty, 'inFlightActions empty', true)
              .having((s) => s.jobs.first.pauseRequested, 'pauseRequested', true)
              .having((s) => s.actionSuccess, 'actionSuccess', 'Pause requested'),
        ],
      );
    });

    group('ResumeJobEvent', () {
      blocTest<HomeBloc, HomeState>(
        'resumes a paused job and updates state on success',
        build: () {
          final pausedJob = processingJob.copyWith(
            status: 'paused',
            pauseRequested: false,
          );
          final resumedJob = processingJob.copyWith(
            status: 'processing',
            pauseRequested: false,
          );
          when(() => mockDataSource.resumeJob(pausedJob.jobId))
              .thenAnswer((_) async => Right(resumedJob));
          return HomeBloc(jobDataSource: mockDataSource);
        },
        seed: () {
          final pausedJob = processingJob.copyWith(
            status: 'paused',
            pauseRequested: false,
          );
          return HomeLoaded(
            jobs: [pausedJob],
            filteredJobs: [pausedJob],
          );
        },
        act: (bloc) => bloc.add(ResumeJobEvent(processingJob.jobId)),
        expect: () => [
          // In-flight state
          isA<HomeLoaded>().having(
            (s) => s.inFlightActions[processingJob.jobId],
            'inFlightAction',
            JobActionType.resume,
          ),
          // Success state
          isA<HomeLoaded>()
              .having((s) => s.inFlightActions.isEmpty, 'inFlightActions empty', true)
              .having((s) => s.jobs.first.status, 'status', 'processing')
              .having((s) => s.actionSuccess, 'actionSuccess', 'Job resumed'),
        ],
      );
    });
  });
}
