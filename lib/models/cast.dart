/// Represents a cast member defined for a video
class Cast {
  final int id;
  final String jobId;
  final String displayName;
  final String? description;
  final bool isCelebrity;
  final String? role;
  final String? faceProfileId;
  final String? voiceProfileId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Cast({
    required this.id,
    required this.jobId,
    required this.displayName,
    this.description,
    required this.isCelebrity,
    this.role,
    this.faceProfileId,
    this.voiceProfileId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Cast.fromJson(Map<String, dynamic> json) {
    return Cast(
      id: json['id'],
      jobId: json['job_id'],
      displayName: json['display_name'],
      description: json['description'],
      isCelebrity: json['is_celebrity'] ?? false,
      role: json['role'],
      faceProfileId: json['face_profile_id'],
      voiceProfileId: json['voice_profile_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'job_id': jobId,
      'display_name': displayName,
      'description': description,
      'is_celebrity': isCelebrity,
      'role': role,
      'face_profile_id': faceProfileId,
      'voice_profile_id': voiceProfileId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

/// Request to create a new cast member
class CreateCastRequest {
  final String displayName;
  final String? description;
  final bool isCelebrity;
  final String? role;

  CreateCastRequest({
    required this.displayName,
    this.description,
    this.isCelebrity = false,
    this.role,
  });

  Map<String, dynamic> toJson() {
    return {
      'display_name': displayName,
      'description': description,
      'is_celebrity': isCelebrity,
      'role': role,
    };
  }
}

/// Represents a mapping between a diarized speaker and a cast member
class SpeakerMapping {
  final int id;
  final String jobId;
  final String speakerLabel;
  final int? castId;
  final String? resolvedName;
  final String resolutionSource;
  final double? confidence;
  final String? aiReasoning;
  final DateTime createdAt;
  final DateTime updatedAt;

  SpeakerMapping({
    required this.id,
    required this.jobId,
    required this.speakerLabel,
    this.castId,
    this.resolvedName,
    required this.resolutionSource,
    this.confidence,
    this.aiReasoning,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SpeakerMapping.fromJson(Map<String, dynamic> json) {
    return SpeakerMapping(
      id: json['id'],
      jobId: json['job_id'],
      speakerLabel: json['speaker_label'],
      castId: json['cast_id'],
      resolvedName: json['resolved_name'],
      resolutionSource: json['resolution_source'],
      confidence: json['confidence']?.toDouble(),
      aiReasoning: json['ai_reasoning'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  bool get isManual => resolutionSource == 'manual';
  bool get isAiGuess => resolutionSource == 'ai_guess';
  bool get isFallback => resolutionSource == 'fallback';

  String get confidencePercent {
    if (confidence == null) return '';
    return '${(confidence! * 100).toInt()}%';
  }
}

/// Represents a speaker-attributed transcript segment
class VideoSegment {
  final int id;
  final String jobId;
  final String? chunkId;
  final int segmentIndex;
  final int startTimeMs;
  final int endTimeMs;
  final String? speakerLabel;
  final String? text;
  final int? resolvedCastId;
  final String? resolvedName;
  final String? resolutionSource;
  final double? confidence;
  final DateTime createdAt;
  final DateTime updatedAt;

  VideoSegment({
    required this.id,
    required this.jobId,
    this.chunkId,
    required this.segmentIndex,
    required this.startTimeMs,
    required this.endTimeMs,
    this.speakerLabel,
    this.text,
    this.resolvedCastId,
    this.resolvedName,
    this.resolutionSource,
    this.confidence,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VideoSegment.fromJson(Map<String, dynamic> json) {
    return VideoSegment(
      id: json['id'],
      jobId: json['job_id'],
      chunkId: json['chunk_id'],
      segmentIndex: json['segment_index'],
      startTimeMs: json['start_time_ms'],
      endTimeMs: json['end_time_ms'],
      speakerLabel: json['speaker_label'],
      text: json['text'],
      resolvedCastId: json['resolved_cast_id'],
      resolvedName: json['resolved_name'],
      resolutionSource: json['resolution_source'],
      confidence: json['confidence']?.toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Duration get startTime => Duration(milliseconds: startTimeMs);
  Duration get endTime => Duration(milliseconds: endTimeMs);
  Duration get duration => Duration(milliseconds: endTimeMs - startTimeMs);

  String get formattedStartTime => _formatDuration(startTime);

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Display name to show in UI (resolved name or speaker label or 'Unknown')
  String get displaySpeaker {
    return resolvedName ?? speakerLabel ?? 'Unknown';
  }

  bool get isResolved => resolvedName != null && resolvedName!.isNotEmpty;
}

/// Response from the transcript with speakers endpoint
class TranscriptWithSpeakersResponse {
  final String jobId;
  final int speakerCount;
  final bool resolved;
  final List<VideoSegment> segments;
  final String? formattedText;

  TranscriptWithSpeakersResponse({
    required this.jobId,
    required this.speakerCount,
    required this.resolved,
    required this.segments,
    this.formattedText,
  });

  factory TranscriptWithSpeakersResponse.fromJson(Map<String, dynamic> json) {
    return TranscriptWithSpeakersResponse(
      jobId: json['job_id'],
      speakerCount: json['speaker_count'] ?? 0,
      resolved: json['resolved'] ?? false,
      segments: (json['segments'] as List<dynamic>?)
              ?.map((s) => VideoSegment.fromJson(s))
              .toList() ??
          [],
      formattedText: json['formatted_text'],
    );
  }
}
