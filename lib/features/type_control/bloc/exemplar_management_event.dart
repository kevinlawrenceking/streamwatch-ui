import 'package:equatable/equatable.dart';

abstract class ExemplarManagementEvent extends Equatable {
  const ExemplarManagementEvent();

  @override
  List<Object?> get props => [];
}

class LoadExemplarsEvent extends ExemplarManagementEvent {
  final String videoTypeId;

  const LoadExemplarsEvent(this.videoTypeId);

  @override
  List<Object?> get props => [videoTypeId];
}

class BulkCreateExemplarsEvent extends ExemplarManagementEvent {
  final String videoTypeId;
  final List<String> clipIds;
  final String? exemplarKind;
  final String? notes;

  const BulkCreateExemplarsEvent({
    required this.videoTypeId,
    required this.clipIds,
    this.exemplarKind,
    this.notes,
  });

  @override
  List<Object?> get props => [videoTypeId, clipIds, exemplarKind, notes];
}

class DeleteExemplarEvent extends ExemplarManagementEvent {
  final String exemplarId;
  final String videoTypeId;

  const DeleteExemplarEvent({
    required this.exemplarId,
    required this.videoTypeId,
  });

  @override
  List<Object?> get props => [exemplarId, videoTypeId];
}
