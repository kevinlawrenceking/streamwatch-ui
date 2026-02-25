import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:streamwatch_frontend/data/models/video_type_model.dart';
import 'package:streamwatch_frontend/data/sources/video_type_data_source.dart';
import 'package:streamwatch_frontend/features/type_control/bloc/rule_management_bloc.dart';
import 'package:streamwatch_frontend/features/type_control/bloc/rule_management_event.dart';
import 'package:streamwatch_frontend/features/type_control/bloc/rule_management_state.dart';
import 'package:streamwatch_frontend/shared/errors/failures/failure.dart';

class MockVideoTypeDataSource extends Mock implements IVideoTypeDataSource {}

void main() {
  late MockVideoTypeDataSource mockDataSource;
  late RuleManagementBloc bloc;

  final tRule = VideoTypeRuleModel(
    id: 'rule-1',
    versionId: 'ver-1',
    ruleText: 'Test rule text',
    ruleOrder: 1,
    status: 'active',
    source: 'manual',
    createdAt: DateTime(2026, 1, 1),
  );

  setUp(() {
    mockDataSource = MockVideoTypeDataSource();
    bloc = RuleManagementBloc(dataSource: mockDataSource);
  });

  tearDown(() {
    bloc.close();
  });

  group('RuleManagementBloc', () {
    test('initial state is RuleManagementInitial', () {
      expect(bloc.state, const RuleManagementInitial());
    });

    blocTest<RuleManagementBloc, RuleManagementState>(
      'emits [Submitting, Success] when CreateRuleEvent succeeds',
      build: () {
        when(() => mockDataSource.createRule(any(), any()))
            .thenAnswer((_) async => Right(tRule));
        return bloc;
      },
      act: (bloc) => bloc.add(const CreateRuleEvent(
        versionId: 'ver-1',
        ruleText: 'Test rule text',
      )),
      expect: () => [
        const RuleManagementSubmitting(),
        const RuleManagementSuccess('Rule created'),
      ],
    );

    blocTest<RuleManagementBloc, RuleManagementState>(
      'emits [Submitting, Error] when CreateRuleEvent fails',
      build: () {
        when(() => mockDataSource.createRule(any(), any()))
            .thenAnswer((_) async => const Left(Failure('fail')));
        return bloc;
      },
      act: (bloc) => bloc.add(const CreateRuleEvent(
        versionId: 'ver-1',
        ruleText: 'Test rule text',
      )),
      expect: () => [
        const RuleManagementSubmitting(),
        const RuleManagementError(Failure('fail')),
      ],
    );

    blocTest<RuleManagementBloc, RuleManagementState>(
      'emits [Submitting, Success] when UpdateRuleEvent succeeds',
      build: () {
        when(() => mockDataSource.updateRule(any(), any()))
            .thenAnswer((_) async => Right(tRule));
        return bloc;
      },
      act: (bloc) => bloc.add(const UpdateRuleEvent(
        ruleId: 'rule-1',
        ruleText: 'Updated text',
      )),
      expect: () => [
        const RuleManagementSubmitting(),
        const RuleManagementSuccess('Rule updated'),
      ],
    );

    blocTest<RuleManagementBloc, RuleManagementState>(
      'emits [Submitting, Success] when DeprecateRuleEvent succeeds',
      build: () {
        when(() => mockDataSource.deprecateRule(any()))
            .thenAnswer((_) async => Right(tRule));
        return bloc;
      },
      act: (bloc) => bloc.add(const DeprecateRuleEvent('rule-1')),
      expect: () => [
        const RuleManagementSubmitting(),
        const RuleManagementSuccess('Rule deprecated'),
      ],
    );

    blocTest<RuleManagementBloc, RuleManagementState>(
      'emits [Submitting, Error] when DeprecateRuleEvent fails',
      build: () {
        when(() => mockDataSource.deprecateRule(any()))
            .thenAnswer((_) async => const Left(Failure('fail')));
        return bloc;
      },
      act: (bloc) => bloc.add(const DeprecateRuleEvent('rule-1')),
      expect: () => [
        const RuleManagementSubmitting(),
        const RuleManagementError(Failure('fail')),
      ],
    );

    blocTest<RuleManagementBloc, RuleManagementState>(
      'emits [Submitting, Success] when ReorderRulesEvent succeeds',
      build: () {
        when(() => mockDataSource.reorderRules(any(), any()))
            .thenAnswer((_) async => Right([tRule]));
        return bloc;
      },
      act: (bloc) => bloc.add(const ReorderRulesEvent(
        versionId: 'ver-1',
        orderedRuleIds: ['rule-1', 'rule-2'],
      )),
      expect: () => [
        const RuleManagementSubmitting(),
        const RuleManagementSuccess('Rules reordered'),
      ],
    );
  });
}
