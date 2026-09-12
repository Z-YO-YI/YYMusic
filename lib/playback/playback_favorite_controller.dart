import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/models/collection_models.dart';
import '../domain/models/domain_failure.dart';
import '../domain/models/track.dart';
import '../domain/repositories/collection_repository.dart';
import 'playback_controller.dart';

part 'playback_favorite_state.dart';
part 'playback_favorite_actions.dart';

/// Root-owned read projection and guarded writes; never owns audio or storage.
final class PlaybackFavoriteController extends ChangeNotifier {
  PlaybackFavoriteController({required this._playback, this._repository}) {
    _rebuild();
    _playback.addListener(_playbackChanged);
  }

  final PlaybackController _playback;
  final CollectionRepository? _repository;
  late PlaybackFavoriteState _state;
  Set<TrackRef> _favorites = const {};
  StreamSubscription<List<FavoriteEntry>>? _subscription;
  final _pending = <Future<void>>{};
  bool _started = false, _ready = false, _busy = false, _watchHealthy = false;
  bool _armed = false;
  bool _closed = false, _notifierDisposed = false, _cleanupFailed = false;
  int _generation = 0, _notificationDepth = 0;
  Future<void>? _closeFuture;
  PlaybackFavoriteFailure? _failure;

  PlaybackFavoriteState get state => _state;
  bool get ready => _ready;
  bool get busy => _busy;
  PlaybackFavoriteFailure? get failure => _failure;

  /// Arms the projection; no collection query until a current entry exists.
  void start() {
    if (_closed) return;
    _armed = true;
    if (!_started && state.reference != null) retryRead();
  }

  /// Explicitly replaces the read subscription and revokes all old projections.
  void retryRead() {
    if (_closed) return;
    _armed = true;
    _started = true;
    final generation = ++_generation;
    final old = _subscription;
    _subscription = null;
    _ready = _watchHealthy = false;
    if (_failure?.kind == PlaybackFavoriteFailureKind.read) _failure = null;
    _rebuild();
    _track(() async {
      try {
        if (old != null) await _cancel(old);
        if (!_currentGeneration(generation)) return;
        final repository = _repository;
        if (repository == null) throw StateError('Favorites unavailable');
        _watchHealthy = true;
        final subscription = repository.watchFavorites().listen(
          (items) {
            if (!_currentGeneration(generation) || !_watchHealthy) return;
            _favorites = Set.unmodifiable(items.map((item) => item.track));
            _ready = true;
            if (_failure?.kind == PlaybackFavoriteFailureKind.read) {
              _failure = null;
            }
            _rebuild();
            _notify();
          },
          onError: (Object _) => _readFailed(generation),
          onDone: () => _readFailed(generation),
        );
        // A custom listen may synchronously retry or close the root.
        if (!_currentGeneration(generation)) {
          await _cancel(subscription);
        } else {
          _subscription = subscription;
        }
      } catch (_) {
        _readFailed(generation);
      }
    });
    _notify();
  }

  bool _currentGeneration(int generation) =>
      !_closed && generation == _generation;

  void _readFailed(int generation) {
    if (!_currentGeneration(generation)) return;
    _ready = _watchHealthy = false;
    _rebuild();
    _failure = PlaybackFavoriteFailure._(
      PlaybackFavoriteFailureKind.read,
      state,
      null,
    );
    _notify();
  }

  void _playbackChanged() {
    if (_closed || identical(state.queue, _playback.state.queue)) return;
    _rebuild();
    if (_armed && !_started && state.reference != null) {
      retryRead();
      return;
    }
    _notify();
  }

  void _rebuild() {
    final queue = _playback.state.queue;
    final entry = queue.entries
        .where((item) => item.id == queue.currentEntryId)
        .firstOrNull;
    _state = PlaybackFavoriteState._(
      queue,
      entry?.track,
      _ready && entry != null ? _favorites.contains(entry.track) : null,
    );
  }

  Future<void> _track(Future<void> Function() action) {
    late final Future<void> work;
    work = Future<void>(action).whenComplete(() => _pending.remove(work));
    _pending.add(work);
    unawaited(work.catchError((Object _) {}));
    return work;
  }

  Future<void> _cancel(
    StreamSubscription<List<FavoriteEntry>> subscription,
  ) async {
    try {
      await subscription.cancel();
    } catch (_) {
      _cleanupFailed = true;
      rethrow;
    }
  }

  void _notify() {
    if (_closed) return;
    _notificationDepth++;
    try {
      notifyListeners();
    } finally {
      _notificationDepth--;
      if (_closed) dispose();
    }
  }

  /// Rejects new work immediately; use close to drain accepted repository writes.
  @override
  void dispose() {
    if (!_closed) {
      _closed = true;
      _ready = _watchHealthy = false;
      _generation++;
      _playback.removeListener(_playbackChanged);
      final subscription = _subscription;
      _subscription = null;
      if (subscription != null) _track(() => _cancel(subscription));
      _closeFuture = Future.wait<void>(_pending)
          .then((_) {
            if (_cleanupFailed) throw StateError('Favorite cleanup failed');
          })
          .catchError((Object _) {
            throw DomainFailure(
              code: DomainFailureCode.unknown,
              diagnosticId: 'playback-favorite.close',
            );
          });
      unawaited(_closeFuture!.catchError((Object _) {}));
    }
    if (_notifierDisposed || _notificationDepth != 0) return;
    _notifierDisposed = true;
    super.dispose();
  }

  /// Idempotent resource barrier; does not dispose the borrowed player or store.
  Future<void> close() {
    dispose();
    return _closeFuture!;
  }
}
