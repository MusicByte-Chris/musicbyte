import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:musicbyteai/models/practice_log_model.dart';
import 'package:musicbyteai/services/local_storage_service.dart';

/// PracticeLogService persists sessions locally using LocalStorageService under the key `practice_logs`.
class PracticeLogService {
  static const String _key = 'practice_logs';

  PracticeLogService._internal();
  static final PracticeLogService instance = PracticeLogService._internal();

  List<PracticeLogModel> _cache = [];
  bool _loaded = false;

  // Utilities
  String _formatYmd(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    try {
      final list = await LocalStorageService.instance.readJsonList(_key);
      _cache = list.map(PracticeLogModel.fromJson).toList();
      // Sort desc by date for convenience
      _cache.sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      debugPrint('PracticeLogService: load failed: $e');
      _cache = [];
    } finally {
      _loaded = true;
    }
  }

  Future<void> _persist() async {
    try {
      await LocalStorageService.instance.writeJsonList(_key, _cache.map((e) => e.toJson()).toList());
    } catch (e) {
      debugPrint('PracticeLogService: persist failed: $e');
    }
  }

  // API
  Future<void> addSession({
    required String focusArea,
    required int minutes,
    String? notes,
    DateTime? sessionDate,
  }) async {
    try {
      await _ensureLoaded();
      final now = DateTime.now();
      final id = '${now.millisecondsSinceEpoch}_${Random().nextInt(0x7fffffff)}';
      final dateStr = _formatYmd(_dateOnly(sessionDate ?? now));
      final entry = PracticeLogModel(id: id, focusArea: focusArea, minutes: minutes, notes: notes, sessionDate: dateStr);
      _cache = [entry, ..._cache];
      // Keep cache sorted desc
      _cache.sort((a, b) => b.date.compareTo(a.date));
      await _persist();
    } catch (e) {
      debugPrint('PracticeLogService: addSession failed: $e');
    }
  }

  Future<List<PracticeLogModel>> getAllSessions() async {
    await _ensureLoaded();
    return List.unmodifiable(_cache);
  }

  Future<List<PracticeLogModel>> getSessionsByDate(DateTime date) async {
    await _ensureLoaded();
    final target = _formatYmd(_dateOnly(date));
    return _cache.where((e) => e.sessionDate == target).toList();
  }

  /// Returns the total minutes for the week that begins on Monday containing [weekStart].
  Future<int> getTotalMinutesForWeek(DateTime weekStart) async {
    await _ensureLoaded();
    // Normalize to Monday
    final start = _weekMonday(weekStart);
    final end = start.add(const Duration(days: 6));
    int sum = 0;
    for (final s in _cache) {
      final d = s.date;
      if (!d.isBefore(start) && !d.isAfter(end)) {
        sum += s.minutes;
      }
    }
    return sum;
  }

  /// Counts consecutive days backward from today (inclusive) with at least 1 session.
  /// If today has no session, returns 0.
  Future<int> getCurrentStreak() async {
    await _ensureLoaded();
    final set = _cache.map((e) => e.sessionDate).toSet();
    int streak = 0;
    var cursor = _dateOnly(DateTime.now());
    if (!set.contains(_formatYmd(cursor))) return 0;
    while (set.contains(_formatYmd(cursor))) {
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  Future<void> resetAllProgress() async {
    try {
      _cache = [];
      _loaded = true;
      await LocalStorageService.instance.remove(_key);
    } catch (e) {
      debugPrint('PracticeLogService: resetAllProgress failed: $e');
    }
  }

  DateTime _weekMonday(DateTime any) {
    final d = _dateOnly(any);
    // DateTime.weekday: Mon=1..Sun=7
    final diffToMon = d.weekday - DateTime.monday; // 0..6
    return d.subtract(Duration(days: diffToMon));
  }
}
