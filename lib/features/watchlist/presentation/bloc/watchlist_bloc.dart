import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/errors/failures/failure.dart';
import '../../data/data_sources/guest_watchlist_data_source.dart';
import '../../data/models/change_status_request.dart';
import '../../data/models/guest_watchlist_entry.dart';
import '../../data/models/patch_guest_watchlist_request.dart';

part 'watchlist_event.dart';
part 'watchlist_state.dart';

/// Editorial-tracking bloc for the guest watchlist surface.
///
/// Three mutation paths follow the §30.6 optimistic-rollback contract:
///   * `_onCreate` -- captures `priorList`, optimistically appends after
///     server returns success (no optimistic-list-add before the call --
///     server-issued id is required to render the new row).
///   * `_onPatch`  -- captures `priorState` (single-row update); rolls
///     back the entire state on failure so the form stays open.
///   * `_onChangeStatus` -- captures `priorState`; on 400 keeps form open,
///     on 409 restores priorState and dispatches `LoadGuestWatchlistEvent`
///     for auto-refetch.
///
/// Status-code discrimination follows the L-8 / L-9 / L-10 toast table
/// in WO-078 KB §31.12.
class WatchlistBloc extends Bloc<WatchlistEvent, WatchlistState> {
  final IGuestWatchlistDataSource _dataSource;

  WatchlistBloc({required IGuestWatchlistDataSource dataSource})
      : _dataSource = dataSource,
        super(const WatchlistInitial()) {
    on<LoadGuestWatchlistEvent>(_onLoad);
    on<WatchlistFilterChangedEvent>(_onFilterChanged);
    on<CreateWatchlistEntryEvent>(_onCreate);
    on<PatchWatchlistEntryEvent>(_onPatch);
    on<ChangeWatchlistStatusEvent>(_onChangeStatus);
    on<WatchlistErrorAcknowledged>(_onErrorAcknowledged);
  }

  Future<void> _onLoad(
    LoadGuestWatchlistEvent event,
    Emitter<WatchlistState> emit,
  ) async {
    final current = state;
    // Preserve pending toast fields across refetch (L-9 dispatches a
    // load right after emitting lastActionError; we don't want the
    // refetch to clobber the toast before the view's listener fires).
    final preservedError =
        current is WatchlistLoaded ? current.lastActionError : null;
    final preservedMessage =
        current is WatchlistLoaded ? current.lastActionMessage : null;

    if (current is! WatchlistLoaded) {
      emit(const WatchlistLoading());
    }
    final result = await _dataSource.listGuestWatchlistEntries(
      status: event.status,
    );
    result.fold(
      (failure) => emit(WatchlistError(failure.message)),
      (list) => emit(WatchlistLoaded(
        entries: list,
        statusFilter: event.status,
        lastActionError: preservedError,
        lastActionMessage: preservedMessage,
      )),
    );
  }

  Future<void> _onFilterChanged(
    WatchlistFilterChangedEvent event,
    Emitter<WatchlistState> emit,
  ) async {
    final current = state;
    if (current is! WatchlistLoaded) return;
    if (current.statusFilter == event.status) return;
    emit(current.copyWith(isMutating: true, clearLastActionError: true));
    final result = await _dataSource.listGuestWatchlistEntries(
      status: event.status,
    );
    result.fold(
      (failure) => emit(current.copyWith(
        isMutating: false,
        lastActionError: failure.message,
      )),
      (list) => emit(WatchlistLoaded(
        entries: list,
        statusFilter: event.status,
      )),
    );
  }

  Future<void> _onCreate(
    CreateWatchlistEntryEvent event,
    Emitter<WatchlistState> emit,
  ) async {
    final current = state;
    if (current is! WatchlistLoaded) return;
    if (current.isMutating) return;

    final priorList = current.entries;
    emit(current.copyWith(isMutating: true, clearLastActionError: true));

    final result = await _dataSource.createGuestWatchlistEntry(event.body);
    final after = state;
    if (after is! WatchlistLoaded) return;

    result.fold(
      (failure) => emit(after.copyWith(
        entries: priorList,
        isMutating: false,
        lastActionError: failure.message,
      )),
      (created) => emit(after.copyWith(
        entries: [created, ...priorList],
        isMutating: false,
        clearLastActionError: true,
      )),
    );
  }

  Future<void> _onPatch(
    PatchWatchlistEntryEvent event,
    Emitter<WatchlistState> emit,
  ) async {
    final current = state;
    if (current is! WatchlistLoaded) return;
    if (current.isMutating) return;

    final priorState = current;
    emit(current.copyWith(isMutating: true, clearLastActionError: true));

    final result = await _dataSource.patchGuestWatchlistEntry(
      event.entryId,
      event.request,
    );
    final after = state;
    if (after is! WatchlistLoaded) return;

    result.fold(
      (failure) {
        // Toast L-10: PATCH 400 = forbidden field. Server returns the
        // field name in the message; surface verbatim, restore prior
        // state, form stays open.
        if (failure is HttpFailure && failure.statusCode == 400) {
          emit(priorState.copyWith(
            isMutating: false,
            lastActionError: failure.message,
          ));
        } else {
          emit(priorState.copyWith(
            isMutating: false,
            lastActionError: failure.message,
          ));
        }
      },
      (updated) => emit(after.copyWith(
        entries:
            after.entries.map((e) => e.id == updated.id ? updated : e).toList(),
        isMutating: false,
        clearLastActionError: true,
      )),
    );
  }

  Future<void> _onChangeStatus(
    ChangeWatchlistStatusEvent event,
    Emitter<WatchlistState> emit,
  ) async {
    final current = state;
    if (current is! WatchlistLoaded) return;
    if (current.isMutating) return;

    final priorState = current;
    emit(current.copyWith(isMutating: true, clearLastActionError: true));

    final result = await _dataSource.changeGuestWatchlistEntryStatus(
      event.entryId,
      event.request,
    );
    final after = state;
    if (after is! WatchlistLoaded) return;

    await result.fold(
      (failure) async {
        if (failure is HttpFailure && failure.statusCode == 400) {
          // Toast L-8: episode not found. Form stays open with episode
          // field highlighted -- view inspects lastActionError.
          emit(priorState.copyWith(
            isMutating: false,
            lastActionError: 'Episode not found -- pick a valid episode',
          ));
        } else if (failure is HttpFailure && failure.statusCode == 409) {
          // Toast L-9: already finalized by another user.
          // Restore priorState + auto-refetch.
          emit(priorState.copyWith(
            isMutating: false,
            lastActionError: 'Already finalized by another user',
          ));
          add(LoadGuestWatchlistEvent(status: priorState.statusFilter));
        } else {
          emit(priorState.copyWith(
            isMutating: false,
            lastActionError: failure.message,
          ));
        }
      },
      (updated) async {
        emit(after.copyWith(
          entries: after.entries
              .map((e) => e.id == updated.id ? updated : e)
              .toList(),
          isMutating: false,
          clearLastActionError: true,
        ));
      },
    );
  }

  void _onErrorAcknowledged(
    WatchlistErrorAcknowledged event,
    Emitter<WatchlistState> emit,
  ) {
    final current = state;
    if (current is! WatchlistLoaded) return;
    if (current.lastActionError == null && current.lastActionMessage == null) {
      return;
    }
    emit(current.copyWith(
      clearLastActionError: true,
      clearLastActionMessage: true,
    ));
  }
}
