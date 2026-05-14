import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:musicbyteai/models/app_settings.dart';
import 'package:musicbyteai/services/local_storage_service.dart';

class SettingsService {
  static const _key = 'settings_v1';
  SettingsService._internal();
  static final SettingsService instance = SettingsService._internal();

  AppSettings? _cache;
  Future<AppSettings>? _loadFuture;
  // Emits the latest settings whenever they are loaded or saved
  final ValueNotifier<AppSettings?> notifier = ValueNotifier<AppSettings?>(null);

  Future<AppSettings> load() async {
    if (_cache != null) {
      // Ensure listeners always see the cache, even if they subscribe late.
      notifier.value ??= _cache;
      return _cache!;
    }

    // If multiple widgets request settings during startup, we should only do the
    // shared_preferences read/JSON decode once.
    return _loadFuture ??= () async {
      try {
        final raw = await LocalStorageService.instance.readString(_key);
        if (raw != null && raw.isNotEmpty) {
          final decoded = jsonDecode(raw);
          if (decoded is Map) {
            final map = decoded.map((k, v) => MapEntry(k.toString(), v));
            _cache = AppSettings.fromJson(map);
            notifier.value = _cache!;
            return _cache!;
          }
        }
      } catch (e) {
        debugPrint('SettingsService: failed to load settings: $e');
      }

      // Defaults (best-effort persist, but never crash).
      final defaults = AppSettings.defaults();
      _cache = defaults;
      notifier.value = _cache!;
      try {
        await LocalStorageService.instance.writeStringQuiet(_key, AppSettings.toJsonString(defaults));
      } catch (e) {
        debugPrint('SettingsService: failed to persist defaults: $e');
      }
      return defaults;
    }();
  }

  Future<void> save(AppSettings s) async {
    try {
      _cache = s.copyWith(updatedAt: DateTime.now());
      await LocalStorageService.instance.writeStringQuiet(_key, AppSettings.toJsonString(_cache!));
      notifier.value = _cache!;
    } catch (e) {
      debugPrint('SettingsService: save failed: $e');
    }
  }

  Future<void> update({
    String? a4Reference,
    String? enharmonicPreference,
    String? notationSystem,
    bool? darkMode,
    String? appColorScheme,
    bool? haptics,
  }) async {
    final current = await load();
    final next = current.copyWith(
      a4Reference: a4Reference,
      enharmonicPreference: enharmonicPreference,
      notationSystem: notationSystem,
      darkMode: darkMode,
      appColorScheme: appColorScheme,
      haptics: haptics,
      updatedAt: DateTime.now(),
    );
    await save(next);
  }
}
