import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/playback/playback_controller.dart';
import 'package:yymusic/playback/playback_sleep_timer_state.dart';
import 'package:yymusic/playback/playback_state.dart';

import '../support/fake_audio_engine.dart';
import '../support/fake_domain_repositories.dart';
import '../support/fake_playback_dependencies.dart';

void main() {
  late _Clock clock;
  late FakeAudioEngine engine;
  late PlaybackController player;
  late FakeLibraryRepository library;

  setUp(() {
    clock = _Clock();
    engine = FakeAudioEngine();
    library = FakeLibraryRepository(tracks: [playbackFixtureTrack]);
    player = PlaybackController(
      engine,
      library: library,
      sourceResolver: FakePlaybackSourceResolver(),
      clock: () => clock.now,
      sleepScheduler: clock.schedule,
    );
  });
  tearDown(() async {
    await player.close();
    await engine.dispose();
    await library.dispose();
  });

  Future<void> start() async {
    await player.replaceQueue([playbackFixtureEntry()]);
    await player.play();
    engine.calls.clear();
  }

  void expire() {
    clock.now = player.sleepTimer.deadline!;
    clock.wakes.last.fire();
  }

  test('off has no timer or audio side effects', () {
    expect(player.sleepTimer.phase, PlaybackSleepPhase.off);
    player.setSleepTimer(null);
    expect(clock.wakes, isEmpty);
    expect(engine.calls, isEmpty);
  });

  test('entry-end replacement revokes retained deadline callback', () async {
    await start();
    player.setSleepTimer(PlaybackSleepDuration.fifteen);
    final old = clock.wakes.single;
    expect(player.setSleepAtCurrentEntryEnd(), isTrue);
    clock.now = clock.now.add(const Duration(hours: 1));
    old.fire();
    await _flush();
    expect(old.isActive, isFalse);
    expect(engine.calls, isEmpty);
    expect(player.sleepTimer.entryId, 'graph-fixture-entry');
    engine.complete();
    await _flush();
    expect(player.sleepTimer.phase, PlaybackSleepPhase.expired);
  });

  for (final duration in PlaybackSleepDuration.values) {
    test('${duration.name} arms exact UTC deadline without autoplay', () {
      final before = player.state;
      player.setSleepTimer(duration);
      expect(player.sleepTimer.deadline, clock.now.add(duration.duration));
      expect(player.sleepTimer.deadline!.isUtc, isTrue);
      expect(clock.wakes.single.delay, duration.duration);
      expect(player.sleepTimer.phase, PlaybackSleepPhase.armed);
      expect(player.state, same(before));
      expect(engine.calls, isEmpty);
    });
  }

  test('expiry pauses once and preserves queue and position', () async {
    await start();
    final queue = player.state.queue;
    final position = player.state.position;
    player.setSleepTimer(PlaybackSleepDuration.fifteen);
    expire();
    await _flush();
    clock.wakes.single.fire();
    await _flush();
    expect(engine.calls, ['pause']);
    expect(player.state.phase, PlaybackPhase.paused);
    expect(player.state.queue, same(queue));
    expect(player.state.position, position);
    expect(player.sleepTimer.phase, PlaybackSleepPhase.expired);
  });

  for (final reset in [false, true]) {
    test('retained canceled callback cannot act: reset=$reset', () async {
      await start();
      player.setSleepTimer(PlaybackSleepDuration.fifteen);
      final old = clock.wakes.last;
      player.setSleepTimer(reset ? PlaybackSleepDuration.sixty : null);
      clock.now = clock.now.add(const Duration(minutes: 15));
      old.fire();
      await _flush();
      expect(old.isActive, isFalse);
      expect(engine.calls, isEmpty);
      expect(
        player.sleepTimer.phase,
        reset ? PlaybackSleepPhase.armed : PlaybackSleepPhase.off,
      );
    });
  }

  test('early wake reschedules and revokes old callback', () async {
    await start();
    player.setSleepTimer(PlaybackSleepDuration.fifteen);
    final old = clock.wakes.single;
    clock.now = clock.now.add(const Duration(minutes: 5));
    old.fire();
    expect(clock.wakes.last.delay, const Duration(minutes: 10));
    old.fire();
    expect(clock.wakes, hasLength(2));
    expire();
    await _flush();
    expect(engine.calls, ['pause']);
  });

  test('clock rollback waits for absolute deadline', () {
    player.setSleepTimer(PlaybackSleepDuration.fifteen);
    clock.now = clock.now.subtract(const Duration(minutes: 5));
    clock.wakes.single.fire();
    expect(clock.wakes.last.delay, const Duration(minutes: 20));
    expect(player.sleepTimer.phase, PlaybackSleepPhase.armed);
  });

  test('late wake acts immediately without another timer', () async {
    await start();
    player.setSleepTimer(PlaybackSleepDuration.fifteen);
    clock.now = clock.now.add(const Duration(hours: 2));
    clock.wakes.single.fire();
    await _flush();
    expect(engine.calls, ['pause']);
    expect(clock.wakes, hasLength(1));
  });

  for (final paused in [false, true]) {
    test(
      'empty or already paused expires without engine call: $paused',
      () async {
        if (paused) {
          await start();
          await player.pause();
          engine.calls.clear();
        }
        player.setSleepTimer(PlaybackSleepDuration.fifteen);
        expire();
        await _flush();
        expect(engine.calls, isEmpty);
        expect(player.sleepTimer.phase, PlaybackSleepPhase.expired);
      },
    );
  }

  test('expiry waits for accepted load then pauses', () async {
    await player.replaceQueue([playbackFixtureEntry()]);
    final gate = Completer<void>();
    engine.loadGate = gate.future;
    final playing = player.play();
    await _flush();
    expect(engine.calls, ['load']);
    player.setSleepTimer(PlaybackSleepDuration.fifteen);
    expire();
    await _flush();
    expect(engine.calls, ['load']);
    gate.complete();
    await playing;
    await _flush();
    expect(engine.calls, ['load', 'play', 'pause']);
  });

  test('cancel revokes queued sleep pause behind load', () async {
    await player.replaceQueue([playbackFixtureEntry()]);
    final gate = Completer<void>();
    engine.loadGate = gate.future;
    final playing = player.play();
    await _flush();
    player.setSleepTimer(PlaybackSleepDuration.fifteen);
    expire();
    player.setSleepTimer(null);
    gate.complete();
    await playing;
    await _flush();
    expect(engine.calls, ['load', 'play']);
  });

  test('accepted pause does not overwrite a newly armed intent', () async {
    await start();
    final gate = Completer<void>();
    engine.pauseGate = gate.future;
    player.setSleepTimer(PlaybackSleepDuration.fifteen);
    expire();
    await _flush();
    expect(engine.calls, ['pause']);
    player.setSleepTimer(PlaybackSleepDuration.sixty);
    final replacement = player.sleepTimer;
    gate.complete();
    await _flush();
    expect(player.sleepTimer, same(replacement));
    expect(player.state.phase, PlaybackPhase.paused);
    expect(engine.calls, ['pause']);
  });

  test('close cancels timer and drains accepted pause', () async {
    await start();
    final gate = Completer<void>();
    engine.pauseGate = gate.future;
    player.setSleepTimer(PlaybackSleepDuration.fifteen);
    expire();
    await _flush();
    var closed = false;
    final closing = player.close().then((_) => closed = true);
    await _flush();
    expect(closed, isFalse);
    clock.wakes.single.fire();
    gate.complete();
    await closing;
    expect(player.sleepTimer.phase, PlaybackSleepPhase.off);
    expect(engine.calls, ['pause']);
    expect(() => player.setSleepTimer(null), throwsStateError);
  });

  test('completion queued before expiry cannot auto advance', () async {
    await start();
    await player.addToEnd(
      QueueEntry(
        id: 'second',
        track: playbackFixtureTrack.ref,
        position: 1,
        addedAt: clock.now,
      ),
    );
    player.setSleepTimer(PlaybackSleepDuration.fifteen);
    engine.complete();
    expire();
    await _flush();
    expect(engine.calls, isEmpty);
    expect(player.state.queue.currentEntryId, 'graph-fixture-entry');
    expect(player.sleepTimer.phase, PlaybackSleepPhase.expired);
  });

  for (final close in [false, true]) {
    test('pausing notification can revoke intent: close=$close', () async {
      await start();
      player.addListener(() {
        if (player.sleepTimer.phase == PlaybackSleepPhase.pausing) {
          if (close) {
            player.dispose();
          } else {
            player.setSleepTimer(null);
          }
        }
      });
      player.setSleepTimer(PlaybackSleepDuration.fifteen);
      expire();
      await _flush();
      expect(engine.calls, isEmpty);
      expect(player.sleepTimer.phase, PlaybackSleepPhase.off);
    });
  }

  test(
    'completion after deadline cannot enqueue a fresh auto advance',
    () async {
      await start();
      await player.addToEnd(
        QueueEntry(
          id: 'second',
          track: playbackFixtureTrack.ref,
          position: 1,
          addedAt: clock.now,
        ),
      );
      player.setSleepTimer(PlaybackSleepDuration.fifteen);
      expire();
      engine.complete();
      await _flush();
      expect(engine.calls, isEmpty);
      expect(player.state.queue.currentEntryId, 'graph-fixture-entry');
      expect(player.sleepTimer.phase, PlaybackSleepPhase.expired);
    },
  );

  for (final early in [false, true]) {
    test('scheduler failure is safe and terminal: early=$early', () {
      if (early) player.setSleepTimer(PlaybackSleepDuration.fifteen);
      clock.fail = true;
      if (early) {
        clock.wakes.single.fire();
      } else {
        player.setSleepTimer(PlaybackSleepDuration.fifteen);
      }
      expect(player.sleepTimer.phase, PlaybackSleepPhase.failed);
      expect(engine.calls, isEmpty);
    });
  }

  test('pause failure is observable without retry or sensitive text', () async {
    await start();
    engine.pauseError = StateError('private-device-detail');
    player.setSleepTimer(PlaybackSleepDuration.fifteen);
    expire();
    await _flush();
    expect(player.sleepTimer.phase, PlaybackSleepPhase.failed);
    expect(player.state.phase, PlaybackPhase.error);
    expect(
      player.state.failure.toString(),
      isNot(contains('private-device-detail')),
    );
    clock.wakes.single.fire();
    await _flush();
    expect(engine.calls, ['pause']);
  });
}

// Drain finite microtask chains without advancing the injected deadline clock.
Future<void> _flush() => Future<void>.delayed(Duration.zero);

final class _Clock {
  DateTime now = DateTime.utc(2026, 9, 13);
  final wakes = <_Wake>[];
  bool fail = false;

  Timer schedule(Duration delay, void Function() callback) {
    if (fail) throw StateError('private-scheduler-detail');
    final wake = _Wake(delay, callback);
    wakes.add(wake);
    return wake;
  }
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

  // Deliberately deliver canceled callbacks to exercise stale intent protection.
  void fire() {
    isActive = false;
    tick++;
    callback();
  }
}
