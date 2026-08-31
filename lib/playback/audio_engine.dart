import 'playback_state.dart';

/// Phase 1 lifecycle boundary. Track loading is designed with Phase 3 models.
abstract interface class AudioEngine {
  bool get isAvailable;
  Stream<PlaybackState> get states;
  Future<void> play();
  Future<void> pause();
  Future<void> dispose();
}

/// Deliberately reports no backend, never simulates successful playback.
final class UnavailableAudioEngine implements AudioEngine {
  @override
  bool get isAvailable => false;
  @override
  Stream<PlaybackState> get states => const Stream.empty();
  @override
  Future<void> play() async =>
      throw UnsupportedError('Audio POC not implemented');
  @override
  Future<void> pause() async =>
      throw UnsupportedError('Audio POC not implemented');
  @override
  Future<void> dispose() async {}
}
