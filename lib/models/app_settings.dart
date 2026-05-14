import 'dart:convert';

class AppSettings {
  final String a4Reference; // e.g., '440 Hz'
  final String enharmonicPreference; // 'Sharps (#)' | 'Flats (b)' | 'Contextual'
  final String notationSystem; // 'English' | 'Latin' | 'German'
  final bool darkMode; // UI preference
  /// User-selected global color schema id (e.g. 'luxury', 'ocean').
  ///
  /// Stored as a string so it can be extended without migrations.
  final String appColorScheme;
  final bool haptics;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AppSettings({
    required this.a4Reference,
    required this.enharmonicPreference,
    required this.notationSystem,
    required this.darkMode,
    required this.appColorScheme,
    required this.haptics,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppSettings.defaults() => AppSettings(
        a4Reference: '440 Hz',
        enharmonicPreference: 'Sharps (#)',
        notationSystem: 'English',
        darkMode: true,
        appColorScheme: 'luxury',
        haptics: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  AppSettings copyWith({
    String? a4Reference,
    String? enharmonicPreference,
    String? notationSystem,
    bool? darkMode,
    String? appColorScheme,
    bool? haptics,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      AppSettings(
        a4Reference: a4Reference ?? this.a4Reference,
        enharmonicPreference: enharmonicPreference ?? this.enharmonicPreference,
        notationSystem: notationSystem ?? this.notationSystem,
        darkMode: darkMode ?? this.darkMode,
        appColorScheme: appColorScheme ?? this.appColorScheme,
        haptics: haptics ?? this.haptics,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'a4_reference': a4Reference,
        'enharmonic_preference': enharmonicPreference,
        'notation_system': notationSystem,
        'dark_mode': darkMode,
        'app_color_scheme': appColorScheme,
        'haptics': haptics,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  static AppSettings fromJson(Map<String, dynamic> json) => AppSettings(
        a4Reference: json['a4_reference'] as String? ?? '440 Hz',
        enharmonicPreference: json['enharmonic_preference'] as String? ?? 'Sharps (#)',
        notationSystem: json['notation_system'] as String? ?? 'English',
        darkMode: json['dark_mode'] as bool? ?? true,
        appColorScheme: json['app_color_scheme'] as String? ?? 'luxury',
        haptics: json['haptics'] as bool? ?? true,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ?? DateTime.now(),
      );

  static AppSettings fromJsonString(String source) => AppSettings.fromJson(jsonDecode(source) as Map<String, dynamic>);
  static String toJsonString(AppSettings s) => jsonEncode(s.toJson());
}
