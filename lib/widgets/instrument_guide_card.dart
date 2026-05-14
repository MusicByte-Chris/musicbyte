import 'package:flutter/material.dart';
import 'package:musicbyteai/models/instrument_guide.dart';
import 'package:musicbyteai/theme.dart';

/// Collapsible card presenting an InstrumentGuide with structured sections.
class InstrumentGuideCard extends StatefulWidget {
  final InstrumentGuide guide;
  const InstrumentGuideCard({super.key, required this.guide});

  @override
  State<InstrumentGuideCard> createState() => _InstrumentGuideCardState();
}

class _InstrumentGuideCardState extends State<InstrumentGuideCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(Icons.library_music_rounded, color: theme.colorScheme.tertiary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.guide.instrumentName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    color: theme.colorScheme.secondary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) Divider(height: 1, color: theme.dividerColor),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Section(label: 'Fundamental Range', value: widget.guide.fundamentals),
                  _Section(label: 'Key Harmonics', value: widget.guide.harmonics),
                  _Section(label: 'Problem Areas', value: widget.guide.problems),
                  _Section(label: 'EQ Sweet Spots', value: widget.guide.eqNotes),
                  _Section(label: 'HPF/LPF Starting Point', value: _extractHpfLpf(widget.guide.eqNotes)),
                  _Section(label: 'Compression Guide', value: widget.guide.compNotes),
                  _Section(label: 'Tracking Tips', value: widget.guide.tracking),
                  _Section(label: 'Mic Suggestions', value: widget.guide.micNotes),
                  _Section(label: 'Mixing Notes', value: widget.guide.mixNotes, last: true),
                ].where((w) => (w as _Section).hasContent).toList(),
              ),
            ),
        ],
      ),
    );
  }

  // Naive HPF/LPF extraction: returns first sentence containing 'HPF' or 'LPF' from eqNotes.
  String _extractHpfLpf(String eqNotes) {
    final parts = eqNotes.split('.');
    final hit = parts.firstWhere(
      (p) => p.toLowerCase().contains('hpf') || p.toLowerCase().contains('lpf'),
      orElse: () => '',
    ).trim();
    return hit.isEmpty ? '-' : (hit.endsWith('.') ? hit : '$hit.');
  }
}

class _Section extends StatelessWidget {
  final String label;
  final String value;
  final bool last;
  const _Section({required this.label, required this.value, this.last = false});

  bool get hasContent => value.trim().isNotEmpty && value.trim() != '-';

  @override
  Widget build(BuildContext context) {
    if (!hasContent) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary)),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface),
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
          if (!last) ...[
            const SizedBox(height: 12),
            Divider(height: 1, color: theme.dividerColor),
          ],
        ],
      ),
    );
  }
}
