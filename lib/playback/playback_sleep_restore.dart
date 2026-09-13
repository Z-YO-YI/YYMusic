import '../domain/models/sleep_timer_snapshot.dart';

enum PlaybackSleepRestoreResult {
  restored,
  expired,
  superseded,
  unavailable,
  failed,
}

/// Capture before an asynchronous read. A permit can be used at most once.
final class PlaybackSleepRestoreAction {
  factory PlaybackSleepRestoreAction({
    required bool Function() isCurrent,
    required PlaybackSleepRestoreResult Function(SleepTimerSnapshot) apply,
  }) => PlaybackSleepRestoreAction._(isCurrent, apply);

  const PlaybackSleepRestoreAction._(this._isCurrent, this._apply);

  final bool Function() _isCurrent;
  final PlaybackSleepRestoreResult Function(SleepTimerSnapshot) _apply;

  /// Non-consuming query, also usable when a storage read failed or was empty.
  bool get isCurrent => _isCurrent();

  PlaybackSleepRestoreResult call(SleepTimerSnapshot snapshot) =>
      _apply(snapshot);
}
