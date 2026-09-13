import 'audio_engine_state.dart';
import 'audio_sequence.dart';
import 'playable_source.dart';

/// Cross-platform audio boundary. Implementations must not leak plugin types.
abstract interface class AudioEngine {
  bool get isAvailable;
  Stream<AudioEngineState> get states;
  Future<void> load(PlayableSource source);
  Future<void> play();
  Future<void> pause();
  Future<void> stop();
  Future<void> seek(Duration position);
  Future<void> setVolume(double value);
  Future<void> setPlaybackRate(double value);
  Future<void> dispose();
}

/// Optional native sequence capability. Queue and continuation policy stay in
/// PlaybackController; loading never implicitly requests playback.
abstract interface class AudioSequenceEngine implements AudioEngine {
  bool get supportsSequences;
  Future<void> loadSequence(AudioSequence sequence, {int initialIndex = 0});

  /// Retains the current entry and everything before it. A stale cursor is a
  /// no-op (false); an in-flight transition/failure requires a fresh load.
  Future<bool> retainSequenceThrough(AudioSequenceCursor expected);
  Future<bool> appendSequence(AudioSequenceAppend request);
  Future<bool> pruneSequenceBefore(AudioSequenceCursor expected);
}

/// Deliberately reports no backend, never simulates successful playback.
final class UnavailableAudioEngine implements AudioEngine {
  @override
  bool get isAvailable => false;
  @override
  Stream<AudioEngineState> get states => const Stream.empty();
  @override
  Future<void> load(PlayableSource source) async => _unsupported();
  @override
  Future<void> play() async => _unsupported();
  @override
  Future<void> pause() async => _unsupported();
  @override
  Future<void> stop() async => _unsupported();
  @override
  Future<void> seek(Duration position) async => _unsupported();
  @override
  Future<void> setVolume(double value) async => _unsupported();
  @override
  Future<void> setPlaybackRate(double value) async => _unsupported();
  @override
  Future<void> dispose() async {}

  Never _unsupported() => throw UnsupportedError(
    'Windows and Android audio POC has not selected a production backend',
  );
}
