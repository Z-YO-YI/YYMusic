/// Pure amplitude envelope for minute-timer expiry, not a timer or player.
///
/// The root must supply monotonic elapsed time and the latest user volume.
/// Sampling neither persists nor changes that user intent. Engine commands,
/// cancellation, pause and restoration remain the root's responsibility.
abstract final class SleepFadeEnvelope {
  static const duration = Duration(seconds: 2);
  static const sampleInterval = Duration(milliseconds: 50);

  /// Linear amplitude, not a claim of perceptually linear loudness.
  static double gainAt(Duration elapsed) {
    if (elapsed <= Duration.zero) return 1;
    if (elapsed >= duration) return 0;
    return 1 - elapsed.inMicroseconds / duration.inMicroseconds;
  }

  static bool isComplete(Duration elapsed) => elapsed >= duration;

  /// Accept the latest intent on every sample; never capture an old volume.
  static double volumeAt(Duration elapsed, {required double userVolume}) {
    if (!userVolume.isFinite || userVolume < 0 || userVolume > 1) {
      throw ArgumentError('User volume must be finite and between 0 and 1');
    }
    return userVolume * gainAt(elapsed);
  }

  /// Delay to the next sample, shortened at the end; zero means no next wake.
  /// Delayed callbacks must sample actual elapsed time, not replay missed steps.
  static Duration nextDelay(Duration elapsed) {
    if (isComplete(elapsed)) return Duration.zero;
    if (elapsed <= Duration.zero) return sampleInterval;
    final remaining = duration - elapsed;
    return remaining < sampleInterval ? remaining : sampleInterval;
  }
}
