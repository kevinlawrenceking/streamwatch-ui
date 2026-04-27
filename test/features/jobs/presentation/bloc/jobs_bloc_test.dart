import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:streamwatch_frontend/features/jobs/data/data_sources/jobs_data_source.dart';
import 'package:streamwatch_frontend/features/jobs/data/models/podcast_job.dart';
import 'package:streamwatch_frontend/features/jobs/presentation/bloc/jobs_bloc.dart';
import 'package:streamwatch_frontend/shared/errors/failures/failure.dart';

class MockJobsDataSource extends Mock implements IJobsDataSource {}

PodcastJob _job(String id, {String status = 'failed'}) => PodcastJob(
      jobId: id,
      status: status,
      createdAt: DateTime.utc(2026, 4, 25),
    );

void main() {
  late MockJobsDataSource ds;
  setUp(() {
    ds = MockJobsDataSource();
  });
  JobsBloc build() => JobsBloc(dataSource: ds);

  blocTest<JobsBloc, JobsState>(
    'load happy path',
    build: () {
      when(() => ds.listPodcastJobs(
            status: any(named: 'status'),
            podcastId: any(named: 'podcastId'),
            createdFrom: any(named: 'createdFrom'),
            createdTo: any(named: 'createdTo'),
          )).thenAnswer((_) async => Right([_job('j-1'), _job('j-2')]));
      return build();
    },
    act: (b) => b.add(const LoadJobsEvent()),
    expect: () => [
      const JobsLoading(),
      isA<JobsLoaded>().having((s) => s.jobs.length, 'count', 2),
    ],
  );

  blocTest<JobsBloc, JobsState>(
    'filter changed re-fetches with new params',
    build: () {
      when(() => ds.listPodcastJobs(
            status: any(named: 'status'),
            podcastId: any(named: 'podcastId'),
            createdFrom: any(named: 'createdFrom'),
            createdTo: any(named: 'createdTo'),
          )).thenAnswer((_) async => Right([_job('j-1', status: 'failed')]));
      return build();
    },
    seed: () => JobsLoaded(jobs: [_job('j-1')]),
    act: (b) =>
        b.add(const JobsFilterChangedEvent(status: 'failed', podcastId: 'p-1')),
    expect: () => [
      isA<JobsLoaded>().having((s) => s.isMutating, 'mutating', true),
      isA<JobsLoaded>()
          .having((s) => s.statusFilter, 'status', 'failed')
          .having((s) => s.podcastFilter, 'podcast', 'p-1'),
    ],
  );

  blocTest<JobsBloc, JobsState>(
    'L-1: retry 202 single emit -- status flips to queued + lastActionMessage set',
    build: () {
      when(() => ds.retryPodcastJob('j-1'))
          .thenAnswer((_) async => const Right(null));
      return build();
    },
    seed: () => JobsLoaded(jobs: [_job('j-1', status: 'failed')]),
    act: (b) => b.add(const RetryJobEvent('j-1')),
    expect: () => [
      isA<JobsLoaded>().having((s) => s.isMutating, 'mutating', true),
      isA<JobsLoaded>()
          .having((s) => s.jobs.first.status, 'status', 'queued')
          .having(
            (s) => s.lastActionMessage,
            'L-1',
            'Retry queued for j-1',
          ),
    ],
  );

  blocTest<JobsBloc, JobsState>(
    'L-2: retry 404 -> Job not found + priorState restore',
    build: () {
      when(() => ds.retryPodcastJob('j-x')).thenAnswer((_) async =>
          const Left(HttpFailure(statusCode: 404, message: 'not found')));
      return build();
    },
    seed: () => JobsLoaded(jobs: [_job('j-x', status: 'failed')]),
    act: (b) => b.add(const RetryJobEvent('j-x')),
    expect: () => [
      isA<JobsLoaded>().having((s) => s.isMutating, 'mutating', true),
      isA<JobsLoaded>()
          .having((s) => s.jobs.first.status, 'restored', 'failed')
          .having((s) => s.lastActionError, 'L-2', 'Job not found'),
    ],
  );

  blocTest<JobsBloc, JobsState>(
    'isMutating gate: second retry while first is in flight is ignored',
    build: () {
      when(() => ds.retryPodcastJob('j-1'))
          .thenAnswer((_) async => await Future.delayed(
                const Duration(milliseconds: 30),
                () => const Right(null),
              ));
      return build();
    },
    seed: () => JobsLoaded(
      jobs: [_job('j-1', status: 'failed')],
      isMutating: true, // already mutating -> guard returns
    ),
    act: (b) => b.add(const RetryJobEvent('j-1')),
    expect: () => [],
  );

  blocTest<JobsBloc, JobsState>(
    'JobsErrorAcknowledged clears both error and message',
    build: () => build(),
    seed: () => JobsLoaded(
      jobs: [_job('j-1')],
      lastActionError: 'boom',
      lastActionMessage: 'queued',
    ),
    act: (b) => b.add(const JobsErrorAcknowledged()),
    expect: () => [
      isA<JobsLoaded>()
          .having((s) => s.lastActionError, 'cleared err', isNull)
          .having((s) => s.lastActionMessage, 'cleared msg', isNull),
    ],
  );
}
