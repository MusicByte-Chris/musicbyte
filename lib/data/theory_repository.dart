import 'dart:math' as math;
import 'package:musicbyteai/models/music_theory.dart';

class TheoryRepository {
  static const List<KeyData> circleOfFifths = [
    KeyData(
      id: 'c_major',
      name: 'C Major',
      relativeMinor: 'A Minor',
      sharps: 0,
      signatureDesc: 'No ♯ / ♭',
      mode: 'Ionian',
      triads: ['C', 'F', 'G'],
      accidentals: [],
    ),
    KeyData(
      id: 'g_major',
      name: 'G Major',
      relativeMinor: 'E Minor',
      sharps: 1,
      signatureDesc: 'F♯',
      mode: 'Ionian',
      triads: ['G', 'C', 'D'],
      accidentals: ['F♯'],
    ),
    KeyData(
      id: 'd_major',
      name: 'D Major',
      relativeMinor: 'B Minor',
      sharps: 2,
      signatureDesc: 'F♯, C♯',
      mode: 'Ionian',
      triads: ['D', 'G', 'A'],
      accidentals: ['F♯', 'C♯'],
    ),
    KeyData(
      id: 'a_major',
      name: 'A Major',
      relativeMinor: 'F♯ Minor',
      sharps: 3,
      signatureDesc: 'F♯, C♯, G♯',
      mode: 'Ionian',
      triads: ['A', 'D', 'E'],
      accidentals: ['F♯', 'C♯', 'G♯'],
    ),
    KeyData(
      id: 'e_major',
      name: 'E Major',
      relativeMinor: 'C♯ Minor',
      sharps: 4,
      signatureDesc: 'F♯, C♯, G♯, D♯',
      mode: 'Ionian',
      triads: ['E', 'A', 'B'],
      accidentals: ['F♯', 'C♯', 'G♯', 'D♯'],
    ),
    KeyData(
      id: 'b_major',
      name: 'B Major',
      relativeMinor: 'G♯ Minor',
      sharps: 5,
      signatureDesc: 'F♯, C♯, G♯, D♯, A♯',
      mode: 'Ionian',
      triads: ['B', 'E', 'F♯'],
      accidentals: ['F♯', 'C♯', 'G♯', 'D♯', 'A♯'],
    ),
    KeyData(
      id: 'fs_major',
      name: 'F♯ Major',
      relativeMinor: 'D♯ Minor',
      sharps: 6,
      signatureDesc: 'F♯, C♯, G♯, D♯, A♯, E♯',
      mode: 'Ionian',
      triads: ['F♯', 'B', 'C♯'],
      accidentals: ['F♯', 'C♯', 'G♯', 'D♯', 'A♯', 'E♯'],
    ),
    KeyData(
      id: 'cs_major',
      name: 'C♯ Major',
      relativeMinor: 'A♯ Minor',
      sharps: 7,
      signatureDesc: 'F♯, C♯, G♯, D♯, A♯, E♯, B♯',
      mode: 'Ionian',
      triads: ['C♯', 'F♯', 'G♯'],
      accidentals: ['F♯', 'C♯', 'G♯', 'D♯', 'A♯', 'E♯', 'B♯'],
    ),
    KeyData(
      id: 'ab_major',
      name: 'Ab Major',
      relativeMinor: 'F Minor',
      sharps: -4,
      signatureDesc: 'B♭, E♭, A♭, D♭',
      mode: 'Ionian',
      triads: ['A♭', 'D♭', 'E♭'],
      accidentals: ['B♭', 'E♭', 'A♭', 'D♭'],
    ),
    KeyData(
      id: 'eb_major',
      name: 'Eb Major',
      relativeMinor: 'C Minor',
      sharps: -3,
      signatureDesc: 'B♭, E♭, A♭',
      mode: 'Ionian',
      triads: ['E♭', 'A♭', 'B♭'],
      accidentals: ['B♭', 'E♭', 'A♭'],
    ),
    KeyData(
      id: 'bb_major',
      name: 'Bb Major',
      relativeMinor: 'G Minor',
      sharps: -2,
      signatureDesc: 'B♭, E♭',
      mode: 'Ionian',
      triads: ['B♭', 'E♭', 'F'],
      accidentals: ['B♭', 'E♭'],
    ),
    KeyData(
      id: 'f_major',
      name: 'F Major',
      relativeMinor: 'D Minor',
      sharps: -1,
      signatureDesc: 'B♭',
      mode: 'Ionian',
      triads: ['F', 'B♭', 'C'],
      accidentals: ['B♭'],
    ),
  ];

  /// Relative minor keys for the majors in [circleOfFifths].
  ///
  /// These are primarily used for navigation (viewer) and UI labeling.
  static const List<KeyData> relativeMinors = [
    KeyData(
      id: 'a_minor',
      name: 'A Minor',
      relativeMinor: 'C Major',
      sharps: 0,
      signatureDesc: 'No ♯ / ♭',
      mode: 'Aeolian',
      triads: ['Am', 'Dm', 'Em'],
      accidentals: [],
    ),
    KeyData(
      id: 'e_minor',
      name: 'E Minor',
      relativeMinor: 'G Major',
      sharps: 1,
      signatureDesc: 'F♯',
      mode: 'Aeolian',
      triads: ['Em', 'Am', 'Bm'],
      accidentals: ['F♯'],
    ),
    KeyData(
      id: 'b_minor',
      name: 'B Minor',
      relativeMinor: 'D Major',
      sharps: 2,
      signatureDesc: 'F♯, C♯',
      mode: 'Aeolian',
      triads: ['Bm', 'Em', 'F♯m'],
      accidentals: ['F♯', 'C♯'],
    ),
    KeyData(
      id: 'fs_minor',
      name: 'F♯ Minor',
      relativeMinor: 'A Major',
      sharps: 3,
      signatureDesc: 'F♯, C♯, G♯',
      mode: 'Aeolian',
      triads: ['F♯m', 'Bm', 'C♯m'],
      accidentals: ['F♯', 'C♯', 'G♯'],
    ),
    KeyData(
      id: 'cs_minor',
      name: 'C♯ Minor',
      relativeMinor: 'E Major',
      sharps: 4,
      signatureDesc: 'F♯, C♯, G♯, D♯',
      mode: 'Aeolian',
      triads: ['C♯m', 'F♯m', 'G♯m'],
      accidentals: ['F♯', 'C♯', 'G♯', 'D♯'],
    ),
    KeyData(
      id: 'gs_minor',
      name: 'G♯ Minor',
      relativeMinor: 'B Major',
      sharps: 5,
      signatureDesc: 'F♯, C♯, G♯, D♯, A♯',
      mode: 'Aeolian',
      triads: ['G♯m', 'C♯m', 'D♯m'],
      accidentals: ['F♯', 'C♯', 'G♯', 'D♯', 'A♯'],
    ),
    KeyData(
      id: 'ds_minor',
      name: 'D♯ Minor',
      relativeMinor: 'F♯ Major',
      sharps: 6,
      signatureDesc: 'F♯, C♯, G♯, D♯, A♯, E♯',
      mode: 'Aeolian',
      triads: ['D♯m', 'G♯m', 'A♯m'],
      accidentals: ['F♯', 'C♯', 'G♯', 'D♯', 'A♯', 'E♯'],
    ),
    KeyData(
      id: 'as_minor',
      name: 'A♯ Minor',
      relativeMinor: 'C♯ Major',
      sharps: 7,
      signatureDesc: 'F♯, C♯, G♯, D♯, A♯, E♯, B♯',
      mode: 'Aeolian',
      triads: ['A♯m', 'D♯m', 'E♯m'],
      accidentals: ['F♯', 'C♯', 'G♯', 'D♯', 'A♯', 'E♯', 'B♯'],
    ),
    KeyData(
      id: 'd_minor',
      name: 'D Minor',
      relativeMinor: 'F Major',
      sharps: -1,
      signatureDesc: 'B♭',
      mode: 'Aeolian',
      triads: ['Dm', 'Gm', 'Am'],
      accidentals: ['B♭'],
    ),
    KeyData(
      id: 'g_minor',
      name: 'G Minor',
      relativeMinor: 'Bb Major',
      sharps: -2,
      signatureDesc: 'B♭, E♭',
      mode: 'Aeolian',
      triads: ['Gm', 'Cm', 'Dm'],
      accidentals: ['B♭', 'E♭'],
    ),
    KeyData(
      id: 'c_minor',
      name: 'C Minor',
      relativeMinor: 'Eb Major',
      sharps: -3,
      signatureDesc: 'B♭, E♭, A♭',
      mode: 'Aeolian',
      triads: ['Cm', 'Fm', 'Gm'],
      accidentals: ['B♭', 'E♭', 'A♭'],
    ),
    KeyData(
      id: 'f_minor',
      name: 'F Minor',
      relativeMinor: 'Ab Major',
      sharps: -4,
      signatureDesc: 'B♭, E♭, A♭, D♭',
      mode: 'Aeolian',
      triads: ['Fm', 'B♭m', 'Cm'],
      accidentals: ['B♭', 'E♭', 'A♭', 'D♭'],
    ),
  ];

  static const List<KeyData> allKeys = [...circleOfFifths, ...relativeMinors];

  /// Returns the relative minor key id for a major key id.
  /// Example: 'c_major' -> 'a_minor'.
  static String relativeMinorIdForMajor(String majorKeyId) {
    const map = {
      'c_major': 'a_minor',
      'g_major': 'e_minor',
      'd_major': 'b_minor',
      'a_major': 'fs_minor',
      'e_major': 'cs_minor',
      'b_major': 'gs_minor',
      'fs_major': 'ds_minor',
      'cs_major': 'as_minor',
      'f_major': 'd_minor',
      'bb_major': 'g_minor',
      'eb_major': 'c_minor',
      'ab_major': 'f_minor',
    };
    return map[majorKeyId] ?? 'a_minor';
  }

  static KeyData getKeyById(String id) {
    return allKeys.firstWhere((k) => k.id == id, orElse: () => circleOfFifths[0]);
  }

  // Algorithmic major scale generation (A4 = 440 Hz, equal temperament)
  static List<ScaleDegree> getMajorScale(String keyId) {
    final tonicPc = TheoryUtils.pcForKeyId(keyId);
    final pcs = TheoryUtils.majorScalePcs(tonicPc);
    final spelled = TheoryUtils.spelledMajorScaleForKey(keyId);

    // Build ascending MIDI numbers starting in 4th octave
    // MIDI: n = 12 * (octave + 1) + pc; A4 = 69
    const startOctave = 4;
    final List<int> midis = [];
    for (var i = 0; i < pcs.length; i++) {
      final base = 12 * (startOctave + 1) + pcs[i];
      if (midis.isEmpty) {
        midis.add(base);
      } else {
        var n = base;
        while (n <= midis.last) {
          n += 12;
        }
        midis.add(n);
      }
    }

    String fmtHz(int midi) {
      final hz = 440 * math.pow(2, (midi - 69) / 12);
      return "${hz.toStringAsFixed(2)} Hz";
    }

    return List.generate(pcs.length, (i) =>
      ScaleDegree(degree: i + 1, note: spelled[i], frequency: fmtHz(midis[i]))
    );
  }

  static List<Chord> getDiatonicChords(String keyId) {
    final spelled = TheoryUtils.spelledMajorScaleForKey(keyId);

    const romans = ['I','ii','iii','IV','V','vi','vii°'];
    const types = ['Major','Minor','Minor','Major','Major','Minor','Dim'];

    return List.generate(7, (i) {
      // Root name from correctly spelled scale
      final rootName = spelled[i % spelled.length];
      final type = types[i];
      final displayName = switch (type) {
        'Major' => rootName,
        'Minor' => '${rootName}m',
        'Dim' => '${rootName}dim',
        _ => rootName,
      };
      return Chord(roman: romans[i], name: displayName, type: type);
    });
  }
}
