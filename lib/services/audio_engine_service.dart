import 'dart:math' as math;
import 'dart:collection';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:musicbyteai/models/music_theory.dart';
import 'package:musicbyteai/services/audio_wav_file_store.dart';
import 'package:musicbyteai/services/audio_wav_file_store_factory.dart';

/// Lightweight pitch representation for playback
/// noteName examples: C, C#, Db, D, Eb, ...
class NoteModel {
  final String noteName;
  final int octave;
  const NoteModel({required this.noteName, required this.octave});
}

/// Segment definition: one or more frequencies for a duration
class _ToneSegment {
  final List<double> frequencies;
  final double durationSeconds;
  const _ToneSegment(this.frequencies, this.durationSeconds);
}

/// Central Audio Engine - Singleton
/// - Uses a single AudioPlayer instance (audioplayers backend)
/// - Generates tones programmatically (sine wave)
/// - A4 = 440Hz reference, 12-TET
class AudioEngineService {
  static final AudioEngineService _instance = AudioEngineService._internal();
  factory AudioEngineService() => _instance;
  AudioEngineService._internal() {
    // Configure the underlying platform audio session/context early.
    // On iOS, the default session often respects the Silent switch, which makes
    // generated tones appear to “not work” in TestFlight builds.
    Future.microtask(() async {
      try {
        await _ensureInitialized();
      } catch (e) {
        debugPrint('AudioEngineService init error: $e');
      }
    });

    // Non-blocking warmup: pre-generate a few common tones so the first interaction
    // feels instant. This stays lightweight and can be disabled by setting
    // _enablePrewarm = false.
    if (_enablePrewarm) {
      Future.microtask(() async {
        try {
          await _prewarmDefaults();
        } catch (e) {
          debugPrint('AudioEngineService prewarm error: $e');
        }
      });
    }
  }

  final AudioPlayer _player = AudioPlayer();
  // Dedicated looping player for long-running tone generation (studio test use-case).
  // Kept separate so looping tones don’t interfere with short one-shot notes/intervals.
  final AudioPlayer _continuousPlayer = AudioPlayer();

  AudioWavFileStore? _wavFileStore;

  // UI-friendly error surface area.
  // We keep the existing behavior (no throws) but expose the latest error so
  // callers can optionally show a SnackBar.
  String? _lastError;
  final ValueNotifier<String?> errorNotifier = ValueNotifier<String?>(null);

  void _setError(String message, Object error) {
    final msg = '$message: $error';
    _lastError = msg;
    errorNotifier.value = msg;
    debugPrint(msg);
  }

  /// Returns and clears the latest error message (if any).
  String? consumeLastError() {
    final v = _lastError;
    _lastError = null;
    if (errorNotifier.value == v) errorNotifier.value = null;
    return v;
  }

  bool _isContinuousPlaying = false;
  String? _continuousRequestKey;

  Future<void>? _initFuture;
  bool _didInit = false;

  Future<void>? _continuousInitFuture;
  bool _didContinuousInit = false;

  // ---- WAV byte cache (in-memory, bounded, LRU-ish) ----
  //
  // Why: Generating WAV bytes repeatedly is CPU-heavy and can add audible/UX latency
  // during rapid tapping (piano keys, interval drills, etc.). We cache generated WAV
  // bytes keyed by the playback request so repeats can play almost instantly.
  //
  // Implementation notes:
  // - Uses insertion-ordered LinkedHashMap to support simple LRU behavior.
  // - On cache hit we move the entry to the end (most-recent).
  // - When full, we evict the oldest entry.
  static const int _maxWavCacheEntries = 120;
  final Map<String, Uint8List> _wavCache = LinkedHashMap<String, Uint8List>();
  int _cacheHits = 0;
  int _cacheMisses = 0;

  // ---- Rapid re-tap protections ----
  // Some platform backends can drop/ignore rapid repeated play() calls on the same
  // player, especially when reusing the same in-memory source. We mitigate this via:
  // 1) Centralized stop->play behavior
  // 2) Optional same-key debounce (OFF by default)
  // 3) Simple superseding token so older queued requests don't override newer taps
  int _sameKeyDebounceMs = 0; // 0 = disabled
  final Map<String, int> _lastPlayMsByKey = <String, int>{};
  int _playToken = 0;

  // Config
  static const int _sampleRate = 44100; // 44.1kHz CD-quality
  static const double _masterGain = 0.9; // master volume scaler to avoid clipping

  /// Convert a musical note and octave (A4=440) to frequency in Hz
  double noteToFrequency(String noteName, int octave) {
    final pc = TheoryUtils.pcForNoteName(noteName);
    if (pc == null) {
      debugPrint('AudioEngineService.noteToFrequency: Unknown note "$noteName"');
      return 0;
    }
    // A = pitch class 9 in our mapping (C=0,...,A=9,B=11)
    final semitonesFromA4 = (octave - 4) * 12 + (pc - 9);
    return 440.0 * math.pow(2.0, semitonesFromA4 / 12.0).toDouble();
  }

  /// Play a pure sine wave at [hz] for [durationSeconds]
  Future<void> playFrequency(double hz, {double durationSeconds = 1.0}) async {
    try {
      if (hz <= 0) return;
      await _ensureInitialized();
      final roundedHz = _roundTo1Decimal(hz);
      final durKey = _durationKey(durationSeconds);
      final cacheKey = 'freq|${roundedHz.toStringAsFixed(1)}|$durKey';
      final bytes = _getOrBuildWav(cacheKey, () {
        return _buildWavForSegments([
          _ToneSegment([roundedHz], durationSeconds),
        ]);
      });
      await _playBytes(bytes, requestKey: cacheKey);
    } catch (e) {
      _setError('AudioEngineService.playFrequency error', e);
    }
  }

  /// Start a continuous (looping) sine wave at [hz] until [stopContinuousTone] is called.
  ///
  /// This is intended for studio/testing workflows where the tone should keep playing.
  Future<void> startContinuousTone(double hz) async {
    try {
      if (hz <= 0) return;
      await _ensureContinuousInitialized();

      final roundedHz = _roundTo1Decimal(hz);
      // Use a 1s buffer that loops; this keeps memory low and avoids huge WAVs.
      const durationSeconds = 1.0;
      final durKey = _durationKey(durationSeconds);
      final cacheKey = 'continuous|freq|${roundedHz.toStringAsFixed(1)}|$durKey';
      _continuousRequestKey = cacheKey;

      final bytes = _getOrBuildWav(cacheKey, () {
        return _buildWavForSegments([
          _ToneSegment([roundedHz], durationSeconds),
        ]);
      });

      // Ensure we are in loop mode for continuous tone.
      await _continuousPlayer.setReleaseMode(ReleaseMode.loop);

      await _playBytesOn(
        _continuousPlayer,
        bytes,
        requestKey: cacheKey,
        useSharedToken: false,
      );
      _isContinuousPlaying = true;
    } catch (e) {
      _setError('AudioEngineService.startContinuousTone error', e);
    }
  }

  /// Stop the currently running continuous tone (if any).
  Future<void> stopContinuousTone() async {
    try {
      await _ensureContinuousInitialized();
      await _continuousPlayer.stop();
    } catch (e) {
      _setError('AudioEngineService.stopContinuousTone error', e);
    } finally {
      _isContinuousPlaying = false;
      _continuousRequestKey = null;
    }
  }

  bool get isContinuousPlaying => _isContinuousPlaying;
  String? get continuousRequestKey => _continuousRequestKey;

  /// Play a musical note by name + octave using 12-TET conversion
  Future<void> playNote(String noteName, int octave, {double durationSeconds = 1.0}) async {
    try {
      await _ensureInitialized();
      final hz = noteToFrequency(noteName, octave);
      if (hz <= 0) return;

      // Note-specific key (lets us preserve intent even if Hz rounding changes)
      final durKey = _durationKey(durationSeconds);
      final cacheKey = 'note|${noteName.trim()}|$octave|$durKey';
      final bytes = _getOrBuildWav(cacheKey, () {
        // Use the exact computed Hz for playback quality; cache key is based on note.
        return _buildWavForSegments([
          _ToneSegment([hz], durationSeconds),
        ]);
      });
      await _playBytes(bytes, requestKey: cacheKey);
    } catch (e) {
      _setError('AudioEngineService.playNote error', e);
    }
  }

  /// Play an interval by name (e.g., m2, M2, m3, M3, P4, TT, P5, m6, M6, m7, M7, P8)
  /// Plays root, short gap, then target (melodic ascending)
  Future<void> playInterval(String rootNote, int rootOctave, String intervalName) async {
    try {
      await _ensureInitialized();
      final rootHz = noteToFrequency(rootNote, rootOctave);
      if (rootHz <= 0) return;
      final offset = _intervalSemitones(intervalName);
      final targetHz = rootHz * math.pow(2.0, offset / 12.0).toDouble();

      final cacheKey = 'interval|${rootNote.trim()}|$rootOctave|${intervalName.trim()}';

      final bytes = _getOrBuildWav(cacheKey, () {
        return _buildWavForSegments([
          _ToneSegment([rootHz], 0.8),
          _ToneSegment(const [], 0.08), // small silence
          _ToneSegment([targetHz], 0.8),
        ]);
      });
      await _playBytes(bytes, requestKey: cacheKey);
    } catch (e) {
      _setError('AudioEngineService.playInterval error', e);
    }
  }

  /// Play a chord from a list of notes
  /// If [arpeggiate] is false, plays all tones simultaneously
  /// If true, plays tones sequentially with a small overlap/gap
  Future<void> playChord(List<NoteModel> notes, {bool arpeggiate = false}) async {
    if (notes.isEmpty) return;
    try {
      await _ensureInitialized();
      final freqs = notes
          .map((n) => noteToFrequency(n.noteName, n.octave))
          .where((f) => f > 0)
          .toList();
      if (freqs.isEmpty) return;

      // Optional cache: key by the chord notes (normalized) + arpeggiate flag.
      final normalizedNotes = notes
          .map((n) => '${n.noteName.trim()}${n.octave}')
          .toList(growable: false)
        ..sort();
      final cacheKey = 'chord|arp:$arpeggiate|${normalizedNotes.join(",")}';

      final bytes = _getOrBuildWav(cacheKey, () {
        final segments = <_ToneSegment>[];
        if (!arpeggiate) {
          segments.add(_ToneSegment(freqs, 1.2));
        } else {
          for (int i = 0; i < freqs.length; i++) {
            segments.add(_ToneSegment([freqs[i]], 0.7));
            if (i != freqs.length - 1) {
              segments.add(_ToneSegment(const [], 0.06));
            }
          }
        }
        return _buildWavForSegments(segments);
      });
      await _playBytes(bytes, requestKey: cacheKey);
    } catch (e) {
      _setError('AudioEngineService.playChord error', e);
    }
  }

  /// Play a scale from a list of notes. If [ascending] is false, plays in reverse.
  Future<void> playScale(List<NoteModel> notes, {bool ascending = true}) async {
    if (notes.isEmpty) return;
    try {
      await _ensureInitialized();
      final ordered = ascending ? notes : notes.reversed.toList();

      // Optional cache: key by ordered notes + direction.
      final keyNotes = ordered.map((n) => '${n.noteName.trim()}${n.octave}').join(',');
      final cacheKey = 'scale|asc:$ascending|$keyNotes';

      final bytes = _getOrBuildWav(cacheKey, () {
        final segments = <_ToneSegment>[];
        for (int i = 0; i < ordered.length; i++) {
          final hz = noteToFrequency(ordered[i].noteName, ordered[i].octave);
          if (hz <= 0) continue;
          segments.add(_ToneSegment([hz], 0.55));
          if (i != ordered.length - 1) {
            segments.add(_ToneSegment(const [], 0.05));
          }
        }
        return _buildWavForSegments(segments);
      });
      await _playBytes(bytes, requestKey: cacheKey);
    } catch (e) {
      _setError('AudioEngineService.playScale error', e);
    }
  }

  /// Stop current playback (if any)
  Future<void> stop() async {
    try {
      await _ensureInitialized();
      await _player.stop();
    } catch (e) {
      _setError('AudioEngineService.stop error', e);
    }
  }

  Future<void> _ensureInitialized() {
    if (_didInit) return Future.value();
    return _initFuture ??= _configurePlayer();
  }

  Future<void> _ensureContinuousInitialized() {
    if (_didContinuousInit) return Future.value();
    return _continuousInitFuture ??= _configureContinuousPlayer();
  }

  Future<void> _configurePlayer() async {
    try {
      await _configurePlayerInstance(_player, defaultReleaseMode: ReleaseMode.stop);
      _wavFileStore ??= await createAudioWavFileStore();
    } catch (e, st) {
      debugPrint('AudioEngineService._configurePlayer failed: $e');
      debugPrint(st.toString());
    } finally {
      _didInit = true;
    }
  }

  Future<void> _configureContinuousPlayer() async {
    try {
      // Default to stop; we’ll explicitly switch to loop for continuous playback.
      await _configurePlayerInstance(_continuousPlayer, defaultReleaseMode: ReleaseMode.stop);
      _wavFileStore ??= await createAudioWavFileStore();
    } catch (e, st) {
      debugPrint('AudioEngineService._configureContinuousPlayer failed: $e');
      debugPrint(st.toString());
    } finally {
      _didContinuousInit = true;
    }
  }

  Future<void> _configurePlayerInstance(AudioPlayer player, {required ReleaseMode defaultReleaseMode}) async {
    // Release mode: ensure short tones stop cleanly and don't loop.
    await player.setReleaseMode(defaultReleaseMode);
    await player.setVolume(1.0);

    // iOS: use a playback category so tones are audible even with the Silent switch.
    // Android: keep defaults but enable speaker output.
    // Note: these enums/classes are provided by the audioplayers package.
    final context = AudioContext(
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: const {
          AVAudioSessionOptions.defaultToSpeaker,
          AVAudioSessionOptions.mixWithOthers,
        },
      ),
      android: const AudioContextAndroid(
        isSpeakerphoneOn: true,
        stayAwake: false,
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.media,
        audioFocus: AndroidAudioFocus.gain,
      ),
    );
    await player.setAudioContext(context);
  }

  /// Clears all cached WAV bytes (useful when tuning/A4 reference changes or as a
  /// memory management hook).
  void clearCache() {
    _wavCache.clear();
    _cacheHits = 0;
    _cacheMisses = 0;
    _lastPlayMsByKey.clear();
    // Best-effort: we can't easily enumerate old temp files here without tracking,
    // but eviction cleanup covers normal usage.
    if (kDebugMode) debugPrint('AudioEngineService: WAV cache cleared');
  }

  /// Optional: ignore repeated play requests for the same key within [duration].
  ///
  /// - Set to `null` or `Duration.zero` to disable (default).
  /// - This helps avoid flooding the audio backend during rapid tapping.
  void setSameKeyDebounce(Duration? duration) {
    final ms = duration == null ? 0 : duration.inMilliseconds;
    _sameKeyDebounceMs = ms < 0 ? 0 : ms;
    if (kDebugMode) debugPrint('AudioEngineService: debounce = ${_sameKeyDebounceMs}ms');
  }

  /// Lightweight cache stats for debugging/perf verification.
  ///
  /// Returns a map like:
  /// {"entries": 12, "maxEntries": 140, "hits": 40, "misses": 10, "hitRate": 80.0}
  Map<String, Object> getCacheStats() {
    final total = _cacheHits + _cacheMisses;
    final hitRate = total == 0 ? 0.0 : (_cacheHits / total) * 100.0;
    return {
      'entries': _wavCache.length,
      'maxEntries': _maxWavCacheEntries,
      'hits': _cacheHits,
      'misses': _cacheMisses,
      'hitRate': double.parse(hitRate.toStringAsFixed(1)),
    };
  }

  // ---- Internal helpers ----

  static const bool _enablePrewarm = true;

  Future<void> _playBytes(Uint8List bytes, {required String requestKey}) async {
    return _playBytesOn(_player, bytes, requestKey: requestKey, useSharedToken: true);
  }

  Future<void> _playBytesOn(
    AudioPlayer player,
    Uint8List bytes, {
    required String requestKey,
    required bool useSharedToken,
  }) async {
    // Centralized playback path so all public methods benefit from consistent
    // stop->play behavior.

    // Optional debounce to prevent flooding when a user taps the same key rapidly.
    if (_sameKeyDebounceMs > 0) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final last = _lastPlayMsByKey[requestKey];
      if (last != null && (now - last) < _sameKeyDebounceMs) {
        if (kDebugMode) debugPrint('AudioEngineService: debounce skip $requestKey');
        return;
      }
      _lastPlayMsByKey[requestKey] = now;
    }

    final myToken = useSharedToken ? ++_playToken : 0;

    try {
      // Best-effort stop first; some backends need an explicit stop to reliably
      // restart the same source.
      try {
        await player.stop();
      } catch (e) {
        debugPrint('AudioEngineService._playBytes stop error: $e');
      }

      // If a newer request came in while we were stopping, prefer the newest.
      if (useSharedToken && myToken != _playToken) return;

      try {
        await player.play(await _sourceForBytes(bytes, requestKey: requestKey));
      } catch (e) {
        // Defensive retry: some backends can throw if interrupted mid-transition.
        debugPrint('AudioEngineService._playBytes play error: $e');
        try {
          await player.stop();
          if (useSharedToken && myToken != _playToken) return;
          await player.play(await _sourceForBytes(bytes, requestKey: requestKey));
        } catch (e2) {
          debugPrint('AudioEngineService._playBytes retry failed: $e2');
        }
      }
    } catch (e) {
      debugPrint('AudioEngineService._playBytes error: $e');
    }
  }

  Future<Source> _sourceForBytes(Uint8List bytes, {required String requestKey}) async {
    // iOS/macOS: prefer file-backed playback for reliability.
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS)) {
      try {
        final store = _wavFileStore ??= await createAudioWavFileStore();
        if (store != null) {
          final path = await store.put(requestKey, bytes);
          return DeviceFileSource(path);
        }
      } catch (e) {
        debugPrint('AudioEngineService: file-backed source failed, falling back to bytes: $e');
      }
    }
    return BytesSource(bytes);
  }

  Future<void> _prewarmDefaults() async {
    // Prewarm common tones in octave 4 (C major). Keep short to be lightweight.
    const durationSeconds = 0.55;
    const octave = 4;
    const notes = <String>['C', 'D', 'E', 'F', 'G', 'A', 'B', 'C'];
    for (final n in notes) {
      final durKey = _durationKey(durationSeconds);
      final cacheKey = 'note|$n|$octave|$durKey';
      _getOrBuildWav(cacheKey, () {
        final hz = noteToFrequency(n, octave);
        return _buildWavForSegments([
          _ToneSegment([hz], durationSeconds),
        ]);
      });
    }

    if (kDebugMode) {
      debugPrint('AudioEngineService: prewarm complete (${_wavCache.length} cached)');
    }
  }

  Uint8List _getOrBuildWav(String cacheKey, Uint8List Function() builder) {
    final existing = _wavCache[cacheKey];
    if (existing != null) {
      _cacheHits++;

      // Touch entry to behave like LRU.
      _wavCache.remove(cacheKey);
      _wavCache[cacheKey] = existing;

      if (kDebugMode) debugPrint('AudioEngineService cache HIT: $cacheKey');
      return existing;
    }

    _cacheMisses++;
    if (kDebugMode) debugPrint('AudioEngineService cache MISS: $cacheKey');

    final bytes = builder();
    _wavCache[cacheKey] = bytes;
    _evictIfNeeded();
    return bytes;
  }

  void _evictIfNeeded() {
    while (_wavCache.length > _maxWavCacheEntries) {
      final oldestKey = _wavCache.keys.first;
      _wavCache.remove(oldestKey);
      // Keep temp storage in check on iOS/macOS.
      try {
        _wavFileStore?.remove(oldestKey);
      } catch (_) {}
      if (kDebugMode) debugPrint('AudioEngineService cache EVICT: $oldestKey');
    }
  }

  double _roundTo1Decimal(double value) => (value * 10).roundToDouble() / 10.0;

  String _durationKey(double seconds) {
    // Stable string key for durations (avoid floating point noise).
    // 2 decimals is enough for this app's short tone durations.
    return seconds.toStringAsFixed(2);
  }

  /// Maps common interval names to semitone offsets
  int _intervalSemitones(String name) {
    final n = name.trim();
    switch (n) {
      case 'm2':
        return 1;
      case 'M2':
        return 2;
      case 'm3':
        return 3;
      case 'M3':
        return 4;
      case 'P4':
        return 5;
      case 'TT':
      case 'tritone':
        return 6;
      case 'P5':
        return 7;
      case 'm6':
        return 8;
      case 'M6':
        return 9;
      case 'm7':
        return 10;
      case 'M7':
        return 11;
      case 'P8':
      case 'octave':
        return 12;
      default:
        debugPrint('AudioEngineService._intervalSemitones: Unknown interval name "$name"');
        return 0;
    }
  }

  /// Build a mono 16-bit PCM WAV for a sequence of segments (with optional silences)
  Uint8List _buildWavForSegments(List<_ToneSegment> segments) {
    // Calculate samples per segment
    final samplesPerSegment = <int>[];
    for (final s in segments) {
      final count = (s.durationSeconds * _sampleRate).round();
      samplesPerSegment.add(count);
    }

    // Generate PCM data (16-bit little endian)
    final pcm = BytesBuilder(copy: false);
    int segIndex = 0;
    for (final s in segments) {
      final count = samplesPerSegment[segIndex++];
      if (s.frequencies.isEmpty) {
        // Silence
        for (int i = 0; i < count; i++) {
          pcm.add([0, 0]);
        }
        continue;
      }
      // Precompute angular frequencies
      final twoPi = 2 * math.pi;
      final omegas = s.frequencies.map((f) => twoPi * f).toList(growable: false);

      for (int i = 0; i < count; i++) {
        final t = i / _sampleRate;
        double sum = 0;
        for (int k = 0; k < omegas.length; k++) {
          sum += math.sin(omegas[k] * t);
        }
        // Average to avoid clipping when mixing; apply master gain
        final value = (sum / omegas.length) * _masterGain;
        final sample = (value * 32767.0).clamp(-32768.0, 32767.0).round();
        // Little endian 16-bit
        final lo = sample & 0xFF;
        final hi = (sample >> 8) & 0xFF;
        pcm.add([lo, hi]);
      }
    }

    final pcmBytes = pcm.toBytes();

    // WAV header (44 bytes)
    final dataLength = pcmBytes.lengthInBytes;
    final totalLength = 44 + dataLength;
    final header = BytesBuilder(copy: false);

    void _writeString(String s) => header.add(s.codeUnits);
    void _writeUint32(int value) {
      final b = ByteData(4)..setUint32(0, value, Endian.little);
      header.add(b.buffer.asUint8List());
    }
    void _writeUint16(int value) {
      final b = ByteData(2)..setUint16(0, value, Endian.little);
      header.add(b.buffer.asUint8List());
    }

    _writeString('RIFF');
    _writeUint32(totalLength - 8); // ChunkSize
    _writeString('WAVE');
    _writeString('fmt ');
    _writeUint32(16); // Subchunk1Size for PCM
    _writeUint16(1); // AudioFormat PCM
    _writeUint16(1); // NumChannels mono
    _writeUint32(_sampleRate);
    final byteRate = _sampleRate * 1 * 16 ~/ 8;
    _writeUint32(byteRate);
    _writeUint16(1 * 16 ~/ 8); // BlockAlign
    _writeUint16(16); // BitsPerSample
    _writeString('data');
    _writeUint32(dataLength);

    final wav = BytesBuilder(copy: false);
    wav.add(header.toBytes());
    wav.add(pcmBytes);
    return wav.toBytes();
  }
}
