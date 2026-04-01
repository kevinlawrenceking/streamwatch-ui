import 'package:equatable/equatable.dart';
import '../../../data/models/video_type_model.dart';
import '../../../shared/errors/failures/failure.dart';

abstract class ExemplarManagementState extends Equatable {
  const ExemplarManagementState();

  @override
  List<Object?> get props => [];
}

class ExemplarManagementInitial extends ExemplarManagementState {
  const ExemplarManagementInitial();
}

class ExemplarManagementLoading extends ExemplarManagementState {
  const ExemplarManagementLoading();
}

class ExemplarManagementLoaded extends ExemplarManagementState {
  final List<VideoTypeExemplarModel> exemplars;
  final bool isSubmitting;
  final Set<String> updatingExemplarIds;

  const ExemplarManagementLoaded({
    required this.exemplars,
    this.isSubmitting = false,
    this.updatingExemplarIds = const {},
  });

  @override
  List<Object?> get props => [exemplars, isSubmitting, updatingExemplarIds];

  ExemplarManagementLoaded copyWith({
    List<VideoTypeExemplarModel>? exemplars,
    bool? isSubmitting,
    Set<String>? updatingExemplarIds,
  }) {
    return ExemplarManagementLoaded(
      exemplars: exemplars ?? this.exemplars,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      updatingExemplarIds: updatingExemplarIds ?? this.updatingExemplarIds,
    );
  }
}

class ExemplarManagementError extends ExemplarManagementState {
  final Failure failure;

  const ExemplarManagementError(this.failure);

  @override
  List<Object?> get props => [failure];
}
