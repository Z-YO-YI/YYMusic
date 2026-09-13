import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/playback_presenter.dart';
import 'package:yymusic/app/playback_sleep_action.dart';
import 'package:yymusic/playback/playback_controller.dart';
import 'package:yymusic/playback/playback_sleep_timer_state.dart';

import '../support/fake_audio_engine.dart';
import '../support/fake_domain_repositories.dart';
import '../support/fake_playback_dependencies.dart';

void main() {
  late DateTime now;
  late FakeAudioEngine engine;
  late FakeLibraryRepository library;
  late PlaybackController root;
  late PlaybackPresenter presenter;
  late List<_Wake> wakes;
  var clockReads = 0;
  var failSchedule = false;
  setUp(() {
    now = DateTime.utc(2026, 9, 13);
    clockReads = 0;
    failSchedule = false;
    wakes = [];
    engine = FakeAudioEngine();
    library = FakeLibraryRepository(tracks: [playbackFixtureTrack]);
    root = PlaybackController(
      engine,
      library: library,
      sourceResolver: FakePlaybackSourceResolver(),
      clock: () {
        clockReads++;
        return now;
      },
      sleepScheduler: (_, callback) {
        if (failSchedule) throw StateError('test scheduler failure');
        final wake = _Wake(callback);
        wakes.add(wake);
        return wake;
      },
    );
    presenter = PlaybackPresenter(root);
  });
  tearDown(() async {
    presenter.dispose();
    await root.close();
    await engine.dispose();
    await library.dispose();
  });

  test('off has no countdown and never reads clock', () {
    final before = clockReads;
    expect(root.sleepRemaining, isNull);
    expect(presenter.sleepRemainingSeconds, isNull);
    expect(clockReads, before);
  });

  for (final duration in PlaybackSleepDuration.values) {
    test(
      '${duration.name} maps exact deadline without selecting another option',
      () {
        root.setSleepTimer(duration);
        final state = root.sleepTimer;
        final selected = presenter.selectedSleepChoice;
        expect(root.sleepRemaining, duration.duration);
        expect(presenter.sleepRemainingSeconds, duration.duration.inSeconds);
        now = now.add(const Duration(minutes: 2, microseconds: 1));
        expect(
          root.sleepRemaining,
          duration.duration - const Duration(minutes: 2, microseconds: 1),
        );
        expect(
          presenter.sleepRemainingSeconds,
          duration.duration.inSeconds - 120,
        );
        expect(presenter.selectedSleepChoice, selected);
        expect(root.sleepTimer, same(state));
        expect(wakes.length, 1);
      },
    );
  }

  for (final micros in [1000001, 1000000, 999999, 1, 0, -1]) {
    test('$micros remaining microseconds round up and clamp expired', () {
      root.setSleepTimer(PlaybackSleepDuration.fifteen);
      now = root.sleepTimer.deadline!.subtract(Duration(microseconds: micros));
      expect(
        presenter.sleepRemainingSeconds,
        micros > 1000000
            ? 2
            : micros > 0
            ? 1
            : 0,
      );
      expect(root.sleepRemaining!.isNegative, isFalse);
      expect(root.sleepTimer.phase, PlaybackSleepPhase.armed);
      expect(engine.calls, isEmpty);
    });
  }

  test('clock rollback and forward jump do not rewrite deadline', () {
    root.setSleepTimer(PlaybackSleepDuration.fifteen);
    final state = root.sleepTimer;
    now = now.subtract(const Duration(minutes: 3));
    expect(presenter.sleepRemainingSeconds, 18 * 60);
    now = now.add(const Duration(hours: 1));
    expect(presenter.sleepRemainingSeconds, 0);
    expect(root.sleepTimer, same(state));
    expect(wakes.single.isActive, isTrue);
  });

  test('repeated reads do not notify, revoke choice, or schedule audio', () {
    root.setSleepTimer(PlaybackSleepDuration.fifteen);
    final action = presenter.sleepAction(
      PlaybackSleepChoice.thirty,
      isCurrent: () => true,
    )!;
    var notifications = 0;
    presenter.addListener(() => notifications++);
    final state = root.state;
    for (var i = 0; i < 100; i++) {
      now = now.add(const Duration(milliseconds: 10));
      expect(presenter.sleepRemainingSeconds, greaterThan(0));
    }
    expect(notifications, 0);
    expect(root.state, same(state));
    expect(wakes.length, 1);
    expect(engine.calls, isEmpty);
    expect(action(), PlaybackSleepActionResult.accepted);
    expect(presenter.sleepRemainingSeconds, 30 * 60);
  });

  test(
    'reset and cancel discard previous display without stale timer effect',
    () async {
      root.setSleepTimer(PlaybackSleepDuration.fifteen);
      final old = wakes.single;
      now = now.add(const Duration(minutes: 10));
      root.setSleepTimer(PlaybackSleepDuration.sixty);
      expect(presenter.sleepRemainingSeconds, 60 * 60);
      old.fire();
      await Future<void>.delayed(Duration.zero);
      expect(presenter.sleepRemainingSeconds, 60 * 60);
      root.setSleepTimer(null);
      expect(presenter.sleepRemainingSeconds, isNull);
    },
  );

  test(
    'paused playback still uses wall deadline, entry end has no seconds',
    () async {
      await root.replaceQueue([playbackFixtureEntry()]);
      await root.play();
      root.setSleepTimer(PlaybackSleepDuration.fifteen);
      await root.pause();
      now = now.add(const Duration(minutes: 5));
      expect(presenter.sleepRemainingSeconds, 10 * 60);
      expect(root.setSleepAtCurrentEntryEnd(), isTrue);
      expect(presenter.sleepRemainingSeconds, isNull);
    },
  );

  test('late callback owns expiry, not reading zero seconds', () async {
    root.setSleepTimer(PlaybackSleepDuration.fifteen);
    now = now.add(const Duration(hours: 1));
    expect(presenter.sleepRemainingSeconds, 0);
    expect(root.sleepTimer.phase, PlaybackSleepPhase.armed);
    wakes.single.fire();
    expect(root.sleepTimer.phase, PlaybackSleepPhase.pausing);
    expect(presenter.sleepRemainingSeconds, isNull);
    await Future<void>.delayed(Duration.zero);
    expect(root.sleepTimer.phase, PlaybackSleepPhase.expired);
    expect(presenter.sleepRemainingSeconds, isNull);
  });

  test('failed scheduling exposes no countdown', () {
    failSchedule = true;
    root.setSleepTimer(PlaybackSleepDuration.fifteen);
    expect(root.sleepTimer.phase, PlaybackSleepPhase.failed);
    expect(presenter.sleepRemainingSeconds, isNull);
  });

  test('disposed presenter stops reading clock without cancelling root', () {
    root.setSleepTimer(PlaybackSleepDuration.fifteen);
    presenter.dispose();
    final before = clockReads;
    expect(presenter.sleepRemainingSeconds, isNull);
    expect(clockReads, before);
    expect(wakes.single.isActive, isTrue);
  });

  test('closed root has no countdown or clock reads', () async {
    root.setSleepTimer(PlaybackSleepDuration.fifteen);
    await root.close();
    final before = clockReads;
    expect(root.sleepRemaining, isNull);
    expect(presenter.sleepRemainingSeconds, isNull);
    expect(clockReads, before);
    expect(wakes.single.isActive, isFalse);
  });
}

final class _Wake implements Timer {
  _Wake(this.callback);
  final void Function() callback;
  @override
  bool isActive = true;
  @override
  int tick = 0;
  @override
  void cancel() => isActive = false;
  void fire() {
    cancel();
    tick++;
    callback();
  }
}
