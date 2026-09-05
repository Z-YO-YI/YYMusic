part of 'catalog_detail_controller.dart';

/// Lazy view of the borrowed root repository, never an independent store.
final class _DetailFavorites {
  _DetailFavorites(this._repository, this._notify, this._track);
  final CollectionRepository? _repository;
  final VoidCallback _notify;
  final Future<void> Function(Future<void> Function()) _track;
  StreamSubscription<List<FavoriteEntry>>? _subscription;
  Set<TrackRef> _values = const {};
  bool _started = false, _closed = false;
  bool ready = false;
  String? error;
  int _generation = 0;
  bool contains(TrackRef reference) => _values.contains(reference);
  bool _current(int generation) => !_closed && generation == _generation;

  void start() {
    if (!_started) retry();
  }

  void retry() {
    if (_closed) return;
    _started = true;
    final generation = ++_generation;
    final old = _subscription;
    _subscription = null;
    if (old != null) _cancel(old);
    ready = false;
    error = null;
    unawaited(
      _track(() async {
        if (!_current(generation)) return;
        try {
          final repository = _repository;
          if (repository == null) throw StateError('Favorites unavailable');
          final subscription = repository.watchFavorites().listen(
            (items) {
              if (!_current(generation)) return;
              _values = Set.unmodifiable(items.map((item) => item.track));
              ready = true;
              error = null;
              _notify();
            },
            onError: (Object _) => _failed(generation),
            onDone: () => _failed(generation),
          );
          // Stream setup may reenter close/retry before listen returns.
          // That new subscription still needs draining.
          if (!_current(generation)) {
            await subscription.cancel();
          } else {
            _subscription = subscription;
          }
        } catch (_) {
          _failed(generation);
        }
      }),
    );
    _notify();
  }

  void _failed(int generation) {
    if (!_current(generation)) return;
    ready = false;
    error = '收藏状态读取失败，请重试。';
    _notify();
  }

  void _cancel(StreamSubscription<List<FavoriteEntry>> subscription) {
    unawaited(
      _track(() async {
        try {
          await subscription.cancel();
        } catch (_) {
          // This generation has already lost permission to publish any result.
        }
      }),
    );
  }

  void close() {
    if (_closed) return;
    _closed = true;
    _generation++;
    ready = false;
    final subscription = _subscription;
    _subscription = null;
    if (subscription != null) _cancel(subscription);
  }
}
