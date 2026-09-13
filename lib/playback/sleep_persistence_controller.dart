import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/models/domain_failure.dart';
import '../domain/models/sleep_timer_snapshot.dart';
import '../domain/repositories/sleep_timer_repository.dart';
import 'playback_controller.dart';
import 'playback_sleep_restore.dart';
import 'playback_sleep_timer_state.dart';

/// Persistence bridge only. The root remains the sole deadline/audio owner.
final class SleepPersistenceController extends ChangeNotifier {
  SleepPersistenceController({
    required PlaybackController playback,
    this.repository,
  }) : _playback = playback {
    _permit = playback.captureSleepRestore();
    _offObservation = playback.captureSleepRestore();
    _observed = playback.sleepTimer;
    _desired = _snapshot();
    _revision = _permit == null ? 1 : 0;
    _dirty = _revision > 0;
    playback.addListener(_changed);
  }
  final PlaybackController _playback;
  final SleepTimerRepository? repository;
  late final PlaybackSleepRestoreAction? _permit;
  PlaybackSleepRestoreAction? _offObservation;
  late PlaybackSleepTimerState _observed;
  SleepTimerSnapshot? _desired, _saved, _restoringValue;
  Future<void>? _worker, _initializing, _closing;
  DomainFailure? _failure;
  int _revision = 0, _notificationDepth = 0;
  bool _dirty = false, _loaded = false, _loading = false, _saving = false;
  bool _stopped = false, _restoring = false, _notifierDisposed = false;

  bool get persistent => repository != null;
  bool get loading => _loading;
  bool get saving => _saving;
  bool get unsaved => persistent && (_dirty || _saving);
  DomainFailure? get failure => _failure;
  bool get canRetry =>
      !_stopped &&
      _worker == null &&
      _failure != null &&
      _failure!.diagnosticId != 'sleep-persistence.restore';

  SleepTimerSnapshot? _snapshot() {
    final state = _playback.sleepTimer;
    if (state.phase != PlaybackSleepPhase.armed ||
        state.duration == null ||
        state.deadline == null) {
      return null;
    }
    return SleepTimerSnapshot(
      durationMinutes: state.duration!.duration.inMinutes,
      deadline: state.deadline!,
    );
  }

  Future<void> initialize() {
    if (_stopped) return _closing ?? Future<void>.value();
    if (!persistent) {
      _loaded = true;
      _dirty = false;
      return _initializing ??= Future<void>.value();
    }
    return _initializing ??= _start(read: _revision == 0);
  }

  void retry(DomainFailure expected) {
    if (!canRetry || !identical(_failure, expected)) return;
    _failure = null;
    unawaited(_start(read: !_loaded && _revision == 0));
  }

  void _changed() {
    if (_stopped || _restoring) return;
    final state = _playback.sleepTimer;
    if (identical(state, _observed) && (_offObservation?.isCurrent ?? true)) {
      return;
    }
    _observed = state;
    _offObservation = _playback.captureSleepRestore();
    _revision++;
    _desired = _snapshot();
    _dirty = persistent;
    _failure = null;
    _ensureSave();
    _notify();
  }

  void _ensureSave() {
    if (persistent &&
        _dirty &&
        _failure == null &&
        _worker == null &&
        (_loaded || _revision > 0)) {
      unawaited(_start(read: false));
    }
  }

  Future<void> _start({required bool read}) {
    if (_worker != null) return _worker!;
    _loading = read;
    final work = _worker =
        Future<void>(() async {
          if (read) {
            await _read();
          } else {
            _loaded = true;
          }
          while (persistent && _dirty && _failure == null) {
            final value = _desired;
            final revision = _revision;
            _saving = true;
            _notify();
            try {
              if (value == null) {
                await repository!.clear();
              } else {
                await repository!.save(value);
              }
              _saved = value;
              _dirty = _desired != _saved;
            } catch (_) {
              if (_revision == revision && _desired == value) {
                _failure = _safeFailure('save');
              }
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
      _saved = stored;
      _loaded = true;
      if (_revision > 0) {
        _dirty = true;
        return;
      }
      if (_stopped || _playback.isClosed) {
        _desired = stored;
        _dirty = false;
        return;
      }
      if (stored == null) {
        _desired = null;
        _dirty = false;
        return;
      }
      _restoring = true;
      _restoringValue = stored;
      _desired = stored;
      late PlaybackSleepRestoreResult result;
      try {
        result = _permit?.call(stored) ?? PlaybackSleepRestoreResult.superseded;
      } finally {
        _restoring = false;
        _restoringValue = null;
      }
      if (_stopped) return;
      _observed = _playback.sleepTimer;
      _offObservation = _playback.captureSleepRestore();
      _desired = _snapshot();
      switch (result) {
        case PlaybackSleepRestoreResult.restored:
          _dirty = _desired != stored;
        case PlaybackSleepRestoreResult.expired:
          _dirty = true;
        case PlaybackSleepRestoreResult.superseded:
          _revision++;
          _dirty = true;
        case PlaybackSleepRestoreResult.unavailable:
        case PlaybackSleepRestoreResult.failed:
          _dirty = false;
          _failure = _safeFailure('restore');
      }
    } catch (error) {
      if (_revision > 0) {
        _loaded = true;
        _dirty = true;
      } else if (error is DomainFailure &&
          error.code == DomainFailureCode.schemaMismatch) {
        _loaded = true;
        _desired = null;
        _dirty = !_stopped;
      } else {
        _failure = _safeFailure('load');
      }
    } finally {
      _loading = false;
    }
  }

  static DomainFailure _safeFailure(String operation) => DomainFailure(
    code: DomainFailureCode.databaseCorrupted,
    diagnosticId: 'sleep-persistence.$operation',
    retryable: operation != 'restore',
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
      // Freeze accepted intent before root shutdown cancels its session timer.
      if (!_playback.isClosed) {
        final actual = _snapshot();
        if (actual != (_restoring ? _restoringValue : _desired) ||
            (!_restoring && !(_offObservation?.isCurrent ?? true))) {
          _desired = actual;
          _revision++;
          _dirty = persistent;
          _failure = null;
        }
      }
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
    if (persistent && _dirty) throw _safeFailure('close');
  }

  Future<void> close() {
    dispose();
    return _closing!;
  }
}
