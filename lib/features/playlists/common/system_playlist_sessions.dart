part of 'system_playlist_controller.dart';

/// Root-owned sessions borrow one repository and never own another queue/store.
final class SystemPlaylistSessions {
  SystemPlaylistSessions({this.repository, this.playback});
  final CollectionRepository? repository;
  final PlaybackController? playback;
  final _sessions = <SystemPlaylistController>{};
  bool _disposed = false;
  Future<void>? _closeFuture;
  int get retainedSessionCount => _sessions.length;

  /// Creates a fixed-type idle projection, not a deletable Playlist parent.
  SystemPlaylistController open(SystemPlaylistType type) {
    if (_disposed) throw StateError('System playlist sessions closed');
    late final SystemPlaylistController session;
    session = SystemPlaylistController._(
      type,
      repository,
      () => _sessions.remove(session),
      playback,
    );
    _sessions.add(session);
    return session;
  }

  /// Stops accepting work synchronously, retaining sessions until fully drained.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    final sessions = _sessions.toList();
    for (final session in sessions) {
      session.dispose();
    }
    _closeFuture = Future.wait<void>(sessions.map((session) => session.close()))
        .then((_) {});
    unawaited(_closeFuture!.catchError((Object _) {}));
  }

  /// Waits for reads and cancellations; the root may then release its database.
  Future<void> close() {
    dispose();
    return _closeFuture!;
  }
}
