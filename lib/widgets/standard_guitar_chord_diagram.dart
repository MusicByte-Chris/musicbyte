import 'package:flutter/material.dart';
import 'package:musicbyteai/models/music_theory.dart';
import 'package:musicbyteai/theme.dart';

/// A classic, standard “chord-box” diagram (like printed chord charts).
///
/// - 6 strings (low E -> high e)
/// - 5 frets
/// - `X` for muted strings and `O` for open strings
/// - Filled dots for finger positions (optional finger numbers inside)
/// - Optional base fret indicator on the left when the chord starts higher up
class StandardGuitarChordDiagram extends StatefulWidget {
  final String chordLabel;
  final GuitarChordVoicing voicing;
  final VoidCallback? onTap;
  final bool showPlayButton;
  final VoidCallback? onPlay;

  const StandardGuitarChordDiagram({super.key, required this.chordLabel, required this.voicing, this.onTap, this.showPlayButton = false, this.onPlay});

  @override
  State<StandardGuitarChordDiagram> createState() => _StandardGuitarChordDiagramState();
}

class _StandardGuitarChordDiagramState extends State<StandardGuitarChordDiagram> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed == v) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chart = theme.extension<ChordChartColors>() ?? ChordChartColors.light();
    final safeVoicing = _sanitizeVoicing(widget.voicing);

    return LayoutBuilder(
      builder: (context, constraints) {
        final boundedHeight = constraints.hasBoundedHeight && constraints.maxHeight.isFinite;

        // Use a FittedBox so the chord-box can shrink (or grow) to fit the
        // available space inside a Grid tile without triggering overflow.
        final diagram = FittedBox(
          fit: BoxFit.contain,
          alignment: Alignment.topLeft,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: chart.paper,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: chart.border),
            ),
            child: SizedBox(
              width: 200,
              height: 232,
              child: CustomPaint(
                painter: _ChordBoxPainter(voicing: safeVoicing, theme: theme, chart: chart),
              ),
            ),
          ),
        );

        return GestureDetector(
          onTap: widget.onTap,
          onTapDown: (_) => _setPressed(true),
          onTapCancel: () => _setPressed(false),
          onTapUp: (_) => _setPressed(false),
          child: AnimatedScale(
            duration: const Duration(milliseconds: 120),
            scale: _pressed ? 0.985 : 1,
            curve: Curves.easeOut,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.chordLabel,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.showPlayButton)
                        _ChordPlayPill(
                          onPressed: widget.onPlay,
                          foreground: theme.colorScheme.onSurface,
                          background: theme.scaffoldBackgroundColor,
                          border: theme.dividerColor,
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (boundedHeight) Expanded(child: diagram) else SizedBox(height: 240, child: diagram),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  GuitarChordVoicing _sanitizeVoicing(GuitarChordVoicing v) {
    const expected = 6;
    if (v.frets.length == expected && v.fingers.length == expected) return v;

    debugPrint(
      'StandardGuitarChordDiagram: sanitizing voicing for "${widget.chordLabel}" '
      '(frets=${v.frets.length}, fingers=${v.fingers.length})',
    );

    final frets = List<int>.filled(expected, -1);
    for (int i = 0; i < expected && i < v.frets.length; i++) {
      frets[i] = v.frets[i];
    }

    final fingers = List<int?>.filled(expected, null);
    for (int i = 0; i < expected && i < v.fingers.length; i++) {
      fingers[i] = v.fingers[i];
    }

    return GuitarChordVoicing(frets: frets, fingers: fingers);
  }
}

class _ChordPlayPill extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color foreground;
  final Color background;
  final Color border;

  const _ChordPlayPill({required this.onPressed, required this.foreground, required this.background, required this.border});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_arrow_rounded, size: 18, color: foreground),
            const SizedBox(width: 6),
            Text('Play', style: theme.textTheme.labelMedium?.copyWith(color: foreground, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

@immutable
class GuitarChordVoicing {
  /// Frets for strings [E, A, D, G, B, e]
  /// -1 = muted, 0 = open, >0 = fret number.
  final List<int> frets;

  /// Optional finger numbers (1..4) aligned with [frets].
  /// Use null when not specified.
  final List<int?> fingers;

  const GuitarChordVoicing({required this.frets, List<int?>? fingers}) : fingers = fingers ?? const [null, null, null, null, null, null];

  int get minFretted {
    final fretted = frets.where((f) => f > 0);
    if (fretted.isEmpty) return 1;
    return fretted.reduce((a, b) => a < b ? a : b);
  }

  int get maxFretted {
    final fretted = frets.where((f) => f > 0);
    if (fretted.isEmpty) return 1;
    return fretted.reduce((a, b) => a > b ? a : b);
  }
}

class _ChordBoxPainter extends CustomPainter {
  final GuitarChordVoicing voicing;
  final ThemeData theme;
  final ChordChartColors chart;

  static const int _strings = 6;
  static const int _fretsVisible = 5;

  const _ChordBoxPainter({required this.voicing, required this.theme, required this.chart});

  @override
  void paint(Canvas canvas, Size size) {
    // Layout: leave a bit of space above the nut for X/O markers.
    const topMarkersHeight = 18.0;
    const leftFretLabelWidth = 18.0;
    final gridLeft = leftFretLabelWidth;
    final gridTop = topMarkersHeight;
    final gridRight = size.width;
    final gridBottom = size.height;

    final gridWidth = gridRight - gridLeft;
    final gridHeight = gridBottom - gridTop;

    final stringGap = gridWidth / (_strings - 1);
    final fretGap = gridHeight / _fretsVisible;

    final ink = chart.ink;
    final lineColor = ink.withValues(alpha: 0.55);
    final nutColor = ink.withValues(alpha: 0.92);
    final dotColor = ink;

    final linePaint = Paint()..color = lineColor..strokeWidth = 1.0;
    final nutPaint = Paint()..color = nutColor..strokeWidth = 3.0;
    final dotPaint = Paint()..color = dotColor;

    // Determine base fret.
    final minFret = voicing.minFretted;
    final maxFret = voicing.maxFretted;
    final usesNut = minFret <= 1 && maxFret <= _fretsVisible;
    int baseFret;
    if (usesNut) {
      baseFret = 1;
    } else {
      // Keep the whole shape inside the visible window.
      baseFret = minFret;
      if (maxFret - baseFret >= _fretsVisible) {
        baseFret = (maxFret - _fretsVisible) + 1;
      }
    }

    // Vertical strings.
    for (int s = 0; s < _strings; s++) {
      final x = gridLeft + s * stringGap;
      canvas.drawLine(Offset(x, gridTop), Offset(x, gridBottom), linePaint);
    }

    // Horizontal frets.
    for (int f = 0; f <= _fretsVisible; f++) {
      final y = gridTop + f * fretGap;
      final isNutLine = usesNut && f == 0;
      canvas.drawLine(Offset(gridLeft, y), Offset(gridRight, y), isNutLine ? nutPaint : linePaint);
    }

    // Fret number indicator on the left (when not using the nut).
    if (!usesNut) {
      final tp = TextPainter(textAlign: TextAlign.left, textDirection: TextDirection.ltr);
      tp.text = TextSpan(text: '$baseFret', style: theme.textTheme.labelSmall?.copyWith(color: ink, fontWeight: FontWeight.w800));
      tp.layout();
      tp.paint(canvas, Offset(0, gridTop + (fretGap * 0.05)));
    }

    // X / O above strings.
    final markerTp = TextPainter(textAlign: TextAlign.center, textDirection: TextDirection.ltr);
    for (int s = 0; s < _strings; s++) {
      final fret = voicing.frets[s];
      final marker = switch (fret) {
        -1 => 'X',
        0 => 'O',
        _ => '',
      };
      if (marker.isEmpty) continue;
      markerTp.text = TextSpan(text: marker, style: theme.textTheme.labelSmall?.copyWith(color: ink, fontWeight: FontWeight.w900));
      markerTp.layout();
      final x = gridLeft + s * stringGap - markerTp.width / 2;
      markerTp.paint(canvas, Offset(x, 0));
    }

    // Finger dots.
    final fingerTp = TextPainter(textAlign: TextAlign.center, textDirection: TextDirection.ltr);
    for (int s = 0; s < _strings; s++) {
      final fret = voicing.frets[s];
      if (fret <= 0) continue;
      final rel = fret - baseFret;
      if (rel < 0 || rel >= _fretsVisible) continue;
      final x = gridLeft + s * stringGap;
      final y = gridTop + (rel + 0.5) * fretGap;

      final radius = (stringGap < fretGap ? stringGap : fretGap) * 0.26;
      canvas.drawCircle(Offset(x, y), radius, dotPaint);

      final finger = voicing.fingers[s];
      if (finger != null) {
        fingerTp.text = TextSpan(
          text: '$finger',
          style: theme.textTheme.labelSmall?.copyWith(color: chart.paper, fontWeight: FontWeight.w900),
        );
        fingerTp.layout();
        fingerTp.paint(canvas, Offset(x - fingerTp.width / 2, y - fingerTp.height / 2));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ChordBoxPainter oldDelegate) {
    return oldDelegate.theme.brightness != theme.brightness ||
        oldDelegate.chart != chart ||
        oldDelegate.voicing.frets != voicing.frets ||
        oldDelegate.voicing.fingers != voicing.fingers;
  }
}

/// Helper for generating a reasonable, standard-looking voicing for a chord.
///
/// This is intentionally conservative: it prefers common open-chord shapes when
/// available, otherwise falls back to E-shape / A-shape barre chords.
class GuitarChordVoicingGenerator {
  static GuitarChordVoicing forChordLabel(String chordLabel) {
    final parsed = _parseChordLabel(chordLabel);
    final rootPc = TheoryUtils.pcForNoteName(parsed.rootForPcLookup) ?? 0;
    return _voicingFor(rootPc, parsed.quality);
  }

  static GuitarChordVoicing _voicingFor(int rootPc, _ChordQuality quality) {
    // Open chord dictionary (canonical “chart” shapes) for the most common roots.
    // Strings are [E A D G B e].
    final open = _openChordVoicing(rootPc, quality);
    if (open != null) return open;

    // Fall back to movable barre shapes.
    final eShape = _eShape(rootPc, quality);
    final aShape = _aShape(rootPc, quality);

    // Choose the lower-position shape, with a slight preference for E-shape.
    final eBase = eShape.minFretted;
    final aBase = aShape.minFretted;
    if (eBase < aBase) return eShape;
    if (aBase < eBase) return aShape;
    return eShape;
  }

  static GuitarChordVoicing? _openChordVoicing(int rootPc, _ChordQuality quality) {
    // Major opens: C, D, E, F, G, A.
    // Minor opens: Am, Dm, Em.
    // Dom7 opens: A7, B7, C7, D7, E7, G7.
    // Maj7 opens: Cmaj7, Fmaj7, Gmaj7, Amaj7.
    // m7 opens: Am7, Dm7, Em7.
    // Sus2/sus4 opens: Asus2/Asus4, Dsus2/Dsus4, Esus4.
    // Dim has no reliable open canonical; use barre.
    const shapes = <String, List<int>>{
      'C:maj': [-1, 3, 2, 0, 1, 0],
      'D:maj': [-1, -1, 0, 2, 3, 2],
      'E:maj': [0, 2, 2, 1, 0, 0],
      'F:maj': [1, 3, 3, 2, 1, 1],
      'G:maj': [3, 2, 0, 0, 0, 3],
      'A:maj': [-1, 0, 2, 2, 2, 0],
      'E:min': [0, 2, 2, 0, 0, 0],
      'A:min': [-1, 0, 2, 2, 1, 0],
      'D:min': [-1, -1, 0, 2, 3, 1],
      'A:7': [-1, 0, 2, 0, 2, 0],
      'B:7': [-1, 2, 1, 2, 0, 2],
      'C:7': [-1, 3, 2, 3, 1, 0],
      'D:7': [-1, -1, 0, 2, 1, 2],
      'E:7': [0, 2, 0, 1, 0, 0],
      'G:7': [3, 2, 0, 0, 0, 1],
      'C:maj7': [-1, 3, 2, 0, 0, 0],
      'F:maj7': [-1, -1, 3, 2, 1, 0],
      'G:maj7': [3, 2, 0, 0, 0, 2],
      'A:maj7': [-1, 0, 2, 1, 2, 0],
      'A:min7': [-1, 0, 2, 0, 1, 0],
      'D:min7': [-1, -1, 0, 2, 1, 1],
      'E:min7': [0, 2, 2, 0, 3, 0],
      'A:sus2': [-1, 0, 2, 2, 0, 0],
      'A:sus4': [-1, 0, 2, 2, 3, 0],
      'D:sus2': [-1, -1, 0, 2, 3, 0],
      'D:sus4': [-1, -1, 0, 2, 3, 3],
      'E:sus4': [0, 2, 2, 2, 0, 0],
    };

    final rootNameSharp = TheoryUtils.nameForPc(rootPc, useFlats: false);
    final rootNameFlat = TheoryUtils.nameForPc(rootPc, useFlats: true);
    final rootKey = _simpleRootKeyForOpenChord(rootNameSharp) ?? _simpleRootKeyForOpenChord(rootNameFlat);
    if (rootKey == null) return null;

    final qKey = switch (quality) {
      _ChordQuality.major => 'maj',
      _ChordQuality.minor => 'min',
      _ChordQuality.dom7 => '7',
      _ChordQuality.maj7 => 'maj7',
      _ChordQuality.min7 => 'min7',
      _ChordQuality.sus2 => 'sus2',
      _ChordQuality.sus4 => 'sus4',
      _ChordQuality.dim => 'dim',
      _ChordQuality.unknown => 'maj',
    };

    final frets = shapes['$rootKey:$qKey'];
    if (frets == null) return null;

    // Add a few tasteful finger numbers for the open shapes that are commonly labeled.
    final fingers = _defaultOpenFingers(rootKey, quality);
    return GuitarChordVoicing(frets: frets, fingers: fingers);
  }

  static String? _simpleRootKeyForOpenChord(String root) {
    // Open-chord dictionary only includes naturals.
    return switch (root) {
      'A' => 'A',
      'B' => 'B',
      'C' => 'C',
      'D' => 'D',
      'E' => 'E',
      'F' => 'F',
      'G' => 'G',
      _ => null,
    };
  }

  static List<int?> _defaultOpenFingers(String rootKey, _ChordQuality quality) {
    // These are small “nice-to-have” finger labels; leaving them empty is OK.
    // (We only label a subset to avoid misleading information.)
    return switch ('$rootKey:${quality.name}') {
      'C:major' => const [null, 3, 2, null, 1, null],
      'G:major' => const [2, 1, null, null, null, 3],
      'D:major' => const [null, null, null, 1, 3, 2],
      'A:major' => const [null, null, 1, 2, 3, null],
      'E:major' => const [null, 2, 3, 1, null, null],
      'A:minor' => const [null, null, 2, 3, 1, null],
      'E:minor' => const [null, 2, 3, null, null, null],
      _ => const [null, null, null, null, null, null],
    };
  }

  static GuitarChordVoicing _eShape(int rootPc, _ChordQuality quality) {
    // Root on low E string.
    final openE = TheoryUtils.guitarTuning[0];
    final r = _positiveFret((rootPc - openE) % 12);
    final base = r == 0 ? 12 : r; // avoid open E-shape; we already handled open shapes.
    List<int> frets;
    List<int?> fingers;
    switch (quality) {
      case _ChordQuality.minor:
        frets = [base, base + 2, base + 2, base, base, base];
        fingers = const [1, 3, 4, 1, 1, 1];
        break;
      case _ChordQuality.dom7:
        frets = [base, base + 2, base, base + 1, base, base];
        fingers = const [1, 3, 1, 2, 1, 1];
        break;
      case _ChordQuality.maj7:
        frets = [base, base + 2, base + 1, base + 1, base, base];
        fingers = const [1, 3, 2, 2, 1, 1];
        break;
      case _ChordQuality.min7:
        frets = [base, base + 2, base, base, base, base];
        fingers = const [1, 3, 1, 1, 1, 1];
        break;
      case _ChordQuality.sus4:
        frets = [base, base + 2, base + 2, base + 2, base, base];
        fingers = const [1, 3, 4, 2, 1, 1];
        break;
      case _ChordQuality.sus2:
        frets = [base, base + 2, base + 2, base, base, base];
        fingers = const [1, 3, 4, 1, 1, 1];
        break;
      case _ChordQuality.dim:
        // A simple diminished triad-esque shape (not a full dim7 chord).
        frets = [base, base + 1, base + 2, base, base + 2, base];
        fingers = const [1, 2, 4, 1, 4, 1];
        break;
      case _ChordQuality.major:
      case _ChordQuality.unknown:
        frets = [base, base + 2, base + 2, base + 1, base, base];
        fingers = const [1, 3, 4, 2, 1, 1];
        break;
    }
    return GuitarChordVoicing(frets: frets, fingers: fingers);
  }

  static GuitarChordVoicing _aShape(int rootPc, _ChordQuality quality) {
    // Root on A string.
    final openA = TheoryUtils.guitarTuning[1];
    final r = _positiveFret((rootPc - openA) % 12);
    final base = r == 0 ? 12 : r; // avoid open A-shape; open handled above.
    List<int> frets;
    List<int?> fingers;
    switch (quality) {
      case _ChordQuality.minor:
        frets = [-1, base, base + 2, base + 2, base + 1, base];
        fingers = const [null, 1, 3, 4, 2, 1];
        break;
      case _ChordQuality.dom7:
        frets = [-1, base, base + 2, base, base + 2, base];
        fingers = const [null, 1, 3, 1, 4, 1];
        break;
      case _ChordQuality.maj7:
        frets = [-1, base, base + 2, base + 1, base + 2, base];
        fingers = const [null, 1, 3, 2, 4, 1];
        break;
      case _ChordQuality.min7:
        frets = [-1, base, base + 2, base, base + 1, base];
        fingers = const [null, 1, 3, 1, 2, 1];
        break;
      case _ChordQuality.sus4:
        frets = [-1, base, base + 2, base + 2, base + 3, base];
        fingers = const [null, 1, 2, 3, 4, 1];
        break;
      case _ChordQuality.sus2:
        frets = [-1, base, base + 2, base + 2, base, base];
        fingers = const [null, 1, 2, 3, 1, 1];
        break;
      case _ChordQuality.dim:
        frets = [-1, base, base + 1, base + 2, base + 1, base + 2];
        fingers = const [null, 1, 2, 4, 3, 4];
        break;
      case _ChordQuality.major:
      case _ChordQuality.unknown:
        frets = [-1, base, base + 2, base + 2, base + 2, base];
        fingers = const [null, 1, 2, 3, 4, 1];
        break;
    }
    return GuitarChordVoicing(frets: frets, fingers: fingers);
  }

  static int _positiveFret(int semitones) {
    var v = semitones % 12;
    if (v < 0) v += 12;
    return v;
  }
}

class _ParsedChordLabel {
  final String root;
  final _ChordQuality quality;
  const _ParsedChordLabel({required this.root, required this.quality});

  /// Converts Unicode flats/sharps into the ascii note-name set supported by
  /// [TheoryUtils.pcForNoteName].
  String get rootForPcLookup => root.replaceAll('♭', 'b').replaceAll('♯', '#');
}

enum _ChordQuality { major, minor, dom7, maj7, min7, sus2, sus4, dim, unknown }

_ParsedChordLabel _parseChordLabel(String label) {
  final t = label.trim();
  if (t.isEmpty) return const _ParsedChordLabel(root: 'C', quality: _ChordQuality.major);

  // Root = letter + optional accidental.
  final rootMatch = RegExp(r'^[A-G](?:[#b♯♭])?').firstMatch(t);
  final root = rootMatch?.group(0) ?? 'C';
  final rest = t.substring(root.length);

  _ChordQuality q;
  final lower = rest.toLowerCase();
  if (lower.startsWith('maj7')) {
    q = _ChordQuality.maj7;
  } else if (lower.startsWith('m7') || lower.startsWith('min7')) {
    q = _ChordQuality.min7;
  } else if (lower == '7' || lower.startsWith('7')) {
    q = _ChordQuality.dom7;
  } else if (lower.startsWith('sus2')) {
    q = _ChordQuality.sus2;
  } else if (lower.startsWith('sus4') || lower.startsWith('sus')) {
    q = _ChordQuality.sus4;
  } else if (lower.startsWith('dim') || lower.contains('°')) {
    q = _ChordQuality.dim;
  } else if (lower.startsWith('m') || lower.startsWith('min')) {
    q = _ChordQuality.minor;
  } else if (lower.isEmpty) {
    q = _ChordQuality.major;
  } else {
    q = _ChordQuality.unknown;
  }

  return _ParsedChordLabel(root: root, quality: q);
}
