part of 'catalog_detail_controller.dart';

/// Root lifecycle registry, not a second catalog or a cache of all opened pages.
/// A closing session remains registered until its borrowed reads have drained.
final class CatalogDetailSessions {
  CatalogDetailSessions({this.repository});
  final CatalogBrowseRepository? repository;
  final _sessions = <CatalogDetailController>{};
  bool _disposed = false;
  Future<void>? _closeFuture;
  int get retainedSessionCount => _sessions.length;

  /// Creates an idle, independent projection. The caller must eventually close it.
  CatalogDetailController open(CatalogDetailTarget target) {
    if (_disposed) throw StateError('Catalog details closed');
    late final CatalogDetailController session;
    session = CatalogDetailController._(
      target,
      repository,
      () => _sessions.remove(session),
    );
    _sessions.add(session);
    return session;
  }

  /// Synchronously rejects new work before the shared database starts closing.
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
