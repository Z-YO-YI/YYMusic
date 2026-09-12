import 'dart:async';

import 'package:flutter/foundation.dart';

/// A one-shot scheduler. Callbacks must run asynchronously, like [Timer].
typedef PlaybackSleepTimerScheduler = Timer Function(
  Duration delay,
  void Function() callback,
);

enum PlaybackSleepDuration {
  fifteen(Duration(minutes: 15)),
  thirty(Duration(minutes: 30)),
  sixty(Duration(minutes: 60));

  const PlaybackSleepDuration(this.duration);
  final Duration duration;
}

enum PlaybackSleepPhase { off, armed, pausing, expired, failed }

/// Session-only intent; it is not another playback or persisted queue state.
@immutable
final class PlaybackSleepTimerState {
  const PlaybackSleepTimerState.off()
    : phase = PlaybackSleepPhase.off,
      deadline = null;
  const PlaybackSleepTimerState.armed(this.deadline)
    : phase = PlaybackSleepPhase.armed;
  const PlaybackSleepTimerState.pausing(this.deadline)
    : phase = PlaybackSleepPhase.pausing;
  const PlaybackSleepTimerState.expired(this.deadline)
    : phase = PlaybackSleepPhase.expired;
  const PlaybackSleepTimerState.failed(this.deadline)
    : phase = PlaybackSleepPhase.failed;

  final PlaybackSleepPhase phase;
  final DateTime? deadline;
}
