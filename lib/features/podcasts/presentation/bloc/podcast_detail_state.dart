part of 'podcast_detail_bloc.dart';

/// States for the PodcastDetail BLoC.
abstract class PodcastDetailState extends Equatable {
  const PodcastDetailState();

  @override
  List<Object?> get props => [];
}

/// Initial state before detail is loaded.
class PodcastDetailInitial extends PodcastDetailState {
  const PodcastDetailInitial();
}

/// Loading state while fetching detail.
class PodcastDetailLoading extends PodcastDetailState {
  const PodcastDetailLoading();
}

/// Podcast detail loaded with platforms and schedules.
class PodcastDetailLoaded extends PodcastDetailState {
  final PodcastModel podcast;
  final List<PodcastPlatformModel> platforms;
  final List<PodcastScheduleModel> schedules;
  final String? actionError;
  final String? actionSuccess;

  const PodcastDetailLoaded({
    required this.podcast,
    required this.platforms,
    required this.schedules,
    this.actionError,
    this.actionSuccess,
  });

  @override
  List<Object?> get props =>
      [podcast, platforms, schedules, actionError, actionSuccess];

  PodcastDetailLoaded copyWith({
    PodcastModel? podcast,
    List<PodcastPlatformModel>? platforms,
    List<PodcastScheduleModel>? schedules,
    String? actionError,
    String? actionSuccess,
    bool clearActionError = false,
    bool clearActionSuccess = false,
  }) {
    return PodcastDetailLoaded(
      podcast: podcast ?? this.podcast,
      platforms: platforms ?? this.platforms,
      schedules: schedules ?? this.schedules,
      actionError:
          clearActionError ? null : (actionError ?? this.actionError),
      actionSuccess:
          clearActionSuccess ? null : (actionSuccess ?? this.actionSuccess),
    );
  }
}

/// Error state for detail loading.
class PodcastDetailError extends PodcastDetailState {
  final String message;

  const PodcastDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
