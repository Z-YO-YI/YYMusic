part of 'playlist_content_controller.dart';

/// No shared content cache: sessions borrow the root collection repository.
final class PlaylistContentSessions {
  PlaylistContentSessions({this.repository});
  final CollectionRepository? repository;
  final _sessions = <PlaylistContentController>{};
  bool _disposed = false;
  Future<void>? _closeFuture;
  int get retainedSessionCount => _sessions.length;

  PlaylistContentController open(String playlistId) {
    if (_disposed) throw StateError('Playlist content sessions closed');
    DomainValidation.identifier(playlistId, 'playlistId');
    late final PlaylistContentController session;
    session = PlaylistContentController._(
      playlistId,
      repository,
      () => _sessions.remove(session),
    );
    _sessions.add(session);
    return session;
  }

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

  Future<void> close() {
    dispose();
    return _closeFuture!;
  }
}
