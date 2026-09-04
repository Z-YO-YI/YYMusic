import 'audio_engine_state.dart';
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
