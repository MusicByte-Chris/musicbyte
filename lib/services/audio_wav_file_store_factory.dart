import 'package:flutter/foundation.dart';
import 'package:musicbyteai/services/audio_wav_file_store.dart';

import 'package:musicbyteai/services/audio_wav_file_store_io.dart'
    if (dart.library.html) 'package:musicbyteai/services/audio_wav_file_store_web.dart';

/// Creates a platform-appropriate WAV file store.
Future<AudioWavFileStore?> createAudioWavFileStore() async {
  if (kIsWeb) return null;
  // iOS/macOS are the primary targets that benefit from file-backed playback.
  if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
    return createPlatformAudioWavFileStore();
  }
  return null;
}
