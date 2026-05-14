import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show BlurStyle, MaskFilter, lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:musicbyteai/services/audio_engine_service.dart';
import 'package:musicbyteai/services/practice_log_service.dart';
import 'package:musicbyteai/theme.dart';

enum StaffClef { treble, bass }
enum _RoundOutcome { none, zap, miss }

class NoteAssaultPage extends StatefulWidget {
  const NoteAssaultPage({super.key});

  @override
  State<NoteAssaultPage> createState() => _NoteAssaultPageState();
}

class _NoteAssaultPageState extends State<NoteAssaultPage> with TickerProviderStateMixin, WidgetsBindingObserver {
  static const int _maxLives = 3;
  static const Duration _baseRoundDuration = Duration(milliseconds: 4200);
  static const Duration _minRoundDuration = Duration(milliseconds: 1850);
  static const int _speedUpEveryStreak = 5;
  static const int _maxLevel = 9;
  static const Duration _zapAnimDuration = Duration(milliseconds: 320);
  static const Duration _missAnimDuration = Duration(milliseconds: 380);

  final _rng = math.Random();

  late final AnimationController _travel;
  late final AnimationController _fx;

  StaffClef _clef = StaffClef.treble;
  bool _started = false;
  bool _paused = false;
  bool _gameOver = false;

  int _score = 0;
  int _lives = _maxLives;

  int _streak = 0;
  int _level = 1;

  _FlyingNote? _current;
  _RoundOutcome _outcome = _RoundOutcome.none;

  // Practice-session timing (exclude pause time)
  DateTime? _activeStart;
  Duration _activeAccum = Duration.zero;

  bool _loggedThisRun = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _travel = AnimationController(vsync: this, duration: _durationForLevel(1))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _handleTimeoutMiss();
        }
      });

    _fx = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _travel.dispose();
    _fx.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (_started && !_gameOver) _pause();
    }
  }

  void _startOrRestart() {
    setState(() {
      _started = true;
      _paused = false;
      _gameOver = false;
      _score = 0;
      _lives = _maxLives;
      _streak = 0;
      _level = 1;
      _loggedThisRun = false;
      _activeAccum = Duration.zero;
      _activeStart = DateTime.now();
    });
    _spawnNextRound();
  }

  Duration _durationForLevel(int level) {
    final lvl = level.clamp(1, _maxLevel);
    final ms = (_baseRoundDuration.inMilliseconds - ((lvl - 1) * 260)).clamp(
      _minRoundDuration.inMilliseconds,
      _baseRoundDuration.inMilliseconds,
    );
    return Duration(milliseconds: ms);
  }

  void _bumpLevelIfNeeded() {
    if (_streak <= 0) return;
    if (_streak % _speedUpEveryStreak != 0) return;
    if (_level >= _maxLevel) return;
    setState(() => _level += 1);
  }

  void _pause() {
    if (!_started || _paused || _gameOver) return;
    _accumulateActiveTime();
    setState(() => _paused = true);
    _travel.stop(canceled: false);
  }

  void _resume() {
    if (!_started || !_paused || _gameOver) return;
    setState(() {
      _paused = false;
      _activeStart = DateTime.now();
    });
    _travel.forward();
  }

  void _accumulateActiveTime() {
    final start = _activeStart;
    if (start == null) return;
    _activeAccum += DateTime.now().difference(start);
    _activeStart = null;
  }

  Future<void> _logPracticeIfNeeded() async {
    if (_loggedThisRun) return;
    _loggedThisRun = true;

    try {
      _accumulateActiveTime();
      final seconds = _activeAccum.inSeconds;
      final minutes = seconds <= 0 ? 1 : ((seconds / 60).round().clamp(1, 100000));
      final notes = 'Score: $_score\nClef: ${_clef == StaffClef.treble ? 'Treble' : 'Bass'}\nMode: Note name identification (offline).';
      await PracticeLogService.instance.addSession(focusArea: 'Note Assault', minutes: minutes, notes: notes);
    } catch (e) {
      debugPrint('NoteAssault: failed to log practice session: $e');
    }
  }

  void _spawnNextRound() {
    if (!_started || _gameOver) return;
    if (_paused) return;

    // Progressive speed ramp: tie travel duration to current level.
    _travel.duration = _durationForLevel(_level);

    final next = _FlyingNote.randomForClef(_clef, _rng);
    setState(() {
      _current = next;
      _outcome = _RoundOutcome.none;
    });
    _travel
      ..reset()
      ..forward();
  }

  void _setClef(StaffClef next) {
    if (_clef == next) return;
    setState(() => _clef = next);
    if (_started && !_gameOver) {
      // Keep it simple: restart the current round immediately with a note valid for the new clef.
      if (!_paused) _spawnNextRound();
    }
  }

  Future<void> _answer(String letter) async {
    if (!_started || _paused || _gameOver) return;
    final note = _current;
    if (note == null) return;

    if (letter == note.letter) {
      _travel.stop(canceled: false);
      setState(() {
        _score += 1;
        _streak += 1;
        _outcome = _RoundOutcome.zap;
      });

      _bumpLevelIfNeeded();

      try {
        final engine = AudioEngineService();
        await engine.playNote(note.letter, note.octave, durationSeconds: 0.55);
        final err = engine.consumeLastError();
        if (err != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Audio playback failed.')));
        }
      } catch (e) {
        debugPrint('NoteAssault: playNote failed: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Audio playback failed.')));
        }
      }

      await _playFx(_RoundOutcome.zap);
      if (!mounted) return;
      _spawnNextRound();
      return;
    }

    await _registerMiss(reason: 'wrong');
  }

  void _handleTimeoutMiss() {
    if (!_started || _paused || _gameOver) return;
    // Note reached the clef (left side).
    unawaited(_registerMiss(reason: 'timeout'));
  }

  Future<void> _registerMiss({required String reason}) async {
    if (!_started || _paused || _gameOver) return;
    _travel.stop(canceled: false);

    setState(() {
      _lives = (_lives - 1).clamp(0, _maxLives);
      _streak = 0;
      _outcome = _RoundOutcome.miss;
    });
    debugPrint('NoteAssault: miss ($reason). lives=$_lives');
    await _playFx(_RoundOutcome.miss);
    if (!mounted) return;

    if (_lives <= 0) {
      await _endGame();
      return;
    }

    _spawnNextRound();
  }

  Future<void> _endGame() async {
    if (_gameOver) return;
    setState(() {
      _gameOver = true;
      _paused = false;
    });
    try {
      _travel.stop();
    } catch (_) {}
    await _logPracticeIfNeeded();
  }

  Future<void> _playFx(_RoundOutcome outcome) async {
    try {
      _fx.stop();
      _fx.duration = outcome == _RoundOutcome.zap ? _zapAnimDuration : _missAnimDuration;
      _fx.reset();
      await _fx.forward();
    } catch (e) {
      debugPrint('NoteAssault: fx animation failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final on = theme.colorScheme.onSurface;
    final interval = theme.extension<IntervalColors>();
    final accent = interval?.root ?? theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () {
            if (_started && !_gameOver) {
              _pause();
            }
            context.pop();
          },
          icon: Icon(Icons.arrow_back_rounded, color: on),
        ),
        title: Text('Note Assault', style: theme.textTheme.titleMedium?.copyWith(color: on)),
        centerTitle: true,
        actions: [
          _ClefToggle(value: _clef, onChanged: _setClef),
          const SizedBox(width: 6),
          IconButton(
            tooltip: _paused ? 'Resume' : 'Pause',
            onPressed: !_started || _gameOver
                ? null
                : _paused
                    ? _resume
                    : _pause,
            icon: Icon(_paused ? Icons.play_arrow_rounded : Icons.pause_rounded, color: on),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                _TopHud(
                  score: _score,
                  lives: _lives,
                  paused: _paused,
                  started: _started,
                  level: _level,
                  streak: _streak,
                  accent: accent,
                ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              theme.cardTheme.color ?? theme.colorScheme.surface,
                              theme.scaffoldBackgroundColor,
                              (theme.cardTheme.color ?? theme.colorScheme.surface).withValues(alpha: 0.92),
                            ],
                            stops: const [0.0, 0.55, 1.0],
                          ),
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        child: _GameStage(
                          clef: _clef,
                          travel: _travel,
                          fx: _fx,
                          note: _current,
                          outcome: _outcome,
                          dim: _paused || !_started,
                            accent: accent,
                        ),
                      ),
                    ),
                    if (!_started)
                      Positioned.fill(
                        child: _StartOverlay(
                          onStart: _startOrRestart,
                          title: 'Staff Wars style note reading — offline',
                          subtitle: 'Tap the letter before the note reaches the clef.',
                        ),
                      ),
                    if (_started && _paused && !_gameOver)
                      Positioned.fill(
                        child: _PausedOverlay(
                          onResume: _resume,
                          onRestart: _startOrRestart,
                        ),
                      ),
                    if (_started && _gameOver)
                      Positioned.fill(
                        child: _GameOverOverlay(score: _score, onRestart: _startOrRestart),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _AnswerPad(
                enabled: _started && !_paused && !_gameOver,
                onTap: _answer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopHud extends StatelessWidget {
  final int score;
  final int lives;
  final bool paused;
  final bool started;
  final int level;
  final int streak;
  final Color accent;
  const _TopHud({
    required this.score,
    required this.lives,
    required this.paused,
    required this.started,
    required this.level,
    required this.streak,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pillBg = theme.cardTheme.color;

    Widget comboPill() => AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: FadeTransition(opacity: anim, child: child)),
          child: (started && !paused && streak >= 3)
              ? _HudPill(
                  key: ValueKey('combo_$streak'),
                  icon: Icons.local_fire_department_rounded,
                  label: 'Combo',
                  value: 'x$streak',
                  iconColor: accent,
                )
              : const SizedBox.shrink(key: ValueKey('combo_off')),
        );

    Widget pausedBadge() => AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: SizeTransition(sizeFactor: anim, axis: Axis.horizontal, child: child)),
          child: (started && paused)
              ? Container(
                  key: const ValueKey('paused_on'),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: pillBg,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.pause_circle_rounded, size: 18, color: theme.colorScheme.secondary),
                      const SizedBox(width: 6),
                      Text('Paused', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.secondary)),
                    ],
                  ),
                )
              : const SizedBox.shrink(key: ValueKey('paused_off')),
        );

    return LayoutBuilder(
      builder: (context, c) {
        final compact = c.maxWidth < 520;
        final livesValue = '•' * lives + ' ' + '•' * (3 - lives);

        final pills = <Widget>[
          _HudPill(icon: Icons.bolt_rounded, label: 'Score', value: score.toString(), iconColor: accent),
          _HudPill(
            icon: Icons.favorite_rounded,
            label: 'Lives',
            value: livesValue,
            valueStyle: theme.textTheme.labelLarge?.copyWith(
              color: lives <= 1 ? theme.colorScheme.error : theme.colorScheme.onSurface,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          _HudPill(icon: Icons.speed_rounded, label: 'Level', value: level.toString(), iconColor: accent),
          comboPill(),
          pausedBadge(),
        ];

        if (compact) {
          return Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: pills,
          );
        }

        return Row(
          children: [
            ...pills.take(3).expand((w) sync* {
              yield w;
              yield const SizedBox(width: AppSpacing.sm);
            }),
            comboPill(),
            const SizedBox(width: AppSpacing.sm),
            pausedBadge(),
          ],
        );
      },
    );
  }
}

class _HudPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final TextStyle? valueStyle;
  final Color? iconColor;

  const _HudPill({super.key, required this.icon, required this.label, required this.value, this.valueStyle, this.iconColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: iconColor ?? theme.colorScheme.tertiary),
          const SizedBox(width: 8),
          Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary)),
          const SizedBox(width: 8),
          Text(value, style: valueStyle ?? theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _ClefToggle extends StatelessWidget {
  final StaffClef value;
  final ValueChanged<StaffClef> onChanged;
  const _ClefToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ClefChip(
            selected: value == StaffClef.treble,
            label: 'Treble',
            glyph: '𝄞',
            onTap: () => onChanged(StaffClef.treble),
          ),
          _ClefChip(
            selected: value == StaffClef.bass,
            label: 'Bass',
            glyph: '𝄢',
            onTap: () => onChanged(StaffClef.bass),
          ),
        ],
      ),
    );
  }
}

class _ClefChip extends StatelessWidget {
  final bool selected;
  final String label;
  final String glyph;
  final VoidCallback onTap;
  const _ClefChip({required this.selected, required this.label, required this.glyph, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.full),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.primary.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(glyph, style: theme.textTheme.labelLarge?.copyWith(color: selected ? theme.colorScheme.primary : theme.colorScheme.secondary)),
            const SizedBox(width: 6),
            Text(label, style: theme.textTheme.labelMedium?.copyWith(color: selected ? theme.colorScheme.onSurface : theme.colorScheme.secondary, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _GameStage extends StatelessWidget {
  final StaffClef clef;
  final Animation<double> travel;
  final Animation<double> fx;
  final _FlyingNote? note;
  final _RoundOutcome outcome;
  final bool dim;
  final Color accent;

  const _GameStage({
    required this.clef,
    required this.travel,
    required this.fx,
    required this.note,
    required this.outcome,
    required this.dim,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final stagePad = math.min(26.0, w * 0.06);
        final staffHeight = (h * 0.62).clamp(180.0, 320.0);
        final top = (h - staffHeight) / 2;

        return AnimatedBuilder(
          animation: fx,
          builder: (context, child) {
            final fxT = fx.value;
            final shake = outcome == _RoundOutcome.miss ? (1 - fxT) : 0.0;
            final dx = shake <= 0 ? 0.0 : math.sin(fxT * math.pi * 10) * 6.0 * shake;
            final flashA = outcome == _RoundOutcome.zap ? (0.20 * (1 - fxT)) : 0.0;
            final missA = outcome == _RoundOutcome.miss ? (0.18 * (1 - fxT)) : 0.0;

            return Transform.translate(
              offset: Offset(dx, 0),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 180),
                      opacity: dim ? 0.55 : 1.0,
                      child: CustomPaint(painter: _StaffPainter(clef: clef, accent: accent)),
                    ),
                  ),
                  if (flashA > 0)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(color: accent.withValues(alpha: flashA)),
                      ),
                    ),
                  if (missA > 0)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(color: theme.colorScheme.error.withValues(alpha: missA)),
                      ),
                    ),
                  if (note != null)
                    AnimatedBuilder(
                      animation: Listenable.merge([travel, fx]),
                      builder: (context, _) {
                        // Right -> Left (1.0..0.0)
                        final t = travel.value;
                        final x = lerpDouble(w + stagePad, stagePad, t) ?? stagePad;
                        final y = top + (staffHeight * note!.yFrac);
                        final dying = outcome != _RoundOutcome.none;
                        final fxT2 = fx.value;

                        final scale = outcome == _RoundOutcome.zap
                            ? (1.0 + 0.22 * (1 - fxT2))
                            : outcome == _RoundOutcome.miss
                                ? (1.0 - 0.10 * fxT2)
                                : 1.0;
                        final opacity = !dying
                            ? 1.0
                            : outcome == _RoundOutcome.zap
                                ? (1.0 - fxT2).clamp(0.0, 1.0)
                                : (1.0 - fxT2 * 0.75).clamp(0.0, 1.0);

                        return Positioned(
                          left: x - 26,
                          top: y - 26,
                          child: IgnorePointer(
                            child: Opacity(
                              opacity: opacity,
                              child: Transform.scale(
                                scale: scale,
                                child: _NoteWithFx(
                                  note: note!,
                                  outcome: outcome,
                                  fxT: fxT2,
                                  accent: accent,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  Positioned(
                    left: stagePad,
                    top: 0,
                    bottom: 0,
                    child: Center(child: _ClefMarker(clef: clef)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _NoteWithFx extends StatelessWidget {
  final _FlyingNote note;
  final _RoundOutcome outcome;
  final double fxT;
  final Color accent;

  const _NoteWithFx({required this.note, required this.outcome, required this.fxT, required this.accent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = theme.colorScheme.onSurface;

    return CustomPaint(
      size: const Size(52, 52),
      painter: _NotePainter(
        ink: ink,
        accent: accent,
        error: theme.colorScheme.error,
        outcome: outcome,
        fxT: fxT,
      ),
    );
  }
}

class _AnswerPad extends StatelessWidget {
  final bool enabled;
  final ValueChanged<String> onTap;
  const _AnswerPad({required this.enabled, required this.onTap});

  static const _letters = ['A', 'B', 'C', 'D', 'E', 'F', 'G'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: theme.dividerColor),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final compact = c.maxWidth < 420;
          final children = _letters
              .map((l) => _LetterButton(
                    letter: l,
                    enabled: enabled,
                    onTap: () => onTap(l),
                  ))
              .toList();
          if (compact) {
            return Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: children);
          }
          return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: children);
        },
      ),
    );
  }
}

class _LetterButton extends StatelessWidget {
  final String letter;
  final bool enabled;
  final VoidCallback onTap;
  const _LetterButton({required this.letter, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = enabled ? theme.colorScheme.tertiary : theme.dividerColor;
    final fg = enabled ? theme.colorScheme.surface : theme.colorScheme.secondary;
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(AppRadius.full),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Text(
          letter,
          style: theme.textTheme.titleMedium?.copyWith(color: fg, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _ClefMarker extends StatelessWidget {
  final StaffClef clef;
  const _ClefMarker({required this.clef});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = clef == StaffClef.treble ? '𝄞' : '𝄢';
    return Container(
      width: 46,
      height: 140,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Text(
        label,
        style: theme.textTheme.headlineMedium?.copyWith(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StartOverlay extends StatelessWidget {
  final VoidCallback onStart;
  final String title;
  final String subtitle;
  const _StartOverlay({required this.onStart, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.scaffoldBackgroundColor.withValues(alpha: 0.55),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Note Assault', style: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(title, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary)),
              const SizedBox(height: 8),
              Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary)),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('START'),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.onSurface,
                  foregroundColor: theme.colorScheme.surface,
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PausedOverlay extends StatelessWidget {
  final VoidCallback onResume;
  final VoidCallback onRestart;
  const _PausedOverlay({required this.onResume, required this.onRestart});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.scaffoldBackgroundColor.withValues(alpha: 0.55),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.pause_circle_filled_rounded, color: theme.colorScheme.secondary),
                  const SizedBox(width: 8),
                  Text('Paused', style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onResume,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('RESUME'),
                style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.onSurface, foregroundColor: theme.colorScheme.surface, minimumSize: const Size(double.infinity, 48)),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: onRestart,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('RESTART'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameOverOverlay extends StatelessWidget {
  final int score;
  final VoidCallback onRestart;
  const _GameOverOverlay({required this.score, required this.onRestart});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.scaffoldBackgroundColor.withValues(alpha: 0.60),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Game Over', style: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text('Final Score', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary)),
              const SizedBox(height: 6),
              Text(score.toString(), style: theme.textTheme.headlineLarge?.copyWith(color: theme.colorScheme.tertiary, fontWeight: FontWeight.w900)),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: onRestart,
                icon: const Icon(Icons.replay_rounded),
                label: const Text('PLAY AGAIN'),
                style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.onSurface, foregroundColor: theme.colorScheme.surface, minimumSize: const Size(double.infinity, 48)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StaffPainter extends CustomPainter {
  final StaffClef clef;
  final Color accent;
  _StaffPainter({required this.clef, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    // Use a subtle line that reads well in the app's premium dark aesthetic.
    final staffColor = const Color(0xFFFFFFFF).withValues(alpha: 0.10);
    final staffInk = Paint()
      ..color = staffColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final midY = size.height / 2;
    final staffHeight = (size.height * 0.62).clamp(180.0, 320.0);
    final top = midY - staffHeight / 2;
    final left = 18.0;
    final right = size.width - 18.0;
    final lineGap = staffHeight / 8; // 5 lines -> 4 gaps, keep generous spacing

    // 5 staff lines
    for (int i = 0; i < 5; i++) {
      final y = top + (i + 2) * lineGap; // center within staffHeight
      canvas.drawLine(Offset(left, y), Offset(right, y), staffInk);
    }

    // Light vertical guide at the clef side
    final clefX = left + 42;
    final guidePaint = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.06)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(clefX, top + 1.2 * lineGap), Offset(clefX, top + 6.8 * lineGap), guidePaint);

    // Subtle gradient haze behind staff for depth
    final hazeRect = Rect.fromLTWH(0, top, size.width, staffHeight);
    final haze = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          accent.withValues(alpha: 0.08),
          const Color(0xFFFFFFFF).withValues(alpha: 0.015),
          accent.withValues(alpha: 0.06),
        ],
      ).createShader(hazeRect);
    canvas.drawRect(hazeRect, haze);
  }

  @override
  bool shouldRepaint(covariant _StaffPainter oldDelegate) => oldDelegate.clef != clef || oldDelegate.accent != accent;
}

class _NotePainter extends CustomPainter {
  final Color ink;
  final Color accent;
  final Color error;
  final _RoundOutcome outcome;
  final double fxT;

  _NotePainter({required this.ink, required this.accent, required this.error, required this.outcome, required this.fxT});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final headRect = Rect.fromCenter(center: center, width: 28, height: 20);

    // Soft glow halo for the active note.
    final glowAlpha = outcome == _RoundOutcome.miss ? 0.04 : 0.22;
    final glow = Paint()
      ..color = accent.withValues(alpha: glowAlpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(center, 18, glow);

    // Outer highlight ring for clarity.
    final ring = Paint()
      ..color = accent.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawCircle(center, 18.5, ring);

    final base = Paint()..color = ink;

    // Note head (filled)
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-0.25);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawOval(headRect, base);
    canvas.restore();

    // Stem (simple)
    final stemPaint = Paint()
      ..color = ink
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(center.dx + 12, center.dy - 6), Offset(center.dx + 12, center.dy - 30), stemPaint);

    if (outcome == _RoundOutcome.zap) {
      final flash = Paint()
        ..color = accent.withValues(alpha: (0.65 * (1 - fxT)).clamp(0.0, 0.65))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
      canvas.drawCircle(center, 22 + 8 * fxT, flash);

      final zapStroke = Paint()
        ..color = accent.withValues(alpha: (1.0 - fxT).clamp(0.0, 1.0))
        ..strokeWidth = 2.4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      // Electric arcs + particle bursts (deterministic, no RNG).
      for (int i = 0; i < 6; i++) {
        final a = (i / 6) * math.pi * 2 + fxT * 4.6;
        final r = 18 + i * 1.8;
        final p1 = center + Offset(math.cos(a) * r, math.sin(a) * r);
        final p2 = center + Offset(math.cos(a + 0.9) * (r - 7), math.sin(a + 0.9) * (r - 7));
        final mid = (p1 + p2) / 2 + Offset(math.sin(a) * 5, -math.cos(a) * 5);
        final path = Path()..moveTo(p1.dx, p1.dy)..quadraticBezierTo(mid.dx, mid.dy, p2.dx, p2.dy);
        canvas.drawPath(path, zapStroke);
      }

      final burst = Paint()
        ..color = accent.withValues(alpha: (0.85 * (1 - fxT)).clamp(0.0, 0.85))
        ..strokeWidth = 1.9
        ..strokeCap = StrokeCap.round;
      for (int i = 0; i < 14; i++) {
        final a = (i / 14) * math.pi * 2;
        final r1 = 10 + 10 * fxT;
        final r2 = 18 + 26 * fxT;
        canvas.drawLine(
          center + Offset(math.cos(a) * r1, math.sin(a) * r1),
          center + Offset(math.cos(a) * r2, math.sin(a) * r2),
          burst,
        );
      }

      final ringStroke = Paint()
        ..color = accent.withValues(alpha: (0.9 - fxT).clamp(0.0, 0.9))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(center, 12 + 28 * fxT, ringStroke);
    }

    if (outcome == _RoundOutcome.miss) {
      // Red flash overlay to make misses feel punchy.
      final missFill = Paint()
        ..color = error.withValues(alpha: (0.35 * (1 - fxT)).clamp(0.0, 0.35))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(center, 20, missFill);

      final boom = Paint()
        ..color = error.withValues(alpha: (0.95 - fxT).clamp(0.0, 0.95))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round;
      for (int i = 0; i < 8; i++) {
        final a = (i / 8) * math.pi * 2;
        final r1 = 10 + 12 * fxT;
        final r2 = 18 + 18 * fxT;
        canvas.drawLine(
          center + Offset(math.cos(a) * r1, math.sin(a) * r1),
          center + Offset(math.cos(a) * r2, math.sin(a) * r2),
          boom,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _NotePainter oldDelegate) {
    return oldDelegate.ink != ink ||
        oldDelegate.accent != accent ||
        oldDelegate.error != error ||
        oldDelegate.outcome != outcome ||
        oldDelegate.fxT != fxT;
  }
}

class _FlyingNote {
  final String letter; // natural letter only (A-G)
  final int octave;
  /// 0..1 within the staff painter's staff-height region (not the full stage)
  final double yFrac;

  const _FlyingNote({required this.letter, required this.octave, required this.yFrac});

  static _FlyingNote randomForClef(StaffClef clef, math.Random rng) {
    final options = clef == StaffClef.treble ? _trebleStaffNotes : _bassStaffNotes;
    final n = options[rng.nextInt(options.length)];
    return n;
  }

  // Basic staff-only notes (no ledger lines):
  // Treble: E4 (bottom line) .. F5 (top line)
  // Bass: G2 (bottom line) .. B3 (top space)

  static const List<_FlyingNote> _trebleStaffNotes = [
    _FlyingNote(letter: 'E', octave: 4, yFrac: 6 / 8),
    _FlyingNote(letter: 'F', octave: 4, yFrac: 5.5 / 8),
    _FlyingNote(letter: 'G', octave: 4, yFrac: 5 / 8),
    _FlyingNote(letter: 'A', octave: 4, yFrac: 4.5 / 8),
    _FlyingNote(letter: 'B', octave: 4, yFrac: 4 / 8),
    _FlyingNote(letter: 'C', octave: 5, yFrac: 3.5 / 8),
    _FlyingNote(letter: 'D', octave: 5, yFrac: 3 / 8),
    _FlyingNote(letter: 'E', octave: 5, yFrac: 2.5 / 8),
    _FlyingNote(letter: 'F', octave: 5, yFrac: 2 / 8),
  ];

  static const List<_FlyingNote> _bassStaffNotes = [
    _FlyingNote(letter: 'G', octave: 2, yFrac: 6 / 8),
    _FlyingNote(letter: 'A', octave: 2, yFrac: 5.5 / 8),
    _FlyingNote(letter: 'B', octave: 2, yFrac: 5 / 8),
    _FlyingNote(letter: 'C', octave: 3, yFrac: 4.5 / 8),
    _FlyingNote(letter: 'D', octave: 3, yFrac: 4 / 8),
    _FlyingNote(letter: 'E', octave: 3, yFrac: 3.5 / 8),
    _FlyingNote(letter: 'F', octave: 3, yFrac: 3 / 8),
    _FlyingNote(letter: 'G', octave: 3, yFrac: 2.5 / 8),
    _FlyingNote(letter: 'A', octave: 3, yFrac: 2 / 8),
    _FlyingNote(letter: 'B', octave: 3, yFrac: 1.5 / 8),
  ];
}
