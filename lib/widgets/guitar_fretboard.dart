import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:musicbyteai/theme.dart';
import 'package:musicbyteai/models/music_theory.dart';

class GuitarFretboard extends StatelessWidget {
  final int startFret; // starting fret index for the 4-fret window
  final Set<int> selectedPcs; // pitch classes to highlight
  final int rootPc; // root pitch class
  final bool showLabels;
  /// How many frets to render starting from [startFret].
  /// Defaults to 4 (the original compact window used across the app).
  final int fretsVisible;
  /// Optional override for the outer aspect ratio.
  /// If null, uses a sensible default based on [fretsVisible].
  final double? aspectRatio;
  // When true, render the nut on the right and mirror the X-axis mapping.
  final bool nutRight;
  // Optional: prioritize which chord tones to show per string within the 4-fret window.
  // Provide ordered pitch classes; earliest index is most preferred.
  final List<int>? voicingPriority;

  const GuitarFretboard({super.key, required this.startFret, required this.selectedPcs, required this.rootPc, required this.showLabels, this.voicingPriority, this.nutRight = true, this.fretsVisible = 4, this.aspectRatio});

  @override
  Widget build(BuildContext context) {
    final effectiveAspect = aspectRatio ?? _defaultAspectForFrets(fretsVisible);
    return AspectRatio(
      aspectRatio: effectiveAspect,
      child: CustomPaint(
        painter: _GuitarFretboardPainter(
          startFret: startFret,
          selectedPcs: selectedPcs,
          rootPc: rootPc,
          showLabels: showLabels,
          voicingPriority: voicingPriority,
          nutRight: nutRight,
          fretsVisible: fretsVisible,
          theme: Theme.of(context),
        ),
      ),
    );
  }

  static double _defaultAspectForFrets(int fretsVisible) {
    // Keep the original feel at 4 frets.
    // Scale width gently so 12-fret views don’t feel overly compressed.
    final base = 16 / 7;
    if (fretsVisible <= 4) return base;
    if (fretsVisible <= 8) return 3.0;
    return 3.6;
  }
}

class _GuitarFretboardPainter extends CustomPainter {
  final int startFret;
  final Set<int> selectedPcs;
  final int rootPc;
  final bool showLabels;
  final ThemeData theme;
  final List<int>? voicingPriority;
  final bool nutRight;
  final int fretsVisible;

  _GuitarFretboardPainter({
    required this.startFret,
    required this.selectedPcs,
    required this.rootPc,
    required this.showLabels,
    required this.voicingPriority,
    required this.nutRight,
    required this.fretsVisible,
    required this.theme,
  });

  static const int stringsCount = 6;

  @override
  void paint(Canvas canvas, Size size) {
    final intervalColors = theme.extension<IntervalColors>()!;

    final gridLeft = 48.0; // space for string labels
    final gridTop = 16.0;
    final gridRight = size.width - 16.0;
    final gridBottom = size.height - 28.0; // space for fret numbers

    final gridWidth = gridRight - gridLeft;
    final gridHeight = gridBottom - gridTop;

    final cellWidth = gridWidth / fretsVisible;
    final cellHeight = gridHeight / (stringsCount - 1);

    final linePaint = Paint()..color = theme.dividerColor..strokeWidth = 1;
    final fretPaint = Paint()..color = theme.colorScheme.onSurface.withValues(alpha: 0.2)..strokeWidth = 2;

    // Strings (horizontal lines)
    for (int s = 0; s < stringsCount; s++) {
      final y = gridTop + s * cellHeight;
      canvas.drawLine(Offset(gridLeft, y), Offset(gridRight, y), linePaint);
    }

    // Frets (vertical lines)
    // NOTE: only draw a thick "nut" when this window starts at fret 0.
    for (int f = 0; f <= fretsVisible; f++) {
      final x = gridLeft + f * cellWidth;
      final isNut = startFret == 0 && (nutRight ? (f == fretsVisible) : (f == 0));
      canvas.drawLine(Offset(x, gridTop), Offset(x, gridBottom), isNut ? fretPaint : linePaint);
    }

    // String labels
    final textPainter = TextPainter(textAlign: TextAlign.right, textDirection: TextDirection.ltr);
    for (int s = 0; s < stringsCount; s++) {
      String label = TheoryUtils.guitarStringNames[s];
      // Always represent the high E string as a lowercase 'e'
      if (s == stringsCount - 1) label = 'e';
      textPainter.text = TextSpan(text: label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary));
      textPainter.layout();
      final y = gridTop + s * cellHeight - textPainter.height/2;
      textPainter.paint(canvas, Offset(8, y));
    }

    // Fret numbers: label each rendered fret space (e.g., 1..12), not the boundary line.
    for (int f = 0; f < fretsVisible; f++) {
      final fretNum = startFret + f;
      textPainter.text = TextSpan(text: '$fretNum', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary));
      textPainter.layout();
      final fIndex = nutRight ? ((fretsVisible - 1) - f) : f; // mirror when nut is right
      final x = gridLeft + (fIndex + 0.5) * cellWidth - textPainter.width/2;
      textPainter.paint(canvas, Offset(x, gridBottom + 4));
    }

    // Note dots
    final noteTextPainter = TextPainter(textAlign: TextAlign.center, textDirection: TextDirection.ltr);

    // If a voicing priority is provided, pre-compute the preferred fret per string
    final Map<int,int> preferredRfByString = {};
    if (voicingPriority != null && voicingPriority!.isNotEmpty) {
      for (int s = 0; s < stringsCount; s++) {
        final openPc = TheoryUtils.guitarTuning[s];
        int? bestRf;
        int bestPriority = 1 << 30; // large
        for (int rf = 0; rf < fretsVisible; rf++) {
          final absoluteFret = startFret + rf;
          final pc = (openPc + absoluteFret) % 12;
          if (!selectedPcs.contains(pc)) continue;
          final idx = voicingPriority!.indexOf(pc);
          final priority = idx >= 0 ? idx : 999; // de-prioritize tones not in triad voicing
          if (priority < bestPriority || (priority == bestPriority && (bestRf == null || rf < bestRf))) {
            bestPriority = priority;
            bestRf = rf;
          }
        }
        if (bestRf != null) preferredRfByString[s] = bestRf;
      }
    }

    for (int s = 0; s < stringsCount; s++) {
      // top-to-bottom uses E, A, D, G, B, E per TheoryUtils order
      final openPc = TheoryUtils.guitarTuning[s];
      for (int rf = 0; rf < fretsVisible; rf++) {
        final absoluteFret = startFret + rf;
        final pc = (openPc + absoluteFret) % 12;
        if (!selectedPcs.contains(pc)) continue;
        // If voicing priority is provided, only draw the preferred fret on this string
        if (voicingPriority != null && voicingPriority!.isNotEmpty) {
          final expected = preferredRfByString[s];
          if (expected == null || rf != expected) continue;
        }

        // Mirror the X-axis: map fret index within window to mirrored index when nutRight
        final mirroredIndex = nutRight ? ((fretsVisible - 1) - rf) : rf;
        final cx = gridLeft + (mirroredIndex + 0.5) * cellWidth;
        final cy = gridTop + s * cellHeight;

        final offset = (pc - rootPc) % 12;
        final cat = TheoryUtils.intervalCategory(offset);
        Color fill;
        switch (cat) {
          case 'root': fill = intervalColors.root; break;
          case 'third': fill = intervalColors.third; break;
          case 'fifth': fill = intervalColors.fifth; break;
          case 'seventh': fill = intervalColors.seventh; break;
          default: fill = intervalColors.extensionColor; break;
        }

        final dotPaint = Paint()..color = fill;
        final outlinePaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = theme.colorScheme.onSurface.withValues(alpha: 0.22);

        final base = (cellHeight < cellWidth ? cellHeight : cellWidth);
        // Slightly larger dots in wide fretboard views (e.g., 12 frets) so all scale tones are obvious.
        final radius = base * (fretsVisible >= 10 ? 0.33 : 0.28);
        canvas.drawCircle(Offset(cx, cy), radius, dotPaint);
        canvas.drawCircle(Offset(cx, cy), radius, outlinePaint);

        if (showLabels) {
          final label = TheoryUtils.intervalLabel(offset);
          final onDot = fill.computeLuminance() > 0.55 ? Colors.black : Colors.white;
          noteTextPainter.text = TextSpan(text: label, style: theme.textTheme.labelSmall?.copyWith(color: onDot, fontWeight: FontWeight.w900));
          noteTextPainter.layout();
          noteTextPainter.paint(canvas, Offset(cx - noteTextPainter.width/2, cy - noteTextPainter.height/2));
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GuitarFretboardPainter oldDelegate) {
    return oldDelegate.startFret != startFret ||
      !setEquals(oldDelegate.selectedPcs, selectedPcs) ||
      oldDelegate.rootPc != rootPc ||
      oldDelegate.showLabels != showLabels ||
      _listChanged(oldDelegate.voicingPriority, voicingPriority) ||
      oldDelegate.fretsVisible != fretsVisible ||
      oldDelegate.theme.brightness != theme.brightness;
  }

  bool _listChanged(List<int>? a, List<int>? b){
    if (a == null && b == null) return false;
    if (a == null || b == null) return true;
    if (a.length != b.length) return true;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return true;
    }
    return false;
  }
}
