import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/errors/failures/failure.dart';
import '../constants/report_keys.dart';
import '../data/data_sources/reports_data_source.dart';

part 'reports_dashboard_event.dart';
part 'reports_dashboard_state.dart';

/// Fan-out bloc that fetches one `total` count per WO-065 report slug and
/// renders them as a row of 7 cards on the scheduler view.
///
/// Per-slug error isolation: a single failed endpoint leaves the other 6
/// cards populated. The state exposes both `counts` (slugs that succeeded)
/// and `errors` (slugs that failed) — the view renders badges accordingly.
class ReportsDashboardBloc
    extends Bloc<ReportsDashboardEvent, ReportsDashboardState> {
  final IReportsDataSource _dataSource;

  ReportsDashboardBloc({required IReportsDataSource dataSource})
      : _dataSource = dataSource,
        super(const ReportsDashboardInitial()) {
    on<LoadReportsDashboard>(_onLoad);
    on<RefreshReportsDashboard>(_onRefresh);
  }

  Future<void> _onLoad(
    LoadReportsDashboard event,
    Emitter<ReportsDashboardState> emit,
  ) async {
    emit(const ReportsDashboardLoading());
    await _fetchAll(emit);
  }

  Future<void> _onRefresh(
    RefreshReportsDashboard event,
    Emitter<ReportsDashboardState> emit,
  ) async {
    await _fetchAll(emit);
  }

  Future<void> _fetchAll(Emitter<ReportsDashboardState> emit) async {
    final results = await Future.wait(
      kReports.map((r) => _safeFetchCount(r.key)),
      eagerError: false,
    );

    final counts = <String, int>{};
    final errors = <String, String>{};
    for (final r in results) {
      if (r.error != null) {
        errors[r.slug] = r.error!;
      } else {
        counts[r.slug] = r.total ?? 0;
      }
    }
    emit(ReportsDashboardLoaded(counts: counts, errors: errors));
  }

  Future<_CountResult> _safeFetchCount(String slug) async {
    try {
      final either = await _countForSlug(slug);
      return either.fold(
        (failure) => _CountResult(slug: slug, error: failure.message),
        (total) => _CountResult(slug: slug, total: total),
      );
    } catch (e) {
      return _CountResult(slug: slug, error: e.toString());
    }
  }

  /// Dispatch one pageSize=1 list call per slug and extract the envelope's
  /// `total`. No dedicated count endpoint exists server-side, so we reuse
  /// the list endpoint with a minimum page_size to minimize payload.
  Future<Either<Failure, int>> _countForSlug(String slug) async {
    switch (slug) {
      case 'expected-today':
        final r = await _dataSource.expectedTodayScheduleSlots(
            page: 1, pageSize: 1);
        return r.map((p) => p.total);
      case 'late':
        final r = await _dataSource.lateScheduleSlots(page: 1, pageSize: 1);
        return r.map((p) => p.total);
      case 'recent':
        final r = await _dataSource.recentEpisodes(page: 1, pageSize: 1);
        return r.map((p) => p.total);
      case 'transcript-pending':
        final r = await _dataSource.transcriptPendingEpisodes(
            page: 1, pageSize: 1);
        return r.map((p) => p.total);
      case 'headline-ready':
        final r = await _dataSource.headlineReadyEpisodes(
            page: 1, pageSize: 1);
        return r.map((p) => p.total);
      case 'pending-review':
        final r = await _dataSource.pendingReviewEpisodes(
            page: 1, pageSize: 1);
        return r.map((p) => p.total);
      case 'pending-clip-request':
        final r = await _dataSource.pendingClipRequestEpisodes(
            page: 1, pageSize: 1);
        return r.map((p) => p.total);
      default:
        return Left(GeneralFailure('Unknown report slug: $slug'));
    }
  }
}

class _CountResult {
  final String slug;
  final int? total;
  final String? error;
  const _CountResult({required this.slug, this.total, this.error});
}
