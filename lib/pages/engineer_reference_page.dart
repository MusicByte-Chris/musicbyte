import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:musicbyteai/services/audio_engine_service.dart';
import 'package:musicbyteai/theme.dart';
import 'package:musicbyteai/data/engineering_repository.dart';
import 'package:musicbyteai/widgets/instrument_guide_card.dart';
import 'package:go_router/go_router.dart';
import 'package:musicbyteai/nav.dart';
import 'package:musicbyteai/widgets/responsive_centered.dart';
import 'package:musicbyteai/widgets/luxury_page_header.dart';

class EngineerReferencePage extends StatelessWidget {
  const EngineerReferencePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = ResponsiveCentered.isWide(context);

    final header = const LuxuryPageHeader(
      title: 'Engineer Reference',
      subtitle: 'Professional Audio Utility',
    );

    final proToolsCard = _RefCard(
      title: "Pro Tools Shortcuts",
      icon: Icons.keyboard_rounded,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Browse, search, and filter Pro Tools key commands by category, tags, and platform.',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface),
                softWrap: true,
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              style: ButtonStyle(
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
                ),
              ),
              onPressed: () => context.push(AppRoutes.proToolsShortcuts),
              icon: Icon(Icons.open_in_new_rounded, color: Theme.of(context).colorScheme.onPrimary, size: 18),
              label: Text('Open', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onPrimary)),
            ),
          ],
        ),
      ],
    );

    final eqCard = _RefCard(
      title: "EQ Cheat Sheet",
      icon: Icons.graphic_eq_rounded,
      children: [
        _EqRow(range: "20-60Hz", label: "Sub Bass", description: "Feel, rumble, power. Use high-pass to clear mud."),
        Divider(color: theme.dividerColor),
        _EqRow(range: "60-250Hz", label: "Bass / Thump", description: "Fundamental of kick and bass. 100-200Hz adds warmth."),
        Divider(color: theme.dividerColor),
        _EqRow(range: "250-500Hz", label: "Low Mids", description: "The 'Boxy' region. Often cut to improve clarity."),
        Divider(color: theme.dividerColor),
        _EqRow(range: "2k-4kHz", label: "Presence", description: "Clarity for vocals and guitars. Too much causes fatigue."),
        Divider(color: theme.dividerColor),
        _EqRow(range: "10k-20kHz", label: "Air", description: "Brilliance and shimmer. Subtle shelf boosts work best."),
      ],
    );

    final compressionCard = _RefCard(
      title: "Compression Guide",
      icon: Icons.compress_rounded,
      children: [
        _CompRow(instrument: "Vocals", ratio: "3:1", attack: "5-10ms", release: "100ms", knee: "Soft"),
        _CompRow(instrument: "Drums (Snare)", ratio: "4:1", attack: "1-5ms", release: "20ms", knee: "Hard"),
        _CompRow(instrument: "Bass Guitar", ratio: "4:1", attack: "20ms", release: "50ms", knee: "Hard"),
        _CompRow(instrument: "Mix Bus", ratio: "1.5:1", attack: "30ms", release: "Auto", knee: "Soft"),
      ],
    );

    final instrumentGuidesHeader = Text(
      "Instrument Guides",
      style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.secondary),
    );

    final instrumentGuidesList = _InstrumentGuidesList();

    final octaveCard = _RefCard(
      title: "Octave Table (A4=440)",
      icon: Icons.table_chart_rounded,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Octave", style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary)),
              Text("Frequency (Hz)", style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary)),
            ],
          ),
        ),
        Divider(color: theme.dividerColor),
        _FreqRow(label: "Sub Bass (C0-C1)", value: "16.35 - 32.70"),
        _FreqRow(label: "Mid Range (C4-C5)", value: "261.63 - 523.25"),
        _FreqRow(label: "High End (C7-C8)", value: "2093 - 4186"),
      ],
    );

    final tipCard = Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline, color: theme.colorScheme.onSurface, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              "Trust your ears over the charts. These are starting points, not rules.",
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: ResponsiveCentered(
          maxWidth: isWide ? 1200 : 980,
          child: isWide
              ? SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      header,
                      const SizedBox(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                proToolsCard,
                                const SizedBox(height: 16),
                                eqCard,
                                const SizedBox(height: 16),
                                compressionCard,
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                instrumentGuidesHeader,
                                const SizedBox(height: 8),
                                instrumentGuidesList,
                                const SizedBox(height: 16),
                                octaveCard,
                                const SizedBox(height: 16),
                                tipCard,
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  children: [
                    header,
                    const SizedBox(height: 32),
                    proToolsCard,
                    const SizedBox(height: 24),
                    eqCard,
                    const SizedBox(height: 24),
                    instrumentGuidesHeader,
                    const SizedBox(height: 8),
                    instrumentGuidesList,
                    const SizedBox(height: 24),
                    compressionCard,
                    const SizedBox(height: 24),
                    octaveCard,
                    const SizedBox(height: 24),
                    tipCard,
                    const SizedBox(height: 40),
                  ],
                ),
        ),
      ),
    );
  }
}

class _InstrumentGuidesList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: EngineeringRepository.guides
              .map((g) => InstrumentGuideCard(guide: g))
              .toList(),
        ),
      ),
    );
  }
}

class _RefCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _RefCard({required this.title, required this.icon, required this.children});

  @override
  State<_RefCard> createState() => _RefCardState();
}

class _RefCardState extends State<_RefCard> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.transparent,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(widget.icon, color: theme.colorScheme.tertiary, size: 22),
                      const SizedBox(width: 16),
                      Text(
                        widget.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: theme.colorScheme.secondary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: widget.children,
              ),
            ),
        ],
      ),
    );
  }
}

class _EqRow extends StatelessWidget {
  final String range;
  final String label;
  final String description;

  const _EqRow({required this.range, required this.label, required this.description});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 70,
            padding: const EdgeInsets.symmetric(vertical: 4),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Text(
              range,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.tertiary,
                fontWeight: FontWeight.bold,
                fontSize: 9, // Adjust for fitting
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InstrumentRange extends StatelessWidget {
  final String label;
  final Color color;
  final double widthFactor;
  final double offset;

  const _InstrumentRange({
    required this.label,
    required this.color,
    required this.widthFactor,
    required this.offset,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary)),
        const SizedBox(height: 8),
        Container(
          height: 12,
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Stack(
            children: [
              Positioned(
                left: offset,
                width: 300 * widthFactor, // Approximate width
                top: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompRow extends StatelessWidget {
  final String instrument;
  final String ratio;
  final String attack;
  final String release;
  final String knee;

  const _CompRow({
    required this.instrument,
    required this.ratio,
    required this.attack,
    required this.release,
    required this.knee,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(instrument, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(ratio, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _CompDetail("Attack", attack, theme),
              _CompDetail("Release", release, theme),
              _CompDetail("Knee", knee, theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _CompDetail(String label, String value, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary)),
        Text(value, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface)),
      ],
    );
  }
}

class _FreqRow extends StatelessWidget {
  final String label;
  final String value;

  const _FreqRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface)),
          Text(value, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.tertiary, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

/// Public widget: Interactive EQ Spectrum tool
/// - Scrollable frequency bar (20Hz–20kHz)
/// - Clickable segments reveal details + play center frequency
/// - Instrument highlight mode (Vocal, Kick, Guitar, Bass)
class InteractiveEqSpectrum extends StatefulWidget {
  /// Height of the spectrum bar (default 56)
  final double barHeight;
  /// Total virtual width used for horizontal scrolling (default 1200)
  final double baseWidth;
  /// Whether to show the instrument highlight chips (default true)
  final bool showInstrumentChips;

  const InteractiveEqSpectrum({super.key, this.barHeight = 56, this.baseWidth = 1200, this.showInstrumentChips = true});

  @override
  State<InteractiveEqSpectrum> createState() => _InteractiveEqSpectrumState();
}

class _InteractiveEqSpectrumState extends State<InteractiveEqSpectrum> with TickerProviderStateMixin {
  int? _selectedIndex;
  String? _highlightInstrument; // 'Vocal' | 'Kick' | 'Guitar' | 'Bass'

  static const double _minHz = 20;
  static const double _maxHz = 20000;

  late final List<_EqBand> _bands = [
    _EqBand(
      name: 'Sub', startHz: 20, endHz: 60,
      soundsLike: 'Rumble, weight, power you feel more than hear.',
      problems: 'Excessive energy causes boominess and headroom loss.',
      fix: 'High‑pass filter; gentle cut around 40–60Hz.',
      instruments: const ['Kick', 'Bass', 'Synth'],
    ),
    _EqBand(
      name: 'Bass', startHz: 60, endHz: 120,
      soundsLike: 'Punch and thump. Low-end body.',
      problems: 'Too much = woolly/muddy. Too little = thin.',
      fix: 'Narrow boost around 80–100Hz for punch; control with compression.',
      instruments: const ['Kick', 'Bass', 'Floor Tom'],
    ),
    _EqBand(
      name: 'Warmth', startHz: 120, endHz: 250,
      soundsLike: 'Warmth and fullness; body to many instruments.',
      problems: 'Can build up muddiness, boxiness in mixes.',
      fix: 'Wide cut 2–4dB if mix is cloudy; boost sparingly for thin sources.',
      instruments: const ['Vocal', 'Guitar', 'Piano', 'Bass'],
    ),
    _EqBand(
      name: 'Low‑Mid / Mud', startHz: 250, endHz: 500,
      soundsLike: 'Boxy, congested, honky if overemphasized.',
      problems: 'Masking of vocal/presence; lack of clarity.',
      fix: 'Sweep and cut offending resonances; gentle broad cuts often help.',
      instruments: const ['Vocal', 'Guitar', 'Piano', 'Snare'],
    ),
    _EqBand(
      name: 'Boxy / Nasal', startHz: 500, endHz: 1000,
      soundsLike: 'Telephone-like, hollow, nasal.',
      problems: 'Fatiguing; small speakers can overemphasize.',
      fix: 'Narrow cuts on resonant peaks; de-emphasize 600–900Hz as needed.',
      instruments: const ['Vocal', 'Guitar', 'Piano'],
    ),
    _EqBand(
      name: 'Clarity', startHz: 1000, endHz: 2000,
      soundsLike: 'Definition of speech intelligibility; articulation.',
      problems: 'Over-boost can make sources edgy.',
      fix: 'Moderate boost for presence; watch for harshness.',
      instruments: const ['Vocal', 'Guitar', 'Piano', 'Strings'],
    ),
    _EqBand(
      name: 'Presence', startHz: 2000, endHz: 5000,
      soundsLike: 'Attack, bite, forwardness; beater/click of kick.',
      problems: 'Excess leads to listening fatigue.',
      fix: 'Targeted boosts for definition; tame piercing resonances.',
      instruments: const ['Vocal', 'Guitar', 'Kick', 'Snare', 'Hi‑Hat'],
    ),
    _EqBand(
      name: 'Harsh / Sibilance', startHz: 5000, endHz: 8000,
      soundsLike: 'S, T sibilance; brittle cymbal edge.',
      problems: 'Harshness, ear fatigue.',
      fix: 'De-ess 5–8k; smooth cymbals; avoid over-boosting.',
      instruments: const ['Vocal', 'Cymbals', 'Guitar'],
    ),
    _EqBand(
      name: 'Brightness', startHz: 8000, endHz: 12000,
      soundsLike: 'Shine and sparkle; sheen on top end.',
      problems: 'Too much = brittle/ice-pick highs.',
      fix: 'Gentle shelf boosts; watch hiss accentuation.',
      instruments: const ['Vocal', 'Overheads', 'Acoustic Guitar'],
    ),
    _EqBand(
      name: 'Air', startHz: 12000, endHz: 20000,
      soundsLike: 'Space, openness, ultra-high shimmer.',
      problems: 'Noise/hiss if over-boosted.',
      fix: 'Very gentle high-shelf for polish.',
      instruments: const ['Vocal', 'Cymbals', 'Strings'],
    ),
  ];

  // Instrument highlight ranges
  final Map<String, List<_Range>> _instrumentRanges = const {
    'Vocal': [ _Range(120, 300), _Range(1000, 4000), _Range(5000, 8000) ],
    'Kick': [ _Range(40, 100), _Range(2000, 5000) ],
    'Guitar': [ _Range(80, 1200), _Range(2000, 5000) ],
    'Bass': [ _Range(40, 250), _Range(700, 1200) ],
  };

  double _log10(num x) => math.log(x) / math.ln10;
  double _fractionFor(double start, double end) {
    final total = _log10(_maxHz) - _log10(_minHz);
    final seg = _log10(end) - _log10(start);
    return (seg / total).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final eq = Theme.of(context).extension<EqColors>();
    final gradient = LinearGradient(colors: [
      (eq?.low ?? theme.colorScheme.tertiary),
      (eq?.high ?? theme.colorScheme.primary),
    ]);

    final totalWidth = widget.baseWidth;
    // Compute fixed widths for each segment based on log-spaced fractions to avoid using Expanded within a horizontal scroll view.
    final List<double> segmentFractions = _bands
        .map((b) => _fractionFor(b.startHz, b.endHz))
        .toList();
    final List<double> segmentWidths = segmentFractions.map((f) => totalWidth * f).toList();
    final children = <Widget>[];
    for (int i = 0; i < _bands.length; i++) {
      final b = _bands[i];
      final ranges = _highlightInstrument != null ? (_instrumentRanges[_highlightInstrument!] ?? const []) : const [];
      final isHighlighted = ranges.any((r) => r.intersects(_Range(b.startHz, b.endHz)));
      children.add(
        SizedBox(
          width: segmentWidths[i],
          height: widget.barHeight,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              onTap: () => setState(() => _selectedIndex = _selectedIndex == i ? null : i),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border(
                    right: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3), width: 1),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        b.name,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${b.startHz.toInt()}–${b.endHz.toInt()}Hz',
                      style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary),
                    ),
                    if (isHighlighted)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Icon(Icons.bolt_rounded, size: 14, color: theme.colorScheme.primary),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final spectrum = SizedBox(
      width: totalWidth,
      height: widget.barHeight,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: DecoratedBox(
          decoration: BoxDecoration(gradient: gradient),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < _bands.length; i++)
                SizedBox(
                  width: segmentWidths[i],
                  height: widget.barHeight,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      overlayColor: WidgetStateProperty.all(Colors.transparent),
                      onTap: () => setState(() => _selectedIndex = _selectedIndex == i ? null : i),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: Container(
                        decoration: BoxDecoration(
                          color: (() {
                            if (_highlightInstrument == null) return Colors.transparent;
                            final b = _bands[i];
                            final ranges = _instrumentRanges[_highlightInstrument!] ?? const [];
                            final isHighlighted = ranges.any((r) => r.intersects(_Range(b.startHz, b.endHz)));
                            return isHighlighted ? Colors.transparent : theme.scaffoldBackgroundColor.withValues(alpha: 0.5);
                          })(),
                          border: Border(right: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3), width: 1)),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _bands[i].name,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${_bands[i].startHz.toInt()}–${_bands[i].endHz.toInt()}Hz',
                              style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.8)),
                            ),
                            if (_highlightInstrument != null)
                              (() {
                                final b = _bands[i];
                                final ranges = _instrumentRanges[_highlightInstrument!] ?? const [];
                                final isHighlighted = ranges.any((r) => r.intersects(_Range(b.startHz, b.endHz)));
                                return isHighlighted
                                    ? Padding(
                                        padding: const EdgeInsets.only(left: 6),
                                        child: Icon(Icons.bolt_rounded, size: 14, color: theme.colorScheme.primary),
                                      )
                                    : const SizedBox.shrink();
                              })(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    final instruments = ['Vocal', 'Kick', 'Guitar', 'Bass'];

    // Make the content vertically scrollable only when height is bounded (e.g., fullscreen page).
    // When embedded inside a ListView on the Ref page, height is unbounded; avoid forcing minHeight there.
    return LayoutBuilder(
      builder: (context, constraints) {
        final hasBoundedHeight = constraints.hasBoundedHeight && constraints.maxHeight.isFinite;

        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showInstrumentChips) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Highlight Instrument', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary)),
                  TextButton.icon(
                    onPressed: () => setState(() => _highlightInstrument = null),
                    icon: Icon(Icons.refresh_rounded, size: 16, color: theme.colorScheme.primary),
                    label: Text('Clear', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary)),
                  )
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: instruments.map((name) {
                  final selected = _highlightInstrument == name;
                  return ChoiceChip(
                    label: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Text(name, style: theme.textTheme.labelSmall?.copyWith(
                        color: selected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                      )),
                    ),
                    selected: selected,
                    onSelected: (v) => setState(() => _highlightInstrument = v ? name : null),
                    selectedColor: theme.colorScheme.primary,
                    backgroundColor: theme.scaffoldBackgroundColor,
                    side: BorderSide(color: theme.dividerColor),
                    showCheckmark: false,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
            Container(
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(color: theme.dividerColor),
              ),
              clipBehavior: Clip.hardEdge,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: spectrum,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('20Hz', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary)),
                Text('20kHz', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary)),
              ],
            ),
            const SizedBox(height: 12),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              child: _selectedIndex == null ? const SizedBox.shrink() : _BandDetailCard(band: _bands[_selectedIndex!]),
            ),
          ],
        );

        if (hasBoundedHeight) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: content,
            ),
          );
        } else {
          // Parent scrolls (e.g., Ref page ListView). Just return content without vertical scroll.
          return content;
        }
      },
    );
  }
}

class _BandDetailCard extends StatelessWidget {
  final _EqBand band;
  const _BandDetailCard({required this.band});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final center = ((band.startHz + band.endHz) / 2).toDouble();
    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.dividerColor),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.equalizer_rounded, size: 18, color: theme.colorScheme.tertiary),
              const SizedBox(width: 8),
              Text('${band.name} • ${band.startHz.toInt()}–${band.endHz.toInt()}Hz',
                  style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          _DetailRow(icon: Icons.hearing_rounded, label: 'What it sounds like', text: band.soundsLike),
          _DetailRow(icon: Icons.report_problem_rounded, label: 'Common problems', text: band.problems),
          _DetailRow(icon: Icons.build_circle_rounded, label: 'Typical fix', text: band.fix),
          _DetailRow(icon: Icons.music_note_rounded, label: 'Instruments affected', text: band.instruments.join(', ')),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              style: ButtonStyle(
                shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full))),
              ),
              onPressed: () async {
                try {
                  final engine = AudioEngineService();
                  await engine.playFrequency(center, durationSeconds: 1.0);
                  final err = engine.consumeLastError();
                  if (err != null && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Audio playback failed.')));
                  }
                } catch (e) {
                  debugPrint('Play center frequency failed: $e');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Audio playback failed.')));
                  }
                }
              },
              icon: Icon(Icons.volume_up_rounded, color: Theme.of(context).colorScheme.onPrimary, size: 18),
              label: Text('Play Center Frequency (${center.toStringAsFixed(0)} Hz)',
                  style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onPrimary)),
            ),
          )
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String text;
  const _DetailRow({required this.icon, required this.label, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.secondary, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary)),
                Text(text, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EqBand {
  final String name;
  final double startHz;
  final double endHz;
  final String soundsLike;
  final String problems;
  final String fix;
  final List<String> instruments;
  const _EqBand({
    required this.name,
    required this.startHz,
    required this.endHz,
    required this.soundsLike,
    required this.problems,
    required this.fix,
    required this.instruments,
  });
}

class _Range {
  final double a;
  final double b;
  const _Range(this.a, this.b);
  bool intersects(_Range other) => math.max(a, other.a) <= math.min(b, other.b);
}

