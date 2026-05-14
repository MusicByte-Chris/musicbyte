import 'dart:convert';

/// Stores the user's currently selected root key context.
class KeyContext {
  final String selectedKeyId; // e.g., 'c_major'
  final DateTime createdAt;
  final DateTime updatedAt;

  const KeyContext({required this.selectedKeyId, required this.createdAt, required this.updatedAt});

  factory KeyContext.defaults() => KeyContext(
        selectedKeyId: 'c_major',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  KeyContext copyWith({String? selectedKeyId, DateTime? createdAt, DateTime? updatedAt}) => KeyContext(
        selectedKeyId: selectedKeyId ?? this.selectedKeyId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'selected_key_id': selectedKeyId,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  static KeyContext fromJson(Map<String, dynamic> json) => KeyContext(
        selectedKeyId: json['selected_key_id'] as String? ?? 'c_major',
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ?? DateTime.now(),
      );

  static KeyContext fromJsonString(String source) => KeyContext.fromJson(jsonDecode(source) as Map<String, dynamic>);
  static String toJsonString(KeyContext s) => jsonEncode(s.toJson());
}
