import 'package:flutter/foundation.dart';
import 'package:musicbyteai/models/key_context.dart';
import 'package:musicbyteai/services/local_storage_service.dart';

class KeyContextService {
  static const _storageKey = 'key_context_v1';
  KeyContextService._internal();
  static final KeyContextService instance = KeyContextService._internal();

  KeyContext? _cache;

  Future<KeyContext> load() async {
    if (_cache != null) return _cache!;
    try {
      final raw = await LocalStorageService.instance.readString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        _cache = KeyContext.fromJsonString(raw);
        return _cache!;
      }
    } catch (e) {
      debugPrint('KeyContextService: failed to load: $e');
    }
    final defaults = KeyContext.defaults();
    await save(defaults);
    _cache = defaults;
    return defaults;
  }

  Future<void> save(KeyContext ctx) async {
    try {
      _cache = ctx.copyWith(updatedAt: DateTime.now());
      await LocalStorageService.instance.writeString(_storageKey, KeyContext.toJsonString(_cache!));
    } catch (e) {
      debugPrint('KeyContextService: save failed: $e');
    }
  }

  Future<void> setSelectedKey(String keyId) async {
    final current = await load();
    final next = current.copyWith(selectedKeyId: keyId, updatedAt: DateTime.now());
    await save(next);
  }
}
