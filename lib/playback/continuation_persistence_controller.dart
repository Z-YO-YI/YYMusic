import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/models/domain_failure.dart';
import '../domain/repositories/playback_continuation_repository.dart';
import 'playback_continuation_restore.dart';
import 'playback_controller.dart';

/// Borrows storage and playback; owns only preference I/O and safe feedback.
final class ContinuationPersistenceController extends ChangeNotifier {
  ContinuationPersistenceController({
    required PlaybackController playback,
    this.repository,
  }) : _playback = playback {
    _permit = playback.captureContinuationRestore();
    _observed = playback.continuationIntentRevision;
    _desired = playback.continueAfterTrack;
    _dirty = persistent && _observed > 0;
    playback.addListener(_changed);
  }

  final PlaybackController _playback;
  final PlaybackContinuationRepository? repository;
  late final PlaybackContinuationRestoreAction? _permit;
  late int _observed;
  late bool _desired;
  bool _dirty = false, _loaded = false, _stopped = false;
  bool _loading = false, _saving = false, _notifierDisposed = false;
  int? _restoringRevision;
  int _notificationDepth = 0;
  DomainFailure? _failure;
  Future<void>? _worker, _initializing, _closing;

  bool get persistent => repository != null;
  bool get loading => _loading;
  bool get saving => _saving;
  bool get unsaved => persistent && (_dirty || _saving);
  DomainFailure? get failure => _failure;
  bool get canRetry => !_stopped && _worker == null && _failure != null;

  /// Explicit UI choice, including the unchanged default after a read failure.
  void setEnabled(bool enabled) {
    if (_stopped || _playback.isClosed) return;
    _playback.setContinueAfterTrack(enabled);
    _changed();
  }

  Future<void> initialize() {
    if (_stopped) return _closing ?? Future<void>.value();
    _observe();
    if (!persistent) return _initializing ??= Future<void>.value();
    return _initializing ??= _start(read: !_dirty);
  }

  /// A stale error cannot retry or dismiss a newer failure.
  void retry(DomainFailure expected) {
    if (!canRetry || !identical(expected, _failure)) return;
    _observe();
    _failure = null;
    unawaited(_start(read: !_loaded && !_dirty));
  }

  void _observe() {
    final revision = _playback.continuationIntentRevision;
    // The restore itself is not a user edit, including shutdown in its listener.
    if (revision == _observed ||
        (_restoringRevision != null && revision == _restoringRevision! + 1)) {
      return;
    }
    _observed = revision;
    _desired = _playback.continueAfterTrack;
    _dirty = persistent;
    _failure = null;
  }

  void _changed() {
    if (_stopped || _restoringRevision != null) return;
    final previous = _observed;
    _observe();
    if (previous == _observed) return;
    _ensureSave();
    _notify();
  }

  void _ensureSave() {
    if (persistent && _dirty && _failure == null && _worker == null) {
      unawaited(_start(read: false));
    }
  }

  Future<void> _start({required bool read}) {
    if (_worker != null) return _worker!;
    _loading = read;
    final work = _worker =
        Future<void>.microtask(() async {
          if (read) await _read();
          while (_dirty && _failure == null) {
            final value = _desired;
            final revision = _observed;
            _saving = true;
            _notify();
            try {
              await repository!.save(value);
              _loaded = true;
              _dirty = _desired != value;
            } catch (_) {
              if (_observed == revision) _failure = _safeFailure('save');
            } finally {
              _saving = false;
            }
          }
        }).whenComplete(() {
          _worker = null;
          _ensureSave();
          _notify();
        });
    unawaited(work.catchError((Object _) {}));
    _notify();
    return work;
  }

  Future<void> _read() async {
    try {
      final stored = await repository!.read();
      if (!_stopped) _observe();
      _loaded = true;
      if (_dirty || _stopped || _playback.isClosed || stored == null) return;
      if (!(_permit?.isCurrent ?? false)) return;
      _restoringRevision = _playback.continuationIntentRevision;
      final result = _permit!(stored);
      if (result == PlaybackContinuationRestoreResult.restored) {
        _observed = _playback.continuationIntentRevision;
        _desired = stored;
      } else if (!_stopped) {
        _observe();
      }
    } catch (_) {
      if (!_stopped) _observe();
      if (!_dirty) _failure = _safeFailure('load');
    } finally {
      _restoringRevision = null;
      _loading = false;
    }
  }

  static DomainFailure _safeFailure(String operation) => DomainFailure(
    code: DomainFailureCode.databaseCorrupted,
    diagnosticId: 'continuation-persistence.$operation',
    retryable: true,
  );

  void _notify() {
    if (_stopped) return;
    _notificationDepth++;
    try {
      notifyListeners();
    } finally {
      _notificationDepth--;
      if (_stopped) dispose();
    }
  }

  @override
  void dispose() {
    if (!_stopped) {
      _observe();
      _stopped = true;
      _playback.removeListener(_changed);
      _ensureSave();
      _closing = _drain();
      unawaited(_closing!.catchError((Object _) {}));
    }
    if (_notifierDisposed || _notificationDepth != 0) return;
    _notifierDisposed = true;
    super.dispose();
  }

  Future<void> _drain() async {
    while (_worker != null) {
      await _worker!;
    }
    if (_dirty) throw _safeFailure('close');
  }

  /// Freezes accepted intent and drains writes, without closing borrowed owners.
  Future<void> close() {
    dispose();
    return _closing!;
  }
}
