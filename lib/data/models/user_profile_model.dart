import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Immutable model representing a user profile.
///
/// Maps to the API response from GET /api/v1/me, GET /api/v1/users/{id},
/// and the user objects in GET /api/v1/users list responses.
@immutable
class UserProfileModel extends Equatable {
  final String id;
  final String username;
  final String firstName;
  final String lastName;
  final String role;
  final String? sid;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfileModel({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.sid,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a UserProfileModel from a JSON DTO.
  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      role: json['role'] as String? ?? 'user',
      sid: json['sid'] as String?,
      createdAt: _parseDateTime(json['created_at']) ?? DateTime.now(),
      updatedAt: _parseDateTime(json['updated_at']) ?? DateTime.now(),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }

  /// Whether this user has admin privileges.
  bool get isAdmin => role == 'admin';

  /// Display name combining first and last name.
  /// Falls back to username if names are empty.
  String get displayName {
    final full = '$firstName $lastName'.trim();
    return full.isNotEmpty ? full : username;
  }

  @override
  List<Object?> get props => [
        id,
        username,
        firstName,
        lastName,
        role,
        sid,
        createdAt,
        updatedAt,
      ];
}

/// Response wrapper for the paginated users list endpoint.
class UserListResponse extends Equatable {
  final List<UserProfileModel> users;
  final int total;

  const UserListResponse({
    required this.users,
    required this.total,
  });

  factory UserListResponse.fromJson(Map<String, dynamic> json) {
    final usersList = (json['users'] as List<dynamic>?)
            ?.map((e) => UserProfileModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return UserListResponse(
      users: usersList,
      total: json['total'] as int? ?? usersList.length,
    );
  }

  @override
  List<Object?> get props => [users, total];
}
