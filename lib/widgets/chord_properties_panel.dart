import 'package:flutter/material.dart';
import 'package:musicbyteai/models/chord_builder.dart';
import 'package:musicbyteai/theme.dart';

/// “Chord Properties” selector inspired by the reference UI:
/// - size (Triad/7/9/11/13)
/// - seventh flavor (Auto/Maj7/Dom7/Min7)
/// - inversion
/// - option toggles (sus/add/alterations/omissions)
class ChordPropertiesPanel extends StatefulWidget {
  final String headerTitle;
  final String subtitle;
  final ViewerChordSpec spec;
  final ValueChanged<ViewerChordSpec> onChanged;
  final VoidCallback onReset;

  /// When true, the panel can be collapsed to reclaim vertical space.
  /// Useful on mobile when the user wants to quickly focus on the fretboard/piano.
  final bool collapsible;

  /// Starting expanded state when [collapsible] is true.
  final bool initiallyExpanded;

  /// Uses tighter spacing + smaller chips for wide/desktop layouts.
  final bool dense;

  const ChordPropertiesPanel({
    super.key,
    required this.headerTitle,
    required this.subtitle,
    required this.spec,
    required this.onChanged,
    required this.onReset,
    this.collapsible = false,
    this.initiallyExpanded = true,
    this.dense = false,
  });

  @override
  State<ChordPropertiesPanel> createState() => _ChordPropertiesPanelState();
}

class _ChordPropertiesPanelState extends State<ChordPropertiesPanel> with SingleTickerProviderStateMixin {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  void didUpdateWidget(covariant ChordPropertiesPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.collapsible != widget.collapsible) {
      _expanded = widget.collapsible ? widget.initiallyExpanded : true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dense = widget.dense;
    final pad = dense ? const EdgeInsets.all(12) : const EdgeInsets.all(AppSpacing.md);

    return Container(
      padding: pad,
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
                  'CHORD PROPERTIES',
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 2.6,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (widget.collapsible)
                IconButton(
                  tooltip: _expanded ? 'Collapse' : 'Expand',
                  onPressed: () => setState(() => _expanded = !_expanded),
                  icon: AnimatedRotation(
                    turns: _expanded ? 0.0 : 0.5,
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOut,
                    child: Icon(Icons.expand_less_rounded, color: theme.colorScheme.secondary),
                  ),
                ),
              TextButton(
                onPressed: widget.onReset,
                child: Text(
                  'RESET',
                  style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.8, color: theme.colorScheme.secondary, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(widget.headerTitle, style: theme.textTheme.displaySmall?.copyWith(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(widget.subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.72))),

          if (widget.collapsible && !_expanded) ...[
            const SizedBox(height: 12),
            _SpecSummaryChips(spec: widget.spec),
          ] else ...[
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, c) {
                final wide = c.maxWidth >= 560;

                final typeBlock = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel(icon: Icons.grid_view_rounded, label: 'TYPE'),
                    const SizedBox(height: 10),
                    _SegmentWrap<ChordSize>(
                      dense: dense,
                      options: const [
                        _SegOpt(value: ChordSize.triad, label: 'TRIAD'),
                        _SegOpt(value: ChordSize.seventh, label: '7'),
                        _SegOpt(value: ChordSize.ninth, label: '9'),
                        _SegOpt(value: ChordSize.eleventh, label: '11'),
                        _SegOpt(value: ChordSize.thirteenth, label: '13'),
                      ],
                      selected: widget.spec.size,
                      onSelected: (v) => widget.onChanged(widget.spec.copyWith(size: v, inversion: 0)),
                    ),
                  ],
                );

                final seventhBlock = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel(icon: Icons.waves_rounded, label: '7TH'),
                    const SizedBox(height: 10),
                    Opacity(
                      opacity: widget.spec.size == ChordSize.triad ? 0.45 : 1,
                      child: IgnorePointer(
                        ignoring: widget.spec.size == ChordSize.triad,
                        child: _SegmentWrap<SeventhFlavor>(
                          dense: dense,
                          options: const [
                            _SegOpt(value: SeventhFlavor.auto, label: 'AUTO'),
                            _SegOpt(value: SeventhFlavor.maj7, label: 'MAJ7'),
                            _SegOpt(value: SeventhFlavor.dom7, label: 'DOM7'),
                            _SegOpt(value: SeventhFlavor.min7, label: 'MIN7'),
                          ],
                          selected: widget.spec.seventh,
                          onSelected: (v) => widget.onChanged(widget.spec.copyWith(seventh: v, inversion: 0)),
                        ),
                      ),
                    ),
                  ],
                );

                final inversionBlock = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel(icon: Icons.swap_vert_rounded, label: 'INVERSION'),
                    const SizedBox(height: 10),
                    _SegmentWrap<int>(
                      dense: dense,
                      options: const [
                        _SegOpt(value: 0, label: 'NONE'),
                        _SegOpt(value: 1, label: '1ST'),
                        _SegOpt(value: 2, label: '2ND'),
                        _SegOpt(value: 3, label: '3RD'),
                      ],
                      selected: widget.spec.inversion,
                      onSelected: (v) => widget.onChanged(widget.spec.copyWith(inversion: v)),
                    ),
                  ],
                );

                if (!wide) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      typeBlock,
                      const SizedBox(height: 16),
                      seventhBlock,
                      const SizedBox(height: 16),
                      inversionBlock,
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: typeBlock),
                        const SizedBox(width: 14),
                        Expanded(child: seventhBlock),
                      ],
                    ),
                    const SizedBox(height: 14),
                    inversionBlock,
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            _SectionLabel(icon: Icons.tune_rounded, label: 'OPTIONS'),
            const SizedBox(height: 10),
            _ToggleGrid(spec: widget.spec, onChanged: widget.onChanged, dense: dense),
          ],
        ],
      ),
    );
  }
}

class _SpecSummaryChips extends StatelessWidget {
  final ViewerChordSpec spec;
  const _SpecSummaryChips({required this.spec});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String sizeLabel(ChordSize s) => switch (s) {
          ChordSize.triad => 'Triad',
          ChordSize.seventh => '7',
          ChordSize.ninth => '9',
          ChordSize.eleventh => '11',
          ChordSize.thirteenth => '13',
        };
    String seventhLabel(SeventhFlavor s) => switch (s) {
          SeventhFlavor.auto => 'Auto 7th',
          SeventhFlavor.maj7 => 'Maj7',
          SeventhFlavor.dom7 => 'Dom7',
          SeventhFlavor.min7 => 'Min7',
        };
    String invLabel(int inv) => inv == 0 ? 'Root' : 'Inv $inv';

    final chips = <String>[sizeLabel(spec.size), if (spec.size != ChordSize.triad) seventhLabel(spec.seventh), invLabel(spec.inversion), if (spec.options.isNotEmpty) '+${spec.options.length} opts'];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final t in chips)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Text(t, style: theme.textTheme.labelMedium?.copyWith(letterSpacing: 0.8, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface)),
          ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.secondary),
        const SizedBox(width: 8),
        Text(label, style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 2.2, color: theme.colorScheme.onSurface.withValues(alpha: 0.72), fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _SegOpt<T> {
  final T value;
  final String label;
  const _SegOpt({required this.value, required this.label});
}

class _SegmentWrap<T> extends StatelessWidget {
  final List<_SegOpt<T>> options;
  final T selected;
  final ValueChanged<T> onSelected;
  final bool dense;
  const _SegmentWrap({required this.options, required this.selected, required this.onSelected, required this.dense});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final opt in options)
          _PillSeg(
            label: opt.label,
            selected: opt.value == selected,
            onTap: () => onSelected(opt.value),
            dense: dense,
          ),
      ],
    );
  }
}

class _PillSeg extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool dense;
  const _PillSeg({required this.label, required this.selected, required this.onTap, required this.dense});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = selected ? theme.colorScheme.surface : theme.colorScheme.onSurface;
    final bg = selected ? theme.colorScheme.tertiary : theme.scaffoldBackgroundColor;
    final border = selected ? Colors.transparent : theme.dividerColor;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(horizontal: dense ? 14 : 16, vertical: dense ? 9 : 11),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999), border: Border.all(color: border)),
        child: Text(label, style: theme.textTheme.labelMedium?.copyWith(color: fg, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
      ),
    );
  }
}

class _ToggleGrid extends StatelessWidget {
  final ViewerChordSpec spec;
  final ValueChanged<ViewerChordSpec> onChanged;
  final bool dense;
  const _ToggleGrid({required this.spec, required this.onChanged, required this.dense});

  static const _items = <({ChordOption opt, String label})>[
    (opt: ChordOption.sus2, label: 'SUS2'),
    (opt: ChordOption.add9, label: 'ADD9'),
    (opt: ChordOption.flat5, label: 'b5'),
    (opt: ChordOption.sus4, label: 'SUS4'),
    (opt: ChordOption.add11, label: 'ADD11'),
    (opt: ChordOption.sharp5, label: '#5'),
    (opt: ChordOption.tritoneSub, label: 'Δ-SUB'),
    (opt: ChordOption.add13, label: 'ADD13'),
    (opt: ChordOption.flat9, label: 'b9'),
    (opt: ChordOption.no3, label: 'NO3'),
    (opt: ChordOption.sharp9, label: '#9'),
    (opt: ChordOption.no5, label: 'NO5'),
    (opt: ChordOption.sharp11, label: '#11'),
    (opt: ChordOption.flat13, label: 'b13'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final it in _items)
          _ToggleChip(
            label: it.label,
            selected: spec.options.contains(it.opt),
            dense: dense,
            onTap: () {
              final next = Set<ChordOption>.from(spec.options);
              if (next.contains(it.opt)) {
                next.remove(it.opt);
              } else {
                // SUS2 and SUS4 are mutually exclusive.
                if (it.opt == ChordOption.sus2) next.remove(ChordOption.sus4);
                if (it.opt == ChordOption.sus4) next.remove(ChordOption.sus2);
                // b5 and #5 are mutually exclusive.
                if (it.opt == ChordOption.flat5) next.remove(ChordOption.sharp5);
                if (it.opt == ChordOption.sharp5) next.remove(ChordOption.flat5);
                // b9 and #9 are mutually exclusive.
                if (it.opt == ChordOption.flat9) next.remove(ChordOption.sharp9);
                if (it.opt == ChordOption.sharp9) next.remove(ChordOption.flat9);
                next.add(it.opt);
              }
              onChanged(spec.copyWith(options: next));
            },
          ),
      ],
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool dense;
  const _ToggleChip({required this.label, required this.selected, required this.onTap, required this.dense});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = selected ? theme.colorScheme.surface : theme.colorScheme.onSurface;
    final bg = selected ? theme.colorScheme.tertiary : theme.scaffoldBackgroundColor;
    final border = selected ? Colors.transparent : theme.dividerColor;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(horizontal: dense ? 12 : 14, vertical: dense ? 9 : 11),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: border)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: theme.dividerColor),
                color: selected ? theme.colorScheme.surface.withValues(alpha: 0.16) : Colors.transparent,
              ),
              child: selected
                  ? Center(child: Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: theme.colorScheme.surface)))
                  : null,
            ),
            const SizedBox(width: 10),
            Text(label, style: theme.textTheme.labelMedium?.copyWith(color: fg, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
          ],
        ),
      ),
    );
  }
}
