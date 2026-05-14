import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:musicbyteai/models/rhythm_pattern.dart';
import 'package:musicbyteai/services/audio_engine_service.dart';
import 'package:musicbyteai/services/metronome_service.dart';
import 'package:musicbyteai/services/practice_log_service.dart';
import 'package:musicbyteai/services/rhythm_service.dart';
import 'package:musicbyteai/theme.dart';
import 'package:musicbyteai/widgets/responsive_centered.dart';

class RhythmTrainerPage extends StatefulWidget {
  const RhythmTrainerPage({super.key});

  @override
  State<RhythmTrainerPage> createState() => _RhythmTrainerPageState();
}

class _RhythmTrainerPageState extends State<RhythmTrainerPage> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  bool _isPlaying = false;
  String? _playingId;

  // Recognize mode state
  final Random _rng = Random();
  RhythmPattern? _recognizeTarget;
  List<RhythmPattern> _recognizeOptions = const [];
  bool _recognizeLocked = false;
  int _recognizeCorrect = 0;
  int _recognizeTotal = 0;
  int? _recognizeSelectedIndex;
  String? _recognizeFeedback;
  bool? _recognizeWasCorrect;

  // Perform mode state
  RhythmPattern? _performTarget;
  bool _performRunning = false;
  bool _performFinished = false;
  int _performBpm = 96;
  final List<double> _expectedHitBeats = [];
  final List<int> _tapErrorsMs = [];
  int _nextExpectedIndex = 0;
  DateTime? _performStart;
  Timer? _performTimer;
  Timer? _metronomeTimer;
  int _metronomeTick = 0;
  _TapResult? _lastTapResult;
  int _sessionPerformCount = 0;
  double _sessionAccuracyAvg = 0; // 0..1

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(() {
      if (_tabs.indexIsChanging) return;
      // Be defensive: stop perform timers when leaving Perform.
      if (_tabs.index != 2) _stopPerform();
    });

    // Prime initial rounds.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _nextRecognizeRound();
      _pickPerformTarget();
    });
    _loadPerformBpm();
  }

  Future<void> _loadPerformBpm() async {
    try {
      final s = await MetronomeService.instance.load();
      if (!mounted) return;
      setState(() => _performBpm = s.bpm.clamp(40, 220));
    } catch (e) {
      debugPrint('RhythmTrainerPage: failed to load metronome settings: $e');
    }
  }

  @override
  void dispose() {
    _performTimer?.cancel();
    _metronomeTimer?.cancel();
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _play(RhythmPattern p) async {
    if (_isPlaying) return;
    setState(() {
      _isPlaying = true;
      _playingId = p.id;
    });
    try {
      await RhythmService.instance.playPattern(p);
    } catch (e) {
      debugPrint('RhythmTrainerPage play error: $e');
    } finally {
      if (!mounted) return;
      setState(() {
        _isPlaying = false;
        _playingId = null;
      });
    }
  }

  RhythmPattern _pickRandomPattern({int minDifficulty = 1}) {
    final all = RhythmService.instance.patterns;
    final eligible = all.where((p) => p.difficulty >= minDifficulty).toList();
    final list = eligible.isNotEmpty ? eligible : all;
    return list[_rng.nextInt(max(1, list.length))];
  }

  Future<void> _nextRecognizeRound() async {
    if (_isPlaying) return;
    final all = RhythmService.instance.patterns;
    if (all.isEmpty) return;

    final target = _pickRandomPattern(minDifficulty: 3);
    final optionCount = (4 + _rng.nextInt(3)).clamp(4, 6);
    final options = <RhythmPattern>[target];
    final pool = all.where((p) => p.id != target.id).toList()..shuffle(_rng);
    for (final p in pool) {
      if (options.length >= optionCount) break;
      options.add(p);
    }
    options.shuffle(_rng);

    setState(() {
      _recognizeTarget = target;
      _recognizeOptions = List.unmodifiable(options);
      _recognizeLocked = false;
      _recognizeSelectedIndex = null;
      _recognizeFeedback = null;
      _recognizeWasCorrect = null;
    });

    // Autoplay the prompt rhythm.
    await _playRecognizePrompt();
  }

  Future<void> _playRecognizePrompt() async {
    final p = _recognizeTarget;
    if (p == null) return;
    await _play(p);
  }

  Future<void> _selectRecognizeOption(int index) async {
    if (_recognizeLocked) return;
    final target = _recognizeTarget;
    if (target == null) return;
    if (index < 0 || index >= _recognizeOptions.length) return;

    final chosen = _recognizeOptions[index];
    final correct = chosen.id == target.id;
    final feedback = correct
        ? 'Correct — ${_explainPattern(target)}'
        : 'Not quite — ${_explainPattern(target)}';

    setState(() {
      _recognizeLocked = true;
      _recognizeSelectedIndex = index;
      _recognizeWasCorrect = correct;
      _recognizeFeedback = feedback;
      _recognizeTotal += 1;
      if (correct) _recognizeCorrect += 1;
    });

    // Log the round as a short practice touch.
    unawaited(
      PracticeLogService.instance.addSession(
        focusArea: 'Rhythm Trainer',
        minutes: 1,
        notes: 'Recognize: ${correct ? 'Correct' : 'Wrong'} — ${target.name} (${target.timeSignature})',
      ),
    );
  }

  String _explainPattern(RhythmPattern p) {
    // Lightweight heuristics from the MVP catalog (kept offline + fast).
    final dur = p.pattern;
    bool hasTriplets = dur.any((d) => (d - 0.3333).abs() < 0.06 || (d - 0.6667).abs() < 0.06);
    bool hasDottedEighth = dur.any((d) => (d - 0.75).abs() < 0.06) && dur.any((d) => (d - 0.25).abs() < 0.03);
    bool hasDottedQuarter = dur.any((d) => (d - 1.5).abs() < 0.06);
    bool hasSyncopation = _attackPositionsInBeats(p).any((b) => (b % 1.0 - 0.5).abs() < 0.08);
    bool hasTieLikeSustain = dur.any((d) => d >= 2.0 - 0.01);

    if (hasDottedEighth) return 'it uses dotted 8th + 16th spacing (a tight “DAH–dit” feel).';
    if (hasTriplets) return 'it’s built from triplet subdivision (a smooth 3-part grid).';
    if (hasDottedQuarter) return 'the dotted-quarter pulse pushes across the beat grid.';
    if (hasTieLikeSustain) return 'it sustains through a beat boundary (a tie-like feel).';
    if (hasSyncopation) return 'the attacks land on offbeats (the “&” creates syncopation).';
    return 'it’s primarily straight subdivision—focus on even spacing.';
  }

  List<double> _attackPositionsInBeats(RhythmPattern p) {
    final out = <double>[];
    double cursor = 0;
    for (int i = 0; i < p.pattern.length; i++) {
      out.add(cursor);
      cursor += p.pattern[i];
    }
    return out;
  }

  // -------- Perform mode --------
  void _pickPerformTarget() {
    final t = _pickRandomPattern(minDifficulty: 3);
    _setPerformTarget(t);
  }

  void _setPerformTarget(RhythmPattern p) {
    _stopPerform();
    _expectedHitBeats
      ..clear()
      ..addAll(_attackPositionsInBeats(p));
    _tapErrorsMs.clear();
    _nextExpectedIndex = 0;

    setState(() {
      _performTarget = p;
      _performFinished = false;
      _lastTapResult = null;
    });
  }

  Future<void> _startPerform() async {
    final p = _performTarget;
    if (p == null) return;
    if (_performRunning) return;

    _tapErrorsMs.clear();
    _nextExpectedIndex = 0;
    _metronomeTick = 0;
    _lastTapResult = null;

    // Start metronome and pattern timeline.
    final bpm = _performBpm.clamp(40, 220);
    final quarterMs = (60000 / bpm).round().clamp(150, 2000);
    final totalMs = (p.totalBeats * quarterMs).round().clamp(1, 600000);

    setState(() {
      _performRunning = true;
      _performFinished = false;
      _performStart = DateTime.now();
    });

    _startMetronomeTicks(quarterMs: quarterMs, beatsPerBar: _beatsPerBar(p.timeSignature));
    _performTimer?.cancel();
    _performTimer = Timer(Duration(milliseconds: totalMs + 120), _finishPerform);
  }

  void _startMetronomeTicks({required int quarterMs, required int beatsPerBar}) {
    _metronomeTimer?.cancel();
    _metronomeTimer = Timer.periodic(Duration(milliseconds: quarterMs), (t) {
      if (!_performRunning) return;
      final isDownbeat = beatsPerBar <= 0 ? _metronomeTick == 0 : (_metronomeTick % beatsPerBar == 0);
      final hz = isDownbeat ? 720.0 : 1320.0;
      unawaited(AudioEngineService().playFrequency(hz, durationSeconds: 0.030));
      _metronomeTick += 1;
    });
  }

  int _beatsPerBar(String ts) {
    final parts = ts.split('/');
    if (parts.length != 2) return 4;
    final n = int.tryParse(parts[0]);
    final d = int.tryParse(parts[1]);
    if (n == null || d == null || n <= 0 || d <= 0) return 4;
    final barQuarters = n * (4.0 / d);
    return barQuarters.round().clamp(1, 12);
  }

  void _stopPerform() {
    _performTimer?.cancel();
    _performTimer = null;
    _metronomeTimer?.cancel();
    _metronomeTimer = null;
    if (_performRunning || _performFinished) {
      setState(() {
        _performRunning = false;
      });
    }
  }

  void _finishPerform() {
    if (!mounted) return;
    if (!_performRunning) return;
    _metronomeTimer?.cancel();
    _metronomeTimer = null;

    final acc = _computePerformAccuracy();
    setState(() {
      _performRunning = false;
      _performFinished = true;
      _sessionPerformCount += 1;
      _sessionAccuracyAvg = _sessionPerformCount <= 1 ? acc : ((_sessionAccuracyAvg * (_sessionPerformCount - 1) + acc) / _sessionPerformCount);
    });

    final p = _performTarget;
    if (p != null) {
      unawaited(
        PracticeLogService.instance.addSession(
          focusArea: 'Rhythm Trainer',
          minutes: 1,
          notes: 'Perform: ${(acc * 100).round()}% — ${p.name} (${p.timeSignature})',
        ),
      );
    }
  }

  double _computePerformAccuracy() {
    // Accuracy is based on average absolute error for matched taps.
    // If user didn't tap, accuracy is 0.
    if (_tapErrorsMs.isEmpty) return 0;
    final absAvg = _tapErrorsMs.map((e) => e.abs()).reduce((a, b) => a + b) / _tapErrorsMs.length;
    // Convert to 0..1 with a soft knee: 0ms -> 1.0, 180ms -> ~0.
    final score = (1.0 - (absAvg / 180.0)).clamp(0.0, 1.0);
    return score;
  }

  void _onPerformTap() {
    if (!_performRunning) {
      // First tap starts.
      unawaited(_startPerform());
      return;
    }
    final p = _performTarget;
    if (p == null) return;
    if (_performStart == null) return;
    if (_nextExpectedIndex >= _expectedHitBeats.length) return;

    final bpm = _performBpm.clamp(40, 220);
    final quarterMs = 60000 / bpm;
    final now = DateTime.now();
    final elapsedMs = now.difference(_performStart!).inMilliseconds;

    // Compute expected time (ms) for the next hit.
    final expectedMs = (_expectedHitBeats[_nextExpectedIndex] * quarterMs).round();
    final errorMs = elapsedMs - expectedMs;

    // Windowing:
    // - “Perfect/Good”: within 80ms
    // - “Okay”: within 140ms
    // Otherwise, count as miss (still advance to avoid lock-up).
    final abs = errorMs.abs();
    final result = abs <= 80
        ? _TapResult.good
        : abs <= 140
            ? _TapResult.ok
            : _TapResult.miss;

    // Register tap
    _tapErrorsMs.add(errorMs);
    _nextExpectedIndex += 1;
    setState(() => _lastTapResult = result);

    // Quick decay of highlight.
    Future<void>.delayed(const Duration(milliseconds: 240), () {
      if (!mounted) return;
      if (!_performRunning) return;
      setState(() {
        if (_lastTapResult == result) _lastTapResult = null;
      });
    });

    // If we matched the last expected hit early, finish a bit after.
    if (_nextExpectedIndex >= _expectedHitBeats.length) {
      _performTimer?.cancel();
      _performTimer = Timer(const Duration(milliseconds: 260), _finishPerform);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final patterns = RhythmService.instance.patterns;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Rhythm Trainer'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Learn'),
            Tab(text: 'Recognize'),
            Tab(text: 'Perform'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabs,
          children: [
            // Learn (MVP) — kept as-is except for being one tab among three.
            ResponsiveCentered(
              child: Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 24),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    final useGrid = w >= 900;
                    if (useGrid) {
                      final crossAxisCount = w >= 1200 ? 3 : 2;
                      return GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1.25,
                        ),
                        itemCount: patterns.length,
                        itemBuilder: (context, i) {
                          final p = patterns[i];
                          return RhythmPatternCard(
                            pattern: p,
                            isPlaying: _isPlaying && _playingId == p.id,
                            anyPlaying: _isPlaying,
                            onPlay: () => _play(p),
                          );
                        },
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: patterns.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, i) {
                        final p = patterns[i];
                        return RhythmPatternCard(
                          pattern: p,
                          isPlaying: _isPlaying && _playingId == p.id,
                          anyPlaying: _isPlaying,
                          onPlay: () => _play(p),
                        );
                      },
                    );
                  },
                ),
              ),
            ),

            // Recognize
            ResponsiveCentered(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: _RecognizeMode(
                  target: _recognizeTarget,
                  options: _recognizeOptions,
                  isPlaying: _isPlaying,
                  locked: _recognizeLocked,
                  selectedIndex: _recognizeSelectedIndex,
                  wasCorrect: _recognizeWasCorrect,
                  feedback: _recognizeFeedback,
                  correct: _recognizeCorrect,
                  total: _recognizeTotal,
                  onReplay: _playRecognizePrompt,
                  onSelect: _selectRecognizeOption,
                  onNext: _nextRecognizeRound,
                ),
              ),
            ),

            // Perform
            ResponsiveCentered(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: _PerformMode(
                  target: _performTarget,
                  bpm: _performBpm,
                  running: _performRunning,
                  finished: _performFinished,
                  lastTapResult: _lastTapResult,
                  sessionAvgAccuracy: _sessionAccuracyAvg,
                  onTap: _onPerformTap,
                  onRepeat: () {
                    final t = _performTarget;
                    if (t != null) _setPerformTarget(t);
                    unawaited(_startPerform());
                  },
                  onNew: () {
                    _pickPerformTarget();
                    unawaited(_startPerform());
                  },
                  onStop: _stopPerform,
                  computeAccuracy: _computePerformAccuracy,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecognizeMode extends StatelessWidget {
  final RhythmPattern? target;
  final List<RhythmPattern> options;
  final bool isPlaying;
  final bool locked;
  final int? selectedIndex;
  final bool? wasCorrect;
  final String? feedback;
  final int correct;
  final int total;
  final Future<void> Function() onReplay;
  final Future<void> Function(int) onSelect;
  final Future<void> Function() onNext;

  const _RecognizeMode({
    required this.target,
    required this.options,
    required this.isPlaying,
    required this.locked,
    required this.selectedIndex,
    required this.wasCorrect,
    required this.feedback,
    required this.correct,
    required this.total,
    required this.onReplay,
    required this.onSelect,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = target;
    final scorePct = total <= 0 ? 0 : ((correct / total) * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ModeHeader(
          title: 'Recognize',
          subtitle: 'Hear a rhythm. Pick the matching notation.',
          trailing: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _StatPill(icon: Icons.auto_graph_rounded, label: 'Score $scorePct%'),
              _StatPill(icon: Icons.quiz_rounded, label: '$correct/$total'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Prompt',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.2),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: isPlaying || t == null ? null : () => onReplay(),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(isPlaying ? 'Playing…' : 'Replay'),
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.onSurface,
                      foregroundColor: theme.colorScheme.surface,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Listen, then choose the matching rhythm block below.',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final useGrid = w >= 900;
              if (useGrid) {
                final crossAxisCount = w >= 1200 ? 3 : 2;
                return GridView.builder(
                  itemCount: options.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.35,
                  ),
                  itemBuilder: (context, i) {
                    return _RecognizeOptionCard(
                      pattern: options[i],
                      locked: locked,
                      isSelected: selectedIndex == i,
                      revealCorrect: locked,
                      isCorrect: t != null && options[i].id == t.id,
                      onTap: () => onSelect(i),
                    );
                  },
                );
              }
              return ListView.separated(
                itemCount: options.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  return _RecognizeOptionCard(
                    pattern: options[i],
                    locked: locked,
                    isSelected: selectedIndex == i,
                    revealCorrect: locked,
                    isCorrect: t != null && options[i].id == t.id,
                    onTap: () => onSelect(i),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: feedback == null
              ? const SizedBox.shrink()
              : _FeedbackBanner(text: feedback!, positive: wasCorrect == true),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: locked ? () => onNext() : null,
                icon: const Icon(Icons.skip_next_rounded),
                label: const Text('Next'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RecognizeOptionCard extends StatelessWidget {
  final RhythmPattern pattern;
  final bool locked;
  final bool isSelected;
  final bool revealCorrect;
  final bool isCorrect;
  final VoidCallback onTap;

  const _RecognizeOptionCard({
    required this.pattern,
    required this.locked,
    required this.isSelected,
    required this.revealCorrect,
    required this.isCorrect,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final baseBorder = theme.dividerColor;
    final correctBorder = theme.colorScheme.tertiary.withValues(alpha: 0.95);
    final wrongBorder = theme.colorScheme.error.withValues(alpha: 0.70);
    final borderColor = revealCorrect
        ? (isCorrect ? correctBorder : (isSelected ? wrongBorder : baseBorder))
        : (isSelected ? theme.colorScheme.tertiary.withValues(alpha: 0.65) : baseBorder);

    final bg = theme.cardTheme.color;
    final overlay = revealCorrect && isCorrect
        ? theme.colorScheme.tertiary.withValues(alpha: 0.08)
        : (revealCorrect && isSelected && !isCorrect)
            ? theme.colorScheme.error.withValues(alpha: 0.08)
            : Colors.transparent;

    return InkWell(
      onTap: locked ? null : onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      splashFactory: NoSplash.splashFactory,
      hoverColor: theme.colorScheme.tertiary.withValues(alpha: 0.05),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: borderColor),
          gradient: overlay == Colors.transparent
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [overlay, Colors.transparent],
                ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    pattern.timeSignature,
                    style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700, color: theme.colorScheme.secondary),
                  ),
                ),
                if (revealCorrect)
                  Icon(
                    isCorrect
                        ? Icons.check_circle_rounded
                        : (isSelected ? Icons.cancel_rounded : Icons.circle_outlined),
                    size: 18,
                    color: isCorrect
                        ? theme.colorScheme.tertiary
                        : (isSelected ? theme.colorScheme.error : theme.colorScheme.secondary),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(child: RhythmNotationBar(pattern: pattern)),
          ],
        ),
      ),
    );
  }
}

class _PerformMode extends StatelessWidget {
  final RhythmPattern? target;
  final int bpm;
  final bool running;
  final bool finished;
  final _TapResult? lastTapResult;
  final double sessionAvgAccuracy;
  final VoidCallback onTap;
  final VoidCallback onRepeat;
  final VoidCallback onNew;
  final VoidCallback onStop;
  final double Function() computeAccuracy;

  const _PerformMode({
    required this.target,
    required this.bpm,
    required this.running,
    required this.finished,
    required this.lastTapResult,
    required this.sessionAvgAccuracy,
    required this.onTap,
    required this.onRepeat,
    required this.onNew,
    required this.onStop,
    required this.computeAccuracy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = target;
    final acc = computeAccuracy();

    Color tapGlow;
    switch (lastTapResult) {
      case _TapResult.good:
        tapGlow = theme.colorScheme.tertiary.withValues(alpha: 0.28);
        break;
      case _TapResult.ok:
        tapGlow = theme.colorScheme.tertiary.withValues(alpha: 0.14);
        break;
      case _TapResult.miss:
        tapGlow = theme.colorScheme.error.withValues(alpha: 0.22);
        break;
      default:
        tapGlow = Colors.transparent;
    }

    final sessionPct = (sessionAvgAccuracy * 100).round();
    final currentPct = (acc * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ModeHeader(
          title: 'Perform',
          subtitle: 'Tap the pattern in time. First tap starts the metronome.',
          trailing: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _StatPill(icon: Icons.av_timer_rounded, label: '$bpm BPM'),
              _StatPill(icon: Icons.stacked_line_chart_rounded, label: 'Session $sessionPct%'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (p != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        p.name,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                    _StatPill(icon: Icons.music_note_rounded, label: p.timeSignature),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(height: 74, child: RhythmNotationBar(pattern: p)),
              ],
            ),
          )
        else
          _EmptyStateCard(title: 'No patterns found', subtitle: 'Add patterns to the offline repository to begin.'),
        const SizedBox(height: 14),
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: theme.dividerColor),
              gradient: tapGlow == Colors.transparent
                  ? null
                  : LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [tapGlow, Colors.transparent],
                    ),
            ),
            child: InkWell(
              onTap: p == null ? null : onTap,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              splashFactory: NoSplash.splashFactory,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      running ? Icons.touch_app_rounded : (finished ? Icons.check_circle_rounded : Icons.play_arrow_rounded),
                      size: 40,
                      color: running
                          ? theme.colorScheme.tertiary
                          : (finished ? theme.colorScheme.tertiary : theme.colorScheme.secondary),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      running ? 'Tap in time' : (finished ? 'Completed' : 'Tap to start'),
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      running
                          ? 'Green = good timing • Red = early/late'
                          : (finished ? 'Accuracy: $currentPct%' : 'Metronome starts automatically'),
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary, height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (running)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onStop,
                  icon: const Icon(Icons.stop_rounded),
                  label: const Text('Stop'),
                ),
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: finished && p != null ? onRepeat : null,
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('Repeat'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: p == null ? null : onNew,
                  icon: const Icon(Icons.shuffle_rounded),
                  label: const Text('New'),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.onSurface,
                    foregroundColor: theme.colorScheme.surface,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _ModeHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget trailing;

  const _ModeHeader({required this.title, required this.subtitle, required this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 0.2)),
              const SizedBox(height: 4),
              Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary, height: 1.5)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        trailing,
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.tertiary),
          const SizedBox(width: 6),
          Text(label, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  final String text;
  final bool positive;
  const _FeedbackBanner({required this.text, required this.positive});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = positive ? theme.colorScheme.tertiary : theme.colorScheme.error;
    return Container(
      key: ValueKey(text),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: c.withValues(alpha: 0.55)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(positive ? Icons.check_circle_rounded : Icons.cancel_rounded, size: 18, color: c),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: theme.textTheme.bodySmall?.copyWith(height: 1.5))),
        ],
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final String title;
  final String subtitle;
  const _EmptyStateCard({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary, height: 1.5)),
        ],
      ),
    );
  }
}

enum _TapResult { good, ok, miss }

/// Premium rhythm card for the Learn catalog.
class RhythmPatternCard extends StatelessWidget {
  final RhythmPattern pattern;
  final bool isPlaying;
  final bool anyPlaying;
  final VoidCallback onPlay;

  const RhythmPatternCard({
    super.key,
    required this.pattern,
    required this.isPlaying,
    required this.anyPlaying,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(color: theme.shadowColor.withValues(alpha: 0.10), blurRadius: 10, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pattern.name,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.2),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _MetaPill(icon: Icons.av_timer_rounded, label: pattern.timeSignature),
                        _MetaPill(icon: Icons.auto_graph_rounded, label: 'Lvl ${pattern.difficulty}'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: anyPlaying && !isPlaying ? null : onPlay,
                icon: Icon(isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded),
                label: Text(isPlaying ? 'Playing…' : 'Play'),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.onSurface,
                  foregroundColor: theme.colorScheme.surface,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          RhythmNotationBar(pattern: pattern),
          const SizedBox(height: 12),
          Text(
            pattern.description,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.tertiary),
          const SizedBox(width: 6),
          Text(label, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Simple, elegant rhythm visualization (no heavy notation libraries).
///
/// Draws proportional duration blocks with a subtle downbeat accent marker.
class RhythmNotationBar extends StatelessWidget {
  final RhythmPattern pattern;
  const RhythmNotationBar({super.key, required this.pattern});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: theme.dividerColor),
      ),
      child: CustomPaint(
        painter: _RhythmPainter(
          pattern: pattern,
          divider: theme.dividerColor,
          onyx: theme.colorScheme.onSurface,
          accent: theme.colorScheme.tertiary,
          muted: theme.colorScheme.secondary,
        ),
      ),
    );
  }
}

class _RhythmPainter extends CustomPainter {
  final RhythmPattern pattern;
  final Color divider;
  final Color onyx;
  final Color accent;
  final Color muted;

  const _RhythmPainter({
    required this.pattern,
    required this.divider,
    required this.onyx,
    required this.accent,
    required this.muted,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = pattern.totalBeats;
    if (total <= 0.001) return;

    final barRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final r = RRect.fromRectAndRadius(barRect, const Radius.circular(10));
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = divider.withValues(alpha: 0.9);
    canvas.drawRRect(r, borderPaint);

    final fillPaint = Paint()..style = PaintingStyle.fill;
    final gap = 6.0;
    final inner = Rect.fromLTWH(8, 10, size.width - 16, size.height - 20);

    // Beat grid (subtle)
    final beatsPerBar = _beatsPerBar(pattern.timeSignature);
    if (beatsPerBar > 0) {
      final gridPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = divider.withValues(alpha: 0.45);
      for (int b = 1; b < beatsPerBar; b++) {
        final x = inner.left + inner.width * (b / beatsPerBar);
        canvas.drawLine(Offset(x, inner.top), Offset(x, inner.bottom), gridPaint);
      }
    }

    // Duration blocks
    double cursor = inner.left;
    final usableW = inner.width - gap * (pattern.pattern.length - 1);
    final y = inner.top;
    final h = inner.height;
    for (int i = 0; i < pattern.pattern.length; i++) {
      final beats = pattern.pattern[i].clamp(0.01, 32.0);
      final w = usableW * (beats / total);
      final rect = Rect.fromLTWH(cursor, y, w, h);
      final isDownbeat = i == 0;
      fillPaint.color = isDownbeat ? accent.withValues(alpha: 0.85) : onyx.withValues(alpha: 0.22);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), fillPaint);

      // Tiny “attack” notch
      final notchPaint = Paint()..color = (isDownbeat ? accent : muted).withValues(alpha: 0.9);
      canvas.drawCircle(Offset(rect.left + 6, rect.center.dy), 2.2, notchPaint);

      cursor += w + gap;
    }
  }

  int _beatsPerBar(String ts) {
    final parts = ts.split('/');
    if (parts.length != 2) return 4;
    final n = int.tryParse(parts[0]);
    final d = int.tryParse(parts[1]);
    if (n == null || d == null || n <= 0 || d <= 0) return 4;
    final barQuarters = n * (4.0 / d);
    return barQuarters.round().clamp(1, 12);
  }

  @override
  bool shouldRepaint(covariant _RhythmPainter oldDelegate) {
    return oldDelegate.pattern.id != pattern.id || oldDelegate.divider != divider || oldDelegate.accent != accent || oldDelegate.onyx != onyx;
  }
}
