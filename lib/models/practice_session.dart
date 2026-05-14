import 'dart:convert';

class PracticeSession {
  final String id;
  final String userId;
  final String focusArea; // e.g., Scales & Arpeggios
  final int minutes; // duration in minutes
  final String? notes;
  final DateTime date; // session date (start date)
  final DateTime createdAt;
  final DateTime updatedAt;

  const PracticeSession({
    required this.id,
    required this.userId,
    required this.focusArea,
    required this.minutes,
    this.notes,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
  });

  PracticeSession copyWith({
    String? id,
    String? userId,
    String? focusArea,
    int? minutes,
    String? notes,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      PracticeSession(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        focusArea: focusArea ?? this.focusArea,
        minutes: minutes ?? this.minutes,
        notes: notes ?? this.notes,
        date: date ?? this.date,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'focus_area': focusArea,
        'minutes': minutes,
        'notes': notes,
        'date': date.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  static PracticeSession fromJson(Map<String, dynamic> json) => PracticeSession(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        focusArea: json['focus_area'] as String,
        minutes: (json['minutes'] as num).toInt(),
        notes: json['notes'] as String?,
        date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ?? DateTime.now(),
      );

  static List<PracticeSession> listFromJsonString(String source) {
    final decoded = jsonDecode(source);
    if (decoded is List) {
      return decoded
          .whereType<Map<String, dynamic>>()
          .map((e) => PracticeSession.fromJson(e))
          .toList();
    }
    return [];
  }

  static String listToJsonString(List<PracticeSession> list) => jsonEncode(list.map((e) => e.toJson()).toList());
}
