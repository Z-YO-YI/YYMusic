/// Whether startup restoration survived newer user intent and root shutdown.
enum PlaybackContinuationRestoreResult { restored, superseded }

/// Capture before startup storage I/O. Applying consumes the permit once.
final class PlaybackContinuationRestoreAction {
  factory PlaybackContinuationRestoreAction({
    required bool Function() isCurrent,
    required PlaybackContinuationRestoreResult Function(bool) apply,
  }) => PlaybackContinuationRestoreAction._(isCurrent, apply);

  const PlaybackContinuationRestoreAction._(this._isCurrent, this._apply);

  final bool Function() _isCurrent;
  final PlaybackContinuationRestoreResult Function(bool) _apply;

  /// Non-consuming, including when the storage read is missing or fails.
  bool get isCurrent => _isCurrent();

  /// Applies at most once, without starting or resuming playback.
  PlaybackContinuationRestoreResult call(bool enabled) => _apply(enabled);
}
