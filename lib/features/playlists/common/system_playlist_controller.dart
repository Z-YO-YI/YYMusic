import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../domain/models/collection_models.dart';
import '../../../domain/models/domain_failure.dart';
import '../../../domain/models/load_state.dart';
import '../../../domain/models/pagination.dart';
import '../../../domain/models/system_playlist_content.dart';
import '../../../domain/repositories/collection_repository.dart';
import '../../../playback/playback_controller.dart';
import 'system_playlist_writer.dart';

part 'system_playlist_sessions.dart';
part 'system_playlist_actions.dart';

/// A fixed-type read window with guarded commands delegated to the root writer.
/// Construction is idle; callers explicitly start outside Widget.build.
final class SystemPlaylistController extends ChangeNotifier {
  SystemPlaylistController._(
    this.type,
    this._repository,
    this._onClosed,
    this._playback,
    this._writer,
  ) {
    _writer.addListener(_notify);
  }

  final SystemPlaylistType type;
  final CollectionRepository? _repository;
  final VoidCallback _onClosed;
  final PlaybackController? _playback;
  final SystemPlaylistWriter _writer;
  bool _actionBusy = false;
  int _intent = 0;
  String? _actionError;
  bool get busy => _actionBusy || _writer.busy;
  bool get writeBusy => _writer.busy;
  SystemPlaylistWriteFailure? get writeFailure => _writer.failure;
  String? get actionError => _actionError;
  String? get currentQueueEntryId => _playback?.state.queue.currentEntryId;
  static const pageSize = 20, maxVisibleCount = 200;
  final _pending = <Future<void>>{};
  StreamSubscription<void>? _subscription;
  Future<void>? _readWorker, _closeFuture;
  bool _disposed = false, _started = false, _active = true;
  bool _watchReady = false, _readAgain = false, _cleanupFailed = false;
  bool _notifierDisposed = false;
  int _notificationDepth = 0, _watchGeneration = 0, _readRevision = 0;
  int _limit = pageSize, _offset = 0;
  LoadPhase _phase = LoadPhase.idle;
  SystemPlaylistContent? _content;
  DomainFailure? _failure;

  LoadPhase get phase => _phase;

  /// Previous data may remain visible during loading/error, but is not current.
  SystemPlaylistContent? get content => _content;
  DomainFailure? get failure => _failure;
  bool get loading => phase == LoadPhase.loading;
  bool get isCurrent =>
      !_disposed && (phase == LoadPhase.data || phase == LoadPhase.empty);
  bool get capped =>
      content?.hasMore == true && content!.page.limit >= maxVisibleCount;
  bool get _canBrowse => _active && isCurrent && !busy;
  bool get canLoadMore => _canBrowse && content?.hasMore == true && !capped;
  bool get canShowNextWindow => _canBrowse && capped;
  bool get canShowPreviousWindow =>
      _canBrowse && (content?.page.offset ?? 0) > 0;

  /// Hiding blocks retained callbacks and pending starts, not started audio.
  /// Its bounded projection can still refresh while hidden.
  void setActive(bool value) {
    if (_disposed || _active == value) return;
    _active = value;
    if (!value) _intent++;
  }

  /// Idempotent explicit start; opening a session alone performs no I/O.
  void start() {
    if (_disposed || _started) return;
    refresh();
  }

  /// Rebinds a queue read after root publication without cancelling its play.
  void refreshQueueProjection() {
    if (type == SystemPlaylistType.queue) _requestRead();
  }

  /// Re-subscribes before reading the same target window, including after error.
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
        if (old != null) await _cancel(old);
        if (!_currentWatch(generation)) return;
        final repository = _repository;
        if (repository == null) throw StateError('System content unavailable');
        _watchReady = true;
        final subscription = repository
            .watchSystemPlaylistChanges(type)
            .listen(
              (_) {
                if (_currentWatch(generation) && _watchReady) _requestRead();
              },
              onError: (Object error) => _watchFailed(generation, error),
              onDone: () =>
                  _watchFailed(generation, StateError('System updates ended')),
            );
        // A custom getter/listen may synchronously refresh or close the root.
        // This entire task remains registered until cancellation has completed.
        if (!_currentWatch(generation)) {
          await _cancel(subscription);
          return;
        }
        _subscription = subscription;
        if (_watchReady) _requestRead();
      } catch (error) {
        if (!_currentWatch(generation)) return;
        _watchReady = false;
        _setFailure(error, 'system-playlist.changes');
      }
    });
    _notify();
  }

  /// Replaces the entire expanded window; never joins different query snapshots.
  void loadMore(SystemPlaylistContent expected) {
    if (!canLoadMore || !identical(content, expected)) return;
    _intent++;
    _limit = (_limit + pageSize).clamp(pageSize, maxVisibleCount);
    _requestRead();
  }

  /// Stale callbacks cannot skip over a newer group.
  void showNextWindow(SystemPlaylistContent expected) {
    if (!canShowNextWindow || !identical(content, expected)) return;
    _intent++;
    _offset = expected.page.offset + maxVisibleCount;
    _limit = maxVisibleCount;
    _requestRead();
  }

  /// Reads the preceding group without retaining a second content cache.
  void showPreviousWindow(SystemPlaylistContent expected) {
    if (!canShowPreviousWindow || !identical(content, expected)) return;
    _intent++;
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
    _setFailure(error, 'system-playlist.changes');
  }

  void _requestRead() {
    if (_disposed || !_watchReady) return;
    // The queue current-ID write is part of its own accepted playback command.
    if (type != SystemPlaylistType.queue) _intent++;
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
        final revision = _readRevision, limit = _limit, offset = _offset;
        try {
          final result = await _repository!.readSystemPlaylistContent(
            type,
            PageRequest(limit: limit, offset: offset),
          );
          if (!_validRead(revision)) continue;
          if (result.type != type ||
              result.page.offset != offset ||
              result.page.limit != limit) {
            throw DomainFailure(
              code: DomainFailureCode.schemaMismatch,
              diagnosticId: 'system-playlist.identity-mismatch',
            );
          }
          if (offset > 0 && offset >= result.totalCount) {
            // Never show an out-of-range page as an empty system collection.
            _offset = result.totalCount == 0
                ? 0
                : ((result.totalCount - 1) ~/ maxVisibleCount) *
                      maxVisibleCount;
            _readAgain = true;
            continue;
          }
          _content = result;
          _phase = result.entries.isEmpty ? LoadPhase.empty : LoadPhase.data;
          _failure = null;
          _notify();
        } catch (error) {
          if (_validRead(revision)) _setFailure(error, 'system-playlist.read');
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
    _intent++;
    _phase = LoadPhase.error;
    _failure = DomainFailure(
      code: error is DomainFailure ? error.code : DomainFailureCode.unknown,
      diagnosticId: diagnostic,
      retryable: true,
    );
    _notify();
  }

  Future<void> _cancel(StreamSubscription<void> subscription) async {
    try {
      await subscription.cancel();
    } catch (_) {
      _cleanupFailed = true;
      rethrow;
    }
  }

  Future<void> _track(Future<void> Function() action) {
    late final Future<void> work;
    // Registration precedes execution, including reentrant listener shutdown.
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

  /// Stops accepting work immediately; use close to await actual resource drain.
  @override
  void dispose() {
    if (!_disposed) {
      _disposed = true;
      _writer.removeListener(_notify);
      _watchGeneration++;
      _readRevision++;
      _readAgain = _watchReady = false;
      final subscription = _subscription;
      _subscription = null;
      if (subscription != null) _track(() => _cancel(subscription));
      _closeFuture = Future.wait<void>(_pending)
          .then((_) {
            if (_cleanupFailed) throw StateError('System cleanup failed');
          })
          .catchError((Object _) {
            throw DomainFailure(
              code: DomainFailureCode.unknown,
              diagnosticId: 'system-playlist.close',
            );
          })
          .whenComplete(_onClosed);
      unawaited(_closeFuture!.catchError((Object _) {}));
    }
    if (_notifierDisposed || _notificationDepth != 0) return;
    _notifierDisposed = true;
    super.dispose();
  }

  /// Idempotently drains subscribed/accepted work before releasing registration.
  Future<void> close() {
    dispose();
    return _closeFuture!;
  }
}
