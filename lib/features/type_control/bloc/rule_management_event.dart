import 'package:equatable/equatable.dart';

abstract class RuleManagementEvent extends Equatable {
  const RuleManagementEvent();

  @override
  List<Object?> get props => [];
}

class CreateRuleEvent extends RuleManagementEvent {
  final String versionId;
  final String ruleText;
  final int? ruleOrder;
  final String? source;
  final Map<String, dynamic>? evidence;

  const CreateRuleEvent({
    required this.versionId,
    required this.ruleText,
    this.ruleOrder,
    this.source,
    this.evidence,
  });

  @override
  List<Object?> get props => [versionId, ruleText, ruleOrder, source, evidence];
}

class UpdateRuleEvent extends RuleManagementEvent {
  final String ruleId;
  final String? ruleText;
  final int? ruleOrder;
  final String? source;
  final Map<String, dynamic>? evidence;

  const UpdateRuleEvent({
    required this.ruleId,
    this.ruleText,
    this.ruleOrder,
    this.source,
    this.evidence,
  });

  @override
  List<Object?> get props => [ruleId, ruleText, ruleOrder, source, evidence];
}

class DeprecateRuleEvent extends RuleManagementEvent {
  final String ruleId;

  const DeprecateRuleEvent(this.ruleId);

  @override
  List<Object?> get props => [ruleId];
}

class ReorderRulesEvent extends RuleManagementEvent {
  final String versionId;
  final List<String> orderedRuleIds;

  const ReorderRulesEvent({
    required this.versionId,
    required this.orderedRuleIds,
  });

  @override
  List<Object?> get props => [versionId, orderedRuleIds];
}
