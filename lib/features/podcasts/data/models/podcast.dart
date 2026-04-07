import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Immutable model representing a podcast.
@immutable
class PodcastModel extends Equatable {
  final String id;
  final String name;
  final String? description;
  final bool isActive;
  final DateTime? deactivatedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PodcastModel({
    required this.id,
    required this.name,
    this.description,
    required this.isActive,
    this.deactivatedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PodcastModel.fromJsonDto(Map<String, dynamic> json) {
    return PodcastModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      deactivatedAt: json['deactivated_at'] != null
          ? DateTime.parse(json['deactivated_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJsonDto() {
    return {
      'name': name,
      if (description != null) 'description': description,
    };
  }

  PodcastModel copyWith({
    String? id,
    String? name,
    String? description,
    bool? isActive,
    DateTime? deactivatedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PodcastModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      deactivatedAt: deactivatedAt ?? this.deactivatedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, description, isActive, deactivatedAt, createdAt, updatedAt];
}
