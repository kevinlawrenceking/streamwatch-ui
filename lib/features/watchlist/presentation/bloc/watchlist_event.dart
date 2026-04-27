part of 'watchlist_bloc.dart';

abstract class WatchlistEvent extends Equatable {
  const WatchlistEvent();
  @override
  List<Object?> get props => [];
}

class LoadGuestWatchlistEvent extends WatchlistEvent {
  final String? status;
  const LoadGuestWatchlistEvent({this.status});
  @override
  List<Object?> get props => [status];
}

class WatchlistFilterChangedEvent extends WatchlistEvent {
  final String? status; // null = all
  const WatchlistFilterChangedEvent(this.status);
  @override
  List<Object?> get props => [status];
}

class CreateWatchlistEntryEvent extends WatchlistEvent {
  final Map<String, dynamic> body;
  const CreateWatchlistEntryEvent(this.body);
  @override
  List<Object?> get props => [body];
}

class PatchWatchlistEntryEvent extends WatchlistEvent {
  final String entryId;
  final PatchGuestWatchlistEntryRequest request;
  const PatchWatchlistEntryEvent({
    required this.entryId,
    required this.request,
  });
  @override
  List<Object?> get props => [entryId, request];
}

class ChangeWatchlistStatusEvent extends WatchlistEvent {
  final String entryId;
  final ChangeWatchlistStatusRequest request;
  const ChangeWatchlistStatusEvent({
    required this.entryId,
    required this.request,
  });
  @override
  List<Object?> get props => [entryId, request];
}

/// Disambiguated per §30.10 -- jobs / detection have parallel events
/// with distinct names (JobsErrorAcknowledged, DetectionErrorAcknowledged).
class WatchlistErrorAcknowledged extends WatchlistEvent {
  const WatchlistErrorAcknowledged();
}
