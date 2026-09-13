part of 'playback_controller.dart';

extension _SleepRestoreActions on PlaybackController {
  PlaybackSleepRestoreAction? _captureSleepRestore() {
    if (_disposed || _sleepState.phase != PlaybackSleepPhase.off) return null;
    final captured = _sleepGeneration;
    var used = false;
    bool current() =>
        !_disposed &&
        captured == _sleepGeneration &&
        _sleepState.phase == PlaybackSleepPhase.off;

    return PlaybackSleepRestoreAction(
      isCurrent: () => !used && current(),
      apply: (SleepTimerSnapshot snapshot) {
        if (used || !current()) return PlaybackSleepRestoreResult.superseded;
        used = true;
        Duration? remaining;
        bool available;
        try {
          remaining = snapshot.remainingAt(_clock());
          if (!current()) return PlaybackSleepRestoreResult.superseded;
          if (remaining == null) return PlaybackSleepRestoreResult.expired;
          available = _engine.isAvailable;
        } catch (_) {
          return current()
              ? PlaybackSleepRestoreResult.failed
              : PlaybackSleepRestoreResult.superseded;
        }
        if (!current()) return PlaybackSleepRestoreResult.superseded;
        if (!available) return PlaybackSleepRestoreResult.unavailable;
        final duration = PlaybackSleepDuration.values.firstWhere(
          (value) => value.duration.inMinutes == snapshot.durationMinutes,
        );
        _cancelSleepTimer();
        final restoredGeneration = _sleepGeneration;
        _sleepState = PlaybackSleepTimerState.armed(
          snapshot.deadline,
          duration: duration,
        );
        _armSleepWake(restoredGeneration, remaining);
        if (_disposed || restoredGeneration != _sleepGeneration) {
          return PlaybackSleepRestoreResult.superseded;
        }
        _publish(_state);
        if (_disposed || restoredGeneration != _sleepGeneration) {
          return PlaybackSleepRestoreResult.superseded;
        }
        return _sleepState.phase == PlaybackSleepPhase.armed
            ? PlaybackSleepRestoreResult.restored
            : PlaybackSleepRestoreResult.failed;
      },
    );
  }
}
