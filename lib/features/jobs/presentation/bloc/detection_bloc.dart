import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/errors/failures/failure.dart';
import '../../data/data_sources/detection_data_source.dart';
import '../../data/models/batch_trigger_result.dart';
import '../../data/models/detection_action.dart';
import '../../data/models/detection_run.dart';

part 'detection_event.dart';
part 'detection_state.dart';

/// Operations bloc for the Detection tab.
///
/// Two list surfaces:
///   * `runs`           -- DetectionRun list (filtered)
///   * `actionsByRunId` -- per-run actions cache (lazy on row expand,
///                          ordered by sequence_index server-side)
///
/// Three mutation paths -- NONE use list-rollback (per Specialist C3
/// narrowing). Trigger and batch-trigger emit-success then dispatch
/// `LoadDetectionRunsEvent` to refetch the truth from the server,
/// avoiding divergence between optimistic shape and server-returned
/// shape.
///
///   * `_onTrigger`      -- single-emit on 202 (toast L-3-success) +
///     dispatch refetch. 409 = L-3 (with refetch). 503 = L-4.
///   * `_onBatchTrigger` -- result-driven dialog. 207 surfaces
///     `lastBatchResult`; UI opens BatchResultDialog and dispatches
///     LoadDetectionRunsEvent on close. 503 = L-7.
class DetectionBloc extends Bloc<DetectionEvent, DetectionState> {
  final IDetectionDataSource _dataSource;

  DetectionBloc({required IDetectionDataSource dataSource})
      : _dataSource = dataSource,
        super(const DetectionInitial()) {
    on<LoadDetectionRunsEvent>(_onLoadRuns);
    on<DetectionFilterChangedEvent>(_onFilterChanged);
    on<LoadDetectionActionsEvent>(_onLoadActions);
    on<TriggerDetectionEvent>(_onTrigger);
    on<BatchTriggerEvent>(_onBatchTrigger);
    on<BatchResultAcknowledgedEvent>(_onBatchAcknowledged);
    on<DetectionErrorAcknowledged>(_onErrorAcknowledged);
  }

  Future<void> _onLoadRuns(
    LoadDetectionRunsEvent event,
    Emitter<DetectionState> emit,
  ) async {
    final current = state;
    // Preserve actions cache + pending toast fields across refetches so a
    // refetch dispatched after a successful trigger / batch close does not
    // trample lastActionMessage / lastActionError before the view's
    // BlocConsumer listener has a chance to surface them.
    final preservedActions =
        current is DetectionLoaded ? current.actionsByRunId : null;
    final preservedMessage =
        current is DetectionLoaded ? current.lastActionMessage : null;
    final preservedError =
        current is DetectionLoaded ? current.lastActionError : null;

    if (current is! DetectionLoaded) {
      emit(const DetectionLoading());
    }
    final result = await _dataSource.listDetectionRuns(
      status: event.status,
      episodeId: event.episodeId,
      createdFrom: event.createdFrom,
      createdTo: event.createdTo,
    );
    result.fold(
      (failure) => emit(DetectionError(failure.message)),
      (list) => emit(DetectionLoaded(
        runs: list,
        actionsByRunId:
            preservedActions ?? const <String, List<DetectionAction>>{},
        statusFilter: event.status,
        episodeFilter: event.episodeId,
        createdFrom: event.createdFrom,
        createdTo: event.createdTo,
        lastActionMessage: preservedMessage,
        lastActionError: preservedError,
      )),
    );
  }

  Future<void> _onFilterChanged(
    DetectionFilterChangedEvent event,
    Emitter<DetectionState> emit,
  ) async {
    final current = state;
    if (current is! DetectionLoaded) return;
    emit(current.copyWith(isMutating: true, clearLastActionError: true));
    final result = await _dataSource.listDetectionRuns(
      status: event.status,
      episodeId: event.episodeId,
      createdFrom: event.createdFrom,
      createdTo: event.createdTo,
    );
    result.fold(
      (failure) => emit(current.copyWith(
        isMutating: false,
        lastActionError: failure.message,
      )),
      (list) => emit(DetectionLoaded(
        runs: list,
        actionsByRunId: current.actionsByRunId,
        statusFilter: event.status,
        episodeFilter: event.episodeId,
        createdFrom: event.createdFrom,
        createdTo: event.createdTo,
      )),
    );
  }

  Future<void> _onLoadActions(
    LoadDetectionActionsEvent event,
    Emitter<DetectionState> emit,
  ) async {
    final current = state;
    if (current is! DetectionLoaded) return;
    // Cache hit -> no re-fetch (per Plan-Lock #5 alpha inline expansion).
    if (current.actionsByRunId.containsKey(event.runId)) return;

    final result = await _dataSource.listDetectionActions(event.runId);
    final after = state;
    if (after is! DetectionLoaded) return;

    result.fold(
      (failure) => emit(after.copyWith(
        lastActionError: failure.message,
      )),
      (actions) {
        final updatedCache =
            Map<String, List<DetectionAction>>.from(after.actionsByRunId);
        updatedCache[event.runId] = actions;
        emit(after.copyWith(
          actionsByRunId: updatedCache,
          clearLastActionError: true,
        ));
      },
    );
  }

  Future<void> _onTrigger(
    TriggerDetectionEvent event,
    Emitter<DetectionState> emit,
  ) async {
    final current = state;
    if (current is! DetectionLoaded) return;
    if (current.isMutating) return;

    emit(current.copyWith(isMutating: true, clearLastActionError: true));

    final result = await _dataSource.triggerDetection(event.episodeId);
    final after = state;
    if (after is! DetectionLoaded) return;

    await result.fold(
      (failure) async {
        if (failure is HttpFailure && failure.statusCode == 503) {
          // Toast L-4
          emit(after.copyWith(
            isMutating: false,
            lastActionError: 'Detection queue not configured -- contact infra',
          ));
        } else if (failure is HttpFailure && failure.statusCode == 409) {
          // Toast L-3: already in progress. Auto-refetch.
          emit(after.copyWith(
            isMutating: false,
            lastActionError: 'Detection already in progress for this episode',
          ));
          add(LoadDetectionRunsEvent(
            status: after.statusFilter,
            episodeId: after.episodeFilter,
            createdFrom: after.createdFrom,
            createdTo: after.createdTo,
          ));
        } else {
          emit(after.copyWith(
            isMutating: false,
            lastActionError: failure.message,
          ));
        }
      },
      (_) async {
        // Toast L-3-success: emit success message + dispatch refetch.
        // No optimistic list-add (avoids divergence with server shape
        // -- the new run will surface on the refetch).
        emit(after.copyWith(
          isMutating: false,
          clearLastActionError: true,
          lastActionMessage: 'Detection queued for episode ${event.episodeId}',
        ));
        add(LoadDetectionRunsEvent(
          status: after.statusFilter,
          episodeId: after.episodeFilter,
          createdFrom: after.createdFrom,
          createdTo: after.createdTo,
        ));
      },
    );
  }

  Future<void> _onBatchTrigger(
    BatchTriggerEvent event,
    Emitter<DetectionState> emit,
  ) async {
    final current = state;
    if (current is! DetectionLoaded) return;
    if (current.isBatchTriggering) return;

    emit(current.copyWith(
      isBatchTriggering: true,
      clearLastActionError: true,
      clearLastBatchResult: true,
    ));

    final result = await _dataSource.batchTriggerDetection(event.episodeIds);
    final after = state;
    if (after is! DetectionLoaded) return;

    result.fold(
      (failure) {
        if (failure is HttpFailure && failure.statusCode == 503) {
          // Toast L-7: outer 503; no per-item results.
          emit(after.copyWith(
            isBatchTriggering: false,
            lastActionError: 'Detection queue not configured -- contact infra',
          ));
        } else {
          // Toast L-5 surfaces here on client-side reject as
          // ValidationFailure with verbatim "Maximum 50 episodes per
          // batch" message.
          emit(after.copyWith(
            isBatchTriggering: false,
            lastActionError: failure.message,
          ));
        }
      },
      (results) {
        // Toast L-6: 207. No toast text; UI opens BatchResultDialog
        // when lastBatchResult is non-null. Dialog close dispatches
        // LoadDetectionRunsEvent (BatchResultAcknowledgedEvent path).
        emit(after.copyWith(
          isBatchTriggering: false,
          clearLastActionError: true,
          lastBatchResult: results,
        ));
      },
    );
  }

  void _onBatchAcknowledged(
    BatchResultAcknowledgedEvent event,
    Emitter<DetectionState> emit,
  ) {
    final current = state;
    if (current is! DetectionLoaded) return;
    if (current.lastBatchResult == null) return;
    emit(current.copyWith(clearLastBatchResult: true));
    add(LoadDetectionRunsEvent(
      status: current.statusFilter,
      episodeId: current.episodeFilter,
      createdFrom: current.createdFrom,
      createdTo: current.createdTo,
    ));
  }

  void _onErrorAcknowledged(
    DetectionErrorAcknowledged event,
    Emitter<DetectionState> emit,
  ) {
    final current = state;
    if (current is! DetectionLoaded) return;
    if (current.lastActionError == null && current.lastActionMessage == null) {
      return;
    }
    emit(current.copyWith(
      clearLastActionError: true,
      clearLastActionMessage: true,
    ));
  }
}
