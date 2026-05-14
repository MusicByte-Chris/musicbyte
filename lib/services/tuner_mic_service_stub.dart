import 'dart:typed_data';

/// Microphone capture for the Chromatic Tuner.
///
/// Non-web stub: keeps the app compiling for Android/iOS, but reports
/// unsupported.
class TunerMicService {
  final void Function(Float32List buffer, double sampleRate) onAudioFrame;
  TunerMicService({required this.onAudioFrame});

  bool get isSupported => false;

  Future<void> start() async {
    // Not supported on mobile in this implementation.
  }

  void stop() {}
}
