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

/// Live root intent; persisted minute snapshots are separate from queue state.
@immutable
final class PlaybackSleepTimerState {
  const PlaybackSleepTimerState.off()
    : phase = PlaybackSleepPhase.off,
      entryId = null,
      duration = null,
      deadline = null;
  const PlaybackSleepTimerState.armed(this.deadline, {this.duration})
    : phase = PlaybackSleepPhase.armed,
      entryId = null;
  const PlaybackSleepTimerState.pausing(this.deadline)
    : phase = PlaybackSleepPhase.pausing,
      duration = null,
      entryId = null;
  const PlaybackSleepTimerState.expired(this.deadline)
    : phase = PlaybackSleepPhase.expired,
      duration = null,
      entryId = null;
  const PlaybackSleepTimerState.failed(this.deadline)
    : phase = PlaybackSleepPhase.failed,
      duration = null,
      entryId = null;
  const PlaybackSleepTimerState.atEntryEnd(String id, {bool expired = false})
    : phase = expired ? PlaybackSleepPhase.expired : PlaybackSleepPhase.armed,
      duration = null,
      entryId = id,
      deadline = null;

  final PlaybackSleepPhase phase;
  final DateTime? deadline;

  /// Original active option, not inferred from the remaining clock time.
  final PlaybackSleepDuration? duration;

  /// Exact queue entry, never the shared TrackRef of duplicate songs.
  final String? entryId;
}
