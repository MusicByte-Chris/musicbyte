import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:musicbyteai/models/practice_session.dart';
import 'package:musicbyteai/services/local_storage_service.dart';
import 'package:musicbyteai/services/user_service.dart';

class PracticeService {
  static const _key = 'practice_sessions_v1';
  PracticeService._internal();
  static final PracticeService instance = PracticeService._internal();

  List<PracticeSession> _cache = [];
  bool _loaded = false;

  Future<List<PracticeSession>> loadSessions() async {
    if (_loaded) return _cache;
    try {
      final rawList = await LocalStorageService.instance.readJsonList(_key);
      final sessions = rawList.map((e) => PracticeSession.fromJson(e)).toList();
      _cache = sessions;
      _loaded = true;
      if (sessions.isEmpty) {
        // seed with sample data for first run
        await _seedSample();
      }
    } catch (e) {
      debugPrint('PracticeService: failed to load sessions: $e');
      _cache = [];
      _loaded = true;
    }
    return _cache;
  }

  Future<void> _persist() async {
    try {
      await LocalStorageService.instance
          .writeJsonList(_key, _cache.map((e) => e.toJson()).toList());
    } catch (e) {
      debugPrint('PracticeService: persist failed: $e');
    }
  }

  Future<void> addSession({
    required String focusArea,
    required int minutes,
    String? notes,
    DateTime? date,
  }) async {
    try {
      final user = await UserService.instance.getOrCreateLocalUser();
      final now = DateTime.now();
      final id = _randomId();
      final session = PracticeSession(
        id: id,
        userId: user.id,
        focusArea: focusArea,
        minutes: minutes,
        notes: notes,
        date: date ?? now,
        createdAt: now,
        updatedAt: now,
      );
      await loadSessions();
      _cache = [session, ..._cache];
      await _persist();
    } catch (e) {
      debugPrint('PracticeService: addSession failed: $e');
    }
  }

  Future<void> deleteSession(String id) async {
    await loadSessions();
    _cache.removeWhere((s) => s.id == id);
    await _persist();
  }

  Future<void> clearAll() async {
    _cache = [];
    await _persist();
  }

  Map<int, int> weeklyMinutes() {
    // returns map of weekday index (0=Mon) to total minutes in last 7 days
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 6));
    final map = {for (var i = 0; i < 7; i++) i: 0};
    for (final s in _cache) {
      if (s.date.isAfter(DateTime(start.year, start.month, start.day)) && s.date.isBefore(now.add(const Duration(days: 1)))) {
        final weekdayIndex = (s.date.weekday + 6) % 7; // convert 1..7 (Mon..Sun) -> 0..6
        map[weekdayIndex] = (map[weekdayIndex] ?? 0) + s.minutes;
      }
    }
    return map;
  }

  Future<void> _seedSample() async {
    try {
      final user = await UserService.instance.getOrCreateLocalUser();
      final now = DateTime.now();
      final samples = <PracticeSession>[
        PracticeSession(
          id: _randomId(),
          userId: user.id,
          focusArea: 'Circle of Fifths Drills',
          minutes: 45,
          notes: 'Key of Ab Major & Db Major',
          date: now.subtract(const Duration(days: 1)),
          createdAt: now,
          updatedAt: now,
        ),
        PracticeSession(
          id: _randomId(),
          userId: user.id,
          focusArea: 'Metronome Speed Work',
          minutes: 30,
          notes: '140 BPM Subdivisions',
          date: now.subtract(const Duration(days: 2)),
          createdAt: now,
          updatedAt: now,
        ),
        PracticeSession(
          id: _randomId(),
          userId: user.id,
          focusArea: 'Ear Training',
          minutes: 20,
          notes: 'Perfect 4th vs Perfect 5th',
          date: now.subtract(const Duration(days: 3)),
          createdAt: now,
          updatedAt: now,
        ),
      ];
      _cache = samples;
      await _persist();
    } catch (e) {
      debugPrint('PracticeService: seed failed: $e');
    }
  }

  String _randomId() {
    final r = Random();
    return '${DateTime.now().millisecondsSinceEpoch}_${r.nextInt(0x7fffffff)}';
  }
}
