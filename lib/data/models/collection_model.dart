import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Immutable model representing a video collection (folder).
@immutable
class CollectionModel extends Equatable {
  final String id;
  final String ownerUserId;
  final String name;
  final String visibility;
  final String status;
  final bool isDefault;
  final int videoCount;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CollectionModel({
    required this.id,
    required this.ownerUserId,
    required this.name,
    required this.visibility,
    required this.status,
    required this.isDefault,
    required this.videoCount,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CollectionModel.fromJson(Map<String, dynamic> json) {
    return CollectionModel(
      id: json['id'] as String,
      ownerUserId: json['owner_user_id'] as String,
      name: json['name'] as String,
      visibility: json['visibility'] as String? ?? 'private',
      status: json['status'] as String? ?? 'active',
      isDefault: json['is_default'] as bool? ?? false,
      videoCount: json['video_count'] as int? ?? 0,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'owner_user_id': ownerUserId,
        'name': name,
        'visibility': visibility,
        'status': status,
        'is_default': isDefault,
        'video_count': videoCount,
        'tags': tags,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  bool get isPublic => visibility == 'public';
  bool get isPrivate => visibility == 'private';
  bool get isActive => status == 'active';

  @override
  List<Object?> get props => [
        id,
        ownerUserId,
        name,
        visibility,
        status,
        isDefault,
        videoCount,
        tags,
        createdAt,
        updatedAt,
      ];
}
