class KeyData {
  final String id;
  final String name;
  final String relativeMinor;
  final int sharps; // positive for sharps, negative for flats
  final String signatureDesc;
  final String mode;
  final List<String> triads; // I, IV, V
  final List<String> accidentals;

  const KeyData({
    required this.id,
    required this.name,
    required this.relativeMinor,
    required this.sharps,
    required this.signatureDesc,
    required this.mode,
    required this.triads,
    required this.accidentals,
  });

  String get accidentalsCountString {
    if (sharps == 0) return "0";
    if (sharps > 0) return "$sharps Sharp${sharps > 1 ? 's' : ''}";
    return "${sharps.abs()} Flat${sharps.abs() > 1 ? 's' : ''}";
  }
}

class Chord {
  final String roman;
  final String name;
  final String type;

  const Chord({
    required this.roman,
    required this.name,
    required this.type,
  });
}

class ScaleDegree {
  final int degree;
  final String note;
  final String frequency; // Pre-calculated string for now

  const ScaleDegree({
    required this.degree,
    required this.note,
    required this.frequency,
  });
}

/// Utility helpers for pitch classes, intervals, and instrument mappings
class TheoryUtils {
  static const List<String> pitchNamesSharp = ['C','C#','D','D#','E','F','F#','G','G#','A','A#','B'];
  static const List<String> pitchNamesFlat = ['C','Db','D','Eb','E','F','Gb','G','Ab','A','Bb','B'];
  static const List<String> letterOrder = ['C','D','E','F','G','A','B'];
  static const Map<String,int> letterToPc = {'C':0,'D':2,'E':4,'F':5,'G':7,'A':9,'B':11};

  // Map major key id -> tonic pitch class (C=0)
  static const Map<String,int> keyIdToPc = {
    'c_major': 0,
    'g_major': 7,
    'd_major': 2,
    'a_major': 9,
    'e_major': 4,
    'b_major': 11,
    'fs_major': 6,
    'cs_major': 1,
    'f_major': 5,
    'bb_major': 10,
    'eb_major': 3,
    'ab_major': 8,

    // Relative minors (same key signature)
    'a_minor': 9,
    'e_minor': 4,
    'b_minor': 11,
    'fs_minor': 6,
    'cs_minor': 1,
    'gs_minor': 8,
    'ds_minor': 3,
    'as_minor': 10,
    'd_minor': 2,
    'g_minor': 7,
    'c_minor': 0,
    'f_minor': 5,
  };

  static int pcForKeyId(String keyId) => keyIdToPc[keyId] ?? 0;

  static List<int> majorScalePcs(int tonic) => [0,2,4,5,7,9,11].map((o)=> (tonic+o)%12).toList();
  static List<int> naturalMinorScalePcs(int tonic) => [0,2,3,5,7,8,10].map((o)=> (tonic+o)%12).toList();
  static List<int> harmonicMinorScalePcs(int tonic) => [0,2,3,5,7,8,11].map((o)=> (tonic+o)%12).toList();
  // Melodic minor (ascending): 1 2 b3 4 5 6 7
  static List<int> melodicMinorAscScalePcs(int tonic) => [0,2,3,5,7,9,11].map((o)=> (tonic+o)%12).toList();
  static List<int> dorianScalePcs(int tonic) => [0,2,3,5,7,9,10].map((o)=> (tonic+o)%12).toList();
  static List<int> mixolydianScalePcs(int tonic) => [0,2,4,5,7,9,10].map((o)=> (tonic+o)%12).toList();
  static List<int> pentatonicMajorPcs(int tonic) => [0,2,4,7,9].map((o)=> (tonic+o)%12).toList();
  static List<int> pentatonicMinorPcs(int tonic) => [0,3,5,7,10].map((o)=> (tonic+o)%12).toList();
  // Blues scales
  static List<int> bluesMinorPcs(int tonic) => [0,3,5,6,7,10].map((o)=> (tonic+o)%12).toList(); // 1 b3 4 b5 5 b7
  static List<int> bluesMajorPcs(int tonic) => [0,2,3,4,7,9].map((o)=> (tonic+o)%12).toList(); // 1 2 b3 3 5 6
  // Diminished (Whole–Half) octatonic
  static List<int> diminishedWholeHalfPcs(int tonic) => [0,2,3,5,6,8,9,11].map((o)=> (tonic+o)%12).toList();

  // Scale catalog
  static const Map<String,String> scaleNames = {
    // Core/common
    'ionian': 'Major (Ionian)',
    'minor': 'Minor', // alias of Natural Minor for simpler UX
    'aeolian': 'Natural Minor (Aeolian)',
    'harm_minor': 'Harmonic Minor',
    'mel_minor_asc': 'Melodic Minor (Ascending)',
    'diminished_wh': 'Diminished (Whole–Half)',
    // Modes and others
    'dorian': 'Dorian',
    'mixolydian': 'Mixolydian',
    'pent_major': 'Pentatonic Major',
    'pent_minor': 'Pentatonic Minor',
    'blues_minor': 'Blues (Minor)',
    'blues_major': 'Blues (Major)',
  };

  static List<int> scaleById(String id, int tonic) {
    switch(id){
      case 'minor': return naturalMinorScalePcs(tonic);
      case 'aeolian': return naturalMinorScalePcs(tonic);
      case 'harm_minor': return harmonicMinorScalePcs(tonic);
      case 'mel_minor_asc': return melodicMinorAscScalePcs(tonic);
      case 'diminished_wh': return diminishedWholeHalfPcs(tonic);
      case 'dorian': return dorianScalePcs(tonic);
      case 'mixolydian': return mixolydianScalePcs(tonic);
      case 'pent_major': return pentatonicMajorPcs(tonic);
      case 'pent_minor': return pentatonicMinorPcs(tonic);
      case 'blues_minor': return bluesMinorPcs(tonic);
      case 'blues_major': return bluesMajorPcs(tonic);
      case 'ionian':
      default: return majorScalePcs(tonic);
    }
  }

  /// Returns the best-fit pitch name for a pitch class.
  /// When useFlats is true, flats are preferred (Db, Eb, ...). Otherwise sharps (C#, D#, ...).
  static String nameForPc(int pc, {bool useFlats = false}) {
    final p = (pc % 12 + 12) % 12;
    return useFlats ? pitchNamesFlat[p] : pitchNamesSharp[p];
  }

  /// Key-aware diatonic spelling for the major scale of [keyId].
  /// Produces correctly spelled notes including E#, B#, Cb, Fb when appropriate.
  static List<String> spelledMajorScaleForKey(String keyId) {
    final tonicPc = pcForKeyId(keyId);
    // Determine tonic base letter from keyId prefix (e.g., 'fs_major' -> 'F')
    final idPrefix = keyId.split('_').first;
    final tonicLetter = idPrefix.isNotEmpty ? idPrefix[0].toUpperCase() : 'C';
    int tonicLetterIdx = letterOrder.indexOf(tonicLetter);
    if (tonicLetterIdx < 0) tonicLetterIdx = 0;

    const majorIntervals = [0,2,4,5,7,9,11];
    final List<String> result = [];
    for (int i = 0; i < 7; i++) {
      final letterIdx = (tonicLetterIdx + i) % 7;
      final baseLetter = letterOrder[letterIdx];
      final naturalPc = letterToPc[baseLetter]!;
      final targetPc = (tonicPc + majorIntervals[i]) % 12;
      final spelled = _spellLetterToPc(baseLetter, naturalPc, targetPc);
      result.add(spelled);
    }
    return result;
  }

  /// Key-aware diatonic spelling for any 7-tone scale defined by [scaleId]
  /// using the same tonic letter progression as the key.
  ///
  /// This is used for interval tables and other reference UIs where accurate
  /// enharmonic spelling matters (e.g., E#, B#, Cb, Fb).
  static List<String> spelledScaleForKey({required String keyId, required String scaleId}) {
    final tonicPc = pcForKeyId(keyId);
    final idPrefix = keyId.split('_').first;
    final tonicLetter = idPrefix.isNotEmpty ? idPrefix[0].toUpperCase() : 'C';
    int tonicLetterIdx = letterOrder.indexOf(tonicLetter);
    if (tonicLetterIdx < 0) tonicLetterIdx = 0;

    final pcs = scaleById(scaleId, tonicPc);
    if (pcs.length < 7) return pcs.map((pc) => nameForPc(pc, useFlats: keyId.contains('b_'))).toList();

    final result = <String>[];
    for (int i = 0; i < 7; i++) {
      final letterIdx = (tonicLetterIdx + i) % 7;
      final baseLetter = letterOrder[letterIdx];
      final naturalPc = letterToPc[baseLetter]!;
      final targetPc = pcs[i] % 12;
      result.add(_spellLetterToPc(baseLetter, naturalPc, targetPc));
    }
    return result;
  }

  /// Spells all tones of a chord built on the [degreeIndex] (0-based) within the
  /// major key [keyId], honoring correct letter progression (root, 3rd, 5th, 7th)
  /// and applying accidentals to reach the target pitch classes.
  static List<String> spelledChordTonesInKey({
    required String keyId,
    required String chordType,
    required int degreeIndex, // 0..6 for I..VII
  }) {
    final tonicPc = pcForKeyId(keyId);
    // Determine tonic base letter from keyId
    final idPrefix = keyId.split('_').first;
    final tonicLetter = idPrefix.isNotEmpty ? idPrefix[0].toUpperCase() : 'C';
    int tonicLetterIdx = letterOrder.indexOf(tonicLetter);
    if (tonicLetterIdx < 0) tonicLetterIdx = 0;

    // Root pc for degree
    final majorScale = majorScalePcs(tonicPc);
    final rootPc = majorScale[degreeIndex % 7];

    // Determine step degrees for letter assignment per chord tone
    // triad: 0, +2, +4; seventh adds +6
    List<int> stepDegrees;
    switch (chordType) {
      case 'Sus2':
        stepDegrees = [0, 1, 4];
        break;
      case 'Sus4':
        stepDegrees = [0, 3, 4];
        break;
      case 'Maj7':
      case 'Min7':
      case 'Dom7':
        stepDegrees = [0, 2, 4, 6];
        break;
      default:
        stepDegrees = [0, 2, 4];
        break;
    }

    // Get chord formula (semitone offsets from root)
    final formula = chordFormulas[_normalizeChordType(chordType)] ?? chordFormulas['Major']!;

    final tones = <String>[];
    for (int i = 0; i < stepDegrees.length && i < formula.length; i++) {
      final step = stepDegrees[i];
      final letterIdx = (tonicLetterIdx + degreeIndex + step) % 7;
      final baseLetter = letterOrder[letterIdx];
      final naturalPc = letterToPc[baseLetter]!;
      final targetPc = (rootPc + formula[i]) % 12;
      tones.add(_spellLetterToPc(baseLetter, naturalPc, targetPc));
    }
    return tones;
  }

  static String _normalizeChordType(String type) {
    switch (type) {
      case 'Major':
      case 'Minor':
      case 'Dim':
      case 'Aug':
      case 'Maj7':
      case 'Min7':
      case 'Dom7':
      case 'Sus2':
      case 'Sus4':
        return type;
      default:
        // Fallback to Major if unknown
        return 'Major';
    }
  }

  /// Spell a [baseLetter] by applying an accidental so its pitch class equals [targetPc].
  /// Chooses the nearest accidental within [-2, 2] (bb..##). Returns e.g., 'E#', 'Bb'.
  static String _spellLetterToPc(String baseLetter, int naturalPc, int targetPc) {
    int diff = (targetPc - naturalPc) % 12;
    if (diff > 6) diff -= 12; // pick the nearest negative direction
    // Clamp to a reasonable range; major diatonic needs at most +/-1, but support +/-2 for safety
    if (diff < -2) diff = -2;
    if (diff > 2) diff = 2;
    final accidental = switch (diff) {
      -2 => 'bb',
      -1 => 'b',
      0 => '',
      1 => '#',
      2 => '##',
      _ => '',
    };
    return '$baseLetter$accidental';
  }

  /// Attempts to parse a note name (e.g., C, C#, Db, Eb, F, Gb, A, Bb, B)
  /// into a pitch class. Returns null if unknown.
  static int? pcForNoteName(String name){
    final clean = name.trim();
    final sharpIndex = pitchNamesSharp.indexOf(clean);
    if (sharpIndex != -1) return sharpIndex;
    final flatIndex = pitchNamesFlat.indexOf(clean);
    if (flatIndex != -1) return flatIndex;
    return null;
  }

  // Chord formulas in semitone offsets from root
  static const Map<String,List<int>> chordFormulas = {
    'Major': [0,4,7],
    'Minor': [0,3,7],
    'Dim': [0,3,6],
    'Aug': [0,4,8],
    'Maj7': [0,4,7,11],
    'Min7': [0,3,7,10],
    'Dom7': [0,4,7,10],
    'Sus2': [0,2,7],
    'Sus4': [0,5,7],
  };

  // Roman numeral to scale degree (0-based)
  static int romanToDegree(String roman){
    final r = roman.replaceAll('°','').replaceAll('#','').replaceAll('b','');
    switch(r){
      case 'I': return 0;
      case 'II': return 1;
      case 'III': return 2;
      case 'IV': return 3;
      case 'V': return 4;
      case 'VI': return 5;
      case 'VII': return 6;
      case 'i': return 0;
      case 'ii': return 1;
      case 'iii': return 2;
      case 'iv': return 3;
      case 'v': return 4;
      case 'vi': return 5;
      case 'vii': return 6;
      default: return 0;
    }
  }

  // Interval label for offset (within octave)
  static String intervalLabel(int offset) {
    final o = (offset % 12 + 12) % 12;
    switch(o){
      case 0: return 'R';
      case 1: return 'b9';
      case 2: return '9';
      case 3: return 'b3';
      case 4: return '3';
      case 5: return '11';
      case 6: return '#11';
      case 7: return '5';
      case 8: return 'b13';
      case 9: return '13';
      case 10: return 'b7';
      case 11: return '7';
      default: return '';
    }
  }

  // Category for color coding
  static String intervalCategory(int offset){
    final o = (offset % 12 + 12) % 12;
    if (o == 0) return 'root';
    if (o == 3 || o == 4) return 'third';
    if (o == 7) return 'fifth';
    if (o == 10 || o == 11) return 'seventh';
    return 'extension';
  }

  // Guitar tuning (EADGBE) as pitch classes
  static const List<int> guitarTuning = [4,9,2,7,11,4];
  static const List<String> guitarStringNames = ['E','A','D','G','B','E'];
}

