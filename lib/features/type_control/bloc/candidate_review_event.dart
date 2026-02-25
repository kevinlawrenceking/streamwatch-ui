import 'package:equatable/equatable.dart';

abstract class CandidateReviewEvent extends Equatable {
  const CandidateReviewEvent();

  @override
  List<Object?> get props => [];
}

class LoadCandidatesEvent extends CandidateReviewEvent {
  final String videoTypeId;

  const LoadCandidatesEvent(this.videoTypeId);

  @override
  List<Object?> get props => [videoTypeId];
}

class ApproveCandidateEvent extends CandidateReviewEvent {
  final String candidateId;
  final String videoTypeId;
  final String? ruleText;
  final int? ruleOrder;
  final String? source;
  final Map<String, dynamic>? evidence;

  const ApproveCandidateEvent({
    required this.candidateId,
    required this.videoTypeId,
    this.ruleText,
    this.ruleOrder,
    this.source,
    this.evidence,
  });

  @override
  List<Object?> get props =>
      [candidateId, videoTypeId, ruleText, ruleOrder, source, evidence];
}

class RejectCandidateEvent extends CandidateReviewEvent {
  final String candidateId;
  final String videoTypeId;
  final String reason;

  const RejectCandidateEvent({
    required this.candidateId,
    required this.videoTypeId,
    required this.reason,
  });

  @override
  List<Object?> get props => [candidateId, videoTypeId, reason];
}

class MergeCandidateEvent extends CandidateReviewEvent {
  final String candidateId;
  final String videoTypeId;
  final String targetRuleId;
  final String? ruleText;
  final Map<String, dynamic>? evidence;

  const MergeCandidateEvent({
    required this.candidateId,
    required this.videoTypeId,
    required this.targetRuleId,
    this.ruleText,
    this.evidence,
  });

  @override
  List<Object?> get props =>
      [candidateId, videoTypeId, targetRuleId, ruleText, evidence];
}
