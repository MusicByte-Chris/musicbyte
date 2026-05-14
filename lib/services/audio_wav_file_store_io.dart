import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:musicbyteai/services/audio_wav_file_store.dart';

/// Platform implementation for non-web targets.
Future<AudioWavFileStore?> createPlatformAudioWavFileStore() => AudioWavFileStoreIo.create();

class AudioWavFileStoreIo implements AudioWavFileStore {
  final Directory _dir;

  AudioWavFileStoreIo._(this._dir);

  static Future<AudioWavFileStoreIo> create() async {
    final dir = Directory('${Directory.systemTemp.path}/musicbyteai_wav_cache');
    try {
      if (!await dir.exists()) await dir.create(recursive: true);
    } catch (e) {
      debugPrint('AudioWavFileStoreIo: failed to create temp dir: $e');
    }
    return AudioWavFileStoreIo._(dir);
  }

  String _fileNameForKey(String key) {
    // Use a stable, filesystem-safe identifier.
    final digest = base64Url.encode(utf8.encode(key));
    final safe = digest.replaceAll('=', '');
    return '$safe.wav';
  }

  @override
  Future<String> put(String key, Uint8List bytes) async {
    final path = '${_dir.path}/${_fileNameForKey(key)}';
    final file = File(path);
    try {
      // Write only if missing to reduce IO churn.
      if (!await file.exists()) await file.writeAsBytes(bytes, flush: true);
    } catch (e) {
      debugPrint('AudioWavFileStoreIo.put failed: $e');
      // If writing failed, still return the path; the caller will surface errors
      // when attempting to play.
    }
    return path;
  }

  @override
  Future<void> remove(String key) async {
    final path = '${_dir.path}/${_fileNameForKey(key)}';
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (e) {
      debugPrint('AudioWavFileStoreIo.remove failed: $e');
    }
  }
}
