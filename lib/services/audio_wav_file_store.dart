import 'dart:typed_data';

/// Platform abstraction for storing generated WAV bytes in a place that can be
/// played back by platform media backends.
///
/// On iOS, `audioplayers` is more reliable when playing from a file path rather
/// than from an in-memory `BytesSource`.
abstract class AudioWavFileStore {
  /// Persist bytes for [key] and return a playable file path.
  Future<String> put(String key, Uint8List bytes);

  /// Best-effort removal for [key].
  Future<void> remove(String key);
}
