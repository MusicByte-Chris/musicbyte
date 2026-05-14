import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:musicbyteai/models/music_theory.dart';
import 'package:musicbyteai/services/audio_engine_service.dart';
import 'package:musicbyteai/services/practice_log_service.dart';
import 'package:musicbyteai/theme.dart';

enum EarTrainerMode { note, interval, chord }

class EarTrainerPage extends StatefulWidget {
  const EarTrainerPage({super.key});

  @override
  State<EarTrainerPage> createState() => _EarTrainerPageState();
}

class _EarTrainerPageState extends State<EarTrainerPage> {
  EarTrainerMode _currentMode = EarTrainerMode.note;
  String _correctAnswer = '';
  List<String> _options = const [];
  int _streak = 0;
  int _bestStreak = 0;
  int _totalAttempts = 0;
  int _correctAttempts = 0;
  bool? _lastCorrect; // null before any attempt

  final _rng = Random();
  String? _rootNote; // for interval/chord rounds
  int _rootOctave = 4; // middle octave for ear training

  // Session timer state
  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _isTimerRunning = false;

  // Prevent double-complete / double-save when user finishes then navigates back.
  bool _isCompleting = false;
  bool _didWritePracticeLogForSession = false;

  @override
  void initState() {
    super.initState();
    _options = _generateOptionsForMode(_currentMode);
    _startRound();
    _startSessionTimer();
  }

  void _changeMode(EarTrainerMode mode) {
    setState(() {
      _currentMode = mode;
      _options = _generateOptionsForMode(mode);
      _startRound();
    });
  }

  // ===== Timer & Session Handling =====
  void _startSessionTimer() {
    if (_isTimerRunning) return; // prevent duplicate timers
    try {
      _timer?.cancel();
    } catch (_) {}
    setState(() {
      _elapsedSeconds = 0;
      _isTimerRunning = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _elapsedSeconds += 1);
    });
    debugPrint('EarTrainer: session timer started');
  }

  int _stopSessionTimer() {
    final seconds = _elapsedSeconds;
    try {
      _timer?.cancel();
    } catch (e) {
      debugPrint('EarTrainer: timer cancel failed: $e');
    }
    setState(() => _isTimerRunning = false);
    debugPrint('EarTrainer: session timer stopped at ${_formatElapsedMMSS(seconds)}');
    return seconds;
  }

  String _formatElapsedMMSS(int totalSeconds) {
    final mm = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final ss = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  String _modeLabel(EarTrainerMode m) {
    switch (m) {
      case EarTrainerMode.note:
        return 'Notes';
      case EarTrainerMode.interval:
        return 'Intervals';
      case EarTrainerMode.chord:
        return 'Chords';
    }
  }

  Future<void> _completeSession({required bool exitAfter}) async {
    if (_isCompleting) return;
    _isCompleting = true;
    try {
      final seconds = _stopSessionTimer();
      final accuracyPct = _totalAttempts == 0 ? 0 : ((_correctAttempts / _totalAttempts) * 100).round();
      final scoreSummary = '${_correctAttempts}/${_totalAttempts} – ${accuracyPct}%';
      final durationText = _formatElapsedMMSS(seconds);

      final save = await _showSavePrompt(durationText: durationText, scoreSummary: scoreSummary, mode: _modeLabel(_currentMode));

      if (save == true) {
        if (_didWritePracticeLogForSession) {
          debugPrint('EarTrainer: session already saved; skipping duplicate write');
        } else {
          final minutes = seconds <= 0 ? 1 : ((seconds / 60).round().clamp(1, 100000));
          final mode = _modeLabel(_currentMode);
          final notes = 'Score: ${_correctAttempts}/${_totalAttempts} (${accuracyPct}%)\nMode: $mode\nInterval recognition session.';
          debugPrint('EarTrainer: saving session to Practice Log: ${minutes}m, $notes');
          await PracticeLogService.instance.addSession(focusArea: 'Ear Training', minutes: minutes, notes: notes);
          _didWritePracticeLogForSession = true;
          if (mounted && !exitAfter) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved to Practice Log')));
          }
        }
      } else if (save == null) {
        // Dismissed without explicit choice: resume timer and stay
        if (mounted) _startSessionTimer();
        return;
      } else {
        debugPrint('EarTrainer: session discarded');
      }

      if (!mounted) return;
      if (exitAfter) {
        context.pop();
      } else {
        setState(() => _elapsedSeconds = 0);
        _startSessionTimer();
      }
    } finally {
      _isCompleting = false;
    }
  }

  Future<bool?> _showSavePrompt({required String durationText, required String scoreSummary, required String mode}) async {
    final theme = Theme.of(context);
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: theme.cardTheme.color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
      builder: (ctx) {
        final bottomInset = MediaQuery.viewInsetsOf(ctx).bottom;
        final safeBottom = MediaQuery.paddingOf(ctx).bottom;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 16, 24, 16 + safeBottom + bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.save_alt_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Save Ear Training Session?', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
                ),
              ]),
              const SizedBox(height: 12),
              Text('Time spent: $durationText', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('Score: $scoreSummary', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface)),
              const SizedBox(height: 4),
              Text('Mode: $mode', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary)),
              const SizedBox(height: 18),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(color: theme.colorScheme.error),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Discard'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Save to Practice Log'),
                  ),
                ),
              ]),
            ],
          ),
        );
      },
    );
  }

  Future<void> _onBackPressed() async {
    await _completeSession(exitAfter: true);
  }

  @override
  void dispose() {
    try {
      _timer?.cancel();
    } catch (e) {
      debugPrint('EarTrainer: timer cancel in dispose failed: $e');
    }
    super.dispose();
  }

  void _startRound() {
    if (_options.isEmpty) _options = _generateOptionsForMode(_currentMode);
    _correctAnswer = _options[_rng.nextInt(_options.length)];
    _lastCorrect = null; // clear feedback until user answers
    // Choose a new root for interval/chord modes
    if (_currentMode != EarTrainerMode.note) {
      _rootNote = _randomRootNatural();
      _rootOctave = 4;
    }
    setState(() {});
    // Auto-play the generated target for the new round
    _playCurrentTarget();
  }

  void _onPlay() {
    // Replay the current target without changing the round
    _playCurrentTarget();
  }

  void _onAnswer(String choice) {
    final isCorrect = choice == _correctAnswer;
    setState(() {
      _totalAttempts++;
      if (isCorrect) {
        _correctAttempts++;
        _streak++;
        if (_streak > _bestStreak) _bestStreak = _streak;
      } else {
        _streak = 0;
      }
      _lastCorrect = isCorrect;
    });
  }

  // Generate an entirely new set of options and start a fresh round
  void _nextRound() {
    setState(() {
      _options = _generateOptionsForMode(_currentMode);
    });
    _startRound();
  }

  List<String> _generateOptionsForMode(EarTrainerMode mode) {
    switch (mode) {
      case EarTrainerMode.note:
        final pool = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
        return _pickFour(pool);
      case EarTrainerMode.interval:
        final pool = ['m2', 'M2', 'm3', 'M3', 'P4', 'TT', 'P5', 'm6', 'M6', 'm7', 'M7', 'P8'];
        return _pickFour(pool);
      case EarTrainerMode.chord:
        final pool = ['Maj', 'min', 'dim', 'aug', '7', 'm7', 'Maj7', 'sus2', 'sus4', 'm7b5'];
        return _pickFour(pool);
    }
  }

  List<String> _pickFour(List<String> pool) {
    final list = List<String>.from(pool)..shuffle(_rng);
    return list.take(4).toList();
  }

  String _randomRootNatural() {
    const naturals = ['C','D','E','F','G','A','B'];
    return naturals[_rng.nextInt(naturals.length)];
  }

  Future<void> _playCurrentTarget() async {
    try {
      final audio = AudioEngineService();
      switch (_currentMode) {
        case EarTrainerMode.note:
          await audio.stop();
          await audio.playNote(_correctAnswer, 4, durationSeconds: 1.0);
          break;
        case EarTrainerMode.interval:
          final root = _rootNote ?? _randomRootNatural();
          await audio.playInterval(root, _rootOctave, _correctAnswer);
          break;
        case EarTrainerMode.chord:
          final root = _rootNote ?? _randomRootNatural();
          final notes = _buildChordFromLabel(root, _rootOctave, _correctAnswer);
          await audio.playChord(notes, arpeggiate: false);
          break;
      }

      final err = audio.consumeLastError();
      if (err != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Audio playback failed.')));
      }
    } catch (e) {
      debugPrint('EarTrainer play error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Audio playback failed.')));
      }
    }
  }

  List<NoteModel> _buildChordFromLabel(String rootName, int octave, String label) {
    // Map displayed labels to semitone formulas
    final formula = _chordFormulaForLabel(label);
    final rootPc = TheoryUtils.pcForNoteName(rootName) ?? 0;
    final List<NoteModel> result = [];
    for (final off in formula) {
      final pc = (rootPc + off) % 12;
      final name = TheoryUtils.nameForPc(pc, useFlats: false);
      result.add(NoteModel(noteName: name, octave: octave));
    }
    return result;
  }

  List<int> _chordFormulaForLabel(String label) {
    switch (label) {
      case 'Maj':
        return TheoryUtils.chordFormulas['Major']!;
      case 'min':
        return TheoryUtils.chordFormulas['Minor']!;
      case 'dim':
        return TheoryUtils.chordFormulas['Dim']!;
      case 'aug':
        return TheoryUtils.chordFormulas['Aug']!;
      case '7':
        return TheoryUtils.chordFormulas['Dom7']!;
      case 'm7':
        return TheoryUtils.chordFormulas['Min7']!;
      case 'Maj7':
        return TheoryUtils.chordFormulas['Maj7']!;
      case 'sus2':
        return TheoryUtils.chordFormulas['Sus2']!;
      case 'sus4':
        return TheoryUtils.chordFormulas['Sus4']!;
      case 'm7b5':
        return const [0, 3, 6, 10]; // Half-diminished 7th
      default:
        return TheoryUtils.chordFormulas['Major']!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final success = AppColors.goldSoft;
    final feedbackColor = _lastCorrect == null
        ? theme.colorScheme.secondary
        : _lastCorrect == true
            ? success
            : theme.colorScheme.error;
    final accuracy = _totalAttempts == 0 ? 0 : ((_correctAttempts / _totalAttempts) * 100).round();

    return WillPopScope(
      onWillPop: () async {
        await _completeSession(exitAfter: true);
        return false; // navigation handled in _completeSession
      },
      child: Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      floatingActionButton: _currentMode == EarTrainerMode.note
          ? FloatingActionButton(
              onPressed: () async {
                try {
                  final audio = AudioEngineService();
                  await audio.playFrequency(440.0, durationSeconds: 1.2);
                } catch (e) {
                  debugPrint('A4 reference play error: $e');
                }
              },
              child: const Icon(Icons.music_note_rounded),
            )
          : null,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Header with back button
            Row(
              children: [
                // Back button
                SizedBox(
                  width: 44,
                  height: 44,
                  child: Material(
                    color: theme.cardTheme.color,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _onBackPressed,
                      child: Icon(Icons.arrow_back_rounded, color: theme.colorScheme.onSurface),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Title & subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ear Trainer', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                      const SizedBox(height: 4),
                      Text('Train your musical ear', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary)),
                    ],
                  ),
                ),
                // Finish Session
                TextButton.icon(
                  onPressed: () => _completeSession(exitAfter: true),
                  icon: Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary, size: 20),
                  label: Text('Finish', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Mode selector
            SegmentedButton<EarTrainerMode>(
              segments: const [
                ButtonSegment(value: EarTrainerMode.note, label: Text('Notes'), icon: Icon(Icons.music_note_rounded)),
                ButtonSegment(value: EarTrainerMode.interval, label: Text('Intervals'), icon: Icon(Icons.compare_arrows_rounded)),
                ButtonSegment(value: EarTrainerMode.chord, label: Text('Chords'), icon: Icon(Icons.piano_rounded)),
              ],
              selected: {_currentMode},
              onSelectionChanged: (s) => _changeMode(s.first),
              showSelectedIcon: false,
              style: ButtonStyle(
                visualDensity: VisualDensity.comfortable,
                padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
              ),
            ),

            const SizedBox(height: 28),

            // Big Play button
            Center(
              child: Column(
                children: [
                  FilledButton(
                    onPressed: _onPlay,
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(28),
                    ),
                    child: const Icon(Icons.play_arrow_rounded, size: 48),
                  ),
                  const SizedBox(height: 8),
                  Text('Tap to hear', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.secondary)),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Answer buttons 2x2 grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 3.0,
              children: _options
                  .map(
                    (opt) => OutlinedButton(
                      onPressed: () => _onAnswer(opt),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: theme.dividerColor),
                        backgroundColor: theme.cardTheme.color,
                        foregroundColor: theme.colorScheme.onSurface,
                      ),
                      child: Text(opt, style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
                    ),
                  )
                  .toList(),
            ),

            const SizedBox(height: 20),

            // Feedback text
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: (_lastCorrect == null
                        ? theme.scaffoldBackgroundColor
                        : feedbackColor)
                    .withValues(alpha: _lastCorrect == null ? 0.0 : 0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: _lastCorrect == null ? theme.dividerColor : feedbackColor.withValues(alpha: 0.6)),
              ),
              child: Row(
                children: [
                  Icon(
                    _lastCorrect == true
                        ? Icons.check_circle_rounded
                        : _lastCorrect == false
                            ? Icons.cancel_rounded
                            : Icons.info_outline_rounded,
                    color: feedbackColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AnimatedSize(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      child: Text(
                        _lastCorrect == null
                            ? 'Choose an answer'
                            : _lastCorrect == true
                                ? 'Correct!'
                                : 'Incorrect – Correct answer: $_correctAnswer',
                        style: theme.textTheme.bodyMedium?.copyWith(color: feedbackColor, fontWeight: FontWeight.w600),
                        softWrap: true,
                      ),
                    ),
                  ),
                  if (_lastCorrect != null)
                    TextButton.icon(
                      onPressed: _nextRound,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('NEXT'),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Stats row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _StatChip(icon: Icons.local_fire_department_rounded, label: 'Current Streak', value: '$_streak'),
                  _StatChip(icon: Icons.emoji_events_rounded, label: 'Best Streak', value: '$_bestStreak'),
                  _StatChip(icon: Icons.percent_rounded, label: 'Accuracy', value: '$accuracy%'),
                ],
              ),
            ),

            const SizedBox(height: 8),
            if (_isTimerRunning)
              Align(
                alignment: Alignment.centerRight,
                child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Icon(Icons.timer_rounded, size: 16, color: theme.colorScheme.tertiary),
                  const SizedBox(width: 6),
                  Text(_formatElapsedMMSS(_elapsedSeconds), style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary)),
                ]),
              ),
          ],
        ),
      ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatChip({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.tertiary),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary)),
            Text(value, style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface)),
          ],
        )
      ],
    );
  }
}
