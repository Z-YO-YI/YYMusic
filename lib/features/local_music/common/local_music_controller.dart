import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../domain/models/catalog_search.dart';
import '../../../domain/models/domain_failure.dart';
import '../../../domain/models/load_state.dart';
import '../../../domain/models/local_library_overview.dart';
import '../../../domain/models/pagination.dart';
import '../../../domain/repositories/local_library_repository.dart';

/// Root-owned bounded read state. The repository and its database are borrowed.
final class LocalMusicController extends ChangeNotifier {
  LocalMusicController({this.repository});
  final LocalLibraryRepository? repository;
  static const pageSize = 20;
  final _pending = <Future<void>>{};
  StreamSubscription<void>? _subscription;
  Future<void>? _worker, _closeFuture;
  SearchCancellation? _token;
  bool _started = false, _active = false, _disposed = false;
  bool _watchReady = false, _readAgain = false, _cleanupFailed = false;
  bool _notifierDisposed = false;
  int _watchGeneration = 0, _revision = 0, _offset = 0, _notificationDepth = 0;
  LoadPhase _phase = LoadPhase.idle;
  LocalLibraryOverview? _content;
  DomainFailure? _failure;
  LoadPhase get phase => _phase;
  LocalLibraryOverview? get content => _content;
  DomainFailure? get failure => _failure;
  bool get isCurrent =>
      !_disposed &&
      _active &&
      _watchReady &&
      (phase == LoadPhase.data || phase == LoadPhase.empty);
  bool get canRefresh => !_disposed && _active && _started;
  bool get canNext => isCurrent && content!.hasMore;
  bool get canPrevious => isCurrent && content!.page.offset > 0;

  /// Explicitly started outside build; no I/O occurs until the view is active.
  void start() {
    if (_disposed || _started) return;
    _started = true;
    if (_active) refresh();
  }

  void setActive(bool value) {
    if (_disposed || _active == value) return;
    _active = value;
    if (value) {
      if (_started) refresh();
    } else {
      _disconnect();
    }
  }

  void _disconnect() {
    _watchGeneration++;
    _revision++;
    _token?.cancel();
    _readAgain = _watchReady = false;
    final old = _subscription;
    _subscription = null;
    if (old != null) _track(() => _cancel(old));
  }

  /// Reconnects changes before reading, including recovery from a closed stream.
  void refresh() {
    if (!canRefresh) return;
    _disconnect();
    final generation = _watchGeneration;
    _phase = LoadPhase.loading;
    _failure = null;
    _track(() async {
      try {
        if (!_currentWatch(generation)) return;
        final source = repository;
        if (source == null) throw StateError('Local index unavailable');
        _watchReady = true;
        final subscription = source.watchLocalChanges().listen(
          (_) {
            if (_currentWatch(generation) && _watchReady) _requestRead();
          },
          onError: (Object error) => _watchFailed(generation, error),
          onDone: () =>
              _watchFailed(generation, StateError('Local updates ended')),
        );
        if (!_currentWatch(generation)) {
          await _cancel(subscription);
          return;
        }
        _subscription = subscription;
        if (_watchReady) _requestRead();
      } catch (error) {
        if (_currentWatch(generation)) _watchFailed(generation, error);
      }
    });
    _notify();
  }

  void next(LocalLibraryOverview expected) {
    if (!canNext || !identical(content, expected)) return;
    _offset = expected.page.offset + pageSize;
    _requestRead();
  }

  void previous(LocalLibraryOverview expected) {
    if (!canPrevious || !identical(content, expected)) return;
    _offset = (expected.page.offset - pageSize).clamp(0, _offset);
    _requestRead();
  }

  bool _currentWatch(int generation) =>
      !_disposed && _active && generation == _watchGeneration;

  void _watchFailed(int generation, Object error) {
    if (!_currentWatch(generation)) return;
    _watchReady = _readAgain = false;
    _revision++;
    _token?.cancel();
    _setFailure(error, 'local-music.changes');
  }

  void _requestRead() {
    if (_disposed || !_active || !_watchReady) return;
    _revision++;
    _token?.cancel();
    _readAgain = true;
    _phase = LoadPhase.loading;
    _failure = null;
    _ensureRead();
    _notify();
  }

  void _ensureRead() {
    if (_worker != null ||
        _disposed ||
        !_active ||
        !_watchReady ||
        !_readAgain) {
      return;
    }
    final work = _worker = _track(() async {
      while (!_disposed && _active && _watchReady && _readAgain) {
        _readAgain = false;
        final revision = _revision, offset = _offset;
        final token = _token = SearchCancellation();
        try {
          final result = await repository!.readLocalOverview(
            PageRequest(offset: offset, limit: pageSize),
            cancellation: token,
          );
          if (!_validRead(revision)) continue;
          if (result.page.offset != offset || result.page.limit != pageSize) {
            throw DomainFailure(
              code: DomainFailureCode.schemaMismatch,
              diagnosticId: 'local-music.window',
            );
          }
          if (offset > 0 && offset >= result.folderCount) {
            _offset = result.folderCount == 0
                ? 0
                : ((result.folderCount - 1) ~/ pageSize) * pageSize;
            _readAgain = true;
            continue;
          }
          _content = result;
          _phase = result.folderCount == 0 && result.tracks.totalCount == 0
              ? LoadPhase.empty
              : LoadPhase.data;
          _failure = null;
          _notify();
        } catch (error) {
          if (_validRead(revision)) _setFailure(error, 'local-music.read');
        }
      }
    });
    unawaited(
      work
          .whenComplete(() {
            _worker = null;
            _ensureRead();
          })
          .catchError((Object _) {}),
    );
  }

  bool _validRead(int revision) =>
      !_disposed && _active && _watchReady && revision == _revision;

  void _setFailure(Object error, String diagnostic) {
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
    }
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
      _disconnect();
      _closeFuture = Future.wait<void>(_pending)
          .then((_) {
            if (_cleanupFailed) {
              throw StateError('Local subscription cleanup failed');
            }
          })
          .catchError((Object _) {
            throw DomainFailure(
              code: DomainFailureCode.unknown,
              diagnosticId: 'local-music.close',
            );
          });
      unawaited(_closeFuture!.catchError((Object _) {}));
    }
    if (_notifierDisposed || _notificationDepth != 0) return;
    _notifierDisposed = true;
    super.dispose();
  }

  /// Drains accepted reads and asynchronous subscription cleanup, once.
  Future<void> close() {
    dispose();
    return _closeFuture!;
  }
}
