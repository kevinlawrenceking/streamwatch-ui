import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/sources/video_type_data_source.dart';
import 'exemplar_management_event.dart';
import 'exemplar_management_state.dart';

class ExemplarManagementBloc
    extends Bloc<ExemplarManagementEvent, ExemplarManagementState> {
  final IVideoTypeDataSource _dataSource;

  ExemplarManagementBloc({required IVideoTypeDataSource dataSource})
      : _dataSource = dataSource,
        super(const ExemplarManagementInitial()) {
    on<LoadExemplarsEvent>(_onLoadExemplars);
    on<BulkCreateExemplarsEvent>(_onBulkCreateExemplars);
    on<DeleteExemplarEvent>(_onDeleteExemplar);
  }

  Future<void> _onLoadExemplars(
    LoadExemplarsEvent event,
    Emitter<ExemplarManagementState> emit,
  ) async {
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
      'clip_ids': event.clipIds,
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
}
