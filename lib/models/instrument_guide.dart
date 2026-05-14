import 'package:flutter/foundation.dart';

/// Instrument engineering guide record
/// Structured to map 1:1 with future SQLite fields:
/// instrument_name, fundamentals, harmonics, problems,
/// eq_notes, comp_notes, tracking, mic_notes, mix_notes
@immutable
class InstrumentGuide {
  final String instrumentName;
  final String fundamentals; // Fundamental Range
  final String harmonics; // Key Harmonics / presence bands
  final String problems; // Problem Areas
  final String eqNotes; // EQ Sweet Spots + HPF/LPF starting points
  final String compNotes; // Compression Guide (ratio + attack feel)
  final String tracking; // Tracking Tips
  final String micNotes; // Mic Suggestions
  final String mixNotes; // Mixing Notes

  const InstrumentGuide({
    required this.instrumentName,
    required this.fundamentals,
    required this.harmonics,
    required this.problems,
    required this.eqNotes,
    required this.compNotes,
    required this.tracking,
    required this.micNotes,
    required this.mixNotes,
  });

  Map<String, dynamic> toJson() => {
        'instrument_name': instrumentName,
        'fundamentals': fundamentals,
        'harmonics': harmonics,
        'problems': problems,
        'eq_notes': eqNotes,
        'comp_notes': compNotes,
        'tracking': tracking,
        'mic_notes': micNotes,
        'mix_notes': mixNotes,
      };

  factory InstrumentGuide.fromJson(Map<String, dynamic> json) => InstrumentGuide(
        instrumentName: (json['instrument_name'] ?? '').toString(),
        fundamentals: (json['fundamentals'] ?? '').toString(),
        harmonics: (json['harmonics'] ?? '').toString(),
        problems: (json['problems'] ?? '').toString(),
        eqNotes: (json['eq_notes'] ?? '').toString(),
        compNotes: (json['comp_notes'] ?? '').toString(),
        tracking: (json['tracking'] ?? '').toString(),
        micNotes: (json['mic_notes'] ?? '').toString(),
        mixNotes: (json['mix_notes'] ?? '').toString(),
      );

  InstrumentGuide copyWith({
    String? instrumentName,
    String? fundamentals,
    String? harmonics,
    String? problems,
    String? eqNotes,
    String? compNotes,
    String? tracking,
    String? micNotes,
    String? mixNotes,
  }) => InstrumentGuide(
        instrumentName: instrumentName ?? this.instrumentName,
        fundamentals: fundamentals ?? this.fundamentals,
        harmonics: harmonics ?? this.harmonics,
        problems: problems ?? this.problems,
        eqNotes: eqNotes ?? this.eqNotes,
        compNotes: compNotes ?? this.compNotes,
        tracking: tracking ?? this.tracking,
        micNotes: micNotes ?? this.micNotes,
        mixNotes: mixNotes ?? this.mixNotes,
      );
}
