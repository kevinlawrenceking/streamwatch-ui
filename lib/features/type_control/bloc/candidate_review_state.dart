import 'package:equatable/equatable.dart';
import '../../../data/models/video_type_model.dart';
import '../../../shared/errors/failures/failure.dart';

abstract class CandidateReviewState extends Equatable {
  const CandidateReviewState();

  @override
  List<Object?> get props => [];
}

class CandidateReviewInitial extends CandidateReviewState {
  const CandidateReviewInitial();
}

class CandidateReviewLoading extends CandidateReviewState {
  const CandidateReviewLoading();
}

class CandidateReviewLoaded extends CandidateReviewState {
  final List<VideoTypeRuleCandidateModel> candidates;
  final bool isSubmitting;

  const CandidateReviewLoaded({
    required this.candidates,
    this.isSubmitting = false,
  });

  @override
  List<Object?> get props => [candidates, isSubmitting];

  CandidateReviewLoaded copyWith({
    List<VideoTypeRuleCandidateModel>? candidates,
    bool? isSubmitting,
  }) {
    return CandidateReviewLoaded(
      candidates: candidates ?? this.candidates,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

class CandidateReviewError extends CandidateReviewState {
  final Failure failure;

  const CandidateReviewError(this.failure);

  @override
  List<Object?> get props => [failure];
}
