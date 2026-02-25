import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/sources/video_type_data_source.dart';
import 'candidate_review_event.dart';
import 'candidate_review_state.dart';

class CandidateReviewBloc
    extends Bloc<CandidateReviewEvent, CandidateReviewState> {
  final IVideoTypeDataSource _dataSource;

  CandidateReviewBloc({required IVideoTypeDataSource dataSource})
      : _dataSource = dataSource,
        super(const CandidateReviewInitial()) {
    on<LoadCandidatesEvent>(_onLoadCandidates);
    on<ApproveCandidateEvent>(_onApproveCandidate);
    on<RejectCandidateEvent>(_onRejectCandidate);
    on<MergeCandidateEvent>(_onMergeCandidate);
  }

  Future<void> _onLoadCandidates(
    LoadCandidatesEvent event,
    Emitter<CandidateReviewState> emit,
  ) async {
    emit(const CandidateReviewLoading());
    final result = await _dataSource.getCandidates(event.videoTypeId);
    result.fold(
      (failure) => emit(CandidateReviewError(failure)),
      (candidates) =>
          emit(CandidateReviewLoaded(candidates: candidates)),
    );
  }

  Future<void> _onApproveCandidate(
    ApproveCandidateEvent event,
    Emitter<CandidateReviewState> emit,
  ) async {
    final current = state;
    if (current is CandidateReviewLoaded) {
      emit(current.copyWith(isSubmitting: true));
    }
    final body = <String, dynamic>{
      if (event.ruleText != null) 'rule_text': event.ruleText,
      if (event.ruleOrder != null) 'rule_order': event.ruleOrder,
      if (event.source != null) 'source': event.source,
      if (event.evidence != null) 'evidence': event.evidence,
    };
    final result =
        await _dataSource.approveCandidate(event.candidateId, body);
    result.fold(
      (failure) => emit(CandidateReviewError(failure)),
      (_) => add(LoadCandidatesEvent(event.videoTypeId)),
    );
  }

  Future<void> _onRejectCandidate(
    RejectCandidateEvent event,
    Emitter<CandidateReviewState> emit,
  ) async {
    final current = state;
    if (current is CandidateReviewLoaded) {
      emit(current.copyWith(isSubmitting: true));
    }
    final result =
        await _dataSource.rejectCandidate(event.candidateId, event.reason);
    result.fold(
      (failure) => emit(CandidateReviewError(failure)),
      (_) => add(LoadCandidatesEvent(event.videoTypeId)),
    );
  }

  Future<void> _onMergeCandidate(
    MergeCandidateEvent event,
    Emitter<CandidateReviewState> emit,
  ) async {
    final current = state;
    if (current is CandidateReviewLoaded) {
      emit(current.copyWith(isSubmitting: true));
    }
    final body = <String, dynamic>{
      'target_rule_id': event.targetRuleId,
      if (event.ruleText != null) 'rule_text': event.ruleText,
      if (event.evidence != null) 'evidence': event.evidence,
    };
    final result =
        await _dataSource.mergeCandidate(event.candidateId, body);
    result.fold(
      (failure) => emit(CandidateReviewError(failure)),
      (_) => add(LoadCandidatesEvent(event.videoTypeId)),
    );
  }
}
