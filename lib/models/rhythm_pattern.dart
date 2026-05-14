import 'package:flutter/foundation.dart';

/// A curated rhythm pattern (offline-first) used by Rhythm Trainer.
///
/// [pattern] is a list of relative durations measured in quarter-note beats.
/// Example (4/4): straight 8ths => eight 0.5 values, total = 4.0 beats.
@immutable
class RhythmPattern {
  final String id;
  final String name;
  final String timeSignature; // e.g. "4/4", "3/4"
  final List<double> pattern;
  final int difficulty; // 1..5
  final String description;
  final List<String> tags;

  const RhythmPattern({
    required this.id,
    required this.name,
    required this.timeSignature,
    required this.pattern,
    required this.difficulty,
    required this.description,
    required this.tags,
  });

  RhythmPattern copyWith({
    String? id,
    String? name,
    String? timeSignature,
    List<double>? pattern,
    int? difficulty,
    String? description,
    List<String>? tags,
  }) {
    return RhythmPattern(
      id: id ?? this.id,
      name: name ?? this.name,
      timeSignature: timeSignature ?? this.timeSignature,
      pattern: pattern ?? this.pattern,
      difficulty: difficulty ?? this.difficulty,
      description: description ?? this.description,
      tags: tags ?? this.tags,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'timeSignature': timeSignature,
      'pattern': pattern,
      'difficulty': difficulty,
      'description': description,
      'tags': tags,
    };
  }

  factory RhythmPattern.fromJson(Map<String, Object?> json) {
    final rawPattern = json['pattern'];
    final rawTags = json['tags'];
    return RhythmPattern(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      timeSignature: (json['timeSignature'] as String?) ?? '4/4',
      pattern: rawPattern is List ? rawPattern.map((e) => (e as num).toDouble()).toList(growable: false) : const <double>[],
      difficulty: (json['difficulty'] as num?)?.toInt() ?? 1,
      description: (json['description'] as String?) ?? '',
      tags: rawTags is List ? rawTags.map((e) => e.toString()).toList(growable: false) : const <String>[],
    );
  }

  int get beatsPerBar {
    final parts = timeSignature.split('/');
    if (parts.length != 2) return 4;
    final n = int.tryParse(parts[0]);
    final d = int.tryParse(parts[1]);
    if (n == null || d == null || n <= 0 || d <= 0) return 4;
    return (n * (4 / d)).round();
  }

  double get totalBeats => pattern.fold(0.0, (a, b) => a + b);
}
