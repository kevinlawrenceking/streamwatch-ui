part of 'watchlist_bloc.dart';

abstract class WatchlistState extends Equatable {
  const WatchlistState();
  @override
  List<Object?> get props => [];
}

class WatchlistInitial extends WatchlistState {
  const WatchlistInitial();
}

class WatchlistLoading extends WatchlistState {
  const WatchlistLoading();
}

class WatchlistLoaded extends WatchlistState {
  final List<PodcastGuestWatchlistEntry> entries;
  final String? statusFilter;
  final bool isMutating;
  final String? lastActionError;

  /// Success-toast field, distinct from `lastActionError`. Currently
  /// unused by Watchlist (the surface relies on inline row updates),
  /// but kept on the state class for symmetry with JobsState (L-1)
  /// and DetectionState (L-3-success). Cleared by
  /// [WatchlistErrorAcknowledged].
  final String? lastActionMessage;

  const WatchlistLoaded({
    required this.entries,
    this.statusFilter,
    this.isMutating = false,
    this.lastActionError,
    this.lastActionMessage,
  });

  WatchlistLoaded copyWith({
    List<PodcastGuestWatchlistEntry>? entries,
    String? statusFilter,
    bool? isMutating,
    String? lastActionError,
    String? lastActionMessage,
    bool clearLastActionError = false,
    bool clearLastActionMessage = false,
    bool clearStatusFilter = false,
  }) {
    return WatchlistLoaded(
      entries: entries ?? this.entries,
      statusFilter:
          clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      isMutating: isMutating ?? this.isMutating,
      lastActionError: clearLastActionError
          ? null
          : (lastActionError ?? this.lastActionError),
      lastActionMessage: clearLastActionMessage
          ? null
          : (lastActionMessage ?? this.lastActionMessage),
    );
  }

  @override
  List<Object?> get props => [
        entries,
        statusFilter,
        isMutating,
        lastActionError,
        lastActionMessage,
      ];
}

class WatchlistError extends WatchlistState {
  final String message;
  const WatchlistError(this.message);
  @override
  List<Object?> get props => [message];
}
