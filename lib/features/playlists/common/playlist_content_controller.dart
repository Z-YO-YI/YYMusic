import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../domain/models/domain_failure.dart';
import '../../../domain/models/domain_validation.dart';
import '../../../domain/models/load_state.dart';
import '../../../domain/models/pagination.dart';
import '../../../domain/models/playlist_content.dart';
import '../../../domain/repositories/collection_repository.dart';

part 'playlist_content_sessions.dart';

/// Root-registered, read-only projection. Construction performs no work.
final class PlaylistContentController extends ChangeNotifier {
  PlaylistContentController._(
    this.playlistId,
    this._repository,
    this._onClosed,
  );
  final String playlistId;
  final CollectionRepository? _repository;
  final VoidCallback _onClosed;
  static const pageSize = 20, maxVisibleCount = 200;
  final _pending = <Future<void>>{};
  StreamSubscription<void>? _subscription;
  Future<void>? _readWorker, _closeFuture;
  bool _disposed = false, _started = false, _watchReady = false;
  bool _readAgain = false, _cleanupFailed = false;
  bool _notifierDisposed = false;
  int _notificationDepth = 0;
  int _watchGeneration = 0, _readRevision = 0, _limit = pageSize;
  LoadPhase _phase = LoadPhase.idle;
  PlaylistContent? _content;
  DomainFailure? _failure;
  LoadPhase get phase => _phase;
  PlaylistContent? get content => _content;
  DomainFailure? get failure => _failure;
  bool get loading => phase == LoadPhase.loading;
  bool get missing => phase == LoadPhase.empty && content == null;
  bool get isCurrent =>
      !_disposed && (phase == LoadPhase.data || phase == LoadPhase.empty);
  bool get capped =>
      content?.hasMore == true && content!.page.limit >= maxVisibleCount;
  bool get canLoadMore =>
      !_disposed && isCurrent && content?.hasMore == true && !capped;

  void start() {
    if (_disposed || _started) return;
    refresh();
  }

  /// Re-establishes invalidation before re-reading the requested visible window.
  void refresh() {
    if (_disposed) return;
    _started = true;
    final generation = ++_watchGeneration;
    _watchReady = false;
    _readRevision++;
    _readAgain = false;
    final old = _subscription;
    _subscription = null;
    _phase = LoadPhase.loading;
    _failure = null;
    _track(() async {
      try {
        if (old != null) {
          try {
            await old.cancel();
          } catch (_) {
            _cleanupFailed = true;
            rethrow;
          }
        }
        if (!_currentWatch(generation)) return;
        final repository = _repository;
        if (repository == null) {
          throw StateError('Playlist content unavailable');
        }
        _watchReady = true;
        final subscription = repository.watchPlaylistContentChanges().listen(
          (_) {
            if (_currentWatch(generation) && _watchReady) _requestRead();
          },
          onError: (Object error) => _watchFailed(generation, error),
          onDone: () =>
              _watchFailed(generation, StateError('Content updates ended')),
        );
        // A custom stream getter or listen can synchronously close/refresh us.
        if (!_currentWatch(generation)) {
          try {
            await subscription.cancel();
          } catch (_) {
            _cleanupFailed = true;
            rethrow;
          }
          return;
        }
        _subscription = subscription;
        if (_watchReady) _requestRead();
      } catch (error) {
        if (!_currentWatch(generation)) return;
        _watchReady = false;
        _setFailure(error, 'playlist-content.changes');
      }
    });
    _notify();
  }

  /// Expands a single consistent prefix, never appends a potentially stale page.
  void loadMore() {
    if (!canLoadMore) return;
    _limit = (_limit + pageSize).clamp(pageSize, maxVisibleCount);
    _requestRead();
  }

  bool _currentWatch(int generation) =>
      !_disposed && generation == _watchGeneration;

  void _watchFailed(int generation, Object error) {
    if (!_currentWatch(generation) || !_watchReady) return;
    _watchReady = false;
    _readRevision++;
    _readAgain = false;
    _setFailure(error, 'playlist-content.changes');
  }

  void _requestRead() {
    if (_disposed || !_watchReady) return;
    _readRevision++;
    _readAgain = true;
    _phase = LoadPhase.loading;
    _failure = null;
    _ensureRead();
    _notify();
  }

  void _ensureRead() {
    if (_readWorker != null || _disposed || !_watchReady || !_readAgain) return;
    final work = _readWorker = _track(() async {
      while (!_disposed && _watchReady && _readAgain) {
        _readAgain = false;
        final revision = _readRevision;
        final limit = _limit;
        try {
          final result = await _repository!.readPlaylistContent(
            playlistId,
            PageRequest(limit: limit),
          );
          if (!_validRead(revision)) continue;
          if (result != null &&
              (result.playlist.id != playlistId ||
                  result.page.offset != 0 ||
                  result.page.limit != limit)) {
            throw DomainFailure(
              code: DomainFailureCode.schemaMismatch,
              diagnosticId: 'playlist-content.identity-mismatch',
            );
          }
          _content = result;
          _phase = result == null || result.entries.isEmpty
              ? LoadPhase.empty
              : LoadPhase.data;
          _failure = null;
          _notify();
        } catch (error) {
          if (_validRead(revision)) _setFailure(error, 'playlist-content.read');
        }
      }
    });
    unawaited(
      work
          .whenComplete(() {
            _readWorker = null;
            _ensureRead();
          })
          .catchError((Object _) {}),
    );
  }

  bool _validRead(int revision) =>
      !_disposed && _watchReady && revision == _readRevision;

  void _setFailure(Object error, String diagnostic) {
    _phase = LoadPhase.error;
    _failure = DomainFailure(
      code: error is DomainFailure ? error.code : DomainFailureCode.unknown,
      diagnosticId: diagnostic,
      retryable: true,
    );
    _notify();
  }

  Future<void> _track(Future<void> Function() action) {
    late final Future<void> work;
    work = Future<void>(action).whenComplete(() => _pending.remove(work));
    _pending.add(work);
    unawaited(work.catchError((Object _) {}));
    return work;
  }

  void _notify() {
    if (_disposed) return;
    _notificationDepth++;
    try {
      notifyListeners();
    } finally {
      _notificationDepth--;
      if (_disposed) dispose();
    }
  }

  @override
  void dispose() {
    if (!_disposed) {
      _disposed = true;
      _watchGeneration++;
      _readRevision++;
      _readAgain = _watchReady = false;
      final subscription = _subscription;
      _subscription = null;
      if (subscription != null) _track(subscription.cancel);
      _closeFuture = Future.wait<void>(_pending)
          .then((_) {
            if (_cleanupFailed) throw StateError('Content cleanup failed');
          })
          .catchError((Object _) {
            throw DomainFailure(
              code: DomainFailureCode.unknown,
              diagnosticId: 'playlist-content.close',
            );
          })
          .whenComplete(_onClosed);
      unawaited(_closeFuture!.catchError((Object _) {}));
    }
    // A listener can synchronously close the root while we are notifying it.
    // Register and stop work immediately, but let that notification unwind.
    if (_notifierDisposed || _notificationDepth != 0) return;
    _notifierDisposed = true;
    super.dispose();
  }

  Future<void> close() {
    dispose();
    return _closeFuture!;
  }
}
