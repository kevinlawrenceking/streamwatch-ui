import 'package:equatable/equatable.dart';
import '../../../shared/errors/failures/failure.dart';

abstract class RuleManagementState extends Equatable {
  const RuleManagementState();

  @override
  List<Object?> get props => [];
}

class RuleManagementInitial extends RuleManagementState {
  const RuleManagementInitial();
}

class RuleManagementSubmitting extends RuleManagementState {
  const RuleManagementSubmitting();
}

class RuleManagementSuccess extends RuleManagementState {
  final String message;

  const RuleManagementSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class RuleManagementError extends RuleManagementState {
  final Failure failure;

  const RuleManagementError(this.failure);

  @override
  List<Object?> get props => [failure];
}
