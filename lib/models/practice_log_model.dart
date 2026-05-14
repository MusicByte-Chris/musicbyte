import 'dart:convert';

/// Lightweight practice log entry stored under the `practice_logs` key.
/// JSON shape:
/// {
///   "id": String,
///   "focusArea": String,
///   "minutes": int,
///   "notes": String,
///   "sessionDate": "yyyy-MM-dd"
/// }
class PracticeLogModel {
  final String id;
  final String focusArea;
  final int minutes;
  final String? notes;
  /// Date string in yyyy-MM-dd format
  final String sessionDate;

  const PracticeLogModel({
    required this.id,
    required this.focusArea,
    required this.minutes,
    this.notes,
    required this.sessionDate,
  });

  /// Parses [sessionDate] to a DateTime at midnight local time.
  DateTime get date {
    // Expecting format yyyy-MM-dd
    try {
      final parts = sessionDate.split('-');
      if (parts.length == 3) {
        final y = int.tryParse(parts[0]) ?? 1970;
        final m = int.tryParse(parts[1]) ?? 1;
        final d = int.tryParse(parts[2]) ?? 1;
        return DateTime(y, m, d);
      }
      // Fallback to DateTime.parse if string has time
      return DateTime.tryParse(sessionDate) ?? DateTime.now();
    } catch (_) {
      return DateTime.now();
    }
  }

  PracticeLogModel copyWith({
    String? id,
    String? focusArea,
    int? minutes,
    String? notes,
    String? sessionDate,
  }) => PracticeLogModel(
        id: id ?? this.id,
        focusArea: focusArea ?? this.focusArea,
        minutes: minutes ?? this.minutes,
        notes: notes ?? this.notes,
        sessionDate: sessionDate ?? this.sessionDate,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'focusArea': focusArea,
        'minutes': minutes,
        'notes': notes,
        'sessionDate': sessionDate,
      };

  static PracticeLogModel fromJson(Map<String, dynamic> json) => PracticeLogModel(
        id: json['id'] as String,
        focusArea: json['focusArea'] as String,
        minutes: (json['minutes'] as num).toInt(),
        notes: json['notes'] as String?,
        sessionDate: json['sessionDate'] as String,
      );

  static List<PracticeLogModel> listFromJsonString(String source) {
    final decoded = jsonDecode(source);
    if (decoded is List) {
      return decoded.whereType<Map<String, dynamic>>().map(fromJson).toList();
    }
    return [];
  }

  static String listToJsonString(List<PracticeLogModel> list) => jsonEncode(list.map((e) => e.toJson()).toList());
}
