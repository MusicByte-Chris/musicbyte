import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:go_router/go_router.dart';
import 'package:musicbyteai/theme.dart';
import 'package:musicbyteai/services/metronome_service.dart';
import 'package:musicbyteai/models/metronome_settings.dart';
import 'package:musicbyteai/nav.dart';
import 'package:musicbyteai/services/audio_engine_service.dart';
import 'package:musicbyteai/services/tuner_mic_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:musicbyteai/widgets/responsive_centered.dart';
import 'package:musicbyteai/widgets/luxury_page_header.dart';

class ToolsPage extends StatelessWidget {
  const ToolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = ResponsiveCentered.isWide(context);

    final header = const LuxuryPageHeader(
      title: 'Engineering Tools',
      subtitle: 'MusicByte Professional Suite',
    );

    final cards = <Widget>[
      _ToolCard(
        icon: Icons.piano_rounded,
        title: 'Chord & Scale Viewer',
        subtitle: 'Guitar Fretboard + Piano Keyboard',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Visualize chords and scales simultaneously on guitar and piano. Works fully offline.', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary)),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () => context.push('/viewer?key=c_major&tab=chord'),
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('OPEN VIEWER'),
              ),
            ),
          ],
        ),
      ),
      _ToolCard(
        icon: Icons.headphones,
        title: 'Ear Trainer',
        subtitle: 'Train intervals & chords',
        onTap: () => context.push(AppRoutes.earTrainer),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Practice notes, intervals, and chords. Clean UI, audio coming soon.', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary)),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () => context.push(AppRoutes.earTrainer),
                icon: const Icon(Icons.play_circle_fill_rounded),
                label: const Text('OPEN TRAINER'),
              ),
            ),
          ],
        ),
      ),
      _ToolCard(
        icon: Icons.flash_on_rounded,
        title: 'Note Assault',
        subtitle: 'Note recognition — gamified • Offline',
        onTap: () => context.push(AppRoutes.noteAssault),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Whole notes fly across the staff. Tap A–G before they reach the clef.', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary)),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () => context.push(AppRoutes.noteAssault),
                icon: const Icon(Icons.rocket_launch_rounded),
                label: const Text('PLAY'),
              ),
            ),
          ],
        ),
      ),
      _ToolCard(
        icon: Icons.grid_view_rounded,
        title: 'Rhythm Trainer',
        subtitle: 'Common rhythms • Instant click playback • Offline',
        onTap: () => context.push(AppRoutes.rhythmTrainer),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Internalize time with curated patterns: straight subdivisions, dotted rhythms, triplets, ties, and more.', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary)),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () => context.push(AppRoutes.rhythmTrainer),
                icon: const Icon(Icons.play_circle_fill_rounded),
                label: const Text('OPEN'),
              ),
            ),
          ],
        ),
      ),
      _ToolCard(
        icon: Icons.menu_book_rounded,
        title: 'Music Theory Reference',
        subtitle: 'Scales • Key signatures • Symbols • Number systems',
        onTap: () => context.push(AppRoutes.theoryReference),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Scale formulas, order of sharps/flats, accidentals, chord symbols, inversions, and Roman vs Nashville—quick lookups.', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary)),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () => context.push(AppRoutes.theoryReference),
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('OPEN'),
              ),
            ),
          ],
        ),
      ),
      _ToolCard(icon: Icons.mic_none_rounded, title: "Chromatic Tuner", subtitle: "A4 = 440Hz • High Precision", child: const _ChromaticTunerCard()),
      const MetronomeCard(),
      _ToolCard(icon: Icons.waves, title: "Tone Generator", subtitle: "Sine • Square • Saw • Triangle", child: const _ToneGeneratorControls()),
      _ToolCard(icon: Icons.compare_arrows_rounded, title: 'Interval Explorer', subtitle: 'Quickly audition intervals from any root', child: const _IntervalExplorerCard()),
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: ResponsiveCentered(
          maxWidth: isWide ? 1200 : 980,
          child: isWide
              ? LayoutBuilder(
                  builder: (context, constraints) {
                    const spacing = 16.0;
                    final tileW = ((constraints.maxWidth - spacing) / 2).clamp(420.0, 640.0);
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          header,
                          const SizedBox(height: 24),
                          Wrap(
                            spacing: spacing,
                            runSpacing: spacing,
                            children: [
                              for (final card in cards)
                                SizedBox(width: tileW, child: card),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    );
                  },
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  children: [
                    header,
                    const SizedBox(height: 32),
                    for (int i = 0; i < cards.length; i++) ...[
                      cards[i],
                      SizedBox(height: i == cards.length - 1 ? 24 : 16),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onTap;

  const _ToolCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    this.onSettingsTap,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: theme.dividerColor),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              // Leading icon + texts
              Expanded(
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(icon, color: theme.colorScheme.tertiary, size: 24),
                  ),
                  const SizedBox(width: 16),
                  // Make text block flexible so it can wrap on narrow screens
                  Flexible(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 2,
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary),
                      ),
                    ]),
                  ),
                ]),
              ),
              // Trailing settings icon only when provided
              if (onSettingsTap != null)
                GestureDetector(
                  onTap: onSettingsTap,
                  child: Icon(Icons.settings_rounded, color: theme.colorScheme.secondary, size: 20),
                ),
            ]),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _BpmChip extends StatelessWidget {
  final String label;
  final bool selected;

  const _BpmChip({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? theme.colorScheme.tertiary : theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: selected ? Colors.transparent : theme.dividerColor),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: selected ? theme.colorScheme.surface : theme.colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Beat subdivision options for the metronome ticks.
enum BeatSubdivision { quarter, eighth, sixteenth }

/// A self-contained Metronome tool card with BPM, subdivision, and audio click.
class MetronomeCard extends StatelessWidget {
  const MetronomeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final key = GlobalKey<_MetronomeControlsState>();
    return _ToolCard(
      icon: Icons.timer,
      title: 'Metronome',
      subtitle: 'Reliable timing • Custom BPM • Subdivisions',
      onSettingsTap: () async {
        await context.push(AppRoutes.metronomeSettings);
        key.currentState?.reloadSettings();
      },
      child: _MetronomeControls(key: key),
    );
  }
}

class _MetronomeControls extends StatefulWidget {
  const _MetronomeControls({super.key});

  @override
  State<_MetronomeControls> createState() => _MetronomeControlsState();
}

class _MetronomeControlsState extends State<_MetronomeControls> {
  static const int _minBpm = 40;
  static const int _maxBpm = 240;
  static const int _sampleRate = 44100;

  late final AudioPlayer _player;
  Timer? _timer;
  int _bpm = 120;
  bool _isPlaying = false;
  BeatSubdivision _subdivision = BeatSubdivision.quarter;
  int _numerator = 4;
  int _denominator = 4;
  bool _accentDownbeats = true;
  int _tickCounter = 0;
  late final Uint8List _clickBytes;
  late final Uint8List _accentBytes;
  bool _audioAvailable = true;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _clickBytes = _generateClickWav(frequencyHz: 1200, durationMs: 20, amplitude: 0.6);
    _accentBytes = _generateClickWav(frequencyHz: 1800, durationMs: 24, amplitude: 1.0);
    reloadSettings();
    // Dreamflow web preview may not support audioplayers; gracefully disable audio to avoid spammy errors
    if (kIsWeb) {
      _audioAvailable = false;
      debugPrint('Metronome: audio disabled on web preview.');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> reloadSettings() async {
    try {
      final s = await MetronomeService.instance.load();
      _bpm = s.bpm.clamp(_minBpm, _maxBpm);
      _subdivision = _fromStringSubdivision(s.subdivision);
      _numerator = s.numerator;
      _denominator = s.denominator;
      _accentDownbeats = s.accentDownbeats;
      _restartIfPlaying();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Metronome reloadSettings error: $e');
    }
  }

  BeatSubdivision _fromStringSubdivision(String s) {
    switch (s) {
      case 'eighth':
        return BeatSubdivision.eighth;
      case 'sixteenth':
        return BeatSubdivision.sixteenth;
      case 'quarter':
      default:
        return BeatSubdivision.quarter;
    }
  }

  // Generate a short mono PCM WAV for the click sound.
  Uint8List _generateClickWav({int frequencyHz = 1000, int durationMs = 15, double amplitude = 0.7}) {
    final totalSamples = ((_sampleRate * durationMs) / 1000).round();
    final bytesPerSample = 2; // 16-bit PCM
    final dataSize = totalSamples * bytesPerSample;
    final buffer = BytesBuilder();

    void writeString(String s) => buffer.add(s.codeUnits);
    void writeInt32LE(int value) => buffer.add(Uint8List(4)..buffer.asByteData().setUint32(0, value, Endian.little));
    void writeInt16LE(int value) => buffer.add(Uint8List(2)..buffer.asByteData().setUint16(0, value & 0xFFFF, Endian.little));

    // WAV header
    writeString('RIFF');
    writeInt32LE(36 + dataSize);
    writeString('WAVE');
    writeString('fmt ');
    writeInt32LE(16); // PCM chunk size
    writeInt16LE(1); // PCM format
    writeInt16LE(1); // mono
    writeInt32LE(_sampleRate);
    writeInt32LE(_sampleRate * bytesPerSample); // byte rate
    writeInt16LE(bytesPerSample); // block align
    writeInt16LE(8 * bytesPerSample); // bits per sample
    writeString('data');
    writeInt32LE(dataSize);

    // Simple short sine burst with quick fade out
    for (int n = 0; n < totalSamples; n++) {
      final t = n / _sampleRate;
      final env = 1.0 - (n / totalSamples); // quick decay
      final sample = math.sin(2 * math.pi * frequencyHz * t) * amplitude * env;
      final s16 = (sample * 32767).clamp(-32768, 32767).round();
      writeInt16LE(s16);
    }

    return buffer.toBytes();
  }

  int _subdivisionFactor(BeatSubdivision s) {
    switch (s) {
      case BeatSubdivision.quarter:
        return 1;
      case BeatSubdivision.eighth:
        return 2;
      case BeatSubdivision.sixteenth:
        return 4;
    }
  }

  Duration _tickInterval() {
    final quarterMs = 60000.0 / _bpm;
    final intervalMs = quarterMs / _subdivisionFactor(_subdivision);
    return Duration(milliseconds: intervalMs.round());
  }

  int _ticksPerMeasure() {
    final subdivisionValue = _subdivision == BeatSubdivision.quarter
        ? 1.0
        : _subdivision == BeatSubdivision.eighth
            ? 0.5
            : 0.25; // sixteenth
    final measureQuarters = _numerator * (4.0 / _denominator);
    final ticks = (measureQuarters / subdivisionValue).round();
    return math.max(1, ticks);
  }

  Future<void> _tick() async {
    try {
      final accentNow = _accentDownbeats && (_tickCounter % _ticksPerMeasure() == 0);
      final bytes = accentNow ? _accentBytes : _clickBytes;
      await _player.play(BytesSource(bytes), volume: 1.0);
      _tickCounter++;
    } catch (e) {
      debugPrint('Metronome tick error: $e');
    }
  }

  void _start() {
    if (!_audioAvailable) {
      debugPrint('Metronome: audio not available in this environment.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Audio not available in web preview.')));
      }
      return;
    }
    _timer?.cancel();
    _isPlaying = true;
    _tickCounter = 0;
    _timer = Timer.periodic(_tickInterval(), (_) => _tick());
    setState(() {});
  }

  void _stop() {
    _timer?.cancel();
    _isPlaying = false;
    setState(() {});
  }

  void _restartIfPlaying() {
    if (_isPlaying) {
      _timer?.cancel();
      _timer = Timer.periodic(_tickInterval(), (_) => _tick());
    }
  }

  void _setBpm(int value) {
    _bpm = value.clamp(_minBpm, _maxBpm);
    _restartIfPlaying();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        // Summary row: BPM • Division • Time Signature
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: theme.dividerColor),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 380;
               final items = [
                 _SummaryInfoItem(icon: Icons.speed_rounded, labelBuilder: _SummaryLabel.bpm),
                 _SummaryInfoItem(icon: Icons.timeline_rounded, labelBuilder: _SummaryLabel.subdivision),
                 _SummaryInfoItem(icon: Icons.av_timer_rounded, labelBuilder: _SummaryLabel.timeSig),
               ];
              if (compact) {
                return Wrap(spacing: 12, runSpacing: 8, children: items);
              }
              return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: items);
            },
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _isPlaying ? _stop : _start,
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.onSurface,
            foregroundColor: theme.colorScheme.surface,
            minimumSize: const Size(double.infinity, 48),
          ),
          icon: Icon(_isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded),
          label: Text(!_audioAvailable
              ? 'AUDIO UNAVAILABLE (WEB)'
              : _isPlaying
                  ? 'STOP METRONOME'
                  : 'START METRONOME'),
        ),
      ],
    );
  }
}

/// Displays a small icon + dynamic label used in the metronome summary row.
class _SummaryInfoItem extends StatelessWidget {
  final IconData icon;
  final _SummaryLabel labelBuilder;
  const _SummaryInfoItem({required this.icon, required this.labelBuilder});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = context.findAncestorStateOfType<_MetronomeControlsState>();
    String text = '';
    switch (labelBuilder) {
      case _SummaryLabel.bpm:
        text = '${state?._bpm ?? 0} BPM';
        break;
      case _SummaryLabel.subdivision:
        final s = state?._subdivision;
        text = s == BeatSubdivision.quarter ? 'Quarter' : s == BeatSubdivision.eighth ? 'Eighth' : 'Sixteenth';
        break;
      case _SummaryLabel.timeSig:
        text = '${state?._numerator ?? 4}/${state?._denominator ?? 4}';
        break;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.tertiary),
        const SizedBox(width: 6),
        Text(text, style: theme.textTheme.labelLarge?.copyWith(fontWeight: labelBuilder == _SummaryLabel.bpm ? FontWeight.w700 : FontWeight.w500)),
      ],
    );
  }
}

enum _SummaryLabel { bpm, subdivision, timeSig }

class _QuickBpmChip extends StatelessWidget {
  final String label;
  final int value;
  final int current;
  final void Function(int) onTap;
  const _QuickBpmChip({required this.label, required this.value, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = value == current;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.tertiary : theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: selected ? Colors.transparent : theme.dividerColor),
        ),
        child: Text(label, style: theme.textTheme.labelMedium?.copyWith(color: selected ? theme.colorScheme.surface : theme.colorScheme.onSurface, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _SubdivisionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SubdivisionChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.primary : theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: selected ? Colors.transparent : theme.dividerColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timeline_rounded, size: 16, color: selected ? theme.colorScheme.surface : theme.colorScheme.onSurface),
            const SizedBox(width: 6),
            Text(label, style: theme.textTheme.labelMedium?.copyWith(color: selected ? theme.colorScheme.surface : theme.colorScheme.onSurface, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

/// Tone Generator controls that delegate playback to AudioEngineService
class _ToneGeneratorControls extends StatefulWidget {
  const _ToneGeneratorControls();

  @override
  State<_ToneGeneratorControls> createState() => _ToneGeneratorControlsState();
}

class _ToneGeneratorControlsState extends State<_ToneGeneratorControls> {
  double _freq = 440.0;
  bool _isPlaying = false;

  @override
  void dispose() {
    // Stop any ongoing tone when leaving the card
    try {
      // Avoid awaiting in dispose
      AudioEngineService().stopContinuousTone();
    } catch (e) {
      debugPrint('ToneGenerator dispose stop error: $e');
    }
    super.dispose();
  }

  Future<void> _play() async {
    if (_isPlaying) return;
    setState(() => _isPlaying = true);
    try {
      // Continuous tone: keeps playing until user presses STOP.
      final engine = AudioEngineService();
      await engine.startContinuousTone(_freq);
      final err = engine.consumeLastError();
      if (err != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Audio error while starting tone.')));
      }
    } catch (e) {
      debugPrint('ToneGenerator play error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to play tone.')));
      }
      if (mounted) setState(() => _isPlaying = false);
    }
  }

  Future<void> _stop() async {
    try {
      final engine = AudioEngineService();
      await engine.stopContinuousTone();
      final err = engine.consumeLastError();
      if (err != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Audio error while stopping tone.')));
      }
    } catch (e) {
      debugPrint('ToneGenerator stop error: $e');
    } finally {
      if (mounted) setState(() => _isPlaying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Frequency', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary)),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(_freq.toStringAsFixed(1), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                        const SizedBox(width: 4),
                        Text('Hz', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Waveform', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary)),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Sine', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
                        Icon(Icons.keyboard_arrow_down_rounded, color: theme.colorScheme.secondary, size: 20),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 60,
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: theme.dividerColor),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 0),
                      FlSpot(1, 10),
                      FlSpot(2, 0),
                      FlSpot(3, -10),
                      FlSpot(4, 0),
                      FlSpot(5, 10),
                      FlSpot(6, 0),
                      FlSpot(7, -10),
                      FlSpot(8, 0),
                    ],
                    isCurved: true,
                    color: theme.colorScheme.tertiary,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                  ),
                ],
                minX: 0,
                maxX: 8,
                minY: -15,
                maxY: 15,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _stop,
                child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Text('STOP', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: _play,
                child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiary,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Text(_isPlaying ? 'PLAYING…' : 'PLAY TONE', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.surface)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _IntervalExplorerCard extends StatefulWidget {
  const _IntervalExplorerCard();

  @override
  State<_IntervalExplorerCard> createState() => _IntervalExplorerCardState();
}

class _IntervalExplorerCardState extends State<_IntervalExplorerCard> {
  String _root = 'C';
  int _octave = 4;
  String _interval = 'P5';
  static const _roots = ['C','D','E','F','G','A','B'];
  static const _intervals = ['m2','M2','m3','M3','P4','TT','P5','m6','M6','m7','M7','P8'];

  Future<void> _play() async {
    try {
      final engine = AudioEngineService();
      await engine.playInterval(_root, _octave, _interval);
    } catch (e) {
      debugPrint('IntervalExplorer play error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 420;
        final rootField = Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: theme.dividerColor)),
          child: DropdownButton<String>(
            isExpanded: true,
            value: _root,
            underline: const SizedBox.shrink(),
            dropdownColor: theme.cardTheme.color,
            items: _roots.map((r)=> DropdownMenuItem(value: r, child: Text(r, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurface)))).toList(),
            onChanged: (v){ if (v != null) setState(()=> _root = v); },
          ),
        );
        final octaveField = Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: theme.dividerColor)),
          child: DropdownButton<int>(
            isExpanded: true,
            value: _octave,
            underline: const SizedBox.shrink(),
            dropdownColor: theme.cardTheme.color,
            items: [2,3,4,5].map((o)=> DropdownMenuItem(value: o, child: Text('Oct $o', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurface)))).toList(),
            onChanged: (v){ if (v != null) setState(()=> _octave = v); },
          ),
        );
        final intervalField = Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: theme.dividerColor)),
          child: DropdownButton<String>(
            isExpanded: true,
            value: _interval,
            underline: const SizedBox.shrink(),
            dropdownColor: theme.cardTheme.color,
            items: _intervals.map((i)=> DropdownMenuItem(value: i, child: Text(i, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurface)))).toList(),
            onChanged: (v){ if (v != null) setState(()=> _interval = v); },
          ),
        );

        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              rootField,
              const SizedBox(height: 12),
              octaveField,
              const SizedBox(height: 12),
              intervalField,
              const SizedBox(height: 12),
              FilledButton.icon(onPressed: _play, icon: const Icon(Icons.play_arrow_rounded), label: const Text('Play Interval')),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              // Root selector
              Expanded(child: rootField),
              const SizedBox(width: 12),
              // Octave selector (fixed width is OK on wide screens)
              SizedBox(width: 96, child: octaveField),
              const SizedBox(width: 12),
              // Interval selector
              Expanded(child: intervalField),
            ]),
            const SizedBox(height: 12),
            FilledButton.icon(onPressed: _play, icon: const Icon(Icons.play_arrow_rounded), label: const Text('Play Interval')),
          ],
        );
      },
    );
  }
}

// ===== Chromatic Tuner (self-contained) =====

class _ChromaticTunerCard extends StatefulWidget {
  const _ChromaticTunerCard();

  @override
  State<_ChromaticTunerCard> createState() => _ChromaticTunerCardState();
}

class _ChromaticTunerCardState extends State<_ChromaticTunerCard> {
  // Display state
  String _noteLabel = '--';
  String _centsLabel = '--';
  double _needleAngle = 0; // radians; -max..+max
  double _progress = 0.5; // 0..1
  bool _hasPitch = false;

  // Smoothing
  double? _emaCents; // exponential moving average
  static const double _maxNeedleAngle = 0.52; // ~30 degrees

  TunerMicService? _mic;
  final _pitch = _PitchProcessor();
  int _dbg = 0; // rate-limit logs

  @override
  void initState() {
    super.initState();
    // Default OFF. User can enable mic with the toggle button.
  }

  Future<void> _startMic() async {
    _mic ??= TunerMicService(onAudioFrame: _onAudioFrame);
    if (!(_mic!.isSupported)) {
      debugPrint('ChromaticTuner: Microphone capture is not supported on this platform.');
      return;
    }
    try {
      await _mic!.start();
    } catch (e) {
      debugPrint('ChromaticTuner start mic error: $e');
    }
  }

  @override
  void dispose() {
    _mic?.stop();
    super.dispose();
  }

  bool _micEnabled = false;
  bool _isStarting = false;

  Future<void> _toggleMic() async {
    _mic ??= TunerMicService(onAudioFrame: _onAudioFrame);
    if (!(_mic!.isSupported)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mic tuner is available on Web only.')));
      }
      return;
    }

    // Runtime permission (Android/iOS). On web, the browser prompts when
    // getUserMedia is invoked.
    if (!kIsWeb) {
      final ok = await _ensureMicrophonePermission();
      if (!ok) return;
    }

    if (_micEnabled) {
      try { _mic?.stop(); } catch (e) { debugPrint('Tuner stop error: $e'); }
      setState(() {
        _micEnabled = false;
        _hasPitch = false;
        _noteLabel = '--';
        _centsLabel = '--';
        _needleAngle = 0;
        _progress = 0.5;
        _emaCents = null;
      });
      return;
    }
    if (_isStarting) return;
    setState(() => _isStarting = true);
    try {
      await _startMic();
      if (mounted) setState(() => _micEnabled = true);
    } catch (e) {
      debugPrint('Tuner start error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not access microphone.')));
      }
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  Future<bool> _ensureMicrophonePermission() async {
    try {
      final status = await Permission.microphone.status;
      if (status.isGranted) return true;

      final theme = Theme.of(context);
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: theme.cardTheme.color,
            title: const Text('Microphone access'),
            content: const Text('The tuner needs microphone access to detect pitch. Audio is processed on-device and is not uploaded.'),
            actions: [
              TextButton(onPressed: () => context.pop(false), child: const Text('Not now')),
              FilledButton(onPressed: () => context.pop(true), child: const Text('Continue')),
            ],
          );
        },
      );

      if (proceed != true) return false;

      final result = await Permission.microphone.request();
      if (result.isGranted) return true;

      if (mounted) {
        final msg = result.isPermanentlyDenied
            ? 'Microphone permission is disabled in system settings.'
            : 'Microphone permission was not granted.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
      return false;
    } catch (e) {
      debugPrint('Microphone permission request failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not request microphone permission.')));
      }
      return false;
    }
  }

  void _onAudioFrame(Float32List buffer, double sampleRate) {
    try {
      final result = _pitch.detectFrequency(buffer, sampleRate);
      if (result == null) {
        // No reliable pitch
        _emaCents = _emaCents == null ? 0 : _lerp(_emaCents!, 0, 0.2);
        if (!mounted) return;
        setState(() {
          _hasPitch = false;
          _noteLabel = '--';
          _centsLabel = '--';
          _needleAngle = _maxNeedleAngle * (_emaCents ?? 0) / 50.0; // moves toward center
          _progress = 0.5;
        });
        if ((_dbg++ % 40) == 0) {
          // lightweight RMS log to ensure frames are flowing
          double rms = 0; for (int i = 0; i < buffer.length; i++) { final v = buffer[i]; rms += v*v; }
          rms = math.sqrt(rms / buffer.length);
          debugPrint('Tuner: no pitch, rms=${rms.toStringAsFixed(3)} sr=${sampleRate.toStringAsFixed(0)}');
        }
        return;
      }

      final hz = result;
      final info = _NoteInfo.fromFrequency(hz);
      final cents = info.centsDeviation;
      // Smooth cents to reduce jitter
      _emaCents = _emaCents == null ? cents : _lerp(_emaCents!, cents, 0.2);
      final smoothed = _emaCents!;

      final angle = (smoothed.clamp(-50.0, 50.0)) / 50.0 * _maxNeedleAngle;
      final prog = (smoothed + 50.0) / 100.0;

      if (!mounted) return;
      setState(() {
        _hasPitch = true;
        _noteLabel = '${info.note}${info.octave}';
        final centsText = smoothed.abs() < 0.5 ? '0' : smoothed.toStringAsFixed(0);
        _centsLabel = '$centsText cents';
        _needleAngle = angle;
        _progress = prog.clamp(0.0, 1.0);
      });
      if ((_dbg++ % 20) == 0) {
        debugPrint('Tuner: ${hz.toStringAsFixed(1)} Hz -> ${info.note}${info.octave}, cents=${smoothed.toStringAsFixed(0)}');
      }
    } catch (e) {
      debugPrint('ChromaticTuner onAudioFrame error: $e');
    }
  }

  Color _centsColor(ThemeData theme) {
    if (!_hasPitch) return theme.colorScheme.secondary;
    final v = (_emaCents ?? 0).abs();
    if (v <= 5) return theme.colorScheme.primary; // green-like accent in theme
    if (v <= 15) return theme.colorScheme.tertiary; // warning-ish
    return theme.colorScheme.error; // red
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
            onPressed: _isStarting ? null : _toggleMic,
            icon: Icon(_micEnabled ? Icons.mic_rounded : Icons.mic_off_rounded, color: _micEnabled ? theme.colorScheme.primary : theme.colorScheme.secondary),
            label: Text(_micEnabled ? 'Mic ON' : 'Mic OFF'),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Semi-circle background (unchanged)
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: 240,
                  height: 120,
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(120), topRight: Radius.circular(120)),
                    border: Border(
                      top: BorderSide(color: theme.dividerColor, width: 2),
                      left: BorderSide(color: theme.dividerColor, width: 1),
                      right: BorderSide(color: theme.dividerColor, width: 1),
                    ),
                  ),
                ),
              ),
              // Needle with smooth rotation + subtle fade when no pitch
              Positioned(
                bottom: 0,
                child: AnimatedOpacity(
                  opacity: _hasPitch ? 1.0 : 0.5,
                  duration: const Duration(milliseconds: 150),
                  child: AnimatedRotation(
                    turns: _needleAngle / (2 * math.pi),
                    duration: const Duration(milliseconds: 90),
                    curve: Curves.easeOut,
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: 4,
                      height: 110,
                      decoration: BoxDecoration(color: theme.colorScheme.tertiary, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                ),
              ),
              // Text Note + cents
              Positioned(
                bottom: 20,
                child: Column(
                  children: [
                    Text(
                      _noteLabel,
                      style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface),
                    ),
                    Text(
                      _centsLabel,
                      style: theme.textTheme.labelMedium?.copyWith(color: _centsColor(theme)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text("-50", style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary)),
            const SizedBox(width: 8),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: theme.dividerColor,
                  color: theme.colorScheme.tertiary,
                  minHeight: 8,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text("+50", style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary)),
          ],
        ),
      ],
    );
  }
}

class _PitchProcessor {
  // Frequency range for detection
  static const double _minHz = 50.0;
  static const double _maxHz = 1000.0;
  static const double _ampThreshold = 0.004; // ignore low amplitude noise (more sensitive)

  double? detectFrequency(Float32List buffer, double sampleRate) {
    final n = buffer.length;
    // RMS amplitude check (pre)
    double rms = 0;
    for (int i = 0; i < n; i++) { final v = buffer[i]; rms += v*v; }
    rms = math.sqrt(rms / n);
    if (rms < _ampThreshold) return null;

    // Remove DC offset and apply Hann window
    double mean = 0; for (int i = 0; i < n; i++) mean += buffer[i];
    mean /= n;
    final x = Float32List(n);
    for (int i = 0; i < n; i++) {
      final w = 0.5 * (1 - math.cos(2 * math.pi * i / (n - 1)));
      x[i] = (buffer[i] - mean) * w;
    }

    // Autocorrelation search
    final minLag = (sampleRate / _maxHz).floor();
    final maxLag = math.min((sampleRate / _minHz).floor(), n ~/ 2);
    double bestCorr = 0;
    int bestLag = -1;

    // Energy at zero lag for normalization
    double e0 = 0; for (int i = 0; i < n; i++) { final v = x[i]; e0 += v*v; }
    if (e0 <= 1e-9) return null;

    for (int lag = minLag; lag <= maxLag; lag++) {
      double corr = 0;
      // Unrolled simple loop
      final m = n - lag;
      for (int i = 0; i < m; i++) { corr += x[i] * x[i + lag]; }
      if (corr > bestCorr) { bestCorr = corr; bestLag = lag; }
    }

    if (bestLag <= 0 || bestCorr <= 0) return null;

    // Optional clarity gate to reduce false detections
    final clarity = bestCorr / e0;
    if (clarity < 0.15) return null;

    // Parabolic interpolation around bestLag for sub-sample precision
    final l1 = math.max(minLag, bestLag - 1);
    final l2 = bestLag;
    final l3 = math.min(maxLag, bestLag + 1);
    final c1 = _corrAtPreprocessed(x, l1);
    final c2 = _corrAtPreprocessed(x, l2);
    final c3 = _corrAtPreprocessed(x, l3);
    final denom = (2 * (c1 - 2 * c2 + c3));
    double refinedLag = bestLag.toDouble();
    if (denom.abs() > 1e-9) {
      final delta = (c1 - c3) / denom; // shift within [-1,1]
      refinedLag = bestLag + delta;
    }

    final freq = sampleRate / refinedLag;
    if (freq < _minHz || freq > _maxHz || freq.isNaN) return null;
    return freq;
  }

  double _corrAtPreprocessed(Float32List x, int lag) {
    double corr = 0;
    for (int i = 0; i < x.length - lag; i++) { corr += x[i] * x[i + lag]; }
    return corr;
  }
}

class _NoteInfo {
  final String note;
  final int octave;
  final double centsDeviation; // negative = flat, positive = sharp
  const _NoteInfo(this.note, this.octave, this.centsDeviation);

  static const List<String> _names = ['C','C#','D','D#','E','F','F#','G','G#','A','A#','B'];

  static _NoteInfo fromFrequency(double hz) {
    final midi = (69 + 12 * (math.log(hz / 440.0) / math.ln2));
    final nearest = midi.round();
    final name = _names[nearest % 12];
    final octave = (nearest ~/ 12) - 1;
    final exactHz = 440.0 * math.pow(2.0, (nearest - 69) / 12.0);
    final cents = 1200.0 * (math.log(hz / exactHz) / math.ln2);
    return _NoteInfo(name, octave, cents.clamp(-50.0, 50.0));
  }
}

double _lerp(double a, double b, double t) => a + (b - a) * t;
