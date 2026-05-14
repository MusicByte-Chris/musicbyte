import 'dart:convert';

/// Settings for the Metronome tool. Stored locally via LocalStorageService.
class MetronomeSettings {
  final int bpm; // Quarter-notes per minute
  final String subdivision; // 'quarter' | 'eighth' | 'sixteenth'
  final int numerator; // e.g., 4 in 4/4
  final int denominator; // e.g., 4 in 4/4
  final bool accentDownbeats; // Play accented click on the first tick of each measure
  final DateTime createdAt;
  final DateTime updatedAt;

  const MetronomeSettings({
    required this.bpm,
    required this.subdivision,
    required this.numerator,
    required this.denominator,
    required this.accentDownbeats,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MetronomeSettings.defaults() => MetronomeSettings(
        bpm: 120,
        subdivision: 'quarter',
        numerator: 4,
        denominator: 4,
        accentDownbeats: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  MetronomeSettings copyWith({
    int? bpm,
    String? subdivision,
    int? numerator,
    int? denominator,
    bool? accentDownbeats,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      MetronomeSettings(
        bpm: bpm ?? this.bpm,
        subdivision: subdivision ?? this.subdivision,
        numerator: numerator ?? this.numerator,
        denominator: denominator ?? this.denominator,
        accentDownbeats: accentDownbeats ?? this.accentDownbeats,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'bpm': bpm,
        'subdivision': subdivision,
        'numerator': numerator,
        'denominator': denominator,
        'accent_downbeats': accentDownbeats,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  static MetronomeSettings fromJson(Map<String, dynamic> json) => MetronomeSettings(
        bpm: json['bpm'] as int? ?? 120,
        subdivision: (json['subdivision'] as String?)?.toLowerCase() ?? 'quarter',
        numerator: json['numerator'] as int? ?? 4,
        denominator: json['denominator'] as int? ?? 4,
        accentDownbeats: json['accent_downbeats'] as bool? ?? true,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ?? DateTime.now(),
      );

  static MetronomeSettings fromJsonString(String source) => MetronomeSettings.fromJson(jsonDecode(source) as Map<String, dynamic>);
  static String toJsonString(MetronomeSettings s) => jsonEncode(s.toJson());
}
