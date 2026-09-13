part of 'playback_controller.dart';

extension _SleepDeadlineActions on PlaybackController {
  bool get _canSleepAtCurrentEntryEnd {
    final entryId = _loadedEntryId;
    if (_disposed ||
        (_nativeSequence?.pending.isNotEmpty ?? false) ||
        !_engine.isAvailable ||
        _loadingSource ||
        entryId == null ||
        entryId != _state.queue.currentEntryId ||
        _state.currentTrack == null ||
        !const {
          PlaybackPhase.ready,
          PlaybackPhase.playing,
          PlaybackPhase.buffering,
          PlaybackPhase.paused,
        }.contains(_state.phase)) {
      return false;
    }
    return true;
  }

  bool _setSleepAtCurrentEntryEnd() {
    _checkNotDisposed();
    if (!_canSleepAtCurrentEntryEnd) return false;
    final entryId = _loadedEntryId!;
    _cancelSleepTimer();
    _sleepState = PlaybackSleepTimerState.atEntryEnd(entryId);
    _nativePolicyRevision++;
    _requestNativeBoundary();
    _publish(_state);
    return true;
  }

  bool _consumeEntrySleep(String? completedEntryId) {
    final target = _sleepState.entryId;
    if (_sleepState.phase != PlaybackSleepPhase.armed ||
        target == null ||
        target != completedEntryId ||
        target != _state.queue.currentEntryId ||
        _loadingSource) {
      return false;
    }
    // Consume before notifying listeners or constructing automatic advance.
    _sleepState = PlaybackSleepTimerState.atEntryEnd(target, expired: true);
    return true;
  }

  void _reconcileEntrySleep(PlaybackState value) {
    final target = _sleepState.entryId;
    if (target != null &&
        _sleepState.phase == PlaybackSleepPhase.armed &&
        (target != value.queue.currentEntryId ||
            value.currentTrack == null ||
            value.phase == PlaybackPhase.idle ||
            value.phase == PlaybackPhase.loading ||
            value.phase == PlaybackPhase.error)) {
      _cancelSleepTimer();
    }
  }

  void _cancelSleepTimer() {
    _sleepFade?.cancel();
    _sleepFade = null;
    _sleepGeneration++;
    _sleepWake?.cancel();
    _sleepWake = null;
    _sleepState = const PlaybackSleepTimerState.off();
  }

  void _setSleepTimer(PlaybackSleepDuration? duration) {
    _checkNotDisposed();
    if (duration != null) _requireEngine();
    _cancelSleepTimer();
    if (duration != null) {
      final deadline = _clock().toUtc().add(duration.duration);
      _sleepState = PlaybackSleepTimerState.armed(deadline, duration: duration);
      _armSleepWake(_sleepGeneration, duration.duration);
    }
    _publish(_state);
  }

  void _armSleepWake(int generation, Duration delay) {
    try {
      final wake = _sleepScheduler(delay, () => _sleepWoke(generation));
      if (_disposed ||
          generation != _sleepGeneration ||
          _sleepState.phase != PlaybackSleepPhase.armed) {
        wake.cancel();
        return;
      }
      _sleepWake = wake;
    } catch (_) {
      if (!_disposed && generation == _sleepGeneration) {
        _sleepState = PlaybackSleepTimerState.failed(_sleepState.deadline);
      }
    }
  }

  void _sleepWoke(int generation) {
    if (_disposed ||
        generation != _sleepGeneration ||
        _sleepState.phase != PlaybackSleepPhase.armed) {
      return;
    }
    _sleepWake?.cancel();
    _sleepWake = null;
    final deadline = _sleepState.deadline!;
    final remaining = deadline.difference(_clock().toUtc());
    if (_disposed ||
        generation != _sleepGeneration ||
        _sleepState.phase != PlaybackSleepPhase.armed) {
      return;
    }
    if (remaining > Duration.zero) {
      // A new wake token also revokes a retained callback from an early wake.
      _armSleepWake(++_sleepGeneration, remaining);
      if (_sleepState.phase == PlaybackSleepPhase.failed) _publish(_state);
      return;
    }

    _sleepState = PlaybackSleepTimerState.pausing(deadline);
    _sessionRevision++; // Revoke an automatic advance not yet accepted.
    _publish(_state);
    if (_disposed || generation != _sleepGeneration) return;
    unawaited(
      _schedule(() async {
        if (generation != _sleepGeneration ||
            _sleepState.phase != PlaybackSleepPhase.pausing) {
          return;
        }
        if (_state.phase == PlaybackPhase.playing ||
            _state.phase == PlaybackPhase.buffering) {
          _requireEngine();
          _startSleepFade(generation, deadline);
          return;
        }
        if (!_disposed && generation == _sleepGeneration) {
          _sleepState = PlaybackSleepTimerState.expired(deadline);
          _publish(_state);
        }
      }).catchError((Object _) {
        if (!_disposed && generation == _sleepGeneration) {
          _sleepState = PlaybackSleepTimerState.failed(deadline);
          _publish(_state);
        }
      }),
    );
  }
}
