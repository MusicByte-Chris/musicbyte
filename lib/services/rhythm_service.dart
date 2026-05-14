import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:musicbyteai/data/rhythm_repository.dart';
import 'package:musicbyteai/models/rhythm_pattern.dart';
import 'package:musicbyteai/services/audio_engine_service.dart';
import 'package:musicbyteai/services/practice_log_service.dart';

/// RhythmService
///
/// Offline-first singleton that:
/// - Exposes curated rhythm patterns (from [RhythmRepository])
/// - Plays an accented click rendition using [AudioEngineService]
/// - Logs play events to [PracticeLogService]
class RhythmService {
  RhythmService._internal();
  static final RhythmService instance = RhythmService._internal();

  final List<RhythmPattern> _patterns = List<RhythmPattern>.unmodifiable(RhythmRepository.patterns);

  List<RhythmPattern> get patterns => _patterns;

  // Playback config (MVP)
  static const int _defaultBpm = 96;
  static const double _clickDurationSeconds = 0.030;
  static const double _silencePadSeconds = 0.004;

  // Downbeat click is lower + louder; subdivision click is higher + softer.
  static const double _downbeatHz = 720.0;
  static const double _subdivisionHz = 1320.0;

  /// Play a rhythm pattern with a premium “click track” feel.
  ///
  /// [bpm] is fixed for MVP unless overridden.
  Future<void> playPattern(RhythmPattern p, {int bpm = _defaultBpm}) async {
    // Defensive: don't spam if someone passes junk.
    if (p.pattern.isEmpty) return;
    if (bpm <= 20 || bpm > 260) bpm = _defaultBpm;

    try {
      // We interpret [pattern] items as durations in quarter-note beats.
      // Quarter note seconds at BPM: 60 / bpm.
      final quarterSeconds = 60.0 / bpm;
      final totalBeats = p.totalBeats;
      if (totalBeats <= 0.01) return;

      // We schedule clicks at each event boundary, with a downbeat accent on beat 1.
      // For patterns longer than one bar, we accent every bar downbeat.
      final beatsPerBar = _beatsPerBarFromTimeSignature(p.timeSignature);

      double cursorBeats = 0.0;
      int eventIndex = 0;
      while (eventIndex < p.pattern.length) {
        final isBarDownbeat = _isNearIntMultiple(cursorBeats, beatsPerBar.toDouble());
        final hz = isBarDownbeat ? _downbeatHz : _subdivisionHz;
        final dur = _clickDurationSeconds;

        // Fire-and-forget play now.
        unawaited(AudioEngineService().playFrequency(hz, durationSeconds: dur));

        final stepBeats = p.pattern[eventIndex];
        final waitSeconds = (stepBeats * quarterSeconds).clamp(0.01, 10.0);
        await Future<void>.delayed(Duration(milliseconds: (waitSeconds * 1000).round()));

        cursorBeats += stepBeats;
        eventIndex++;
      }

      // Small tail pad so the last click doesn't feel cut short on some backends.
      await Future<void>.delayed(Duration(milliseconds: (_silencePadSeconds * 1000).round()));

      // Log to practice.
      unawaited(
        PracticeLogService.instance.addSession(
          focusArea: 'Rhythm Trainer',
          minutes: 1,
          notes: 'Played: ${p.name} (${p.timeSignature})',
        ),
      );
    } catch (e, st) {
      debugPrint('RhythmService.playPattern failed: $e');
      debugPrint(st.toString());
    }
  }

  int _beatsPerBarFromTimeSignature(String ts) {
    final parts = ts.split('/');
    if (parts.length != 2) return 4;
    final n = int.tryParse(parts[0]);
    final d = int.tryParse(parts[1]);
    if (n == null || d == null || n <= 0 || d <= 0) return 4;
    // Convert to quarter-beat length of a bar.
    final barQuarters = n * (4.0 / d);
    final rounded = barQuarters.round();
    return rounded <= 0 ? 4 : rounded;
  }

  bool _isNearIntMultiple(double value, double modulo, {double eps = 1e-3}) {
    if (modulo <= 0) return false;
    final r = value % modulo;
    return r.abs() < eps || (modulo - r).abs() < eps;
  }
}
