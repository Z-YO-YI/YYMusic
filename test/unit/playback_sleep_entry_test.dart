import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/playback/audio_engine_state.dart';
import 'package:yymusic/playback/playback_controller.dart';
import 'package:yymusic/playback/playback_sleep_timer_state.dart';
import 'package:yymusic/playback/playback_state.dart';

import '../support/fake_audio_engine.dart';
import '../support/fake_domain_repositories.dart';
import '../support/fake_playback_dependencies.dart';

void main() {
  late FakeAudioEngine engine;
  late FakeLibraryRepository library;
  late PlaybackController player;

  setUp(() {
    engine = FakeAudioEngine();
    library = FakeLibraryRepository(tracks: [playbackFixtureTrack]);
    player = PlaybackController(
      engine,
      library: library,
      sourceResolver: FakePlaybackSourceResolver(),
    );
  });
  tearDown(() async {
    await player.close();
    await engine.dispose();
    await library.dispose();
  });

  Future<void> start() async {
    await player.replaceQueue([
      playbackFixtureEntry(),
      QueueEntry(
        id: 'duplicate',
        track: playbackFixtureTrack.ref,
        position: 1,
        addedAt: DateTime.utc(2026),
      ),
    ]);
    await player.play();
    engine.calls.clear();
  }

  for (final repeat in RepeatMode.values) {
    for (final shuffle in [false, true]) {
      test('consumes completion before $repeat shuffle=$shuffle', () async {
        await start();
        player.setRepeatMode(repeat);
        player.setShuffleEnabled(shuffle);
        final queue = player.state.queue;
        expect(player.setSleepAtCurrentEntryEnd(), isTrue);
        expect(player.sleepTimer.entryId, 'graph-fixture-entry');
        expect(player.sleepTimer.deadline, isNull);
        engine.complete();
        engine.complete();
        await _flush();
        expect(player.sleepTimer.phase, PlaybackSleepPhase.expired);
        expect(player.state.phase, PlaybackPhase.completed);
        expect(player.state.queue, same(queue));
        expect(engine.calls, isEmpty);
      });
    }
  }

  test('empty rejection preserves existing deadline', () {
    player.setSleepTimer(PlaybackSleepDuration.fifteen);
    final prior = player.sleepTimer;
    expect(player.setSleepAtCurrentEntryEnd(), isFalse);
    expect(player.sleepTimer, same(prior));
  });

  test('loading rejection does not arm a future entry', () async {
    await player.replaceQueue([playbackFixtureEntry()]);
    final gate = Completer<void>();
    engine.loadGate = gate.future;
    final playing = player.play();
    await _flush();
    expect(player.setSleepAtCurrentEntryEnd(), isFalse);
    gate.complete();
    await playing;
    expect(player.sleepTimer.phase, PlaybackSleepPhase.off);
  });

  test('completed rejection cannot undo consumed sleep', () async {
    await start();
    player.setSleepAtCurrentEntryEnd();
    engine.complete();
    final prior = player.sleepTimer;
    expect(player.setSleepAtCurrentEntryEnd(), isFalse);
    expect(player.sleepTimer, same(prior));
    await _flush();
    expect(engine.calls, isEmpty);
  });

  test('pause, seek and resume retain exact entry intent', () async {
    await start();
    await player.pause();
    expect(player.setSleepAtCurrentEntryEnd(), isTrue);
    final prior = player.sleepTimer;
    await player.seek(const Duration(seconds: 30));
    await player.play();
    expect(player.sleepTimer, same(prior));
    engine.calls.clear();
    engine.complete();
    await _flush();
    expect(engine.calls, isEmpty);
    expect(player.sleepTimer.phase, PlaybackSleepPhase.expired);
  });

  test('buffering can arm without extra audio commands', () async {
    await start();
    engine.events.add(AudioEngineState(phase: AudioEnginePhase.buffering));
    expect(player.setSleepAtCurrentEntryEnd(), isTrue);
    expect(engine.calls, isEmpty);
  });

  test('manual switch to duplicate song cancels exact entry target', () async {
    await start();
    player.setSleepAtCurrentEntryEnd();
    await player.playEntry('duplicate');
    expect(player.sleepTimer.phase, PlaybackSleepPhase.off);
    player.setRepeatMode(RepeatMode.all);
    engine.calls.clear();
    engine.complete();
    await _flush();
    expect(engine.calls, contains('play'));
    expect(player.state.queue.currentEntryId, 'graph-fixture-entry');
  });

  for (final action in ['stop', 'clear', 'reload', 'error']) {
    test('$action revokes armed current entry sleep', () async {
      await start();
      player.setSleepAtCurrentEntryEnd();
      switch (action) {
        case 'stop':
          await player.stop();
        case 'clear':
          await player.clearQueue();
        case 'reload':
          await player.playEntry('graph-fixture-entry');
        case 'error':
          engine.pauseError = StateError('private-detail');
          await expectLater(player.pause(), throwsA(isA<Object>()));
      }
      expect(player.sleepTimer.phase, PlaybackSleepPhase.off);
    });
  }

  test('cancel restores ordinary future completion behavior', () async {
    await start();
    player.setSleepAtCurrentEntryEnd();
    player.setSleepTimer(null);
    engine.complete();
    await _flush();
    expect(player.state.queue.currentEntryId, 'duplicate');
    expect(engine.calls, contains('play'));
  });

  test(
    'deadline replaces entry-end rather than suppressing completion',
    () async {
      await start();
      player.setSleepAtCurrentEntryEnd();
      player.setSleepTimer(PlaybackSleepDuration.sixty);
      expect(player.sleepTimer.entryId, isNull);
      engine.complete();
      await _flush();
      expect(player.state.queue.currentEntryId, 'duplicate');
      expect(player.sleepTimer.phase, PlaybackSleepPhase.armed);
    },
  );

  test('repeated arm and explicit replay are one-shot', () async {
    await start();
    expect(player.setSleepAtCurrentEntryEnd(), isTrue);
    expect(player.setSleepAtCurrentEntryEnd(), isTrue);
    engine.complete();
    await _flush();
    await player.play();
    engine.calls.clear();
    engine.complete();
    await _flush();
    expect(player.state.queue.currentEntryId, 'duplicate');
    expect(engine.calls, contains('play'));
  });

  for (final action in ['cancel', 'deadline', 'close']) {
    test(
      'completion listener $action cannot resurrect consumed advance',
      () async {
        await start();
        player.setSleepAtCurrentEntryEnd();
        var handled = false;
        player.addListener(() {
          if (handled ||
              player.sleepTimer.phase != PlaybackSleepPhase.expired) {
            return;
          }
          handled = true;
          switch (action) {
            case 'cancel':
              player.setSleepTimer(null);
            case 'deadline':
              player.setSleepTimer(PlaybackSleepDuration.thirty);
            case 'close':
              player.dispose();
          }
        });
        engine.complete();
        await _flush();
        expect(handled, isTrue);
        expect(engine.calls, isEmpty);
        expect(player.state.queue.currentEntryId, 'graph-fixture-entry');
      },
    );
  }

  test('close revokes armed entry and late completion', () async {
    await start();
    player.setSleepAtCurrentEntryEnd();
    await player.close();
    engine.complete();
    await _flush();
    expect(player.sleepTimer.phase, PlaybackSleepPhase.off);
    expect(engine.calls, isEmpty);
    expect(() => player.setSleepAtCurrentEntryEnd(), throwsStateError);
  });
}

Future<void> _flush() => Future<void>.delayed(Duration.zero);
