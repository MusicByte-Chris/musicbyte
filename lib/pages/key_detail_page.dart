import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../data/theory_repository.dart';
import 'package:musicbyteai/models/music_theory.dart';
import 'package:musicbyteai/services/audio_engine_service.dart';
import '../theme.dart';
import '../widgets/piano_keyboard.dart';
import '../widgets/guitar_fretboard.dart';

class KeyDetailPage extends StatefulWidget {
  final String keyId;

  const KeyDetailPage({super.key, required this.keyId});

  static const List<String> _intervalScaleIds = ['ionian', 'aeolian', 'harm_minor', 'mel_minor_asc', 'dorian', 'mixolydian'];

  @override
  State<KeyDetailPage> createState() => _KeyDetailPageState();
}

class _KeyDetailPageState extends State<KeyDetailPage> {
  String _notationMode = 'roman'; // 'roman' | 'nashville'

  String _nashLabelFor(int index, String type) {
    final n = (index + 1).toString();
    switch (type) {
      case 'Minor':
        return '${n}m';
      case 'Dim':
        return '${n}°';
      default:
        return n;
    }
  }

  void _showNotationInfo(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: theme.cardTheme.color,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + MediaQuery.of(ctx).padding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline_rounded, color: theme.colorScheme.tertiary, size: 20),
                const SizedBox(width: 8),
                Text('About Notation', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface)),
                const Spacer(),
                IconButton(onPressed: () => ctx.pop(), icon: const Icon(Icons.close_rounded)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Roman numerals and the Nashville Number System both represent scale degrees instead of letter names. Roman uses traditional classical notation. Nashville uses numeric shorthand for fast key changes in studio sessions.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('KeyDetailPage.build: keyId=${widget.keyId} notation=$_notationMode');
    final theme = Theme.of(context);
    final keyData = TheoryRepository.getKeyById(widget.keyId);
    final chords = TheoryRepository.getDiatonicChords(widget.keyId);
    final scale = TheoryRepository.getMajorScale(widget.keyId);

    // Generate modes based on scale degrees
    final modes = [
      "Ionian (${scale[0].note})",
      "Dorian (${scale[1].note})",
      "Phrygian (${scale[2].note})",
      "Lydian (${scale[3].note})",
      "Mixolydian (${scale[4].note})",
      "Aeolian (${scale[5].note})",
      "Locrian (${scale[6].note})",
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(keyData.name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'roman', label: Text('Roman')),
                  ButtonSegment(value: 'nashville', label: Text('Nashville')),
                ],
                selected: {_notationMode},
                onSelectionChanged: (s) => setState(() => _notationMode = s.first),
                showSelectedIcon: false,
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Notation info',
            icon: Icon(Icons.info_outline_rounded, color: theme.colorScheme.secondary),
            onPressed: () => _showNotationInfo(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
        children: [
          _SectionHeader(title: 'Key Signature Visuals', showAction: false),
          KeySignatureVisualsSection(keyId: widget.keyId),

          const SizedBox(height: 32),
          _SectionHeader(title: 'Key Info', showAction: false),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Relative: ${keyData.relativeMinor}",
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  "${keyData.accidentalsCountString}${keyData.accidentals.isEmpty ? '' : ' (${keyData.accidentals.join(', ')})'}",
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary, height: 1.5),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: BorderRadius.circular(AppRadius.full), border: Border.all(color: theme.dividerColor)),
                      child: Text('A4 = 440Hz', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // START CLEAN: degrees list begins immediately under the AppBar.
          ...List.generate(scale.length, (i) {
            final s = scale[i];
            final chord = chords[i];
            final quality = chord.type; // 'Major' | 'Minor' | 'Dim'
            final notation = _notationMode == 'roman' ? chord.roman : _nashLabelFor(i, quality);
            return ScaleDegreeTile(
              degree: s.degree,
              note: s.note,
              frequencyLabel: s.frequency,
              quality: quality,
              notation: notation,
            );
          }),

          const SizedBox(height: 28),

          _SectionHeader(
            title: "Diatonic Chords",
            action: "See All",
            showAction: true,
            onActionTap: () => _openDiatonicChordsSheet(context, widget.keyId),
          ),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: chords.length,
              separatorBuilder: (c, i) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final chord = chords[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  onTap: () => _openChordDetail(context, widget.keyId, chord),
                  child: Container(
                    width: 100,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(chord.roman, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary)),
                        const SizedBox(height: 4),
                        Text(chord.name, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(chord.type, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.tertiary), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: () => context.push('/viewer?key=${widget.keyId}&tab=chord'),
              icon: const Icon(Icons.piano_rounded),
              label: const Text('Open Chord/Scale Viewer'),
            ),
          ),

          const SizedBox(height: 32),
          _SectionHeader(title: "Modes of ${keyData.name}", showAction: false),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: modes
                .map(
                  (mode) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Text(mode, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurface)),
                  ),
                )
                .toList(),
          ),

          const SizedBox(height: 32),
          _SectionHeader(title: 'Interval Reference', showAction: false),
          IntervalReferenceSection(keyId: widget.keyId, keyName: keyData.name, scaleIds: KeyDetailPage._intervalScaleIds),

          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
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
                    Icon(Icons.graphic_eq_rounded, color: theme.colorScheme.tertiary, size: 20),
                    const SizedBox(width: 8),
                    Text("Engineering Note", style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  "Eb1 (Sub-bass) starts at ~38.89 Hz. Fundamental for kick drums in this key often sits around 77.78 Hz (Eb2).",
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary, height: 1.5),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.play_arrow_rounded, size: 16),
                      label: const Text("Tone Gen"),
                      onPressed: () {},
                      backgroundColor: theme.scaffoldBackgroundColor,
                    ),
                    const SizedBox(width: 8),
                    ActionChip(
                      avatar: const Icon(Icons.insights_rounded, size: 16),
                      label: const Text("EQ Map"),
                      onPressed: () {},
                      backgroundColor: theme.scaffoldBackgroundColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openDiatonicChordsSheet(BuildContext context, String keyId) {
    final chords = TheoryRepository.getDiatonicChords(keyId);
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
      builder: (ctx) => DiatonicChordsSheet(
        keyId: keyId,
        chords: chords,
        onSelect: (chord) {
          ctx.pop();
          // Delay to let the sheet close before opening the next
          Future.microtask(() => _openChordDetail(context, keyId, chord));
        },
      ),
    );
  }

  void _openChordDetail(BuildContext context, String keyId, Chord chord) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
      builder: (ctx) => ChordDetailSheet(keyId: keyId, chord: chord),
    );
  }
}

class IntervalReferenceSection extends StatefulWidget {
  final String keyId;
  final String keyName;
  final List<String> scaleIds;

  /// Interval table per scale, spelled for [keyId].
  const IntervalReferenceSection({super.key, required this.keyId, required this.keyName, required this.scaleIds});

  @override
  State<IntervalReferenceSection> createState() => _IntervalReferenceSectionState();
}

class _IntervalReferenceSectionState extends State<IntervalReferenceSection> {
  String? _expandedScaleId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final intervalColors = theme.extension<IntervalColors>()!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tap a scale to view degrees, interval names, and the spelled notes in ${widget.keyName}.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary, height: 1.5),
          ),
          const SizedBox(height: 12),
          ...widget.scaleIds.where((id) => TheoryUtils.scaleNames.containsKey(id)).map((scaleId) {
            final title = TheoryUtils.scaleNames[scaleId]!;
            final expanded = _expandedScaleId == scaleId;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ExpandableScaleCard(
                title: title,
                expanded: expanded,
                onTap: () => setState(() => _expandedScaleId = expanded ? null : scaleId),
                child: _IntervalTable(
                  keyId: widget.keyId,
                  scaleId: scaleId,
                  intervalColors: intervalColors,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ExpandableScaleCard extends StatelessWidget {
  final String title;
  final bool expanded;
  final VoidCallback onTap;
  final Widget child;

  const _ExpandableScaleCard({required this.title, required this.expanded, required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: theme.colorScheme.tertiary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 180),
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(padding: const EdgeInsets.fromLTRB(14, 0, 14, 14), child: child),
            crossFadeState: expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          ),
        ],
      ),
    );
  }
}

class _IntervalTable extends StatelessWidget {
  final String keyId;
  final String scaleId;
  final IntervalColors intervalColors;

  const _IntervalTable({required this.keyId, required this.scaleId, required this.intervalColors});

  static const _degreeLabels = ['1', '2', '3', '4', '5', '6', '7'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final useFlats = TheoryRepository.getKeyById(keyId).sharps < 0;

    final tonicPc = TheoryUtils.pcForKeyId(keyId);
    final pcs = TheoryUtils.scaleById(scaleId, tonicPc);
    final spelled = TheoryUtils.spelledScaleForKey(keyId: keyId, scaleId: scaleId);

    final rows = List.generate(7, (i) {
      final semitones = ((pcs[i] - tonicPc) % 12 + 12) % 12;
      return _IntervalRowData(
        degree: _degreeLabels[i],
        intervalName: _intervalName(semitones),
        note: spelled.length > i ? spelled[i] : TheoryUtils.nameForPc(pcs[i], useFlats: useFlats),
        degreeIndex: i,
      );
    });

    return Column(
      children: [
        _IntervalHeaderRow(),
        const SizedBox(height: 8),
        ...rows.map((r) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: _IntervalRow(r: r, intervalColors: intervalColors),
            )),
        const SizedBox(height: 6),
        Text(
          'Note spellings are diatonic (letter-accurate) for the selected key.',
          style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary),
        ),
      ],
    );
  }

  String _intervalName(int semitones) {
    switch (semitones) {
      case 0:
        return 'Unison';
      case 1:
        return 'Minor 2nd';
      case 2:
        return 'Major 2nd';
      case 3:
        return 'Minor 3rd';
      case 4:
        return 'Major 3rd';
      case 5:
        return 'Perfect 4th';
      case 6:
        return 'Tritone';
      case 7:
        return 'Perfect 5th';
      case 8:
        return 'Minor 6th';
      case 9:
        return 'Major 6th';
      case 10:
        return 'Minor 7th';
      case 11:
        return 'Major 7th';
      default:
        return '${semitones} semitones';
    }
  }
}

class _IntervalHeaderRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        SizedBox(
          width: 58,
          child: Text('Degree', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary)),
        ),
        Expanded(child: Text('Interval', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary))),
        SizedBox(
          width: 88,
          child: Align(
            alignment: Alignment.centerRight,
            child: Text('Note', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary)),
          ),
        ),
      ],
    );
  }
}

class _IntervalRowData {
  final String degree;
  final String intervalName;
  final String note;
  final int degreeIndex;

  const _IntervalRowData({required this.degree, required this.intervalName, required this.note, required this.degreeIndex});
}

class _IntervalRow extends StatelessWidget {
  final _IntervalRowData r;
  final IntervalColors intervalColors;

  const _IntervalRow({required this.r, required this.intervalColors});

  Color _colorForDegree(int i) {
    switch (i) {
      case 0:
        return intervalColors.root;
      case 2:
        return intervalColors.third;
      case 4:
        return intervalColors.fifth;
      case 6:
        return intervalColors.seventh;
      default:
        return intervalColors.extensionColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chipColor = _colorForDegree(r.degreeIndex);

    return Row(
      children: [
        SizedBox(
          width: 58,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: chipColor.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(color: chipColor.withValues(alpha: 0.55)),
              ),
              child: Text(r.degree, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w800)),
            ),
          ),
        ),
        Expanded(
          child: Text(
            r.intervalName,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(
          width: 88,
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              r.note,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}

class KeySignatureVisualsSection extends StatelessWidget {
  final String keyId;

  const KeySignatureVisualsSection({super.key, required this.keyId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final keyData = TheoryRepository.getKeyById(keyId);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.dividerColor),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final isNarrow = c.maxWidth < 520;
          final children = [
            _KeySignatureStaffCard(
              title: 'Treble',
              clef: _Clef.treble,
              sharps: keyData.sharps,
            ),
            _KeySignatureStaffCard(
              title: 'Bass',
              clef: _Clef.bass,
              sharps: keyData.sharps,
            ),
          ];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                keyData.sharps == 0 ? 'No sharps or flats in the key signature.' : 'Key signature: ${keyData.accidentalsCountString}',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary, height: 1.5),
              ),
              const SizedBox(height: 12),
              if (isNarrow)
                Column(children: [children[0], const SizedBox(height: 12), children[1]])
              else
                Row(
                  children: [
                    Expanded(child: children[0]),
                    const SizedBox(width: 12),
                    Expanded(child: children[1]),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

enum _Clef { treble, bass }

class _KeySignatureStaffCard extends StatelessWidget {
  final String title;
  final _Clef clef;
  final int sharps;

  const _KeySignatureStaffCard({required this.title, required this.clef, required this.sharps});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Slightly brighter staff lines in dark mode (they were too faint), while
    // keeping light mode more subtle.
    final staffLineColor = theme.colorScheme.onSurface.withValues(alpha: isDark ? 0.42 : 0.20);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.music_note_rounded, size: 18, color: theme.colorScheme.tertiary),
              const SizedBox(width: 8),
              Text(title, style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          AspectRatio(
            aspectRatio: 3.4,
            child: CustomPaint(
              painter: _KeySignatureStaffPainter(
                clef: clef,
                sharps: sharps,
                lineColor: staffLineColor,
                inkColor: theme.colorScheme.onSurface.withValues(alpha: 0.92),
                accentColor: theme.colorScheme.primary,
                staffLineWidth: isDark ? 1.25 : 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KeySignatureStaffPainter extends CustomPainter {
  final _Clef clef;
  final int sharps;
  final Color lineColor;
  final Color inkColor;
  final Color accentColor;
  final double staffLineWidth;

  const _KeySignatureStaffPainter({required this.clef, required this.sharps, required this.lineColor, required this.inkColor, required this.accentColor, required this.staffLineWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = staffLineWidth;
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = inkColor;

    final staffTop = size.height * 0.22;
    final staffHeight = size.height * 0.56;
    final lineGap = staffHeight / 4.0;
    final step = lineGap / 2.0;
    final leftPad = size.width * 0.06;

    // Staff lines
    paint.color = lineColor;
    for (int i = 0; i < 5; i++) {
      final y = staffTop + i * lineGap;
      canvas.drawLine(Offset(leftPad, y), Offset(size.width - leftPad, y), paint);
    }

    // Clef
    // Clefs are rendered via Unicode musical symbol glyphs.
    // Note: Font support varies by platform; for bass clef we keep a
    // fallback drawer that produces correct dot placement if the glyph
    // isn't available.
    final anchorLineIndexFromTop = clef == _Clef.treble ? 3 : 1; // 0..4
    final anchorY = staffTop + anchorLineIndexFromTop * lineGap;
    // Give clefs a little negative left bleed so they don't crowd accidentals.
    final clefX = clef == _Clef.treble ? leftPad - lineGap * 0.58 : leftPad - lineGap * 0.30;
    if (clef == _Clef.treble) {
      _drawTextAnchored(
        canvas,
        text: '𝄞',
        x: clefX,
        anchorY: anchorY,
        // Slightly larger so the top extends above the staff as expected.
        fontSize: lineGap * 3.05,
        color: inkColor,
        weight: FontWeight.w600,
        // Nudge up a touch so the swirl anchors to the G line while the glyph
        // extends above the top staff line.
        yBias: lineGap * 0.02,
      );
    } else {
      _drawBassClef(canvas, x: clefX + lineGap * 0.26, fLineY: anchorY, lineGap: lineGap, color: inkColor);
    }

    // Key signature accidentals
    final count = sharps.abs().clamp(0, 7);
    if (count == 0) return;

    final isSharps = sharps > 0;
    final glyph = isSharps ? '♯' : '♭';
    final steps = _accidentalSteps(clef: clef, isSharps: isSharps);

    // Positioning: start after clef.
    // Bass clef glyphs tend to have a wider bounding box, so give them extra
    // horizontal clearance so sharps/flats don't collide with the dots.
    double x = leftPad + (clef == _Clef.bass ? lineGap * 2.65 : lineGap * 2.05);
    for (int i = 0; i < count; i++) {
      final s = steps[i];
      // Staff step: 0=bottom line, 8=top line. Allow a little outside.
      final y = staffTop + (8 - s) * step;
      _drawText(
        canvas,
        text: glyph,
        position: Offset(x, y - lineGap * 0.55),
        fontSize: lineGap * 1.35,
        color: accentColor.withValues(alpha: 0.92),
        weight: FontWeight.w700,
      );
      x += lineGap * 0.78;
    }

    // A subtle barline at the end (visual anchor)
    paint.color = lineColor.withValues(alpha: 0.9);
    canvas.drawLine(Offset(size.width - leftPad * 1.2, staffTop), Offset(size.width - leftPad * 1.2, staffTop + staffHeight), paint);
    canvas.drawCircle(Offset(size.width - leftPad * 0.9, staffTop + staffHeight * 0.5), lineGap * 0.08, fill);
  }

  List<int> _accidentalSteps({required _Clef clef, required bool isSharps}) {
    // Steps are in half-spaces relative to staff: 0 bottom line, 8 top line.
    if (clef == _Clef.treble) {
      return isSharps
          ? const [8, 5, 9, 6, 3, 7, 4] // F C G D A E B
          : const [4, 7, 3, 6, 2, 5, 1]; // B E A D G C F
    }
    return isSharps
        ? const [6, 3, 7, 4, 1, 5, 2]
        : const [2, 5, 1, 4, 0, 3, -1];
  }

  void _drawText(
    Canvas canvas, {
    required String text,
    required Offset position,
    required double fontSize,
    required Color color,
    required FontWeight weight,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: fontSize, color: color, fontWeight: weight, height: 1),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    tp.paint(canvas, position);
  }

  void _drawTextAnchored(
    Canvas canvas, {
    required String text,
    required double x,
    required double anchorY,
    required double fontSize,
    required Color color,
    required FontWeight weight,
    double yBias = 0,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: fontSize, color: color, fontWeight: weight, height: 1),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final y = anchorY - tp.height / 2 + yBias;
    tp.paint(canvas, Offset(x, y));
  }

  void _drawBassClef(
    Canvas canvas, {
    required double x,
    required double fLineY,
    required double lineGap,
    required Color color,
  }) {
    // Prefer a real bass-clef glyph.
    // U+1D122 MUSICAL SYMBOL F CLEF: "𝄢"
    // We anchor it to the F line. Because glyph bounding boxes vary per font,
    // we apply a small bias that empirically centers the dot pair around the
    // F line on common fallback fonts.
    final glyphPainter = TextPainter(
      text: TextSpan(
        text: '𝄢',
        style: TextStyle(fontSize: lineGap * 2.92, color: color, fontWeight: FontWeight.w600, height: 1),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();

    // Heuristic: if the glyph isn't supported, width can be suspiciously tiny
    // (or it can render as a tofu box). In that case, fall back to a custom
    // drawer so the reference remains usable.
    final looksUnsupported = glyphPainter.width < lineGap * 0.60;
    if (!looksUnsupported) {
      // IMPORTANT: The F line is the 2nd line from the top on bass staff.
      // On common fallback fonts, the glyph's internal baseline/box tends to
      // sit ~one staff line too high relative to the dot pair.
      // Shift down by exactly one staff line (lineGap).
      final y = fLineY - glyphPainter.height / 2 + lineGap * 1.05;
      glyphPainter.paint(canvas, Offset(x, y));
      return;
    }

    _drawBassClefFallback(canvas, x: x, fLineY: fLineY, lineGap: lineGap, color: color);
  }

  void _drawBassClefFallback(
    Canvas canvas, {
    required double x,
    required double fLineY,
    required double lineGap,
    required Color color,
  }) {
    // Fallback bass clef (font-independent) with mathematically correct dot
    // placement: the F line is centered between the two dots.
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..color = color
      ..strokeWidth = lineGap * 0.36
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = color;

    final h = lineGap * 3.10;
    final w = lineGap * 1.28;
    final top = fLineY - lineGap * 1.60;
    final bottom = fLineY + lineGap * 1.30;
    final p = Path()
      ..moveTo(x + w * 0.62, top)
      ..cubicTo(x + w * 0.10, top + h * 0.25, x + w * 0.05, bottom - h * 0.10, x + w * 0.56, bottom)
      ..cubicTo(x + w * 0.86, bottom + h * 0.10, x + w * 0.92, bottom + h * 0.28, x + w * 0.56, bottom + h * 0.36);
    canvas.drawPath(p, stroke);

    final headCenter = Offset(x + w * 0.56, fLineY + lineGap * 0.08);
    canvas.drawCircle(headCenter, lineGap * 0.25, fill);

    final dotX = x + w * 1.38;
    final dotDy = lineGap * 0.50;
    final dotR = lineGap * 0.12;
    canvas.drawCircle(Offset(dotX, fLineY - dotDy), dotR, fill);
    canvas.drawCircle(Offset(dotX, fLineY + dotDy), dotR, fill);
  }

  @override
  bool shouldRepaint(covariant _KeySignatureStaffPainter oldDelegate) {
    return oldDelegate.clef != clef ||
        oldDelegate.sharps != sharps ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.inkColor != inkColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.staffLineWidth != staffLineWidth;
  }
}

// (Removed) Nashville primer + degrees header section.
// The page now starts directly with playable scale-degree cards.

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final bool showAction;
  final VoidCallback? onActionTap;

  const _SectionHeader({required this.title, this.action, this.showAction = false, this.onActionTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          if (showAction && action != null)
            InkWell(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              onTap: onActionTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  action!,
                  style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class DiatonicChordsSheet extends StatelessWidget {
  final String keyId;
  final List<Chord> chords;
  final ValueChanged<Chord> onSelect;

  const DiatonicChordsSheet({super.key, required this.keyId, required this.chords, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + MediaQuery.of(context).padding.bottom),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('All Diatonic Chords', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface)),
                IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.close_rounded))
              ],
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              // Increase tile height slightly to avoid tight vertical constraints that
              // caused a minor (2px) RenderFlex overflow on some devices/text scales.
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisExtent: 104,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: chords.length,
              itemBuilder: (context, index) {
                final chord = chords[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  onTap: () => onSelect(chord),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(chord.roman, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary)),
                        const SizedBox(height: 6),
                        Text(chord.name, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(chord.type, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.tertiary)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ChordDetailSheet extends StatefulWidget {
  final String keyId;
  final Chord chord;

  const ChordDetailSheet({super.key, required this.keyId, required this.chord});

  @override
  State<ChordDetailSheet> createState() => _ChordDetailSheetState();
}

class _ChordDetailSheetState extends State<ChordDetailSheet> {
  String _view = 'piano'; // 'piano' | 'guitar'

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tonicPc = TheoryUtils.pcForKeyId(widget.keyId);
    final degree = TheoryUtils.romanToDegree(widget.chord.roman);
    final scalePcs = TheoryUtils.majorScalePcs(tonicPc);
    final rootPc = scalePcs[degree % scalePcs.length];
    final formula = TheoryUtils.chordFormulas[widget.chord.type] ?? TheoryUtils.chordFormulas['Major']!;
    final pcs = formula.map((o) => (rootPc + o) % 12).toSet();
    // Use key-aware enharmonic spelling for chord tones in musical order
    final spelledChordTones = TheoryUtils.spelledChordTonesInKey(
      keyId: widget.keyId,
      chordType: widget.chord.type,
      degreeIndex: degree,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + MediaQuery.of(context).padding.bottom),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.music_note_rounded, color: theme.colorScheme.tertiary, size: 20),
                const SizedBox(width: 8),
                Text('${widget.chord.name} • ${widget.chord.type}', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface)),
                const Spacer(),
                IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.close_rounded))
              ],
            ),
            const SizedBox(height: 8),
            Text(
              // If a 7th exists in formula, it will be included; label still "Triad" for brevity
              'Triad: ${spelledChordTones.join(' – ')}',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary),
            ),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'piano', label: Text('Piano'), icon: Icon(Icons.piano_rounded)),
                ButtonSegment(value: 'guitar', label: Text('Guitar'), icon: Icon(Icons.sensors_rounded)),
              ],
              selected: {_view},
              onSelectionChanged: (s) => setState(()=> _view = s.first),
              showSelectedIcon: false,
            ),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
              child: _view == 'piano'
                ? Padding(
                    key: const ValueKey('piano'),
                    padding: const EdgeInsets.only(bottom: 12),
                    child: PianoKeyboard(selectedPcs: pcs, rootPc: rootPc, showLabels: true, octaves: 2),
                  )
                : Padding(
                    key: const ValueKey('guitar'),
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GuitarFretboard(startFret: 3, selectedPcs: pcs, rootPc: rootPc, showLabels: true),
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _LegendChip(label: 'Root', color: theme.extension<IntervalColors>()!.root),
                _LegendChip(label: '3rd', color: theme.extension<IntervalColors>()!.third),
                _LegendChip(label: '5th', color: theme.extension<IntervalColors>()!.fifth),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  final String label;
  final Color color;
  const _LegendChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onPrimary)),
    );
  }
}

/// Reusable tile for a scale degree row with speaker playback.
/// Routes all audio through AudioEngineService and provides brief visual feedback.
class ScaleDegreeTile extends StatefulWidget {
  final int degree;
  final String note;
  final String? frequencyLabel; // e.g., "261.63 Hz" (optional)
  final String? quality; // e.g., Major / Minor / Dim
  final String? notation; // e.g., I / ii / 2m / 7°

  const ScaleDegreeTile({super.key, required this.degree, required this.note, this.frequencyLabel, this.quality, this.notation});

  @override
  State<ScaleDegreeTile> createState() => _ScaleDegreeTileState();
}

class _ScaleDegreeTileState extends State<ScaleDegreeTile> with SingleTickerProviderStateMixin {
  bool _highlight = false;
  bool _pulsing = false;
  final _audio = AudioEngineService();

  Future<void> _onPlayTap() async {
    // Visual pulse
    setState(() {
      _highlight = true;
      _pulsing = true;
    });
    Future.delayed(const Duration(milliseconds: 260), () {
      if (mounted) setState(() => _highlight = false);
    });
    Future.delayed(const Duration(milliseconds: 240), () {
      if (mounted) setState(() => _pulsing = false);
    });

    try {
      await _audio.stop();
      final label = widget.frequencyLabel ?? '';
      final hz = _parseHz(label);
      if (hz != null && hz > 0) {
        await _audio.playFrequency(hz);
      } else {
        // Fallback to default display octave when frequency not available
        await _audio.playNote(widget.note, 4);
      }

      final err = _audio.consumeLastError();
      if (err != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Audio playback failed.')));
      }
    } catch (e) {
      debugPrint('ScaleDegreeTile playback error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Audio playback failed.')));
      }
    }
  }

  double? _parseHz(String label) {
    // Extract the first number (supports integers or decimals) from strings like "261.63 Hz"
    final m = RegExp(r'([0-9]+(?:\.[0-9]+)?)').firstMatch(label);
    if (m == null) return null;
    return double.tryParse(m.group(1)!);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = theme.cardTheme.color;
    final tint = theme.colorScheme.primary.withValues(alpha: 0.06);
    // Build subtext as "Quality • Frequency"
    String? subText;
    final q = widget.quality;
    final f = widget.frequencyLabel;
    if (q != null && q.isNotEmpty && f != null && f.isNotEmpty) {
      subText = '$q • $f';
    } else if (q != null && q.isNotEmpty) {
      subText = q;
    } else if (f != null && f.isNotEmpty) {
      subText = f;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _highlight ? Color.alphaBlend(tint, baseColor ?? Colors.transparent) : baseColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, shape: BoxShape.circle),
            child: Text(
              '${widget.degree}',
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.note, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
                if (subText != null)
                  Text(subText, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary)),
                if (widget.notation != null && widget.notation!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(widget.notation!, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
          ),
          AnimatedScale(
            duration: const Duration(milliseconds: 180),
            scale: _pulsing ? 1.12 : 1.0,
            curve: Curves.easeOut,
            child: IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: _onPlayTap,
              icon: Icon(Icons.volume_up_rounded, color: theme.colorScheme.secondary, size: 22),
              tooltip: 'Play note',
            ),
          ),
        ],
      ),
    );
  }
}
