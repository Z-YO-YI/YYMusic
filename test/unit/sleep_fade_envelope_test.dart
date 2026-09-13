import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/playback/sleep_fade_envelope.dart';

void main() {
  test('fixed two-second envelope and bounded sampling cadence', () {
    expect(SleepFadeEnvelope.duration, const Duration(seconds: 2));
    expect(SleepFadeEnvelope.sampleInterval, const Duration(milliseconds: 50));
  });

  for (final milliseconds in [-1000, 0, 500, 1000, 1500, 2000, 5000]) {
    test('linear amplitude at $milliseconds ms with clamped endpoints', () {
      final elapsed = Duration(milliseconds: milliseconds);
      final expected = (1 - milliseconds / 2000).clamp(0.0, 1.0);
      expect(SleepFadeEnvelope.gainAt(elapsed), expected);
      expect(SleepFadeEnvelope.isComplete(elapsed), milliseconds >= 2000);
    });
  }

  test('microsecond boundary is not rounded into premature silence', () {
    const before = Duration(microseconds: 1999999);
    expect(SleepFadeEnvelope.gainAt(before), greaterThan(0));
    expect(SleepFadeEnvelope.isComplete(before), isFalse);
    expect(
      SleepFadeEnvelope.nextDelay(before),
      const Duration(microseconds: 1),
    );
    expect(SleepFadeEnvelope.gainAt(SleepFadeEnvelope.duration), 0);
  });

  test('all samples are bounded and monotonically decreasing', () {
    var previous = 1.0;
    for (var microseconds = 0; microseconds <= 2200000; microseconds += 137) {
      final elapsed = Duration(microseconds: microseconds);
      final gain = SleepFadeEnvelope.gainAt(elapsed);
      expect(gain, inInclusiveRange(0, previous));
      expect(
        SleepFadeEnvelope.volumeAt(elapsed, userVolume: 0.73),
        inInclusiveRange(0, 0.73),
      );
      previous = gain;
    }
  });

  test('new user volume is used instead of restoring a captured value', () {
    const elapsed = Duration(seconds: 1);
    expect(SleepFadeEnvelope.volumeAt(elapsed, userVolume: 0.8), 0.4);
    expect(SleepFadeEnvelope.volumeAt(elapsed, userVolume: 0.2), 0.1);
    expect(SleepFadeEnvelope.volumeAt(elapsed, userVolume: 0), 0);
    expect(SleepFadeEnvelope.volumeAt(elapsed, userVolume: 1), 0.5);
  });

  for (final invalid in [
    double.nan,
    double.infinity,
    -double.infinity,
    -0.1,
    1.1,
  ]) {
    test('invalid volume $invalid is rejected even after expiry', () {
      for (final elapsed in [Duration.zero, const Duration(seconds: 3)]) {
        expect(
          () => SleepFadeEnvelope.volumeAt(elapsed, userVolume: invalid),
          throwsArgumentError,
        );
      }
    });
  }

  test('late wake skips missed samples and shortens final interval', () {
    const late = Duration(milliseconds: 1980);
    expect(SleepFadeEnvelope.gainAt(late), closeTo(0.01, 1e-12));
    expect(SleepFadeEnvelope.nextDelay(late), const Duration(milliseconds: 20));
    for (final elapsed in [Duration.zero, const Duration(milliseconds: 125)]) {
      expect(
        SleepFadeEnvelope.nextDelay(elapsed),
        SleepFadeEnvelope.sampleInterval,
      );
    }
    expect(
      SleepFadeEnvelope.nextDelay(const Duration(seconds: -1)),
      SleepFadeEnvelope.sampleInterval,
    );
    expect(
      SleepFadeEnvelope.nextDelay(const Duration(seconds: 2)),
      Duration.zero,
    );
    expect(
      SleepFadeEnvelope.nextDelay(const Duration(days: 365)),
      Duration.zero,
    );
  });
}
