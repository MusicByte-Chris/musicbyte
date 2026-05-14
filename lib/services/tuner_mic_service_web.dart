import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:web_audio' as wa;

/// Web implementation of microphone capture for the Chromatic Tuner.
class TunerMicService {
  final void Function(Float32List buffer, double sampleRate) onAudioFrame;
  TunerMicService({required this.onAudioFrame});

  wa.AudioContext? _ctx;
  wa.AnalyserNode? _analyser;
  wa.MediaStreamAudioSourceNode? _source;
  html.MediaStream? _stream;
  Timer? _timer;

  bool get isSupported => true;

  Future<void> start() async {
    _ctx = wa.AudioContext();
    const fftSize = 4096; // larger window improves low-frequency resolution

    final mediaDevices = html.window.navigator.mediaDevices;
    if (mediaDevices == null) throw Exception('MediaDevices not available');

    _stream = await mediaDevices.getUserMedia({'audio': true});
    _source = _ctx!.createMediaStreamSource(_stream!);
    _analyser = _ctx!.createAnalyser();
    _analyser!.fftSize = fftSize;
    _analyser!.smoothingTimeConstant = 0.7;
    _source!.connectNode(_analyser!);

    try {
      // Some browsers require an explicit resume.
      await _ctx!.resume();
    } catch (e) {
      debugPrint('TunerMicService resume error: $e');
    }

    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      try {
        final n = _analyser!.fftSize ?? fftSize;
        final bytes = Uint8List(n);
        _analyser!.getByteTimeDomainData(bytes);

        final data = Float32List(n);
        for (int i = 0; i < n; i++) {
          // Map 0..255 -> -1..1
          data[i] = (bytes[i] - 128) / 128.0;
        }
        onAudioFrame(data, (_ctx!.sampleRate ?? 44100).toDouble());
      } catch (e) {
        debugPrint('TunerMicService poll error: $e');
      }
    });
  }

  void stop() {
    try {
      _timer?.cancel();
      _timer = null;

      _source?.disconnect();
      _analyser?.disconnect();

      final tracks = _stream?.getTracks() ?? const <html.MediaStreamTrack>[];
      for (final t in tracks) {
        try {
          t.stop();
        } catch (_) {}
      }

      _stream = null;
      _ctx?.close();
      _ctx = null;
    } catch (e) {
      debugPrint('TunerMicService stop error: $e');
    }
  }
}
