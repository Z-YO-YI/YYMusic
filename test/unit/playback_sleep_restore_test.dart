import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/domain/models/sleep_timer_snapshot.dart';
import 'package:yymusic/playback/audio_engine.dart';
import 'package:yymusic/playback/playback_controller.dart';
import 'package:yymusic/playback/playback_sleep_restore.dart';
import 'package:yymusic/playback/playback_sleep_timer_state.dart';

import '../support/fake_audio_engine.dart';
import '../support/fake_domain_repositories.dart';
import '../support/fake_playback_dependencies.dart';

void main() {
  late DateTime now;
  late PlaybackController root;
  late FakeAudioEngine engine;
  late FakeLibraryRepository library;
  late List<_Wake> wakes;
  void Function()? onClock;
  void Function()? onSchedule;
  var failClock = false, failSchedule = false;
  setUp(() {
    now = DateTime.utc(2026, 9, 13);
    wakes = [];
    onClock = null;
    onSchedule = null;
    failClock = false;
    failSchedule = false;
    engine = FakeAudioEngine();
    library = FakeLibraryRepository(tracks: [playbackFixtureTrack]);
    root = PlaybackController(
      engine,
      library: library,
      sourceResolver: FakePlaybackSourceResolver(),
      sleepFadeElapsed: () => const Duration(seconds: 2),
      clock: () {
        final callback = onClock;
        onClock = null;
        callback?.call();
        if (failClock) throw StateError('private-clock-detail');
        return now;
      },
      sleepScheduler: (delay, callback) {
        final reentry = onSchedule;
        onSchedule = null;
        reentry?.call();
        if (failSchedule) throw StateError('private-scheduler-detail');
        final wake = _Wake(delay, callback);
        wakes.add(wake);
        return wake;
      },
    );
  });
  tearDown(() async {
    await root.close();
    await engine.dispose();
    await library.dispose();
  });
  SleepTimerSnapshot snapshot([int minutes = 15]) => SleepTimerSnapshot(
    durationMinutes: minutes,
    deadline: now.add(const Duration(minutes: 7, microseconds: 123)),
  );

  for (final minutes in [15, 30, 60]) {
    test(
      'restore $minutes retains original option and exact seven minute deadline',
      () {
        final value = snapshot(minutes);
        final queue = root.state.queue;
        final action = root.captureSleepRestore()!;
        expect(action(value), PlaybackSleepRestoreResult.restored);
        expect(root.sleepTimer.deadline, value.deadline);
        expect(root.sleepTimer.duration!.duration.inMinutes, minutes);
        expect(
          wakes.single.delay,
          const Duration(minutes: 7, microseconds: 123),
        );
        expect(root.state.queue, same(queue));
        expect(engine.calls, isEmpty);
        expect(action(value), PlaybackSleepRestoreResult.superseded);
        expect(root.captureSleepRestore(), isNull);
      },
    );
  }
  for (final micros in [-1, 0, 1]) {
    test(
      '$micros microsecond expiry boundary never restarts full duration',
      () {
        final result = root.captureSleepRestore()!(
          SleepTimerSnapshot(
            durationMinutes: 15,
            deadline: now.add(Duration(microseconds: micros)),
          ),
        );
        expect(
          result,
          micros > 0
              ? PlaybackSleepRestoreResult.restored
              : PlaybackSleepRestoreResult.expired,
        );
        expect(wakes.length, micros > 0 ? 1 : 0);
        expect(engine.calls, isEmpty);
      },
    );
  }
  for (final operation in ['cancel', 'reset', 'reset-cancel', 'close']) {
    test(
      '$operation revokes late storage permit even if state returns off',
      () async {
        final action = root.captureSleepRestore()!;
        if (operation == 'reset' || operation == 'reset-cancel') {
          root.setSleepTimer(PlaybackSleepDuration.sixty);
        }
        if (operation == 'cancel' || operation == 'reset-cancel') {
          root.setSleepTimer(null);
        }
        if (operation == 'close') await root.close();
        final state = root.sleepTimer;
        expect(action(snapshot()), PlaybackSleepRestoreResult.superseded);
        expect(root.sleepTimer, same(state));
      },
    );
  }
  test(
    'wall clock rollback increases delay without changing original choice',
    () {
      final value = snapshot();
      now = now.subtract(const Duration(hours: 1));
      expect(
        root.captureSleepRestore()!(value),
        PlaybackSleepRestoreResult.restored,
      );
      expect(
        wakes.single.delay,
        const Duration(minutes: 67, microseconds: 123),
      );
      expect(root.sleepTimer.deadline, value.deadline);
      expect(root.sleepTimer.duration, PlaybackSleepDuration.fifteen);
    },
  );
  test('scheduler reentrant close cancels returned timer', () {
    onSchedule = root.dispose;
    expect(
      root.captureSleepRestore()!(snapshot()),
      PlaybackSleepRestoreResult.superseded,
    );
    expect(wakes.single.isActive, isFalse);
    expect(root.captureSleepRestore(), isNull);
  });
  test('deadline clock reentry cannot consume a new user intent', () async {
    final value = snapshot();
    root.captureSleepRestore()!(value);
    final old = wakes.single;
    now = value.deadline;
    onClock = () => root.setSleepTimer(PlaybackSleepDuration.sixty);
    old.fire();
    await Future<void>.delayed(Duration.zero);
    expect(root.sleepTimer.phase, PlaybackSleepPhase.armed);
    expect(root.sleepTimer.duration, PlaybackSleepDuration.sixty);
    expect(wakes.last.isActive, isTrue);
    expect(engine.calls, isEmpty);
  });
  test('permit validity is non-consuming and observes an explicit off cancellation', () {
    final action = root.captureSleepRestore()!;
    for (var i = 0; i < 10; i++) {
      expect(action.isCurrent, isTrue);
    }
    expect(wakes, isEmpty);
    root.setSleepTimer(null);
    expect(action.isCurrent, isFalse);
    final fresh = root.captureSleepRestore()!;
    expect(fresh.isCurrent, isTrue);
    expect(fresh(snapshot()), PlaybackSleepRestoreResult.restored);
    expect(fresh.isCurrent, isFalse);
  });
  test('only first competing permit can restore', () {
    final first = root.captureSleepRestore()!,
        second = root.captureSleepRestore()!;
    expect(first(snapshot()), PlaybackSleepRestoreResult.restored);
    expect(second(snapshot(60)), PlaybackSleepRestoreResult.superseded);
    expect(wakes.length, 1);
  });
  test('clock reentry cancellation wins over stored snapshot', () {
    final action = root.captureSleepRestore()!;
    onClock = () => root.setSleepTimer(null);
    expect(action(snapshot()), PlaybackSleepRestoreResult.superseded);
    expect(root.sleepTimer.phase, PlaybackSleepPhase.off);
    expect(wakes, isEmpty);
  });
  test('clock failure consumes permit without mutating root', () {
    final action = root.captureSleepRestore()!;
    failClock = true;
    expect(action(snapshot()), PlaybackSleepRestoreResult.failed);
    failClock = false;
    expect(action(snapshot()), PlaybackSleepRestoreResult.superseded);
    expect(root.sleepTimer.phase, PlaybackSleepPhase.off);
    expect(wakes, isEmpty);
  });
  test('scheduler failure is honest and never starts audio', () {
    failSchedule = true;
    expect(
      root.captureSleepRestore()!(snapshot()),
      PlaybackSleepRestoreResult.failed,
    );
    expect(root.sleepTimer.phase, PlaybackSleepPhase.failed);
    expect(engine.calls, isEmpty);
  });
  test(
    'reentrant scheduler new intent keeps its timer and cancels stale return',
    () {
      onSchedule = () => root.setSleepTimer(PlaybackSleepDuration.sixty);
      expect(
        root.captureSleepRestore()!(snapshot()),
        PlaybackSleepRestoreResult.superseded,
      );
      expect(wakes, hasLength(2));
      expect(wakes.first.isActive, isTrue);
      expect(wakes.last.isActive, isFalse);
      expect(root.sleepTimer.duration, PlaybackSleepDuration.sixty);
      root.setSleepTimer(null);
      expect(wakes.first.isActive, isFalse);
    },
  );
  test(
    'reentrant notification cancellation wins and cancels restored timer',
    () {
      var once = true;
      root.addListener(() {
        if (once) {
          once = false;
          root.setSleepTimer(null);
        }
      });
      expect(
        root.captureSleepRestore()!(snapshot()),
        PlaybackSleepRestoreResult.superseded,
      );
      expect(root.sleepTimer.phase, PlaybackSleepPhase.off);
      expect(wakes.single.isActive, isFalse);
    },
  );
  test('unavailable engine returns unavailable without arming', () async {
    final unavailable = PlaybackController(
      UnavailableAudioEngine(),
      clock: () => now,
    );
    try {
      expect(
        unavailable.captureSleepRestore()!(snapshot()),
        PlaybackSleepRestoreResult.unavailable,
      );
      expect(unavailable.sleepTimer.phase, PlaybackSleepPhase.off);
    } finally {
      await unavailable.close();
    }
  });
  test(
    'permit survives ordinary initialization without automatically playing',
    () async {
      final action = root.captureSleepRestore()!;
      await root.initialize();
      expect(action(snapshot()), PlaybackSleepRestoreResult.restored);
      expect(engine.calls.where((e) => e == 'play'), isEmpty);
    },
  );
  test(
    'restored timer delegates actual deadline pause to existing root path',
    () async {
      await root.replaceQueue([playbackFixtureEntry()]);
      await root.play();
      engine.calls.clear();
      final value = snapshot();
      expect(
        root.captureSleepRestore()!(value),
        PlaybackSleepRestoreResult.restored,
      );
      expect(engine.calls, isEmpty);
      now = value.deadline;
      wakes.single.fire();
      for (var i = 0; i < 8; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(root.sleepTimer.phase, PlaybackSleepPhase.expired);
      expect(engine.calls, ['volume:0.0', 'pause', 'volume:1.0']);
      wakes.single.fire();
      await Future<void>.delayed(Duration.zero);
      expect(engine.calls, ['volume:0.0', 'pause', 'volume:1.0']);
    },
  );
  test(
    'entry-end intent blocks capture and invalidates prior permit',
    () async {
      await root.replaceQueue([playbackFixtureEntry()]);
      await root.play();
      final action = root.captureSleepRestore()!;
      expect(root.setSleepAtCurrentEntryEnd(), isTrue);
      expect(root.captureSleepRestore(), isNull);
      expect(action(snapshot()), PlaybackSleepRestoreResult.superseded);
    },
  );
}

final class _Wake implements Timer {
  _Wake(this.delay, this.callback);
  final Duration delay;
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
