part of 'playlist_add_controller.dart';

final class PlaylistAddSessions {
  PlaylistAddSessions({this.repository, required this.writer});
  final CollectionRepository? repository;
  final PlaylistController writer;
  final _sessions = <PlaylistAddController>{};
  bool _disposed = false;
  Future<void>? _closeFuture;
  int get retainedSessionCount => _sessions.length;
  PlaylistAddController open(TrackRef track, {required String title}) {
    if (_disposed) throw StateError('Playlist add sessions closed');
    final safeTitle = DomainValidation.text(title, 'title', maxLength: 1024);
    late final PlaylistAddController session;
    session = PlaylistAddController._(
      track,
      safeTitle,
      repository,
      writer,
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
    _closeFuture = Future.wait<void>(sessions.map((s) => s.close()))
        .then((_) {});
    unawaited(_closeFuture!.catchError((Object _) {}));
  }

  Future<void> close() {
    dispose();
    return _closeFuture!;
  }
}
