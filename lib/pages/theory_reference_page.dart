import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:musicbyteai/theme.dart';
import 'package:musicbyteai/widgets/responsive_centered.dart';

class TheoryReferencePage extends StatelessWidget {
  const TheoryReferencePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        title: const Text('Music Theory Reference'),
      ),
      body: ResponsiveCentered(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          children: const [
            _PageIntroCard(),
            SizedBox(height: AppSpacing.md),
            _ScaleFormulasCard(),
            SizedBox(height: AppSpacing.md),
            _OrderOfSharpsFlatsCard(),
            SizedBox(height: AppSpacing.md),
            _AccidentalsCard(),
            SizedBox(height: AppSpacing.md),
            _ChordSymbolsCard(),
            SizedBox(height: AppSpacing.md),
            _InversionsCard(),
            SizedBox(height: AppSpacing.md),
            _RomanVsNashvilleCard(),
            SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _PageIntroCard extends StatelessWidget {
  const _PageIntroCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _SectionSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Fast lookups (offline)', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Quick reference for scales, key signatures, accidentals, chord symbols, and numbering systems.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _ScaleFormulasCard extends StatelessWidget {
  const _ScaleFormulasCard();

  static const List<_ScaleFormula> _scales = [
    _ScaleFormula(name: 'Major (Ionian)', degrees: '1 2 3 4 5 6 7', steps: 'W–W–H–W–W–W–H'),
    _ScaleFormula(name: 'Natural Minor (Aeolian)', degrees: '1 2 ♭3 4 5 ♭6 ♭7', steps: 'W–H–W–W–H–W–W'),
    _ScaleFormula(name: 'Harmonic Minor', degrees: '1 2 ♭3 4 5 ♭6 7', steps: 'W–H–W–W–H–1½–H'),
    _ScaleFormula(name: 'Dorian', degrees: '1 2 ♭3 4 5 6 ♭7', steps: 'W–H–W–W–W–H–W'),
    _ScaleFormula(name: 'Mixolydian', degrees: '1 2 3 4 5 6 ♭7', steps: 'W–W–H–W–W–H–W'),
    _ScaleFormula(name: 'Pentatonic Major', degrees: '1 2 3 5 6', steps: 'W–W–1½–W–1½'),
    _ScaleFormula(name: 'Pentatonic Minor', degrees: '1 ♭3 4 5 ♭7', steps: '1½–W–W–1½–W'),
    _ScaleFormula(name: 'Blues (Minor)', degrees: '1 ♭3 4 ♭5 5 ♭7', steps: '1½–W–H–H–1½–W'),
    _ScaleFormula(name: 'Blues (Major)', degrees: '1 2 ♭3 3 5 6', steps: 'W–H–H–1½–W–1½'),
    _ScaleFormula(name: 'Diminished (Whole–Half)', degrees: '1 2 ♭3 4 ♭5 ♭6 6 7', steps: 'W–H–W–H–W–H–W–H'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _ExpandableSectionCard(
      title: 'Scale Formulas',
      subtitle: 'Scales currently supported in the app',
      leadingIcon: Icons.stairs_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'W = whole step (2 semitones), H = half step (1 semitone), 1½ = three semitones.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary, height: 1.45),
          ),
          const SizedBox(height: AppSpacing.md),
          ..._scales.map((s) => _FormulaRow(scale: s)),
        ],
      ),
    );
  }
}

class _FormulaRow extends StatelessWidget {
  final _ScaleFormula scale;
  const _FormulaRow({required this.scale});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(scale.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _MiniPill(label: scale.degrees, icon: Icons.tag_rounded),
              _MiniPill(label: scale.steps, icon: Icons.timeline_rounded),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  final String label;
  final IconData icon;
  const _MiniPill({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.tertiary),
          const SizedBox(width: AppSpacing.xs),
          Text(label, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurface, height: 1.25)),
        ],
      ),
    );
  }
}

class _OrderOfSharpsFlatsCard extends StatelessWidget {
  const _OrderOfSharpsFlatsCard();

  static const _sharps = ['F♯', 'C♯', 'G♯', 'D♯', 'A♯', 'E♯', 'B♯'];
  static const _flats = ['B♭', 'E♭', 'A♭', 'D♭', 'G♭', 'C♭', 'F♭'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget buildRow(String label, List<String> items, IconData icon) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: theme.colorScheme.tertiary),
                const SizedBox(width: AppSpacing.sm),
                Text(label, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: items.map((t) => _KeySigChip(text: t)).toList(),
            ),
          ],
        ),
      );
    }

    return _ExpandableSectionCard(
      title: 'Order of Sharps & Flats',
      subtitle: 'Key signature mnemonic list',
      leadingIcon: Icons.auto_fix_high_rounded,
      child: Column(
        children: [
          buildRow('Sharps (in order)', _sharps, Icons.trending_up_rounded),
          const SizedBox(height: AppSpacing.sm),
          buildRow('Flats (reverse order)', _flats, Icons.trending_down_rounded),
        ],
      ),
    );
  }
}

class _KeySigChip extends StatelessWidget {
  final String text;
  const _KeySigChip({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Text(text, style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
    );
  }
}

class _AccidentalsCard extends StatelessWidget {
  const _AccidentalsCard();

  static const List<_Accidental> _items = [
    _Accidental(symbol: '♯', name: 'Sharp', desc: 'Raise by 1 semitone'),
    _Accidental(symbol: '♭', name: 'Flat', desc: 'Lower by 1 semitone'),
    _Accidental(symbol: '♮', name: 'Natural', desc: 'Cancel sharps/flats'),
    _Accidental(symbol: '𝄪', name: 'Double Sharp', desc: 'Raise by 2 semitones'),
    _Accidental(symbol: '𝄫', name: 'Double Flat', desc: 'Lower by 2 semitones'),
  ];

  @override
  Widget build(BuildContext context) {
    return _ExpandableSectionCard(
      title: 'Types of Accidentals',
      subtitle: 'Symbols and names',
      leadingIcon: Icons.music_note_rounded,
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: _items
            .map((a) => _AccidentalTile(
                  symbol: a.symbol,
                  name: a.name,
                  desc: a.desc,
                ))
            .toList(),
      ),
    );
  }
}

class _AccidentalTile extends StatelessWidget {
  final String symbol;
  final String name;
  final String desc;
  const _AccidentalTile({required this.symbol, required this.name, required this.desc});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 220),
      child: _SectionSurface(
        surfaceColor: theme.scaffoldBackgroundColor,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Text(
                symbol,
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: theme.colorScheme.tertiary),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: AppSpacing.xs),
                  Text(desc, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary, height: 1.35)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChordSymbolsCard extends StatelessWidget {
  const _ChordSymbolsCard();

  static const List<_ChordSymbol> _items = [
    _ChordSymbol(symbol: 'C', meaning: 'Major triad', example: 'C–E–G'),
    _ChordSymbol(symbol: 'Cm', meaning: 'Minor triad', example: 'C–E♭–G'),
    _ChordSymbol(symbol: 'C5', meaning: 'Power chord (no 3rd)', example: 'C–G'),
    _ChordSymbol(symbol: 'Cdim / C°', meaning: 'Diminished triad', example: 'C–E♭–G♭'),
    _ChordSymbol(symbol: 'Caug / C+', meaning: 'Augmented triad', example: 'C–E–G♯'),
    _ChordSymbol(symbol: 'Csus2', meaning: 'Suspend 2 (replace 3rd with 2)', example: 'C–D–G'),
    _ChordSymbol(symbol: 'Csus4', meaning: 'Suspend 4 (replace 3rd with 4)', example: 'C–F–G'),
    _ChordSymbol(symbol: 'C7', meaning: 'Dominant 7th (major triad + ♭7)', example: 'C–E–G–B♭'),
    _ChordSymbol(symbol: 'Cmaj7', meaning: 'Major 7th (major triad + 7)', example: 'C–E–G–B'),
    _ChordSymbol(symbol: 'Cm7', meaning: 'Minor 7th (minor triad + ♭7)', example: 'C–E♭–G–B♭'),
    _ChordSymbol(symbol: 'Cm(maj7)', meaning: 'Minor-major 7th', example: 'C–E♭–G–B'),
    _ChordSymbol(symbol: 'Cø7', meaning: 'Half-diminished 7th', example: 'C–E♭–G♭–B♭'),
  ];

  @override
  Widget build(BuildContext context) {
    return _ExpandableSectionCard(
      title: 'Chord Symbol Notations',
      subtitle: 'Common lead-sheet symbols',
      leadingIcon: Icons.queue_music_rounded,
      child: Column(
        children: _items.map((c) => _ChordSymbolRow(item: c)).toList(),
      ),
    );
  }
}

class _ChordSymbolRow extends StatelessWidget {
  final _ChordSymbol item;
  const _ChordSymbolRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Text(item.symbol, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: theme.colorScheme.tertiary)),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.meaning, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: AppSpacing.xs),
                Text(item.example, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InversionsCard extends StatelessWidget {
  const _InversionsCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _ExpandableSectionCard(
      title: 'How Inversions Work',
      subtitle: 'Figured-bass shorthand + mnemonic',
      leadingIcon: Icons.swap_vert_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionSurface(
            surfaceColor: theme.scaffoldBackgroundColor,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mnemonic', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Triads: 6–6/4  •  7ths: 7–6/5–4/3–4/2  → “664-765-4342”',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Triads (C–E–G)', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: AppSpacing.sm),
          const _TwoColTable(
            rows: [
              _TwoColRow('Root position', 'C   (no figure)'),
              _TwoColRow('1st inversion', 'C6   (E in bass)'),
              _TwoColRow('2nd inversion', 'C6/4 (G in bass)'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text('7th chords (C–E–G–B♭)', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: AppSpacing.sm),
          const _TwoColTable(
            rows: [
              _TwoColRow('Root position', 'C7   (no figure)'),
              _TwoColRow('1st inversion', 'C6/5 (E in bass)'),
              _TwoColRow('2nd inversion', 'C4/3 (G in bass)'),
              _TwoColRow('3rd inversion', 'C4/2 (B♭ in bass)'),
            ],
          ),
        ],
      ),
    );
  }
}

class _RomanVsNashvilleCard extends StatelessWidget {
  const _RomanVsNashvilleCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _ExpandableSectionCard(
      title: 'Roman Numerals vs Nashville',
      subtitle: 'Same idea, different notation',
      leadingIcon: Icons.table_chart_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Example in C major (diatonic triads). Roman numerals often encode chord quality with case/°.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary, height: 1.45),
          ),
          const SizedBox(height: AppSpacing.md),
          const _ThreeColTable(
            header: _ThreeColRow('Scale degree', 'Roman', 'Nashville'),
            rows: [
              _ThreeColRow('1 (C)', 'I', '1'),
              _ThreeColRow('2 (D)', 'ii', '2m'),
              _ThreeColRow('3 (E)', 'iii', '3m'),
              _ThreeColRow('4 (F)', 'IV', '4'),
              _ThreeColRow('5 (G)', 'V', '5'),
              _ThreeColRow('6 (A)', 'vi', '6m'),
              _ThreeColRow('7 (B)', 'vii°', '7dim'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExpandableSectionCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData leadingIcon;
  final Widget child;

  const _ExpandableSectionCard({
    required this.title,
    required this.subtitle,
    required this.leadingIcon,
    required this.child,
  });

  @override
  State<_ExpandableSectionCard> createState() => _ExpandableSectionCardState();
}

class _ExpandableSectionCardState extends State<_ExpandableSectionCard> with SingleTickerProviderStateMixin {
  // Collapsed by default so users can see all section titles at once.
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _SectionSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Icon(widget.leadingIcon, color: theme.colorScheme.tertiary),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(widget.subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary)),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    child: Icon(Icons.expand_more_rounded, color: theme.colorScheme.secondary),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
              child: widget.child,
            ),
            crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
            sizeCurve: Curves.easeOut,
          ),
        ],
      ),
    );
  }
}

class _SectionSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? surfaceColor;
  const _SectionSurface({required this.child, this.padding = const EdgeInsets.all(0), this.surfaceColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: surfaceColor ?? theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.10),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _TwoColTable extends StatelessWidget {
  final List<_TwoColRow> rows;
  const _TwoColTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            _TwoColRowWidget(row: rows[i]),
            if (i != rows.length - 1) const SizedBox(height: AppSpacing.sm),
          ]
        ],
      ),
    );
  }
}

class _TwoColRowWidget extends StatelessWidget {
  final _TwoColRow row;
  const _TwoColRowWidget({required this.row});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Text(row.left, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          flex: 5,
          child: Text(row.right, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary, height: 1.3)),
        ),
      ],
    );
  }
}

class _ThreeColTable extends StatelessWidget {
  final _ThreeColRow header;
  final List<_ThreeColRow> rows;
  const _ThreeColTable({required this.header, required this.rows});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          _ThreeColRowWidget(row: header, isHeader: true),
          const SizedBox(height: AppSpacing.sm),
          for (int i = 0; i < rows.length; i++) ...[
            _ThreeColRowWidget(row: rows[i]),
            if (i != rows.length - 1) const SizedBox(height: AppSpacing.sm),
          ]
        ],
      ),
    );
  }
}

class _ThreeColRowWidget extends StatelessWidget {
  final _ThreeColRow row;
  final bool isHeader;
  const _ThreeColRowWidget({required this.row, this.isHeader = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = isHeader
        ? theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface)
        : theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary, height: 1.3);

    return Row(
      children: [
        Expanded(flex: 4, child: Text(row.col1, style: style)),
        const SizedBox(width: AppSpacing.md),
        Expanded(flex: 3, child: Text(row.col2, style: style)),
        const SizedBox(width: AppSpacing.md),
        Expanded(flex: 3, child: Text(row.col3, style: style)),
      ],
    );
  }
}

class _ScaleFormula {
  final String name;
  final String degrees;
  final String steps;
  const _ScaleFormula({required this.name, required this.degrees, required this.steps});
}

class _Accidental {
  final String symbol;
  final String name;
  final String desc;
  const _Accidental({required this.symbol, required this.name, required this.desc});
}

class _ChordSymbol {
  final String symbol;
  final String meaning;
  final String example;
  const _ChordSymbol({required this.symbol, required this.meaning, required this.example});
}

class _TwoColRow {
  final String left;
  final String right;
  const _TwoColRow(this.left, this.right);
}

class _ThreeColRow {
  final String col1;
  final String col2;
  final String col3;
  const _ThreeColRow(this.col1, this.col2, this.col3);
}
