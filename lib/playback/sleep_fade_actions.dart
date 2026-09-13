part of 'playback_controller.dart';

extension _SleepFadeActions on PlaybackController {
  void _interruptSleepFade() {
    if (_sleepFade == null) return;
    _cancelSleepTimer();
    _publish(_state);
    _checkNotDisposed();
  }

  /// Called only inside the root command queue, including its shutdown lane.
  Future<void> _restoreFadeVolume() async {
    if (!_fadeVolumeDirty) return;
    final priorFailure = _state.failure;
    try {
      await _engine.setVolume(_userVolume!);
      _fadeVolumeDirty = false;
      _fadeRestoreFailure = null;
      // An amplitude-only report must not imply recovery from a failed pause.
      if (priorFailure != null && !_disposed) {
        _publish(
          _state.copyWith(phase: PlaybackPhase.error, failure: priorFailure),
        );
      }
    } catch (error) {
      _fadeRestoreFailure = _safeFailure(error, 'sleep-volume-restore');
      if (!_disposed) _publishFailure(error, 'sleep-volume-restore');
      throw _fadeRestoreFailure!;
    }
  }

  void _startSleepFade(int generation, DateTime deadline) {
    _userVolume ??= _state.volume;
    final entryId = _loadedEntryId;
    late final SleepFadeRunner runner;
    bool current() =>
        !_disposed &&
        generation == _sleepGeneration &&
        identical(_sleepFade, runner) &&
        _sleepState.phase == PlaybackSleepPhase.pausing &&
        _loadedEntryId == entryId &&
        _state.queue.currentEntryId == entryId;
    runner = SleepFadeRunner(
      isCurrent: current,
      elapsed: _sleepFadeTiming.elapsed,
      scheduler: _sleepFadeTiming.scheduler,
      writeGain: (gain) => _schedule(() async {
        if (!current()) return;
        if (_state.phase != PlaybackPhase.playing &&
            _state.phase != PlaybackPhase.buffering) {
          runner.cancel();
          return;
        }
        _fadeVolumeDirty = true;
        await _guarded(
          'sleep-gain',
          () => _engine.setVolume(_userVolume! * gain),
        );
      }),
      pause: () => _schedule(() async {
        if (!current()) return;
        if (_state.phase == PlaybackPhase.playing ||
            _state.phase == PlaybackPhase.buffering) {
          history.suspend();
          _sessionRevision++;
          await _guarded('sleep-pause', _engine.pause);
        }
      }),
      restore: () => _schedule(() async {
        // A newer fade now owns temporary amplitude and its final restoration.
        if (_sleepFade != null && !identical(_sleepFade, runner)) return;
        await _restoreFadeVolume();
      }, allowClosed: true),
    );
    _sleepFade = runner;
    late final Future<void> job;
    job = runner
        .start()
        .then((outcome) {
          if (current()) {
            _sleepFade = null;
            _sleepState =
                outcome.status == SleepFadeStatus.failed ||
                    _state.phase == PlaybackPhase.error
                ? PlaybackSleepTimerState.failed(deadline)
                : PlaybackSleepTimerState.expired(deadline);
            _publish(_state);
          }
        })
        .whenComplete(() => _sleepFadeJobs.remove(job));
    _sleepFadeJobs.add(job);
    unawaited(job.catchError((Object _) {}));
  }
}
