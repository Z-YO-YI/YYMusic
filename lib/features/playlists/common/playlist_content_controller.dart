import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../domain/models/domain_failure.dart';
import '../../../domain/models/domain_validation.dart';
import '../../../domain/models/load_state.dart';
import '../../../domain/models/pagination.dart';
import '../../../domain/models/playlist_content.dart';
import '../../../domain/repositories/collection_repository.dart';
import '../../../playback/playback_controller.dart';
import 'playlist_command_result.dart';
import 'playlist_controller.dart';

part 'playlist_content_actions.dart';
part 'playlist_content_sessions.dart';

/// Root-registered projection with borrowed actions. Construction performs no work.
final class PlaylistContentController extends ChangeNotifier {
  PlaylistContentController._(
    this.playlistId,
    this._repository,
    this._onClosed,
    this._playback,
    this._writer,
  );
  final String playlistId;
  final CollectionRepository? _repository;
  final VoidCallback _onClosed;
  final PlaybackController? _playback;
  final PlaylistController? _writer;
  bool _active = true, _actionBusy = false;
  int _intent = 0;
  String? _actionError;
  String? get actionError => _actionError;
  String? _actionNote;
  String? get actionNote => _actionNote;
  bool get busy => _actionBusy || (_writer?.busy ?? false);
  Listenable? get writerChanges => _writer;
  static const pageSize = 20, maxVisibleCount = 200;
  final _pending = <Future<void>>{};
  StreamSubscription<void>? _subscription;
  Future<void>? _readWorker, _closeFuture;
  bool _disposed = false, _started = false, _watchReady = false;
  bool _readAgain = false, _cleanupFailed = false;
  bool _notifierDisposed = false;
  int _notificationDepth = 0;
  int _watchGeneration = 0, _readRevision = 0, _limit = pageSize, _offset = 0;
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
  bool get _canBrowse => !_disposed && _active && isCurrent && !busy;
  bool get canLoadMore => _canBrowse && content?.hasMore == true && !capped;
  bool get canShowNextWindow => _canBrowse && capped;
  bool get canShowPreviousWindow =>
      _canBrowse && (content?.page.offset ?? 0) > 0;

  void start() {
    if (_disposed || _started) return;
    refresh();
  }

  /// Re-establishes invalidation before re-reading the requested visible window.
  void refresh() {
    if (_disposed) return;
    _intent++;
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

  /// Expands only this consistent window, never appends a potentially stale page.
  void loadMore([PlaylistContent? expected]) {
    if (!canLoadMore || (expected != null && !identical(content, expected))) {
      return;
    }
    _limit = (_limit + pageSize).clamp(pageSize, maxVisibleCount);
    _requestRead();
  }

  /// Replaces the current window; retained callbacks cannot skip a newer group.
  void showNextWindow(PlaylistContent expected) {
    if (!canShowNextWindow || !identical(content, expected)) return;
    _offset = expected.page.offset + maxVisibleCount;
    _limit = maxVisibleCount;
    _requestRead();
  }

  /// Reads the preceding full group without keeping a second page cache.
  void showPreviousWindow(PlaylistContent expected) {
    if (!canShowPreviousWindow || !identical(content, expected)) return;
    _offset = (expected.page.offset - maxVisibleCount).clamp(0, _offset);
    _limit = maxVisibleCount;
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
    _intent++;
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
        final offset = _offset;
        try {
          final result = await _repository!.readPlaylistContent(
            playlistId,
            PageRequest(limit: limit, offset: offset),
          );
          if (!_validRead(revision)) continue;
          if (result != null &&
              (result.playlist.id != playlistId ||
                  result.page.offset != offset ||
                  result.page.limit != limit)) {
            throw DomainFailure(
              code: DomainFailureCode.schemaMismatch,
              diagnosticId: 'playlist-content.identity-mismatch',
            );
          }
          if (result != null && offset > 0 && offset >= result.totalCount) {
            // Deletion can remove this entire group. Never publish an empty
            // out-of-range window as an empty playlist; re-read the last group.
            _offset = result.totalCount == 0
                ? 0
                : ((result.totalCount - 1) ~/ maxVisibleCount) *
                      maxVisibleCount;
            _readAgain = true;
            continue;
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
    _intent++; // A failed/ended update stream cannot authorize delayed playback.
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
