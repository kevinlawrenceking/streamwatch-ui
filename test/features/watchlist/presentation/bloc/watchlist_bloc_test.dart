import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:streamwatch_frontend/features/watchlist/data/data_sources/guest_watchlist_data_source.dart';
import 'package:streamwatch_frontend/features/watchlist/data/models/change_status_request.dart';
import 'package:streamwatch_frontend/features/watchlist/data/models/guest_watchlist_entry.dart';
import 'package:streamwatch_frontend/features/watchlist/data/models/patch_guest_watchlist_request.dart';
import 'package:streamwatch_frontend/features/watchlist/presentation/bloc/watchlist_bloc.dart';
import 'package:streamwatch_frontend/shared/errors/failures/failure.dart';

class MockGuestWatchlistDataSource extends Mock
    implements IGuestWatchlistDataSource {}

PodcastGuestWatchlistEntry _e(String id, {String status = 'active'}) =>
    PodcastGuestWatchlistEntry(
      id: id,
      guestName: 'Guest $id',
      aliases: const [],
      priority: 'medium',
      status: status,
      createdAt: DateTime.utc(2026, 4, 25),
      updatedAt: DateTime.utc(2026, 4, 25),
    );

void main() {
  setUpAll(() {
    registerFallbackValue(const PatchGuestWatchlistEntryRequest());
    registerFallbackValue(
        const ChangeWatchlistStatusRequest(status: 'matched'));
  });

  late MockGuestWatchlistDataSource ds;
  setUp(() {
    ds = MockGuestWatchlistDataSource();
  });
  WatchlistBloc build() => WatchlistBloc(dataSource: ds);

  group('load', () {
    blocTest<WatchlistBloc, WatchlistState>(
      'happy path emits Loading then Loaded',
      build: () {
        when(() => ds.listGuestWatchlistEntries(status: any(named: 'status')))
            .thenAnswer((_) async => Right([_e('a'), _e('b')]));
        return build();
      },
      act: (b) => b.add(const LoadGuestWatchlistEvent()),
      expect: () => [
        const WatchlistLoading(),
        isA<WatchlistLoaded>().having((s) => s.entries.length, 'count', 2),
      ],
    );

    blocTest<WatchlistBloc, WatchlistState>(
      'failure emits Error from initial state',
      build: () {
        when(() => ds.listGuestWatchlistEntries(status: any(named: 'status')))
            .thenAnswer((_) async => const Left(GeneralFailure('list failed')));
        return build();
      },
      act: (b) => b.add(const LoadGuestWatchlistEvent()),
      expect: () => [
        const WatchlistLoading(),
        const WatchlistError('list failed'),
      ],
    );
  });

  group('filter chip happy paths', () {
    for (final filter in ['active', 'matched', 'expired']) {
      blocTest<WatchlistBloc, WatchlistState>(
        'filter $filter dispatches list with status=$filter',
        build: () {
          when(() => ds.listGuestWatchlistEntries(status: any(named: 'status')))
              .thenAnswer((_) async => Right([_e('a', status: filter)]));
          return build();
        },
        seed: () => WatchlistLoaded(entries: [_e('a')]),
        act: (b) => b.add(WatchlistFilterChangedEvent(filter)),
        expect: () => [
          isA<WatchlistLoaded>().having((s) => s.isMutating, 'mutating', true),
          isA<WatchlistLoaded>()
              .having((s) => s.statusFilter, 'filter', filter)
              .having((s) => s.entries.length, 'count', 1),
        ],
      );
    }
  });

  group('create', () {
    blocTest<WatchlistBloc, WatchlistState>(
      'success prepends new entry',
      build: () {
        when(() => ds.createGuestWatchlistEntry(any()))
            .thenAnswer((_) async => Right(_e('new')));
        return build();
      },
      seed: () => WatchlistLoaded(entries: [_e('a')]),
      act: (b) => b.add(CreateWatchlistEntryEvent(const {'guest_name': 'X'})),
      expect: () => [
        isA<WatchlistLoaded>().having((s) => s.isMutating, 'mutating', true),
        isA<WatchlistLoaded>().having((s) => s.entries.length, 'count', 2),
      ],
    );

    blocTest<WatchlistBloc, WatchlistState>(
      'rollback restores priorList on failure',
      build: () {
        when(() => ds.createGuestWatchlistEntry(any()))
            .thenAnswer((_) async => const Left(GeneralFailure('boom')));
        return build();
      },
      seed: () => WatchlistLoaded(entries: [_e('a')]),
      act: (b) => b.add(CreateWatchlistEntryEvent(const {'guest_name': 'X'})),
      expect: () => [
        isA<WatchlistLoaded>().having((s) => s.isMutating, 'mutating', true),
        isA<WatchlistLoaded>()
            .having((s) => s.entries.length, 'restored', 1)
            .having((s) => s.lastActionError, 'error', 'boom'),
      ],
    );
  });

  group('patch', () {
    blocTest<WatchlistBloc, WatchlistState>(
      'success replaces row',
      build: () {
        when(() => ds.patchGuestWatchlistEntry('a', any())).thenAnswer(
            (_) async => Right(_e('a').copyWith(guestName: 'Renamed')));
        return build();
      },
      seed: () => WatchlistLoaded(entries: [_e('a'), _e('b')]),
      act: (b) => b.add(PatchWatchlistEntryEvent(
        entryId: 'a',
        request: const PatchGuestWatchlistEntryRequest(guestName: 'Renamed'),
      )),
      expect: () => [
        isA<WatchlistLoaded>().having((s) => s.isMutating, 'mutating', true),
        isA<WatchlistLoaded>().having(
          (s) => s.entries.first.guestName,
          'renamed',
          'Renamed',
        ),
      ],
    );

    blocTest<WatchlistBloc, WatchlistState>(
      'L-10: PATCH 400 forbidden field rolls back priorState',
      build: () {
        when(() => ds.patchGuestWatchlistEntry('a', any()))
            .thenAnswer((_) async => const Left(HttpFailure(
                  statusCode: 400,
                  message: 'unknown field "status"',
                )));
        return build();
      },
      seed: () => WatchlistLoaded(entries: [_e('a')]),
      act: (b) => b.add(PatchWatchlistEntryEvent(
        entryId: 'a',
        request: const PatchGuestWatchlistEntryRequest(guestName: 'X'),
      )),
      expect: () => [
        isA<WatchlistLoaded>().having((s) => s.isMutating, 'mutating', true),
        isA<WatchlistLoaded>()
            .having((s) => s.entries.length, 'restored', 1)
            .having(
              (s) => s.lastActionError,
              'error',
              'unknown field "status"',
            ),
      ],
    );

    blocTest<WatchlistBloc, WatchlistState>(
      'generic failure also rolls back',
      build: () {
        when(() => ds.patchGuestWatchlistEntry('a', any()))
            .thenAnswer((_) async => const Left(GeneralFailure('boom')));
        return build();
      },
      seed: () => WatchlistLoaded(entries: [_e('a')]),
      act: (b) => b.add(PatchWatchlistEntryEvent(
        entryId: 'a',
        request: const PatchGuestWatchlistEntryRequest(guestName: 'X'),
      )),
      expect: () => [
        isA<WatchlistLoaded>(),
        isA<WatchlistLoaded>()
            .having((s) => s.lastActionError, 'error', 'boom'),
      ],
    );
  });

  group('change-status', () {
    blocTest<WatchlistBloc, WatchlistState>(
      '200: replaces row with matched entry',
      build: () {
        when(() => ds.changeGuestWatchlistEntryStatus('a', any()))
            .thenAnswer((_) async => Right(_e('a', status: 'matched')));
        return build();
      },
      seed: () => WatchlistLoaded(entries: [_e('a')]),
      act: (b) => b.add(ChangeWatchlistStatusEvent(
        entryId: 'a',
        request: const ChangeWatchlistStatusRequest(
          status: 'matched',
          matchedEpisodeId: 'ep-99',
        ),
      )),
      expect: () => [
        isA<WatchlistLoaded>().having((s) => s.isMutating, 'mutating', true),
        isA<WatchlistLoaded>()
            .having((s) => s.entries.first.status, 'status', 'matched'),
      ],
    );

    blocTest<WatchlistBloc, WatchlistState>(
      'L-8: 400 -> Episode not found message + restore',
      build: () {
        when(() => ds.changeGuestWatchlistEntryStatus('a', any()))
            .thenAnswer((_) async => const Left(HttpFailure(
                  statusCode: 400,
                  message: 'episode does not exist',
                )));
        return build();
      },
      seed: () => WatchlistLoaded(entries: [_e('a')]),
      act: (b) => b.add(ChangeWatchlistStatusEvent(
        entryId: 'a',
        request: const ChangeWatchlistStatusRequest(
          status: 'matched',
          matchedEpisodeId: 'ep-x',
        ),
      )),
      expect: () => [
        isA<WatchlistLoaded>().having((s) => s.isMutating, 'mutating', true),
        isA<WatchlistLoaded>().having(
          (s) => s.lastActionError,
          'L-8',
          'Episode not found -- pick a valid episode',
        ),
      ],
    );

    blocTest<WatchlistBloc, WatchlistState>(
      '404 generic message',
      build: () {
        when(() => ds.changeGuestWatchlistEntryStatus('a', any()))
            .thenAnswer((_) async => const Left(HttpFailure(
                  statusCode: 404,
                  message: 'not found',
                )));
        return build();
      },
      seed: () => WatchlistLoaded(entries: [_e('a')]),
      act: (b) => b.add(ChangeWatchlistStatusEvent(
        entryId: 'a',
        request: const ChangeWatchlistStatusRequest(status: 'expired'),
      )),
      expect: () => [
        isA<WatchlistLoaded>(),
        isA<WatchlistLoaded>()
            .having((s) => s.lastActionError, 'error', 'not found'),
      ],
    );

    blocTest<WatchlistBloc, WatchlistState>(
      'L-9: 409 -> Already finalized + auto-refetch dispatches LoadGuestWatchlistEvent',
      build: () {
        when(() => ds.changeGuestWatchlistEntryStatus('a', any()))
            .thenAnswer((_) async => const Left(HttpFailure(
                  statusCode: 409,
                  message: 'concurrent termination',
                )));
        when(() => ds.listGuestWatchlistEntries(status: any(named: 'status')))
            .thenAnswer((_) async => Right([_e('a', status: 'expired')]));
        return build();
      },
      seed: () => WatchlistLoaded(entries: [_e('a')]),
      act: (b) => b.add(ChangeWatchlistStatusEvent(
        entryId: 'a',
        request: const ChangeWatchlistStatusRequest(status: 'matched'),
      )),
      wait: const Duration(milliseconds: 50),
      verify: (_) {
        verify(() => ds.listGuestWatchlistEntries(status: null)).called(1);
      },
    );
  });

  group('ErrorAcknowledged', () {
    blocTest<WatchlistBloc, WatchlistState>(
      'clears lastActionError + lastActionMessage',
      build: () => build(),
      seed: () => WatchlistLoaded(
        entries: [_e('a')],
        lastActionError: 'boom',
        lastActionMessage: 'success',
      ),
      act: (b) => b.add(const WatchlistErrorAcknowledged()),
      expect: () => [
        isA<WatchlistLoaded>()
            .having((s) => s.lastActionError, 'cleared error', isNull)
            .having((s) => s.lastActionMessage, 'cleared msg', isNull),
      ],
    );
  });
}
