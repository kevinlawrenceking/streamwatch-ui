import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/errors/failures/failure.dart';
import '../../../podcasts/data/data_sources/podcast_data_source.dart'
    show PaginatedResponse;
import '../data/data_sources/reports_data_source.dart';
import '../data/models/podcast_schedule_slot.dart';

part 'reported_slots_event.dart';
part 'reported_slots_state.dart';

/// Bloc for the slot-valued drill-downs (expected-today, late).
///
/// Infinite-scroll + load-more mirrors EpisodeListBloc — page 2+ appends
/// onto the existing Loaded state without emitting Loading.
class ReportedSlotsBloc extends Bloc<ReportedSlotsEvent, ReportedSlotsState> {
  final IReportsDataSource _dataSource;

  ReportedSlotsBloc({required IReportsDataSource dataSource})
      : _dataSource = dataSource,
        super(const ReportedSlotsInitial()) {
    on<FetchReportedSlotsEvent>(_onFetch);
  }

  Future<void> _onFetch(
    FetchReportedSlotsEvent event,
    Emitter<ReportedSlotsState> emit,
  ) async {
    final currentState = state;
    final isLoadMore =
        event.page > 1 && currentState is ReportedSlotsLoaded;

    if (!isLoadMore) {
      emit(const ReportedSlotsLoading());
    }

    final result = await _fetchForSlug(
      event.reportKey,
      page: event.page,
      pageSize: event.pageSize,
    );

    result.fold(
      (failure) => emit(ReportedSlotsError(failure.message)),
      (response) {
        final allSlots = isLoadMore
            ? [...currentState.slots, ...response.items]
            : response.items;
        emit(ReportedSlotsLoaded(
          reportKey: event.reportKey,
          slots: allSlots,
          hasMore: response.hasMore,
          currentPage: event.page,
        ));
      },
    );
  }

  Future<Either<Failure, PaginatedResponse<PodcastScheduleSlot>>> _fetchForSlug(
    String slug, {
    required int page,
    required int pageSize,
  }) {
    switch (slug) {
      case 'expected-today':
        return _dataSource.expectedTodayScheduleSlots(
            page: page, pageSize: pageSize);
      case 'late':
        return _dataSource.lateScheduleSlots(page: page, pageSize: pageSize);
      default:
        return Future.value(
          Left(GeneralFailure('Unknown slot report slug: $slug')),
        );
    }
  }
}
