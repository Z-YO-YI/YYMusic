import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/domain/models/domain_failure.dart';
import 'package:yymusic/playback/playback_controller.dart';
import 'package:yymusic/playback/playback_sleep_timer_state.dart';
import 'package:yymusic/playback/playback_state.dart';

import '../support/fake_audio_engine.dart';
import '../support/fake_domain_repositories.dart';
import '../support/fake_playback_dependencies.dart';

void main() {
  late FakeAudioEngine engine;
  late PlaybackController root;
  late FakeLibraryRepository library;
  late DateTime now;
  late Duration elapsed;
  late void Function() deadline;
  late List<_Wake> wakes;
  var expectCloseFailure = false;
  setUp(() async {
    now = DateTime.utc(2026, 9, 13);
    elapsed = Duration.zero;
    wakes = [];
    expectCloseFailure = false;
    engine = FakeAudioEngine();
    library = FakeLibraryRepository(tracks: [playbackFixtureTrack]);
    root = PlaybackController(
      engine,
      library: library,
      sourceResolver: FakePlaybackSourceResolver(),
      clock: () => now,
      sleepScheduler: (_, callback) {
        deadline = callback;
        return _Wake(callback);
      },
      sleepFadeElapsed: () => elapsed,
      sleepFadeScheduler: (_, callback) {
        final wake = _Wake(callback);
        wakes.add(wake);
        return wake;
      },
    );
    await root.replaceQueue([playbackFixtureEntry()]);
    await root.play();
    engine.calls.clear();
  });
  tearDown(() async {
    if (expectCloseFailure) {
      await expectLater(root.close(), throwsA(isA<DomainFailure>()));
    } else {
      await root.close();
    }
    await engine.dispose();
    await library.dispose();
  });

  Future<void> expire() async {
    root.setSleepTimer(PlaybackSleepDuration.fifteen);
    now = root.sleepTimer.deadline!;
    deadline();
    await _flush();
  }

  Future<void> tick(int milliseconds) async {
    elapsed = Duration(milliseconds: milliseconds);
    wakes.last.fire();
    await _flush();
  }

  test(
    'production root fades, pauses once, restores and never moves volume UI',
    () async {
      await root.setVolume(0.8);
      engine.calls.clear();
      final seen = <double>[];
      root.addListener(() => seen.add(root.state.volume));
      final queue = root.state.queue;
      await expire();
      await tick(1000);
      expect(engine.volume, 0.4);
      expect(root.sleepTimer.phase, PlaybackSleepPhase.pausing);
      await tick(2000);
      expect(engine.calls, [
        'volume:0.8',
        'volume:0.4',
        'volume:0.0',
        'pause',
        'volume:0.8',
      ]);
      expect(root.sleepTimer.phase, PlaybackSleepPhase.expired);
      expect(root.state.phase, PlaybackPhase.paused);
      expect(root.state.queue, same(queue));
      expect(seen.every((v) => v == 0.8), isTrue);
      deadline();
      await _flush();
      expect(engine.calls.where((c) => c == 'pause'), hasLength(1));
    },
  );

  test(
    'first fade locks initial volume even without a user adjustment',
    () async {
      await expire();
      await tick(1000);
      expect(engine.volume, 0.5);
      expect(root.state.volume, 1);
      root.setSleepTimer(null);
      await _flush();
      expect(engine.volume, 1);
      expect(root.sleepTimer.phase, PlaybackSleepPhase.off);
      expect(engine.calls, isNot(contains('pause')));
    },
  );

  test(
    'new user volume interrupts fade and old wake cannot overwrite it',
    () async {
      await expire();
      await tick(1000);
      final old = wakes.last;
      await root.setVolume(0.3);
      await _flush();
      old.fire();
      await _flush();
      expect(root.state.volume, 0.3);
      expect(engine.volume, 0.3);
      expect(engine.calls.last, 'volume:0.3');
      expect(root.sleepTimer.phase, PlaybackSleepPhase.off);
    },
  );

  test('invalid volume and revoked seek do not cancel active fade', () async {
    await expire();
    await expectLater(root.setVolume(-1), throwsArgumentError);
    await root.seek(Duration.zero, canSeek: () => false);
    expect(root.sleepTimer.phase, PlaybackSleepPhase.pausing);
    await tick(2000);
    expect(root.sleepTimer.phase, PlaybackSleepPhase.expired);
  });

  test(
    'explicit pause interrupts and restores without waiting two seconds',
    () async {
      await expire();
      await tick(1000);
      await root.pause();
      await _flush();
      expect(root.state.phase, PlaybackPhase.paused);
      expect(root.sleepTimer.phase, PlaybackSleepPhase.off);
      expect(engine.volume, 1);
      expect(engine.calls.where((c) => c == 'pause'), hasLength(1));
    },
  );

  test(
    'reload restores amplitude before starting the selected entry',
    () async {
      await expire();
      await tick(1000);
      engine.calls.clear();
      await root.playEntry(playbackFixtureEntry().id);
      await _flush();
      expect(engine.calls.first, 'volume:1.0');
      expect(engine.calls, contains('play'));
      expect(engine.volume, 1);
      expect(root.sleepTimer.phase, PlaybackSleepPhase.off);
    },
  );

  test('new timer survives old fade completion and restoration', () async {
    await expire();
    await tick(1000);
    root.setSleepTimer(PlaybackSleepDuration.sixty);
    final replacement = root.sleepTimer;
    await _flush();
    expect(root.sleepTimer, same(replacement));
    expect(engine.volume, 1);
    expect(engine.calls, isNot(contains('pause')));
  });

  test(
    'natural completion during fade never advances or restarts playback',
    () async {
      await expire();
      engine.complete();
      await tick(1000);
      expect(root.state.phase, PlaybackPhase.completed);
      expect(root.sleepTimer.phase, PlaybackSleepPhase.expired);
      expect(engine.volume, 1);
      expect(engine.calls, isNot(contains('play')));
    },
  );

  test(
    'close drains a slow native gain and restores after shutdown begins',
    () async {
      final gate = Completer<void>();
      engine.volumeGate = gate.future;
      await expire();
      var closed = false;
      final closing = root.close().then((_) => closed = true);
      await _flush();
      expect(closed, isFalse);
      gate.complete();
      await closing;
      expect(engine.calls, ['volume:1.0', 'volume:1.0']);
      expect(engine.disposalCount, 0);
      expect(root.sleepTimer.phase, PlaybackSleepPhase.off);
    },
  );

  test('failed gain is observable and attempts restoration', () async {
    engine.onVolume = (value) {
      engine.volumeError = value == 0.5 ? StateError('private gain') : null;
    };
    await expire();
    await tick(1000);
    expect(root.sleepTimer.phase, PlaybackSleepPhase.failed);
    expect(root.state.phase, PlaybackPhase.error);
    expect(engine.calls.last, 'volume:1.0');
    expect(engine.volume, 1);
  });

  test(
    'failed restoration is surfaced by close, not hidden as successful cleanup',
    () async {
      await expire();
      await tick(1000);
      engine.volumeError = StateError('private restore');
      expectCloseFailure = true;
      await expectLater(root.close(), throwsA(isA<DomainFailure>()));
    },
  );
  test(
    'user volume behind a slow gain wins after that write completes',
    () async {
      await expire();
      final gate = Completer<void>();
      engine.volumeGate = gate.future;
      await tick(1000);
      final changing = root.setVolume(0.2);
      await _flush();
      gate.complete();
      await changing;
      await _flush();
      expect(root.state.volume, 0.2);
      expect(engine.volume, 0.2);
      expect(engine.calls.last, 'volume:0.2');
      expect(engine.calls, isNot(contains('pause')));
    },
  );

  test(
    'engine callback can close during reduced gain without leaking attenuation',
    () async {
      await expire();
      engine.onVolume = (volume) {
        if (volume == 0.5) root.dispose();
      };
      await tick(1000);
      await root.close();
      expect(engine.volume, 1);
      expect(engine.calls.last, 'volume:1.0');
      expect(engine.disposalCount, 0);
    },
  );

  test(
    'clear queue cancels active fade and restores without autoplay',
    () async {
      await expire();
      await tick(1000);
      await root.clearQueue();
      await _flush();
      expect(root.state.queue.entries, isEmpty);
      expect(root.sleepTimer.phase, PlaybackSleepPhase.off);
      expect(engine.volume, 1);
      expect(engine.calls, isNot(contains('play')));
    },
  );

  test('revoked play entry does not cancel fade', () async {
    await expire();
    await root.playEntry(playbackFixtureEntry().id, canPlay: () => false);
    expect(root.sleepTimer.phase, PlaybackSleepPhase.pausing);
    await tick(2000);
    expect(root.sleepTimer.phase, PlaybackSleepPhase.expired);
  });

  test(
    'explicit play restores user volume before sending native play',
    () async {
      await expire();
      await tick(1000);
      engine.calls.clear();
      await root.play();
      await _flush();
      expect(engine.calls, ['volume:1.0', 'play']);
      expect(root.sleepTimer.phase, PlaybackSleepPhase.off);
    },
  );

  test(
    'failed user volume during fade restores prior confirmed intent',
    () async {
      await expire();
      await tick(1000);
      engine.onVolume = (volume) {
        engine.volumeError = volume == 0.2 ? StateError('rejected') : null;
      };
      await expectLater(root.setVolume(0.2), throwsA(isA<DomainFailure>()));
      await _flush();
      expect(root.state.volume, 1);
      expect(engine.volume, 1);
      expect(root.state.phase, PlaybackPhase.error);
      expect(engine.calls.last, 'volume:1.0');
    },
  );
}

Future<void> _flush() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

final class _Wake implements Timer {
  _Wake(this.callback);
  final void Function() callback;
  bool active = true;
  void fire() => callback();
  @override
  bool get isActive => active;
  @override
  int get tick => 0;
  @override
  void cancel() => active = false;
}
