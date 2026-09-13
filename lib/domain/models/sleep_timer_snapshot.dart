/// A minute-based pause intention, never playback or queue restoration.
final class SleepTimerSnapshot {
  factory SleepTimerSnapshot({
    required int durationMinutes,
    required DateTime deadline,
  }) {
    if (!const {15, 30, 60}.contains(durationMinutes)) {
      throw const FormatException('Invalid sleep duration');
    }
    return SleepTimerSnapshot._(durationMinutes, deadline.toUtc());
  }

  const SleepTimerSnapshot._(this.durationMinutes, this.deadline);

  /// Original option; wall-clock changes never rewrite this value.
  final int durationMinutes;
  final DateTime deadline;

  /// Null means expired, including the exact boundary. No implicit wall clock.
  Duration? remainingAt(DateTime now) {
    final remaining = deadline.difference(now.toUtc());
    return remaining > Duration.zero ? remaining : null;
  }

  @override
  bool operator ==(Object other) =>
      other is SleepTimerSnapshot &&
      other.durationMinutes == durationMinutes &&
      other.deadline == deadline;

  @override
  int get hashCode => Object.hash(durationMinutes, deadline);

  @override
  String toString() => 'SleepTimerSnapshot(<redacted>)';
}
