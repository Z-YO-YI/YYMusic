/// UI options map to the root sleep intent, never to a second timer.
enum PlaybackSleepChoice { off, fifteen, thirty, sixty, currentEntry }

enum PlaybackSleepActionResult { accepted, rejected, failed }

/// A one-shot, snapshot-bound action for a currently visible settings surface.
typedef PlaybackSleepAction = PlaybackSleepActionResult Function();
