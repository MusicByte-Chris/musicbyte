import 'package:flutter/foundation.dart';
import 'package:musicbyteai/models/music_theory.dart';
import 'package:musicbyteai/widgets/standard_guitar_chord_diagram.dart';

/// Generates *playable*, chart-friendly guitar shapes for:
/// - triads in Root/1st/2nd inversion
/// - Maj7 and Dom7 in Root/1st/2nd/3rd inversion
///
/// This is intentionally not an exhaustive algorithmic chord solver.
/// Instead, it uses curated *voicing recipes* (which strings to use and which
/// chord tone belongs on each), then searches for a compact 5-fret position
/// that satisfies those recipes.
class GuitarVoicingLibrary {
  static GuitarChordVoicing voicingFor({required List<int> chordPcsRootOrder, required int inversion}) {
    if (chordPcsRootOrder.isEmpty) {
      // Defensive fallback: an all-muted voicing renders as a “blank” diagram.
      // If callers accidentally provide an empty chord, show a safe, recognizable
      // open C major shape instead.
      debugPrint('GuitarVoicingLibrary: empty chordPcsRootOrder; using C major fallback');
      return GuitarChordVoicingGenerator.forChordLabel('C');
    }

    final inv = inversion.clamp(0, chordPcsRootOrder.length - 1);
    final toneOrder = _rot(chordPcsRootOrder, inv);
    final bassPc = toneOrder.first;

    // Prefer compact 4-string voicings (A-D-G-B) for 7ths, and 4/5-string for triads.
    final recipes = <_VoicingRecipe>[];

    if (chordPcsRootOrder.length == 3) {
      recipes.addAll([
        _VoicingRecipe(strings: const [1, 2, 3, 4], toneIndexes: const [0, 1, 2, 1]), // A D G B
        _VoicingRecipe(strings: const [2, 3, 4, 5], toneIndexes: const [0, 1, 2, 1]), // D G B e
        _VoicingRecipe(strings: const [0, 1, 2, 3], toneIndexes: const [0, 2, 1, 2]), // E A D G
      ]);
    } else {
      // 7th chords: A-string root/bass jazz grip. Keeps low E muted to avoid muddiness.
      recipes.addAll([
        _VoicingRecipe(strings: const [1, 2, 3, 4], toneIndexes: const [0, 2, 3, 1]), // bass,5,7,3
        _VoicingRecipe(strings: const [2, 3, 4, 5], toneIndexes: const [0, 2, 3, 1]), // D G B e
        _VoicingRecipe(strings: const [0, 1, 2, 3], toneIndexes: const [0, 2, 3, 1]), // E A D G
      ]);
    }

    for (final r in recipes) {
      final found = _tryRecipe(recipe: r, toneOrder: toneOrder, bassPc: bassPc);
      if (found != null) return found;
    }

    // Last-resort: a simple root-position barre for the root pitch class.
    // (Inversion may not be satisfied, but this prevents blanks.)
    debugPrint('GuitarVoicingLibrary: fallback barre (inv=$inv, tones=$toneOrder)');
    final rootPc = chordPcsRootOrder.first;
    final label = _labelForFallback(rootPc: rootPc, pcsRootOrder: chordPcsRootOrder);
    return GuitarChordVoicingGenerator.forChordLabel(label);
  }

  static String _labelForFallback({required int rootPc, required List<int> pcsRootOrder}) {
    final root = TheoryUtils.nameForPc(rootPc, useFlats: false);
    if (pcsRootOrder.length == 4) {
      final third = (pcsRootOrder[1] - pcsRootOrder[0]) % 12;
      final seventh = (pcsRootOrder[3] - pcsRootOrder[0]) % 12;
      if (third == 4 && seventh == 11) return '${root}maj7';
      if (third == 4 && seventh == 10) return '${root}7';
      if (third == 3 && seventh == 10) return '${root}m7';
    }
    if (pcsRootOrder.length >= 3) {
      final third = (pcsRootOrder[1] - pcsRootOrder[0]) % 12;
      final fifth = (pcsRootOrder[2] - pcsRootOrder[0]) % 12;
      if (third == 3 && fifth == 6) return '${root}dim';
      if (third == 3) return '${root}m';
    }
    return root;
  }

  static GuitarChordVoicing? _tryRecipe({required _VoicingRecipe recipe, required List<int> toneOrder, required int bassPc}) {
    final bassString = recipe.strings.first;
    final openPc = TheoryUtils.guitarTuning[bassString];

    final bassCandidates = <int>[];
    for (int fret = 0; fret <= 12; fret++) {
      if ((openPc + fret) % 12 == bassPc) bassCandidates.add(fret);
    }
    // Prefer lower frets, but avoid *only* open when possible for consistency.
    bassCandidates.sort();
    final reordered = <int>[...bassCandidates.where((f) => f > 0), ...bassCandidates.where((f) => f == 0)];

    for (final baseFret in reordered) {
      final windowStart = (baseFret - 1).clamp(0, 12);
      final windowEnd = (baseFret + 4).clamp(0, 17);
      final frets = List<int>.filled(6, -1);

      var ok = true;
      for (int i = 0; i < recipe.strings.length; i++) {
        final s = recipe.strings[i];
        final toneIdx = recipe.toneIndexes[i] % toneOrder.length;
        final targetPc = toneOrder[toneIdx];
        final f = _firstFretForPcOnStringInWindow(stringIndex: s, targetPc: targetPc, start: windowStart, end: windowEnd);
        if (f == null) {
          ok = false;
          break;
        }
        frets[s] = f;
      }
      if (!ok) continue;

      // Ensure the bass string really is the lowest sounding string.
      // (If earlier strings are accidentally open, mute them.)
      for (int s = 0; s < bassString; s++) {
        frets[s] = -1;
      }

      // Make sure the resulting span isn't insane.
      final v = GuitarChordVoicing(frets: frets);
      final span = v.maxFretted - v.minFretted;
      if (span > 5) continue;

      return v;
    }
    return null;
  }

  static int? _firstFretForPcOnStringInWindow({required int stringIndex, required int targetPc, required int start, required int end}) {
    final openPc = TheoryUtils.guitarTuning[stringIndex];
    for (int fret = start; fret <= end; fret++) {
      if ((openPc + fret) % 12 == targetPc) return fret;
    }
    return null;
  }

  static List<int> _rot(List<int> list, int by) {
    if (list.isEmpty) return list;
    final k = by % list.length;
    if (k == 0) return List<int>.from(list);
    return [...list.sublist(k), ...list.sublist(0, k)];
  }
}

class _VoicingRecipe {
  final List<int> strings; // 0..5 low->high
  final List<int> toneIndexes; // indexes into rotated toneOrder
  const _VoicingRecipe({required this.strings, required this.toneIndexes});
}
