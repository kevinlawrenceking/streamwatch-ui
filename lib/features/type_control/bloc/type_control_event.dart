import 'package:equatable/equatable.dart';

/// Events for the TypeControl BLoC.
abstract class TypeControlEvent extends Equatable {
  const TypeControlEvent();

  @override
  List<Object?> get props => [];
}

/// Load all video types.
class LoadTypesEvent extends TypeControlEvent {
  const LoadTypesEvent();
}

/// Select a video type to view its detail (versions, rules, prompt).
class SelectTypeEvent extends TypeControlEvent {
  final String videoTypeId;

  const SelectTypeEvent(this.videoTypeId);

  @override
  List<Object?> get props => [videoTypeId];
}

/// Load versions for a video type.
class LoadVersionsEvent extends TypeControlEvent {
  final String videoTypeId;

  const LoadVersionsEvent(this.videoTypeId);

  @override
  List<Object?> get props => [videoTypeId];
}

/// Load rules for a specific version.
class LoadRulesEvent extends TypeControlEvent {
  final String versionId;

  const LoadRulesEvent(this.versionId);

  @override
  List<Object?> get props => [versionId];
}

/// Render the prompt for a video type's active version.
class RenderTypePromptEvent extends TypeControlEvent {
  final String videoTypeId;

  const RenderTypePromptEvent(this.videoTypeId);

  @override
  List<Object?> get props => [videoTypeId];
}

/// Render the prompt for a specific version.
class RenderVersionPromptEvent extends TypeControlEvent {
  final String versionId;

  const RenderVersionPromptEvent(this.versionId);

  @override
  List<Object?> get props => [versionId];
}

/// Activate a draft version.
class ActivateVersionEvent extends TypeControlEvent {
  final String versionId;
  final String videoTypeId;

  const ActivateVersionEvent({
    required this.versionId,
    required this.videoTypeId,
  });

  @override
  List<Object?> get props => [versionId, videoTypeId];
}

/// Rollback a video type to the previous version.
class RollbackVersionEvent extends TypeControlEvent {
  final String videoTypeId;

  const RollbackVersionEvent(this.videoTypeId);

  @override
  List<Object?> get props => [videoTypeId];
}
