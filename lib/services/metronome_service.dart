import 'package:flutter/foundation.dart';
import 'package:musicbyteai/models/metronome_settings.dart';
import 'package:musicbyteai/services/local_storage_service.dart';

/// Service for persisting and retrieving Metronome settings locally.
class MetronomeService {
  static const _key = 'metronome_settings_v1';
  MetronomeService._internal();
  static final MetronomeService instance = MetronomeService._internal();

  MetronomeSettings? _cache;

  Future<MetronomeSettings> load() async {
    if (_cache != null) return _cache!;
    try {
      final raw = await LocalStorageService.instance.readString(_key);
      if (raw != null && raw.isNotEmpty) {
        _cache = MetronomeSettings.fromJsonString(raw);
        return _cache!;
      }
    } catch (e) {
      debugPrint('MetronomeService: load failed: $e');
    }
    final defaults = MetronomeSettings.defaults();
    await save(defaults);
    _cache = defaults;
    return defaults;
  }

  Future<void> save(MetronomeSettings s) async {
    try {
      _cache = s.copyWith(updatedAt: DateTime.now());
      await LocalStorageService.instance.writeString(_key, MetronomeSettings.toJsonString(_cache!));
    } catch (e) {
      debugPrint('MetronomeService: save failed: $e');
    }
  }

  Future<void> update({
    int? bpm,
    String? subdivision,
    int? numerator,
    int? denominator,
    bool? accentDownbeats,
  }) async {
    final current = await load();
    final next = current.copyWith(
      bpm: bpm,
      subdivision: subdivision,
      numerator: numerator,
      denominator: denominator,
      accentDownbeats: accentDownbeats,
      updatedAt: DateTime.now(),
    );
    await save(next);
  }
}
