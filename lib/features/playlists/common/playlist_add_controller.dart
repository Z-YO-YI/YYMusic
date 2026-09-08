import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../domain/models/collection_models.dart';
import '../../../domain/models/domain_failure.dart';
import '../../../domain/models/domain_validation.dart';
import '../../../domain/models/load_state.dart';
import '../../../domain/models/pagination.dart';
import '../../../domain/models/playlist_name_query.dart';
import '../../../domain/models/track.dart';
import '../../../domain/repositories/collection_repository.dart';
import 'playlist_command_result.dart';
import 'playlist_controller.dart';

part 'playlist_add_sessions.dart';

/// Temporary root-registered selection. No reads at construction, no media data.
final class PlaylistAddController extends ChangeNotifier {
  PlaylistAddController._(
    this.track,
    this.title,
    this._repository,
    this._writer,
    this._onClosed,
  );
  final TrackRef track;
  final String title;
  final CollectionRepository? _repository;
  final PlaylistController _writer;
  final VoidCallback _onClosed;
  final _pending = <Future<void>>{};
  StreamSubscription<void>? _subscription;
  Future<void>? _readWorker, _closeFuture;
  bool _disposed = false,
      _started = false,
      _watchReady = false,
      _readAgain = false;
  bool _active = true,
      _submitting = false,
      _cleanupFailed = false,
      _notifierDisposed = false;
  bool _filterValid = true;
  int _watchGeneration = 0,
      _readRevision = 0,
      _limit = 20,
      _notificationDepth = 0;
  PlaylistNameQuery _query = PlaylistNameQuery('');
  PageResult<Playlist>? _snapshot;
  LoadPhase _phase = LoadPhase.idle;
  String? _error, _actionError, _addedTo;
  PlaylistNameQuery get query => _query;
  PageResult<Playlist>? get snapshot => _snapshot;
  LoadPhase get phase => _phase;
  String? get error => _error;
  String? get actionError => _actionError;
  String? get addedTo => _addedTo;
  bool get busy => _submitting || _writer.busy;
  Listenable get writerChanges => _writer;
  bool get isCurrent =>
      !_disposed && (phase == LoadPhase.data || phase == LoadPhase.empty);
  bool get capped => _snapshot?.hasMore == true && _limit == 200;
  bool get canLoadMore =>
      isCurrent &&
      !busy &&
      _addedTo == null &&
      _snapshot?.hasMore == true &&
      !capped;
  bool canAdd(String id) =>
      isCurrent &&
      _active &&
      !busy &&
      _addedTo == null &&
      _writer.isAvailable &&
      (_snapshot?.items.any((p) => p.id == id && !p.isSystem) ?? false);

  void setActive(bool value) {
    if (!_disposed) _active = value;
  }

  void start() {
    if (!_disposed && !_started) refresh();
  }

  void filter(String value) {
    if (_disposed || busy || _addedTo != null) return;
    try {
      _query = PlaylistNameQuery(value);
      _filterValid = true;
    } catch (_) {
      _filterValid = false;
      _readRevision++;
      _readAgain = false;
      _phase = LoadPhase.error;
      _error = '筛选词最多512个字符，不含换行或控制字符。';
      _notify();
      return;
    }
    _limit = 20;
    _snapshot = null;
    refresh();
  }

  void refresh() {
    if (_disposed || _addedTo != null || !_filterValid) return;
    _started = true;
    final generation = ++_watchGeneration;
    _watchReady = _readAgain = false;
    _readRevision++;
    _phase = LoadPhase.loading;
    _error = null;
    final old = _subscription;
    _subscription = null;
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
        if (_repository == null) {
          throw StateError('Playlist storage unavailable');
        }
        _watchReady = true;
        final subscription = _repository.watchPlaylistContentChanges().listen(
          (_) {
            if (_currentWatch(generation) && _watchReady) _requestRead();
          },
          onError: (Object _) => _watchFailed(generation),
          onDone: () => _watchFailed(generation),
        );
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
      } catch (_) {
        if (_currentWatch(generation)) {
          _watchReady = false;
          _fail();
        }
      }
    });
    _notify();
  }

  void loadMore() {
    if (!canLoadMore) return;
    _limit = (_limit + 20).clamp(20, 200);
    _requestRead();
  }

  bool _currentWatch(int value) => !_disposed && value == _watchGeneration;
  void _watchFailed(int generation) {
    if (!_currentWatch(generation) || !_watchReady) return;
    _watchReady = _readAgain = false;
    _readRevision++;
    _fail();
  }

  void _requestRead() {
    if (_disposed || !_watchReady || _addedTo != null || !_filterValid) return;
    _readRevision++;
    _readAgain = true;
    _phase = LoadPhase.loading;
    _error = null;
    _ensureRead();
    _notify();
  }

  void _ensureRead() {
    if (_readWorker != null || _disposed || !_watchReady || !_readAgain) return;
    final work = _readWorker = _track(() async {
      while (!_disposed && _watchReady && _readAgain) {
        _readAgain = false;
        final revision = _readRevision, limit = _limit;
        final query = _query;
        try {
          final result = await _repository!.readCustomPlaylists(
            query,
            PageRequest(limit: limit),
          );
          if (!_validRead(revision)) continue;
          if (result.items.length > limit ||
              result.hasMore && result.items.length != limit ||
              result.items.map((p) => p.id).toSet().length !=
                  result.items.length ||
              result.items.any((p) => p.isSystem || !query.matches(p.name))) {
            throw StateError('Invalid playlist selection snapshot');
          }
          _snapshot = result;
          _phase = result.items.isEmpty ? LoadPhase.empty : LoadPhase.data;
          _error = null;
          _notify();
        } catch (_) {
          if (_validRead(revision)) _fail();
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
  void _fail() {
    _phase = LoadPhase.error;
    _error = '歌单读取未完成，请重试。';
    _notify();
  }

  Future<void> addTo(String id, PageResult<Playlist> snapshot) {
    if (!identical(_snapshot, snapshot) || !canAdd(id)) return Future.value();
    final name = snapshot.items.firstWhere((p) => p.id == id).name;
    _submitting = true;
    _actionError = null;
    final result = Completer<PlaylistCommandResult>();
    // Register before the root writer can notify reentrant shutdown listeners.
    final work = _track(() async {
      try {
        final outcome = await result.future;
        if (!_disposed) {
          if (outcome.succeeded) {
            _addedTo = name;
          } else {
            _actionError = outcome.message;
          }
        }
      } finally {
        _submitting = false;
        _notify();
      }
    });
    try {
      result.complete(_writer.addTrack(id, track));
    } catch (_) {
      result.complete(
        const PlaylistCommandResult(PlaylistCommandStatus.failed),
      );
    }
    _notify();
    return work;
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
            if (_cleanupFailed) {
              throw StateError('Playlist picker cleanup failed');
            }
          })
          .catchError((Object _) {
            throw DomainFailure(
              code: DomainFailureCode.unknown,
              diagnosticId: 'playlist-add.close',
            );
          })
          .whenComplete(_onClosed);
      unawaited(_closeFuture!.catchError((Object _) {}));
    }
    if (_notifierDisposed || _notificationDepth != 0) return;
    _notifierDisposed = true;
    super.dispose();
  }

  Future<void> close() {
    dispose();
    return _closeFuture!;
  }
}
