import 'dart:convert';

/// Represents the single local user on this device.
class AppUser {
  final String id; // e.g. 'local-user'
  final String name;
  final String? email; // optional, offline user can be null
  final DateTime createdAt;
  final DateTime updatedAt;

  const AppUser({
    required this.id,
    required this.name,
    this.email,
    required this.createdAt,
    required this.updatedAt,
  });

  AppUser copyWith({String? id, String? name, String? email, DateTime? createdAt, DateTime? updatedAt}) => AppUser(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  static AppUser fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String?,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ?? DateTime.now(),
      );

  static AppUser fromJsonString(String source) => fromJson(jsonDecode(source) as Map<String, dynamic>);
}
