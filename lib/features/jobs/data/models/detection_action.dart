import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Immutable model for a detection action row from
/// `GET /api/v1/detection-runs/{id}/actions`.
///
/// Per KB section 18g.3 schema. The list endpoint orders ascending by
/// `sequenceIndex` (KB section 18g.2 amendment 7), so the UI renders rows
/// in sequence order without re-sorting.
@immutable
class DetectionAction extends Equatable {
  final String id;
  final String runId;
  final int sequenceIndex;
  final String actionType;
  final Map<String, dynamic>? payloadJson;
  final String? resultCode;
  final DateTime createdAt;

  const DetectionAction({
    required this.id,
    required this.runId,
    required this.sequenceIndex,
    required this.actionType,
    this.payloadJson,
    this.resultCode,
    required this.createdAt,
  });

  factory DetectionAction.fromJsonDto(Map<String, dynamic> json) {
    final payloadRaw = json['payload_json'];
    return DetectionAction(
      id: json['id'] as String,
      runId: json['run_id'] as String,
      sequenceIndex: json['sequence_index'] as int,
      actionType: json['action_type'] as String,
      payloadJson: payloadRaw is Map<String, dynamic> ? payloadRaw : null,
      resultCode: json['result_code'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJsonDto() {
    return {
      'id': id,
      'run_id': runId,
      'sequence_index': sequenceIndex,
      'action_type': actionType,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (resultCode != null) 'result_code': resultCode,
      'created_at': createdAt.toIso8601String(),
    };
  }

  DetectionAction copyWith({
    String? id,
    String? runId,
    int? sequenceIndex,
    String? actionType,
    Map<String, dynamic>? payloadJson,
    String? resultCode,
    DateTime? createdAt,
  }) {
    return DetectionAction(
      id: id ?? this.id,
      runId: runId ?? this.runId,
      sequenceIndex: sequenceIndex ?? this.sequenceIndex,
      actionType: actionType ?? this.actionType,
      payloadJson: payloadJson ?? this.payloadJson,
      resultCode: resultCode ?? this.resultCode,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        runId,
        sequenceIndex,
        actionType,
        payloadJson,
        resultCode,
        createdAt,
      ];
}
