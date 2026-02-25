import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/sources/video_type_data_source.dart';
import 'rule_management_event.dart';
import 'rule_management_state.dart';

class RuleManagementBloc
    extends Bloc<RuleManagementEvent, RuleManagementState> {
  final IVideoTypeDataSource _dataSource;

  RuleManagementBloc({required IVideoTypeDataSource dataSource})
      : _dataSource = dataSource,
        super(const RuleManagementInitial()) {
    on<CreateRuleEvent>(_onCreateRule);
    on<UpdateRuleEvent>(_onUpdateRule);
    on<DeprecateRuleEvent>(_onDeprecateRule);
    on<ReorderRulesEvent>(_onReorderRules);
  }

  Future<void> _onCreateRule(
    CreateRuleEvent event,
    Emitter<RuleManagementState> emit,
  ) async {
    emit(const RuleManagementSubmitting());
    final body = <String, dynamic>{
      'rule_text': event.ruleText,
      if (event.ruleOrder != null) 'rule_order': event.ruleOrder,
      if (event.source != null) 'source': event.source,
      if (event.evidence != null) 'evidence': event.evidence,
    };
    final result = await _dataSource.createRule(event.versionId, body);
    result.fold(
      (failure) => emit(RuleManagementError(failure)),
      (_) => emit(const RuleManagementSuccess('Rule created')),
    );
  }

  Future<void> _onUpdateRule(
    UpdateRuleEvent event,
    Emitter<RuleManagementState> emit,
  ) async {
    emit(const RuleManagementSubmitting());
    final body = <String, dynamic>{
      if (event.ruleText != null) 'rule_text': event.ruleText,
      if (event.ruleOrder != null) 'rule_order': event.ruleOrder,
      if (event.source != null) 'source': event.source,
      if (event.evidence != null) 'evidence': event.evidence,
    };
    final result = await _dataSource.updateRule(event.ruleId, body);
    result.fold(
      (failure) => emit(RuleManagementError(failure)),
      (_) => emit(const RuleManagementSuccess('Rule updated')),
    );
  }

  Future<void> _onDeprecateRule(
    DeprecateRuleEvent event,
    Emitter<RuleManagementState> emit,
  ) async {
    emit(const RuleManagementSubmitting());
    final result = await _dataSource.deprecateRule(event.ruleId);
    result.fold(
      (failure) => emit(RuleManagementError(failure)),
      (_) => emit(const RuleManagementSuccess('Rule deprecated')),
    );
  }

  Future<void> _onReorderRules(
    ReorderRulesEvent event,
    Emitter<RuleManagementState> emit,
  ) async {
    emit(const RuleManagementSubmitting());
    final result =
        await _dataSource.reorderRules(event.versionId, event.orderedRuleIds);
    result.fold(
      (failure) => emit(RuleManagementError(failure)),
      (_) => emit(const RuleManagementSuccess('Rules reordered')),
    );
  }
}
