import '../domain/models/domain_failure.dart';

enum AudioEnginePhase {
  idle,
  loading,
  buffering,
  ready,
  playing,
  paused,
  completed,
  error,
}

/// Backend-neutral audio facts. Playback/queue identity lives in the controller.
final class AudioEngineState {
  AudioEngineState({
    this.phase = AudioEnginePhase.idle,
    this.position = Duration.zero,
    this.buffered = Duration.zero,
    this.duration,
    this.volume = 1,
    this.playbackRate = 1,
    this.failure,
  }) {
    if (position.isNegative) {
      throw ArgumentError.value(position, 'position', 'must not be negative');
    }
    if (buffered.isNegative) {
      throw ArgumentError.value(buffered, 'buffered', 'must not be negative');
    }
    if (duration?.isNegative ?? false) {
      throw ArgumentError.value(duration, 'duration', 'must not be negative');
    }
    if (!volume.isFinite || volume < 0 || volume > 1) {
      throw ArgumentError.value(volume, 'volume', 'must be between 0 and 1');
    }
    if (!playbackRate.isFinite || playbackRate < 0.5 || playbackRate > 2) {
      throw ArgumentError.value(
        playbackRate,
        'playbackRate',
        'must be between 0.5 and 2',
      );
    }
    if ((phase == AudioEnginePhase.error) != (failure != null)) {
      throw ArgumentError('failure must be present exactly for error phase');
    }
  }

  final AudioEnginePhase phase;
  final Duration position;
  final Duration buffered;
  final Duration? duration;
  final double volume;
  final double playbackRate;
  final DomainFailure? failure;
}
