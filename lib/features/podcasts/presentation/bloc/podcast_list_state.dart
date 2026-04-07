part of 'podcast_list_bloc.dart';

/// States for the PodcastList BLoC.
abstract class PodcastListState extends Equatable {
  const PodcastListState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any data is loaded.
class PodcastListInitial extends PodcastListState {
  const PodcastListInitial();
}

/// Loading state while fetching podcasts.
class PodcastListLoading extends PodcastListState {
  const PodcastListLoading();
}

/// Podcasts loaded successfully.
class PodcastListLoaded extends PodcastListState {
  final List<PodcastModel> podcasts;
  final bool hasMore;
  final bool includeInactive;
  final int currentPage;
  final String? actionError;
  final String? actionSuccess;

  const PodcastListLoaded({
    required this.podcasts,
    required this.hasMore,
    this.includeInactive = false,
    this.currentPage = 1,
    this.actionError,
    this.actionSuccess,
  });

  @override
  List<Object?> get props => [
        podcasts,
        hasMore,
        includeInactive,
        currentPage,
        actionError,
        actionSuccess,
      ];

  PodcastListLoaded copyWith({
    List<PodcastModel>? podcasts,
    bool? hasMore,
    bool? includeInactive,
    int? currentPage,
    String? actionError,
    String? actionSuccess,
    bool clearActionError = false,
    bool clearActionSuccess = false,
  }) {
    return PodcastListLoaded(
      podcasts: podcasts ?? this.podcasts,
      hasMore: hasMore ?? this.hasMore,
      includeInactive: includeInactive ?? this.includeInactive,
      currentPage: currentPage ?? this.currentPage,
      actionError:
          clearActionError ? null : (actionError ?? this.actionError),
      actionSuccess:
          clearActionSuccess ? null : (actionSuccess ?? this.actionSuccess),
    );
  }
}

/// Error state when loading podcasts fails.
class PodcastListError extends PodcastListState {
  final String message;

  const PodcastListError(this.message);

  @override
  List<Object?> get props => [message];
}
