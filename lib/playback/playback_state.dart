enum PlaybackPhase { unavailable, idle, loading, playing, paused, error }

final class PlaybackState {
  const PlaybackState({
    this.phase = PlaybackPhase.unavailable,
    this.position = Duration.zero,
  });

  final PlaybackPhase phase;
  final Duration position;
}
