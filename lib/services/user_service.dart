import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:musicbyteai/models/app_user.dart';
import 'package:musicbyteai/services/local_storage_service.dart';

class UserService {
  static const _userKey = 'user_v1';
  UserService._internal();
  static final UserService instance = UserService._internal();

  AppUser? _cached;

  Future<AppUser> getOrCreateLocalUser() async {
    if (_cached != null) return _cached!;

    try {
      final raw = await LocalStorageService.instance.readString(_userKey);
      if (raw != null && raw.isNotEmpty) {
        final user = AppUser.fromJsonString(raw);
        _cached = user;
        return user;
      }
    } catch (e) {
      debugPrint('UserService: failed to parse stored user: $e');
    }

    // Create default local user
    final now = DateTime.now();
    final user = AppUser(id: 'local-user', name: 'Local User', email: null, createdAt: now, updatedAt: now);
    await saveUser(user);
    _cached = user;
    return user;
  }

  Future<void> saveUser(AppUser user) async {
    try {
      await LocalStorageService.instance.writeString(_userKey, jsonEncode(user.toJson()));
    } catch (e) {
      debugPrint('UserService: saveUser failed: $e');
    }
  }
}
