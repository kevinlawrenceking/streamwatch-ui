import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Immutable model representing a video type.
@immutable
class VideoTypeModel extends Equatable {
  final String id;
  final String name;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const VideoTypeModel({
    required this.id,
    required this.name,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VideoTypeModel.fromJson(Map<String, dynamic> json) {
    return VideoTypeModel(
      id: json['id'] as String,
      name: json['name'] as String,
      status: json['status'] as String? ?? 'active',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  bool get isActive => status == 'active';

  @override
  List<Object?> get props => [id, name, status, createdAt, updatedAt];
}

/// Immutable model representing a video type version.
@immutable
class VideoTypeVersionModel extends Equatable {
  final String id;
  final String videoTypeId;
  final int versionNumber;
  final String status;
  final Map<String, dynamic>? definitionJson;
  final String? promptOverride;
  final String? renderedPromptCache;
  final String? renderedPromptHash;
  final DateTime createdAt;
  final DateTime updatedAt;

  const VideoTypeVersionModel({
    required this.id,
    required this.videoTypeId,
    required this.versionNumber,
    required this.status,
    this.definitionJson,
    this.promptOverride,
    this.renderedPromptCache,
    this.renderedPromptHash,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VideoTypeVersionModel.fromJson(Map<String, dynamic> json) {
    return VideoTypeVersionModel(
      id: json['id'] as String,
      videoTypeId: json['video_type_id'] as String,
      versionNumber: json['version_number'] as int,
      status: json['status'] as String,
      definitionJson: json['definition_json'] as Map<String, dynamic>?,
      promptOverride: json['prompt_override'] as String?,
      renderedPromptCache: json['rendered_prompt_cache'] as String?,
      renderedPromptHash: json['rendered_prompt_hash'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  bool get isDraft => status == 'draft';
  bool get isActive => status == 'active';
  bool get isArchived => status == 'archived';

  @override
  List<Object?> get props => [
        id,
        videoTypeId,
        versionNumber,
        status,
        definitionJson,
        promptOverride,
        renderedPromptCache,
        renderedPromptHash,
        createdAt,
        updatedAt,
      ];
}

/// Immutable model representing a video type rule.
@immutable
class VideoTypeRuleModel extends Equatable {
  final String id;
  final String versionId;
  final String ruleText;
  final int ruleOrder;
  final String status;
  final String? source;
  final Map<String, dynamic>? evidence;
  final DateTime createdAt;

  const VideoTypeRuleModel({
    required this.id,
    required this.versionId,
    required this.ruleText,
    required this.ruleOrder,
    required this.status,
    this.source,
    this.evidence,
    required this.createdAt,
  });

  factory VideoTypeRuleModel.fromJson(Map<String, dynamic> json) {
    return VideoTypeRuleModel(
      id: json['id'] as String,
      // API returns 'video_type_version_id'; accept both for safety
      versionId: (json['video_type_version_id'] ?? json['version_id']) as String,
      ruleText: json['rule_text'] as String,
      ruleOrder: json['rule_order'] as int? ?? 0,
      status: json['status'] as String? ?? 'active',
      source: json['source'] as String?,
      evidence: json['evidence'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  bool get isActive => status == 'active';
  bool get isDeprecated => status == 'deprecated';

  @override
  List<Object?> get props => [
        id,
        versionId,
        ruleText,
        ruleOrder,
        status,
        source,
        evidence,
        createdAt,
      ];
}

/// Immutable model representing a rendered prompt.
@immutable
class RenderedPromptModel extends Equatable {
  final String versionId;
  final String prompt;
  final String hash;
  final bool fromCache;

  const RenderedPromptModel({
    required this.versionId,
    required this.prompt,
    required this.hash,
    required this.fromCache,
  });

  factory RenderedPromptModel.fromJson(Map<String, dynamic> json) {
    return RenderedPromptModel(
      versionId: json['version_id'] as String,
      prompt: json['prompt'] as String,
      hash: json['hash'] as String,
      fromCache: json['from_cache'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [versionId, prompt, hash, fromCache];
}

/// Immutable model representing a rule candidate.
@immutable
class VideoTypeRuleCandidateModel extends Equatable {
  final String id;
  final String videoTypeId;
  final String candidateText;
  final String status;
  final String? source;
  final String? sourceExemplarId;
  final Map<String, dynamic>? evidence;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? approvedRuleId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const VideoTypeRuleCandidateModel({
    required this.id,
    required this.videoTypeId,
    required this.candidateText,
    required this.status,
    this.source,
    this.sourceExemplarId,
    this.evidence,
    this.reviewedAt,
    this.reviewedBy,
    this.approvedRuleId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VideoTypeRuleCandidateModel.fromJson(Map<String, dynamic> json) {
    return VideoTypeRuleCandidateModel(
      id: json['id'] as String,
      videoTypeId: json['video_type_id'] as String,
      candidateText: json['candidate_text'] as String,
      status: json['status'] as String,
      source: json['source'] as String?,
      sourceExemplarId: json['source_exemplar_id'] as String?,
      evidence: json['evidence'] as Map<String, dynamic>?,
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
      reviewedBy: json['reviewed_by'] as String?,
      approvedRuleId: json['approved_rule_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isMerged => status == 'merged';

  @override
  List<Object?> get props => [
        id,
        videoTypeId,
        candidateText,
        status,
        source,
        sourceExemplarId,
        evidence,
        reviewedAt,
        reviewedBy,
        approvedRuleId,
        createdAt,
        updatedAt,
      ];
}

/// Immutable model representing an exemplar (linked to an ingested job).
@immutable
class VideoTypeExemplarModel extends Equatable {
  final String id;
  final String videoTypeId;
  final String jobId;
  final String exemplarKind;
  final double weight;
  final String? notes;
  final String? addedBy;
  final String? imageS3Key;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Enriched job metadata (from LEFT JOIN — null if job was deleted)
  final String? jobTitle;
  final String? jobFilename;
  final String? jobSource;
  final String? jobStatus;
  final String? jobThumbnailPath;
  final String? jobTypeCode;
  final int? jobDurationMs;
  final DateTime? jobCreatedAt;

  const VideoTypeExemplarModel({
    required this.id,
    required this.videoTypeId,
    required this.jobId,
    required this.exemplarKind,
    this.weight = 1.0,
    this.notes,
    this.addedBy,
    this.imageS3Key,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.jobTitle,
    this.jobFilename,
    this.jobSource,
    this.jobStatus,
    this.jobThumbnailPath,
    this.jobTypeCode,
    this.jobDurationMs,
    this.jobCreatedAt,
  });

  factory VideoTypeExemplarModel.fromJson(Map<String, dynamic> json) {
    return VideoTypeExemplarModel(
      id: json['id'] as String,
      videoTypeId: json['video_type_id'] as String,
      jobId: json['job_id'] as String,
      exemplarKind: json['exemplar_kind'] as String? ?? 'canonical',
      weight: (json['weight'] as num?)?.toDouble() ?? 1.0,
      notes: json['notes'] as String?,
      addedBy: json['added_by'] as String?,
      imageS3Key: json['image_s3_key'] as String?,
      imageUrl: json['image_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      jobTitle: json['job_title'] as String?,
      jobFilename: json['job_filename'] as String?,
      jobSource: json['job_source'] as String?,
      jobStatus: json['job_status'] as String?,
      jobThumbnailPath: json['job_thumbnail_path'] as String?,
      jobTypeCode: json['job_type_code'] as String?,
      jobDurationMs: json['job_duration_ms'] as int?,
      jobCreatedAt: json['job_created_at'] != null
          ? DateTime.parse(json['job_created_at'] as String)
          : null,
    );
  }

  /// Display name: prefer title, fallback to filename, then job_id.
  String get displayName => jobTitle ?? jobFilename ?? jobId;

  bool get isCanonical => exemplarKind == 'canonical';
  bool get isCounterExample => exemplarKind == 'counter_example';
  bool get isEdgeCase => exemplarKind == 'edge_case';

  @override
  List<Object?> get props => [
        id,
        videoTypeId,
        jobId,
        exemplarKind,
        weight,
        notes,
        addedBy,
        imageS3Key,
        imageUrl,
        createdAt,
        updatedAt,
        jobTitle,
        jobFilename,
        jobSource,
        jobStatus,
        jobThumbnailPath,
        jobTypeCode,
        jobDurationMs,
        jobCreatedAt,
      ];
}
