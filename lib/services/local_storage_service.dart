import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Simple key-value storage using shared_preferences that works on web and mobile.
class LocalStorageService {
  LocalStorageService._internal();
  static final LocalStorageService instance = LocalStorageService._internal();

  // Cache the SharedPreferences instance so we don't repeatedly hit the platform
  // channel (or IndexedDB on web). This also avoids subtle race conditions where
  // multiple simultaneous getInstance() calls can contend at startup.
  Future<SharedPreferences?>? _prefsFuture;

  Future<SharedPreferences?> _prefs() async {
    _prefsFuture ??= () async {
      try {
        // SharedPreferences.getInstance() is normally fast, but if the underlying
        // storage is slow/corrupted it can stall. A short timeout prevents startup
        // deadlocks in release builds.
        return await SharedPreferences.getInstance().timeout(const Duration(seconds: 2));
      } catch (e) {
        debugPrint('LocalStorage init failed: $e');
        return null;
      }
    }();

    return await _prefsFuture;
  }

  Future<String?> readString(String key) async {
    try {
      final p = await _prefs();
      return p?.getString(key);
    } catch (e) {
      debugPrint('LocalStorage readString($key) failed: $e');
      return null;
    }
  }

  Future<bool> writeString(String key, String value) async {
    try {
      final p = await _prefs();
      if (p == null) return false;
      return await p.setString(key, value);
    } catch (e) {
      debugPrint('LocalStorage writeString($key) failed: $e');
      return false;
    }
  }

  /// Best-effort write: never throws.
  ///
  /// Useful for “persist but don’t crash” flows.
  Future<void> writeStringQuiet(String key, String value) async {
    try {
      await writeString(key, value);
    } catch (e) {
      debugPrint('LocalStorage writeStringQuiet($key) failed: $e');
    }
  }

  Future<bool> remove(String key) async {
    try {
      final p = await _prefs();
      if (p == null) return false;
      return await p.remove(key);
    } catch (e) {
      debugPrint('LocalStorage remove($key) failed: $e');
      return false;
    }
  }

  // Helpers for JSON List storage
  Future<List<Map<String, dynamic>>> readJsonList(String key) async {
    final raw = await readString(key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        // Be defensive: jsonDecode returns List<dynamic> with elements that are
        // typically Map<String, dynamic>, but can be Map<dynamic, dynamic>.
        final out = <Map<String, dynamic>>[];
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            out.add(item);
          } else if (item is Map) {
            out.add(item.map((k, v) => MapEntry(k.toString(), v)));
          }
        }
        return out;
      }
      return [];
    } catch (e) {
      debugPrint('LocalStorage readJsonList decode error for $key: $e');
      // Sanitize bad data
      await remove(key);
      return [];
    }
  }

  Future<bool> writeJsonList(String key, List<Map<String, dynamic>> items) async {
    return await writeString(key, jsonEncode(items));
  }
}
