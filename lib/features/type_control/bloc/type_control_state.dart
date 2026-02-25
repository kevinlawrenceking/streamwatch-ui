import 'package:equatable/equatable.dart';
import '../../../data/models/video_type_model.dart';
import '../../../shared/errors/failures/failure.dart';

/// States for the TypeControl BLoC.
abstract class TypeControlState extends Equatable {
  const TypeControlState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any data is loaded.
class TypeControlInitial extends TypeControlState {
  const TypeControlInitial();
}

/// Loading state while fetching types.
class TypeControlLoading extends TypeControlState {
  const TypeControlLoading();
}

/// Types loaded successfully.
class TypeControlLoaded extends TypeControlState {
  final List<VideoTypeModel> types;
  final String? actionError;
  final String? actionSuccess;

  const TypeControlLoaded({
    required this.types,
    this.actionError,
    this.actionSuccess,
  });

  @override
  List<Object?> get props => [types, actionError, actionSuccess];

  TypeControlLoaded copyWith({
    List<VideoTypeModel>? types,
    String? actionError,
    String? actionSuccess,
    bool clearActionError = false,
    bool clearActionSuccess = false,
  }) {
    return TypeControlLoaded(
      types: types ?? this.types,
      actionError:
          clearActionError ? null : (actionError ?? this.actionError),
      actionSuccess:
          clearActionSuccess ? null : (actionSuccess ?? this.actionSuccess),
    );
  }
}

/// Error state when loading types fails.
class TypeControlError extends TypeControlState {
  final Failure failure;

  const TypeControlError(this.failure);

  @override
  List<Object?> get props => [failure];
}

/// State for the type detail screen.
abstract class TypeDetailState extends Equatable {
  const TypeDetailState();

  @override
  List<Object?> get props => [];
}

/// Initial state before detail data is loaded.
class TypeDetailInitial extends TypeDetailState {
  const TypeDetailInitial();
}

/// Loading state for type detail.
class TypeDetailLoading extends TypeDetailState {
  const TypeDetailLoading();
}

/// Type detail loaded with versions and optionally rules/prompt.
class TypeDetailLoaded extends TypeDetailState {
  final VideoTypeModel type;
  final List<VideoTypeVersionModel> versions;
  final List<VideoTypeRuleModel>? rules;
  final String? selectedVersionId;
  final RenderedPromptModel? renderedPrompt;
  final bool isPromptLoading;
  final bool isRulesLoading;
  final String? actionError;
  final String? actionSuccess;

  const TypeDetailLoaded({
    required this.type,
    required this.versions,
    this.rules,
    this.selectedVersionId,
    this.renderedPrompt,
    this.isPromptLoading = false,
    this.isRulesLoading = false,
    this.actionError,
    this.actionSuccess,
  });

  @override
  List<Object?> get props => [
        type,
        versions,
        rules,
        selectedVersionId,
        renderedPrompt,
        isPromptLoading,
        isRulesLoading,
        actionError,
        actionSuccess,
      ];

  /// Get the active version, if any.
  VideoTypeVersionModel? get activeVersion =>
      versions.where((v) => v.isActive).firstOrNull;

  TypeDetailLoaded copyWith({
    VideoTypeModel? type,
    List<VideoTypeVersionModel>? versions,
    List<VideoTypeRuleModel>? rules,
    String? selectedVersionId,
    RenderedPromptModel? renderedPrompt,
    bool? isPromptLoading,
    bool? isRulesLoading,
    String? actionError,
    String? actionSuccess,
    bool clearRules = false,
    bool clearPrompt = false,
    bool clearSelectedVersion = false,
    bool clearActionError = false,
    bool clearActionSuccess = false,
  }) {
    return TypeDetailLoaded(
      type: type ?? this.type,
      versions: versions ?? this.versions,
      rules: clearRules ? null : (rules ?? this.rules),
      selectedVersionId: clearSelectedVersion
          ? null
          : (selectedVersionId ?? this.selectedVersionId),
      renderedPrompt:
          clearPrompt ? null : (renderedPrompt ?? this.renderedPrompt),
      isPromptLoading: isPromptLoading ?? this.isPromptLoading,
      isRulesLoading: isRulesLoading ?? this.isRulesLoading,
      actionError:
          clearActionError ? null : (actionError ?? this.actionError),
      actionSuccess:
          clearActionSuccess ? null : (actionSuccess ?? this.actionSuccess),
    );
  }
}

/// Error state for type detail.
class TypeDetailError extends TypeDetailState {
  final Failure failure;

  const TypeDetailError(this.failure);

  @override
  List<Object?> get props => [failure];
}
