part of 'playback_controller.dart';

extension _SleepDeadlineActions on PlaybackController {
  void _cancelSleepTimer() {
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
      _sleepState = PlaybackSleepTimerState.armed(deadline);
      _armSleepWake(_sleepGeneration, duration.duration);
    }
    _publish(_state);
  }

  void _armSleepWake(int generation, Duration delay) {
    try {
      _sleepWake = _sleepScheduler(delay, () => _sleepWoke(generation));
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
          history.suspend();
          _sessionRevision++;
          await _guarded('sleep-pause', _engine.pause);
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
