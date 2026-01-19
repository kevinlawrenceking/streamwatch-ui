import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Model representing a celebrity identified in a video.
@immutable
class CelebrityModel extends Equatable {
  final String name;
  final double? confidence;
  final String? recognitionSource;

  const CelebrityModel({
    required this.name,
    this.confidence,
    this.recognitionSource,
  });

  /// Creates a CelebrityModel from a JSON map.
  /// Handles multiple key formats for name: "name", "full_name", "label".
  /// Handles confidence as num (int or double).
  /// Handles recognitionSource from "recognition_source" or "source".
  factory CelebrityModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const CelebrityModel(name: 'Unknown');
    }

    // Parse name with priority: name > full_name > label
    final name = (json['name'] as String?) ??
        (json['full_name'] as String?) ??
        (json['label'] as String?) ??
        'Unknown';

    // Parse confidence as num -> double
    double? confidence;
    final rawConfidence = json['confidence'];
    if (rawConfidence is num) {
      confidence = rawConfidence.toDouble();
    }

    // Parse recognition source from "recognition_source" or "source"
    final recognitionSource = (json['recognition_source'] as String?) ??
        (json['source'] as String?);

    return CelebrityModel(
      name: name,
      confidence: confidence,
      recognitionSource: recognitionSource,
    );
  }

  /// Converts to JSON map.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (confidence != null) 'confidence': confidence,
      if (recognitionSource != null) 'recognition_source': recognitionSource,
    };
  }

  @override
  List<Object?> get props => [name, confidence, recognitionSource];
}

/// Parses a list of celebrities from JSON, returning empty list on failure.
List<CelebrityModel> parseCelebrities(dynamic json) {
  if (json == null) return const [];
  if (json is! List) return const [];

  return json
      .whereType<Map<String, dynamic>>()
      .map((c) => CelebrityModel.fromJson(c))
      .where((c) => c.name.isNotEmpty && c.name != 'Unknown')
      .toList();
}
