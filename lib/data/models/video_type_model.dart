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
      versionId: json['version_id'] as String,
      ruleText: json['rule_text'] as String,
      ruleOrder: json['rule_order'] as int,
      status: json['status'] as String,
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

/// Immutable model representing an exemplar.
@immutable
class VideoTypeExemplarModel extends Equatable {
  final String id;
  final String videoTypeId;
  final String clipId;
  final String exemplarKind;
  final String? notes;
  final String? addedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const VideoTypeExemplarModel({
    required this.id,
    required this.videoTypeId,
    required this.clipId,
    required this.exemplarKind,
    this.notes,
    this.addedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VideoTypeExemplarModel.fromJson(Map<String, dynamic> json) {
    return VideoTypeExemplarModel(
      id: json['id'] as String,
      videoTypeId: json['video_type_id'] as String,
      clipId: json['clip_id'] as String,
      exemplarKind: json['exemplar_kind'] as String? ?? 'canonical',
      notes: json['notes'] as String?,
      addedBy: json['added_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  bool get isCanonical => exemplarKind == 'canonical';
  bool get isCounterExample => exemplarKind == 'counter_example';
  bool get isEdgeCase => exemplarKind == 'edge_case';

  @override
  List<Object?> get props => [
        id,
        videoTypeId,
        clipId,
        exemplarKind,
        notes,
        addedBy,
        createdAt,
        updatedAt,
      ];
}
