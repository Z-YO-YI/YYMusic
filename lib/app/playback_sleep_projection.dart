part of 'playback_presenter.dart';

extension _PlaybackSleepProjection on PlaybackPresenter {
  PlaybackSleepChoice? get _selectedSleepChoice {
    final sleep = sleepState;
    if (sleep.phase == PlaybackSleepPhase.off) return PlaybackSleepChoice.off;
    if (sleep.phase != PlaybackSleepPhase.armed) return null;
    if (sleep.entryId != null) return PlaybackSleepChoice.currentEntry;
    return switch (sleep.duration) {
      PlaybackSleepDuration.fifteen => PlaybackSleepChoice.fifteen,
      PlaybackSleepDuration.thirty => PlaybackSleepChoice.thirty,
      PlaybackSleepDuration.sixty => PlaybackSleepChoice.sixty,
      null => null,
    };
  }

  PlaybackSleepAction? _sleepAction(
    PlaybackSleepChoice choice, {
    required bool Function() isCurrent,
  }) {
    if (_disposed ||
        _playback.isClosed ||
        (choice != PlaybackSleepChoice.off && !canSetSleepTimer) ||
        (choice == PlaybackSleepChoice.currentEntry &&
            !canSleepAtCurrentEntryEnd)) {
      return null;
    }
    final playback = _playback.state;
    final sleep = _playback.sleepTimer;
    final revision = _sleepRevision;
    var consumed = false;
    bool matches() =>
        !_disposed &&
        !_playback.isClosed &&
        revision == _sleepRevision &&
        identical(playback, _playback.state) &&
        identical(sleep, _playback.sleepTimer);
    return () {
      if (consumed || !matches()) return PlaybackSleepActionResult.rejected;
      // External permits can reenter; consume before invoking user code.
      consumed = true;
      try {
        if (!isCurrent() || !matches()) {
          return PlaybackSleepActionResult.rejected;
        }
      } catch (_) {
        return PlaybackSleepActionResult.rejected;
      }
      try {
        if (choice == PlaybackSleepChoice.currentEntry) {
          return _playback.setSleepAtCurrentEntryEnd()
              ? PlaybackSleepActionResult.accepted
              : PlaybackSleepActionResult.rejected;
        }
        _playback.setSleepTimer(switch (choice) {
          PlaybackSleepChoice.fifteen => PlaybackSleepDuration.fifteen,
          PlaybackSleepChoice.thirty => PlaybackSleepDuration.thirty,
          PlaybackSleepChoice.sixty => PlaybackSleepDuration.sixty,
          PlaybackSleepChoice.off => null,
          PlaybackSleepChoice.currentEntry => throw StateError('Unreachable'),
        });
        return _playback.sleepTimer.phase == PlaybackSleepPhase.failed
            ? PlaybackSleepActionResult.failed
            : PlaybackSleepActionResult.accepted;
      } catch (_) {
        return PlaybackSleepActionResult.failed;
      }
    };
  }
}
