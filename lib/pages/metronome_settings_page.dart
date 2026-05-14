import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:musicbyteai/models/metronome_settings.dart';
import 'package:musicbyteai/services/metronome_service.dart';
import 'package:musicbyteai/theme.dart';

class MetronomeSettingsPage extends StatefulWidget {
  const MetronomeSettingsPage({super.key});

  @override
  State<MetronomeSettingsPage> createState() => _MetronomeSettingsPageState();
}

class _MetronomeSettingsPageState extends State<MetronomeSettingsPage> {
  late Future<MetronomeSettings> _future;
  int _bpm = 120;
  String _subdivision = 'quarter';
  int _num = 4;
  int _den = 4;
  bool _accent = true;
  static const _minBpm = 40;
  static const _maxBpm = 240;

  @override
  void initState() {
    super.initState();
    _future = MetronomeService.instance.load().then((s) {
      _bpm = s.bpm;
      _subdivision = s.subdivision;
      _num = s.numerator;
      _den = s.denominator;
      _accent = s.accentDownbeats;
      return s;
    });
  }

  Future<void> _save() async {
    await MetronomeService.instance.update(
      bpm: _bpm,
      subdivision: _subdivision,
      numerator: _num,
      denominator: _den,
      accentDownbeats: _accent,
    );
  }

  Future<void> _saveAndClose() async {
    try {
      await _save();
    } catch (e) {
      debugPrint('MetronomeSettingsPage save error: $e');
    } finally {
      if (!mounted) return;
      if (context.canPop()) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Metronome Settings'),
        centerTitle: true,
      ),
      body: FutureBuilder(
        future: _future,
        builder: (context, snapshot) {
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // BPM
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
                    Text('Tempo', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => setState(() => _bpm = (_bpm - 1).clamp(_minBpm, _maxBpm)),
                          icon: Icon(Icons.remove_circle_outline, color: theme.colorScheme.onSurface),
                        ),
                        Column(
                          children: [
                            Text('$_bpm', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                            Text('BPM', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.secondary)),
                          ],
                        ),
                        IconButton(
                          onPressed: () => setState(() => _bpm = (_bpm + 1).clamp(_minBpm, _maxBpm)),
                          icon: Icon(Icons.add_circle_outline, color: theme.colorScheme.onSurface),
                        ),
                      ],
                    ),
                    Slider(
                      value: _bpm.toDouble(),
                      min: _minBpm.toDouble(),
                      max: _maxBpm.toDouble(),
                      onChanged: (v) => setState(() => _bpm = v.round()),
                      activeColor: theme.colorScheme.tertiary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Subdivision
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
                    Text('Click Division', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _ChoiceChip(
                          label: 'Quarter Notes',
                          selected: _subdivision == 'quarter',
                          onTap: () => setState(() => _subdivision = 'quarter'),
                        ),
                        _ChoiceChip(
                          label: 'Eighth Notes',
                          selected: _subdivision == 'eighth',
                          onTap: () => setState(() => _subdivision = 'eighth'),
                        ),
                        _ChoiceChip(
                          label: 'Sixteenth Notes',
                          selected: _subdivision == 'sixteenth',
                          onTap: () => setState(() => _subdivision = 'sixteenth'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Time Signature
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
                    Text('Time Signature', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final ts in const [
                          [2, 4],
                          [3, 4],
                          [4, 4],
                          [5, 4],
                          [7, 4],
                          [2, 2],
                          [3, 8],
                          [6, 8],
                          [9, 8],
                          [12, 8],
                        ])
                          _TimeSigChip(
                            num: ts[0],
                            den: ts[1],
                            selected: _num == ts[0] && _den == ts[1],
                            onTap: () => setState(() {
                              _num = ts[0];
                              _den = ts[1];
                            }),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Accents
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Accent Downbeats', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text('Play a brighter click on the first beat of each measure.', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary)),
                        ],
                      ),
                    ),
                    Switch(
                      value: _accent,
                      onChanged: (v) => setState(() => _accent = v),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saveAndClose,
                icon: const Icon(Icons.check_rounded),
                label: const Text('Save Settings'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ChoiceChip({required this.label, required this.selected, required this.onTap});

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
            Icon(Icons.timelapse_rounded, size: 16, color: selected ? theme.colorScheme.surface : theme.colorScheme.onSurface),
            const SizedBox(width: 6),
            Text(label, style: theme.textTheme.labelMedium?.copyWith(color: selected ? theme.colorScheme.surface : theme.colorScheme.onSurface, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _TimeSigChip extends StatelessWidget {
  final int num;
  final int den;
  final bool selected;
  final VoidCallback onTap;
  const _TimeSigChip({required this.num, required this.den, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.tertiary : theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: selected ? Colors.transparent : theme.dividerColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$num', style: theme.textTheme.labelLarge?.copyWith(color: selected ? theme.colorScheme.surface : theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
            Container(width: 24, height: 1, color: selected ? theme.colorScheme.surface : theme.dividerColor),
            Text('$den', style: theme.textTheme.labelLarge?.copyWith(color: selected ? theme.colorScheme.surface : theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
