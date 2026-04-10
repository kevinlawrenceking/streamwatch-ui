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
  final List<String> jobIds;
  final String? exemplarKind;
  final String? notes;

  const BulkCreateExemplarsEvent({
    required this.videoTypeId,
    required this.jobIds,
    this.exemplarKind,
    this.notes,
  });

  @override
  List<Object?> get props => [videoTypeId, jobIds, exemplarKind, notes];
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

class UpdateExemplarEvent extends ExemplarManagementEvent {
  final String exemplarId;
  final double? weight;
  final String? notes;
  final String? exemplarKind;

  const UpdateExemplarEvent({
    required this.exemplarId,
    this.weight,
    this.notes,
    this.exemplarKind,
  });

  @override
  List<Object?> get props => [exemplarId, weight, notes, exemplarKind];
}

class UploadExemplarImageEvent extends ExemplarManagementEvent {
  final String exemplarId;
  final String filePath;

  const UploadExemplarImageEvent({
    required this.exemplarId,
    required this.filePath,
  });

  @override
  List<Object?> get props => [exemplarId, filePath];
}
