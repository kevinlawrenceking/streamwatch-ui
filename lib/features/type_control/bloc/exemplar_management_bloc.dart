import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/sources/video_type_data_source.dart';
import '../../../shared/errors/failures/failure.dart';
import 'exemplar_management_event.dart';
import 'exemplar_management_state.dart';

class ExemplarManagementBloc
    extends Bloc<ExemplarManagementEvent, ExemplarManagementState> {
  final IVideoTypeDataSource _dataSource;
  String _currentTypeId = '';

  ExemplarManagementBloc({required IVideoTypeDataSource dataSource})
      : _dataSource = dataSource,
        super(const ExemplarManagementInitial()) {
    on<LoadExemplarsEvent>(_onLoadExemplars);
    on<BulkCreateExemplarsEvent>(_onBulkCreateExemplars);
    on<DeleteExemplarEvent>(_onDeleteExemplar);
    on<UpdateExemplarEvent>(_onUpdateExemplar);
  }

  Future<void> _onLoadExemplars(
    LoadExemplarsEvent event,
    Emitter<ExemplarManagementState> emit,
  ) async {
    _currentTypeId = event.videoTypeId;
    emit(const ExemplarManagementLoading());
    final result = await _dataSource.getExemplars(event.videoTypeId);
    result.fold(
      (failure) => emit(ExemplarManagementError(failure)),
      (exemplars) =>
          emit(ExemplarManagementLoaded(exemplars: exemplars)),
    );
  }

  Future<void> _onBulkCreateExemplars(
    BulkCreateExemplarsEvent event,
    Emitter<ExemplarManagementState> emit,
  ) async {
    final current = state;
    if (current is ExemplarManagementLoaded) {
      emit(current.copyWith(isSubmitting: true));
    }
    final body = <String, dynamic>{
      'job_ids': event.jobIds,
      if (event.exemplarKind != null) 'exemplar_kind': event.exemplarKind,
      if (event.notes != null) 'notes': event.notes,
    };
    final result =
        await _dataSource.bulkCreateExemplars(event.videoTypeId, body);
    result.fold(
      (failure) => emit(ExemplarManagementError(failure)),
      (_) => add(LoadExemplarsEvent(event.videoTypeId)),
    );
  }

  Future<void> _onDeleteExemplar(
    DeleteExemplarEvent event,
    Emitter<ExemplarManagementState> emit,
  ) async {
    final current = state;
    if (current is ExemplarManagementLoaded) {
      emit(current.copyWith(isSubmitting: true));
    }
    final result = await _dataSource.deleteExemplar(event.exemplarId);
    result.fold(
      (failure) => emit(ExemplarManagementError(failure)),
      (_) => add(LoadExemplarsEvent(event.videoTypeId)),
    );
  }

  Future<void> _onUpdateExemplar(
    UpdateExemplarEvent event,
    Emitter<ExemplarManagementState> emit,
  ) async {
    if (event.weight == null &&
        event.notes == null &&
        event.exemplarKind == null) {
      emit(const ExemplarManagementError(
          Failure('No fields to update')));
      return;
    }

    final current = state;
    if (current is ExemplarManagementLoaded) {
      emit(current.copyWith(
        updatingExemplarIds: {...current.updatingExemplarIds, event.exemplarId},
      ));
    }

    final result = await _dataSource.updateExemplar(
      event.exemplarId,
      weight: event.weight,
      notes: event.notes,
      exemplarKind: event.exemplarKind,
    );

    if (result.isLeft()) {
      final failure = result.fold((f) => f, (_) => null)!;
      final current = state;
      if (current is ExemplarManagementLoaded) {
        emit(current.copyWith(
          updatingExemplarIds: {...current.updatingExemplarIds}
            ..remove(event.exemplarId),
        ));
      }
      emit(ExemplarManagementError(failure));
      return;
    }

    final listResult = await _dataSource.getExemplars(_currentTypeId);
    listResult.fold(
      (failure) => emit(ExemplarManagementError(failure)),
      (exemplars) => emit(ExemplarManagementLoaded(
        exemplars: exemplars,
        updatingExemplarIds: const {},
      )),
    );
  }
}
