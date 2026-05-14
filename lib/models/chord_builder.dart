import 'package:flutter/foundation.dart';

/// Chord-building utilities for the Viewer.
///
/// This intentionally operates on pitch-classes (0..11) so it can drive
/// both GuitarFretboard + PianoKeyboard highlighting without needing a backend.

enum ChordSize { triad, seventh, ninth, eleventh, thirteenth }

enum SeventhFlavor {
  auto,
  maj7,
  dom7,
  min7,
}

enum ChordOption {
  sus2,
  sus4,
  add9,
  add11,
  add13,
  flat5,
  sharp5,
  flat9,
  sharp9,
  sharp11,
  flat13,
  no3,
  no5,
  tritoneSub,
}

@immutable
class ViewerChordSpec {
  final ChordSize size;
  final SeventhFlavor seventh;
  final int inversion; // 0..(tones-1)
  final Set<ChordOption> options;

  const ViewerChordSpec({
    this.size = ChordSize.triad,
    this.seventh = SeventhFlavor.auto,
    this.inversion = 0,
    this.options = const {},
  });

  ViewerChordSpec copyWith({ChordSize? size, SeventhFlavor? seventh, int? inversion, Set<ChordOption>? options}) =>
      ViewerChordSpec(size: size ?? this.size, seventh: seventh ?? this.seventh, inversion: inversion ?? this.inversion, options: options ?? this.options);
}

class ChordBuilder {
  /// Builds chord pitch-classes in root-position order.
  ///
  /// [diatonicQuality] is the underlying quality of the degree in the key,
  /// typically one of: Major / Minor / Dim / Aug.
  static List<int> buildChordPcsRootOrder({
    required int rootPc,
    required String diatonicQuality,
    required ViewerChordSpec spec,
  }) {
    // If Tritone Sub is enabled, we keep the *shape* but move the root.
    final effectiveRoot = spec.options.contains(ChordOption.tritoneSub) ? (rootPc + 6) % 12 : (rootPc % 12);

    final quality = _normalizeQuality(diatonicQuality);

    // Core degrees: 1, 3, 5
    int third = switch (quality) {
      'Minor' => 3,
      'Dim' => 3,
      _ => 4,
    };
    int fifth = switch (quality) {
      'Dim' => 6,
      'Aug' => 8,
      _ => 7,
    };

    // Sus / alterations / omissions
    if (spec.options.contains(ChordOption.sus2)) third = 2;
    if (spec.options.contains(ChordOption.sus4)) third = 5;
    if (spec.options.contains(ChordOption.flat5)) fifth = 6;
    if (spec.options.contains(ChordOption.sharp5)) fifth = 8;

    final tones = <int>[0];

    if (!spec.options.contains(ChordOption.no3)) tones.add(third);
    if (!spec.options.contains(ChordOption.no5)) tones.add(fifth);

    final wants7 = spec.size != ChordSize.triad;
    if (wants7) {
      final seventh = _resolveSeventhOffset(quality: quality, flavor: spec.seventh);
      if (seventh != null) tones.add(seventh);
    }

    // Natural extensions depending on size.
    final include9 = spec.size == ChordSize.ninth || spec.size == ChordSize.eleventh || spec.size == ChordSize.thirteenth;
    final include11 = spec.size == ChordSize.eleventh || spec.size == ChordSize.thirteenth;
    final include13 = spec.size == ChordSize.thirteenth;

    if (include9 || spec.options.contains(ChordOption.add9)) tones.add(2);
    if (include11 || spec.options.contains(ChordOption.add11)) tones.add(5);
    if (include13 || spec.options.contains(ChordOption.add13)) tones.add(9);

    // Alterations applied to extensions.
    if (spec.options.contains(ChordOption.flat9)) _replaceOrAdd(tones, from: 2, to: 1);
    if (spec.options.contains(ChordOption.sharp9)) _replaceOrAdd(tones, from: 2, to: 3);
    if (spec.options.contains(ChordOption.sharp11)) _replaceOrAdd(tones, from: 5, to: 6);
    if (spec.options.contains(ChordOption.flat13)) _replaceOrAdd(tones, from: 9, to: 8);

    // Make unique, stable order.
    final seen = <int>{};
    final uniqueOffsets = <int>[];
    for (final o in tones) {
      final oo = (o % 12 + 12) % 12;
      if (seen.add(oo)) uniqueOffsets.add(oo);
    }

    return uniqueOffsets.map((o) => (effectiveRoot + o) % 12).toList(growable: false);
  }

  /// Returns a rotated list according to the requested inversion.
  static List<int> applyInversion(List<int> pcsRootOrder, int inversion) {
    if (pcsRootOrder.isEmpty) return pcsRootOrder;
    final inv = inversion.clamp(0, pcsRootOrder.length - 1);
    if (inv == 0) return List<int>.from(pcsRootOrder);
    return [...pcsRootOrder.sublist(inv), ...pcsRootOrder.sublist(0, inv)];
  }

  static String _normalizeQuality(String q) {
    final l = q.trim().toLowerCase();
    if (l.startsWith('min')) return 'Minor';
    if (l.startsWith('dim')) return 'Dim';
    if (l.startsWith('aug')) return 'Aug';
    return 'Major';
  }

  static int? _resolveSeventhOffset({required String quality, required SeventhFlavor flavor}) {
    switch (flavor) {
      case SeventhFlavor.maj7:
        return 11;
      case SeventhFlavor.dom7:
        return 10;
      case SeventhFlavor.min7:
        return 10;
      case SeventhFlavor.auto:
        // Basic diatonic mapping in major:
        // Major -> Maj7, Minor -> Min7, Dim -> Min7 (with b5 already), Aug -> Maj7.
        if (quality == 'Major' || quality == 'Aug') return 11;
        return 10;
    }
  }

  static void _replaceOrAdd(List<int> tones, {required int from, required int to}) {
    final idx = tones.indexWhere((e) => e % 12 == from % 12);
    if (idx == -1) {
      tones.add(to);
    } else {
      tones[idx] = to;
    }
  }
}
