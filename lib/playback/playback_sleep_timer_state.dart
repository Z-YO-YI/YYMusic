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
      entryId = null,
      deadline = null;
  const PlaybackSleepTimerState.armed(this.deadline)
    : phase = PlaybackSleepPhase.armed,
      entryId = null;
  const PlaybackSleepTimerState.pausing(this.deadline)
    : phase = PlaybackSleepPhase.pausing,
      entryId = null;
  const PlaybackSleepTimerState.expired(this.deadline)
    : phase = PlaybackSleepPhase.expired,
      entryId = null;
  const PlaybackSleepTimerState.failed(this.deadline)
    : phase = PlaybackSleepPhase.failed,
      entryId = null;
  const PlaybackSleepTimerState.atEntryEnd(String id, {bool expired = false})
    : phase = expired ? PlaybackSleepPhase.expired : PlaybackSleepPhase.armed,
      entryId = id,
      deadline = null;

  final PlaybackSleepPhase phase;
  final DateTime? deadline;

  /// Exact queue entry, never the shared TrackRef of duplicate songs.
  final String? entryId;
}
