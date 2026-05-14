import 'package:flutter/material.dart';
import 'package:musicbyteai/theme.dart';

enum ViewerChordType { triad, maj7, dom7 }

/// Modern, compact selector used by the Chord Viewer to control:
/// - chord quality family (Triad / Maj7 / Dom7)
/// - inversion (Root / 1st / 2nd / 3rd)
///
/// Uses chip-style segmented controls (not SegmentedButton) to avoid
/// Flutter web selection edge-cases and to match the app's aesthetic.
class ChordInversionSelector extends StatelessWidget {
  final ViewerChordType chordType;
  final ValueChanged<ViewerChordType> onChordTypeChanged;
  final int inversion; // 0..3
  final ValueChanged<int> onInversionChanged;

  const ChordInversionSelector({super.key, required this.chordType, required this.onChordTypeChanged, required this.inversion, required this.onInversionChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxInv = chordType == ViewerChordType.triad ? 2 : 3;
    final effectiveInv = inversion.clamp(0, maxInv);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _GroupLabel(icon: Icons.tune_rounded, label: 'Chord Type'),
          _ChipSegmentRow(
            options: const [
              _ChipOption(value: ViewerChordType.triad, label: 'Triad'),
              _ChipOption(value: ViewerChordType.maj7, label: 'Maj7'),
              _ChipOption(value: ViewerChordType.dom7, label: 'Dom7'),
            ],
            selected: chordType,
            onSelected: onChordTypeChanged,
          ),
          const SizedBox(width: 8),
          _GroupLabel(icon: Icons.swap_vert_rounded, label: 'Inversion'),
          _ChipSegmentRow<int>(
            options: [
              const _ChipOption(value: 0, label: 'Root'),
              const _ChipOption(value: 1, label: '1st'),
              const _ChipOption(value: 2, label: '2nd'),
              _ChipOption(value: 3, label: '3rd', enabled: maxInv == 3),
            ],
            selected: effectiveInv,
            onSelected: (v) {
              if (v == 3 && maxInv != 3) return;
              onInversionChanged(v);
            },
          ),
        ],
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  const _GroupLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.secondary),
        const SizedBox(width: 6),
        Text(label, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _ChipOption<T> {
  final T value;
  final String label;
  final bool enabled;
  const _ChipOption({required this.value, required this.label, this.enabled = true});
}

class _ChipSegmentRow<T> extends StatelessWidget {
  final List<_ChipOption<T>> options;
  final T selected;
  final ValueChanged<T> onSelected;
  const _ChipSegmentRow({required this.options, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final opt in options)
          _ChipSegment(
            label: opt.label,
            selected: opt.value == selected,
            enabled: opt.enabled,
            onTap: () => onSelected(opt.value),
          )
      ],
    );
  }
}

class _ChipSegment extends StatelessWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;
  const _ChipSegment({required this.label, required this.selected, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = selected ? theme.colorScheme.surface : theme.colorScheme.onSurface;
    final bg = selected ? theme.colorScheme.tertiary : theme.scaffoldBackgroundColor;
    final border = selected ? Colors.transparent : theme.dividerColor;
    final opacity = enabled ? 1.0 : 0.45;

    return Opacity(
      opacity: opacity,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999), border: Border.all(color: border)),
          child: Text(label, style: theme.textTheme.labelMedium?.copyWith(color: fg, fontWeight: FontWeight.w900)),
        ),
      ),
    );
  }
}
