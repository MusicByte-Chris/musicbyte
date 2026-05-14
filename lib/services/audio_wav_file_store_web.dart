import 'dart:typed_data';

import 'package:musicbyteai/services/audio_wav_file_store.dart';

/// Web implementation: file system access is not supported.
Future<AudioWavFileStore?> createPlatformAudioWavFileStore() async => null;

class AudioWavFileStoreWeb implements AudioWavFileStore {
  @override
  Future<String> put(String key, Uint8List bytes) => throw UnsupportedError('File store not supported on web');

  @override
  Future<void> remove(String key) async {}
}
