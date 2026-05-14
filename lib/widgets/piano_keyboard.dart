import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:musicbyteai/theme.dart';
import 'package:musicbyteai/models/music_theory.dart';

class PianoKeyboard extends StatelessWidget {
  final Set<int> selectedPcs; // pitch classes to highlight
  final int rootPc;
  final bool showLabels;
  final int octaves; // number of octaves to display, from C
  // Optional anchor for voicing bass preference. When set, we ensure
  // the lowest displayed highlighted tone is this pc by restricting
  // octave 1 highlights to the anchor only (others show in higher octaves).
  final int? anchorPc;

  const PianoKeyboard({super.key, required this.selectedPcs, required this.rootPc, required this.showLabels, this.octaves = 2, this.anchorPc});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16/5,
      child: CustomPaint(
        painter: _PianoPainter(
          selectedPcs: selectedPcs,
          rootPc: rootPc,
          showLabels: showLabels,
          octaves: octaves,
          anchorPc: anchorPc,
          theme: Theme.of(context),
        ),
      ),
    );
  }
}

class _PianoPainter extends CustomPainter {
  final Set<int> selectedPcs;
  final int rootPc;
  final bool showLabels;
  final int octaves;
  final ThemeData theme;
  final int? anchorPc;

  _PianoPainter({required this.selectedPcs, required this.rootPc, required this.showLabels, required this.octaves, required this.anchorPc, required this.theme});

  static const List<int> blackOffsets = [1,3,6,8,10];
  static bool isBlack(int pc) => blackOffsets.contains(pc % 12);

  Color _intervalFill(IntervalColors intervalColors, int offset) {
    final cat = TheoryUtils.intervalCategory(offset);
    return switch (cat) {
      'root' => intervalColors.root,
      'third' => intervalColors.third,
      'fifth' => intervalColors.fifth,
      'seventh' => intervalColors.seventh,
      _ => intervalColors.extensionColor,
    };
  }

  Color _labelColorForFill(Color fill) {
    final lum = fill.computeLuminance();
    return lum >= 0.55 ? Colors.black : Colors.white;
  }

  void _paintHighlight(Canvas canvas, Rect rect, {required bool blackKey, required Color fill, required String label}) {
    // Music UI convention: an outlined color “inlay” reads better than
    // fully flooding the entire key (especially on black keys).
    final inset = blackKey ? 3.0 : 4.0;
    final r = rect.deflate(inset);

    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = blackKey ? 2.0 : 2.2
      ..color = fill.withValues(alpha: 0.95);

    final body = Paint()
      ..style = PaintingStyle.fill
      ..color = fill.withValues(alpha: blackKey ? 0.78 : 0.64);

    final radius = Radius.circular(blackKey ? 5 : 7);
    canvas.drawRRect(RRect.fromRectAndRadius(r, radius), body);
    canvas.drawRRect(RRect.fromRectAndRadius(r, radius), border);

    if (!showLabels) return;
    final tp = TextPainter(textAlign: TextAlign.center, textDirection: TextDirection.ltr);
    tp.text = TextSpan(
      text: label,
      style: theme.textTheme.labelSmall?.copyWith(color: _labelColorForFill(fill), fontWeight: FontWeight.w800, letterSpacing: 0.6),
    );
    tp.layout(maxWidth: r.width);
    final y = blackKey ? (r.top + 3) : (r.top + 4);
    tp.paint(canvas, Offset(r.center.dx - tp.width / 2, y));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final intervalColors = theme.extension<IntervalColors>()!;

    // Layout calcs
    final padding = 8.0;
    final top = padding;
    final bottom = size.height - padding;
    final left = padding;
    final right = size.width - padding;
    final height = bottom - top;

    final whiteKeysPerOctave = 7;
    final totalWhiteKeys = whiteKeysPerOctave * octaves;
    final whiteKeyWidth = (right - left) / totalWhiteKeys;

    // Key base colors: slightly lifted from the page background so the keyboard
    // reads like an instrument (not just a flat panel).
    final whiteBase = Color.lerp(theme.scaffoldBackgroundColor, theme.colorScheme.onSurface, 0.10) ?? theme.colorScheme.surface;
    final blackBase = Color.lerp(theme.scaffoldBackgroundColor, theme.colorScheme.onSurface, 0.04) ?? theme.scaffoldBackgroundColor;

    final whitePaint = Paint()..color = whiteBase;
    final whiteBorder = Paint()
      ..color = theme.dividerColor.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final blackPaint = Paint()..color = blackBase;
    final blackBorder = Paint()
      ..color = theme.dividerColor.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw white keys
    int whiteIndex = 0;
    for (int o = 0; o < octaves; o++) {
      for (int step = 0; step < 12; step++) {
        final pc = step;
        if (isBlack(pc)) continue;
        final x = left + whiteIndex * whiteKeyWidth;
        final rect = Rect.fromLTWH(x, top, whiteKeyWidth, height);
        canvas.drawRect(rect, whitePaint);
        canvas.drawRect(rect, whiteBorder);

        // highlight if selected
        final globalPc = (pc) % 12;
        final shouldHighlight = selectedPcs.contains(globalPc) && !(anchorPc != null && o == 0 && globalPc != anchorPc);
        if (shouldHighlight) {
          final offset = (globalPc - rootPc) % 12;
          final fill = _intervalFill(intervalColors, offset);
          _paintHighlight(canvas, rect, blackKey: false, fill: fill, label: TheoryUtils.intervalLabel(offset));
        }
        whiteIndex++;
      }
    }

    // Draw black keys (overlay)
    whiteIndex = 0;
    for (int o = 0; o < octaves; o++) {
      int stepIndexInWhite = 0;
      for (int step = 0; step < 12; step++) {
        final pc = step;
        if (!isBlack(pc)) {
          // increment white key tracker
          stepIndexInWhite++;
          continue;
        }
        // Find x by placing between adjacent white keys
        // Black key occurs after preceding white key
        final prevWhiteIdx = _prevWhiteIndexForStep(pc, stepIndexInWhite, o, octaves);
        final x = left + (prevWhiteIdx + 0.75) * whiteKeyWidth; // slightly right of prev white center
        final bw = whiteKeyWidth * 0.6;
        final bh = height * 0.6;
        final rect = Rect.fromCenter(center: Offset(x, top + bh/2), width: bw, height: bh);

        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), blackPaint);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), blackBorder);

        final globalPc = (pc) % 12;
        final shouldHighlight = selectedPcs.contains(globalPc) && !(anchorPc != null && o == 0 && globalPc != anchorPc);
        if (shouldHighlight) {
          final offset = (globalPc - rootPc) % 12;
          final fill = _intervalFill(intervalColors, offset);
          _paintHighlight(canvas, rect, blackKey: true, fill: fill, label: TheoryUtils.intervalLabel(offset));
        }
      }
    }
  }

  int _prevWhiteIndexForStep(int stepPc, int stepIndexInWhite, int octave, int octaves) {
    // Map step -> index among whites up to that point in octave
    // White order within octave steps: 0(C),2(D),4(E),5(F),7(G),9(A),11(B)
    int idxInWhiteBeforeBlack;
    switch(stepPc){
      case 1: idxInWhiteBeforeBlack = 0; break; // C# after C
      case 3: idxInWhiteBeforeBlack = 1; break; // D# after D
      case 6: idxInWhiteBeforeBlack = 3; break; // F# after F
      case 8: idxInWhiteBeforeBlack = 4; break; // G# after G
      case 10: idxInWhiteBeforeBlack = 5; break; // A# after A
      default: idxInWhiteBeforeBlack = 0; break;
    }
    final whiteKeysPerOctave = 7;
    return octave * whiteKeysPerOctave + idxInWhiteBeforeBlack;
  }

  @override
  bool shouldRepaint(covariant _PianoPainter oldDelegate) {
    return !setEquals(oldDelegate.selectedPcs, selectedPcs) ||
      oldDelegate.rootPc != rootPc ||
      oldDelegate.showLabels != showLabels ||
      oldDelegate.octaves != octaves ||
      oldDelegate.anchorPc != anchorPc ||
      oldDelegate.theme.brightness != theme.brightness;
  }
}
