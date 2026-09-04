import '../domain/models/collection_models.dart';
import '../domain/models/domain_failure.dart';
import '../domain/models/domain_validation.dart';
import '../domain/models/track.dart';

enum PlaybackPhase {
  idle,
  loading,
  buffering,
  ready,
  playing,
  paused,
  completed,
  error,
}

enum RepeatMode { off, all, one }

final class PlaybackOutputDevice {
  PlaybackOutputDevice({
    required String id,
    required String name,
    this.isSystemDefault = false,
  }) : id = DomainValidation.identifier(id, 'id'),
       name = DomainValidation.text(name, 'name', maxLength: 512);

  final String id;
  final String name;
  final bool isSystemDefault;
}

/// The application's single playback truth, independent of audio plugin types.
final class PlaybackState {
  factory PlaybackState({
    PlaybackPhase phase = PlaybackPhase.idle,
    Track? currentTrack,
    Duration position = Duration.zero,
    Duration buffered = Duration.zero,
    Duration? duration,
    double volume = 1,
    double playbackRate = 1,
    bool shuffleEnabled = false,
    RepeatMode repeatMode = RepeatMode.off,
    QueueSnapshot? queue,
    PlaybackOutputDevice? outputDevice,
    DomainFailure? failure,
  }) {
    final safeQueue = queue ?? _emptyQueue();
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
    if ((phase == PlaybackPhase.error) != (failure != null)) {
      throw ArgumentError('failure must be present exactly for error phase');
    }
    final currentId = safeQueue.currentEntryId;
    if (currentTrack != null &&
        (currentId == null ||
            safeQueue.entries
                    .where((entry) => entry.id == currentId)
                    .single
                    .track !=
                currentTrack.ref)) {
      throw ArgumentError(
        'currentTrack must match the queue current entry reference',
      );
    }
    return PlaybackState._(
      phase: phase,
      currentTrack: currentTrack,
      position: position,
      buffered: buffered,
      duration: duration,
      volume: volume,
      playbackRate: playbackRate,
      shuffleEnabled: shuffleEnabled,
      repeatMode: repeatMode,
      queue: safeQueue,
      outputDevice: outputDevice,
      failure: failure,
    );
  }

  const PlaybackState._({
    required this.phase,
    required this.currentTrack,
    required this.position,
    required this.buffered,
    required this.duration,
    required this.volume,
    required this.playbackRate,
    required this.shuffleEnabled,
    required this.repeatMode,
    required this.queue,
    required this.outputDevice,
    required this.failure,
  });

  final PlaybackPhase phase;
  final Track? currentTrack;
  final Duration position;
  final Duration buffered;
  final Duration? duration;
  final double volume;
  final double playbackRate;
  final bool shuffleEnabled;
  final RepeatMode repeatMode;
  final QueueSnapshot queue;
  final PlaybackOutputDevice? outputDevice;
  final DomainFailure? failure;

  PlaybackState copyWith({
    PlaybackPhase? phase,
    Object? currentTrack = _unchanged,
    Duration? position,
    Duration? buffered,
    Object? duration = _unchanged,
    double? volume,
    double? playbackRate,
    bool? shuffleEnabled,
    RepeatMode? repeatMode,
    QueueSnapshot? queue,
    Object? outputDevice = _unchanged,
    Object? failure = _unchanged,
  }) => PlaybackState(
    phase: phase ?? this.phase,
    currentTrack: identical(currentTrack, _unchanged)
        ? this.currentTrack
        : currentTrack as Track?,
    position: position ?? this.position,
    buffered: buffered ?? this.buffered,
    duration: identical(duration, _unchanged)
        ? this.duration
        : duration as Duration?,
    volume: volume ?? this.volume,
    playbackRate: playbackRate ?? this.playbackRate,
    shuffleEnabled: shuffleEnabled ?? this.shuffleEnabled,
    repeatMode: repeatMode ?? this.repeatMode,
    queue: queue ?? this.queue,
    outputDevice: identical(outputDevice, _unchanged)
        ? this.outputDevice
        : outputDevice as PlaybackOutputDevice?,
    failure: identical(failure, _unchanged)
        ? this.failure
        : failure as DomainFailure?,
  );
}

const _unchanged = Object();

QueueSnapshot _emptyQueue() => QueueSnapshot(
  entries: const [],
  updatedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
);
