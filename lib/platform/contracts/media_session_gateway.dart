import '../../domain/models/track.dart';
import '../../playback/playback_state.dart';

typedef MediaSessionAction = Future<void> Function();
typedef MediaSessionSeekAction = Future<void> Function(Duration position);

final class MediaSessionCallbacks {
  const MediaSessionCallbacks({
    required this.play,
    required this.pause,
    required this.stop,
    required this.skipNext,
    required this.skipPrevious,
    required this.seek,
  });

  final MediaSessionAction play;
  final MediaSessionAction pause;
  final MediaSessionAction stop;
  final MediaSessionAction skipNext;
  final MediaSessionAction skipPrevious;
  final MediaSessionSeekAction seek;
}

/// Android MediaSession and Windows SMTC implementations share this boundary.
abstract interface class MediaSessionGateway {
  bool get isAvailable;
  Future<void> initialize(MediaSessionCallbacks callbacks);
  Future<void> updateMetadata(Track track);
  Future<void> updatePlaybackState(PlaybackState state);
  Future<void> clear();
  Future<void> dispose();
}

final class UnavailableMediaSessionGateway implements MediaSessionGateway {
  const UnavailableMediaSessionGateway();

  @override
  bool get isAvailable => false;
  @override
  Future<void> initialize(MediaSessionCallbacks callbacks) async {}
  @override
  Future<void> updateMetadata(Track track) async {}
  @override
  Future<void> updatePlaybackState(PlaybackState state) async {}
  @override
  Future<void> clear() async {}
  @override
  Future<void> dispose() async {}
}
