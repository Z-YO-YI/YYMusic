import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/domain/models/track.dart';
import 'package:yymusic/playback/playable_source.dart';
import 'package:yymusic/playback/playback_controller.dart';
import 'package:yymusic/playback/playback_sleep_timer_state.dart';
import 'package:yymusic/playback/playback_source_resolver.dart';
import 'package:yymusic/playback/playback_state.dart';

import '../support/fake_audio_engine.dart';
import '../support/fake_domain_repositories.dart';
import '../support/fake_playback_dependencies.dart';

final class GatedResolver implements PlaybackSourceResolver {
  Completer<void>? gate;
  @override
  Future<PlayableSource> resolve(Track track) async {
    await gate?.future;
    return FakePlaybackSourceResolver().resolve(track);
  }
}

Future<void> flush() async {
  for (var i = 0; i < 16; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late FakeAudioEngine engine;
  late FakeLibraryRepository library;
  late GatedResolver resolver;
  late PlaybackController player;
  setUp(() async {
    engine = FakeAudioEngine();
    library = FakeLibraryRepository(tracks: [playbackFixtureTrack]);
    resolver = GatedResolver();
    player = PlaybackController(
      engine,
      library: library,
      sourceResolver: resolver,
      randomIndex: (upper) => upper - 1,
    );
    await player.replaceQueue([
      playbackFixtureEntry(),
      for (var i = 1; i <= 2; i++)
        QueueEntry(
          id: 'next-$i',
          track: playbackFixtureTrack.ref,
          position: i,
          addedAt: DateTime.utc(2026),
        ),
    ]);
    await player.play();
    engine.calls.clear();
  });
  tearDown(() async {
    await player.close();
    await engine.dispose();
    await library.dispose();
  });

  test('default continues once after natural completion', () async {
    expect(player.continueAfterTrack, isTrue);
    engine.complete();
    engine.complete();
    await flush();
    expect(player.state.queue.currentEntryId, 'next-1');
    expect(engine.calls.where((call) => call == 'play').length, 1);
  });

  for (final repeat in RepeatMode.values) {
    for (final shuffle in [false, true]) {
      test('off stops natural advance for $repeat shuffle=$shuffle', () async {
        player.setRepeatMode(repeat);
        player.setShuffleEnabled(shuffle);
        player.setContinueAfterTrack(false);
        engine.complete();
        await flush();
        expect(player.state.phase, PlaybackPhase.completed);
        expect(player.state.queue.currentEntryId, playbackFixtureEntry().id);
        expect(engine.calls, isEmpty);
      });
    }
  }

  test(
    'manual next remains available while automatic continuation is off',
    () async {
      player.setContinueAfterTrack(false);
      await player.skipNext();
      expect(player.state.queue.currentEntryId, 'next-1');
      expect(player.state.phase, PlaybackPhase.playing);
    },
  );

  test('reenabling after completion does not retroactively autoplay', () async {
    player.setContinueAfterTrack(false);
    engine.complete();
    await flush();
    player.setContinueAfterTrack(true);
    engine.complete();
    await flush();
    expect(engine.calls, isEmpty);
    expect(player.state.phase, PlaybackPhase.completed);
  });

  test('disable and reenable revoke a queued old completion', () async {
    engine.complete();
    player.setContinueAfterTrack(false);
    player.setContinueAfterTrack(true);
    await flush();
    expect(engine.calls, isEmpty);
  });

  test('completion listener can revoke before scheduling', () async {
    player.addListener(() {
      if (player.state.phase == PlaybackPhase.completed) {
        player.setContinueAfterTrack(false);
      }
    });
    engine.complete();
    await flush();
    expect(engine.calls, isEmpty);
  });

  test(
    'disable during source resolution prevents loading the next entry',
    () async {
      final gate = resolver.gate = Completer<void>();
      engine.complete();
      await flush();
      player.setContinueAfterTrack(false);
      gate.complete();
      await flush();
      expect(engine.calls, isEmpty);
      expect(player.state.queue.currentEntryId, playbackFixtureEntry().id);
    },
  );

  test(
    'disable during accepted native load prevents play and stops loaded source',
    () async {
      final gate = Completer<void>();
      engine.loadGate = gate.future;
      engine.complete();
      await flush();
      expect(engine.calls, ['stop', 'load']);
      player.setContinueAfterTrack(false);
      gate.complete();
      await flush();
      expect(engine.calls, ['stop', 'load', 'stop']);
      expect(player.state.phase, PlaybackPhase.idle);
    },
  );

  test('repeat-one delayed seek cannot restart after disabling', () async {
    player.setRepeatMode(RepeatMode.one);
    final gate = Completer<void>();
    engine.seekGate = gate.future;
    engine.complete();
    await flush();
    expect(engine.calls, ['seek:0']);
    player.setContinueAfterTrack(false);
    gate.complete();
    await flush();
    expect(engine.calls, ['seek:0']);
  });

  test(
    'cancelled shuffle candidate is not skipped by the next manual action',
    () async {
      player.setShuffleEnabled(true);
      final gate = resolver.gate = Completer<void>();
      engine.complete();
      await flush();
      player.setContinueAfterTrack(false);
      gate.complete();
      resolver.gate = null;
      await flush();
      await player.skipNext();
      expect(player.state.queue.currentEntryId, 'next-1');
    },
  );

  test(
    'entry-end sleep is consumed even when continuation is disabled',
    () async {
      expect(player.setSleepAtCurrentEntryEnd(), isTrue);
      player.setContinueAfterTrack(false);
      engine.complete();
      await flush();
      expect(player.sleepTimer.phase, PlaybackSleepPhase.expired);
      expect(engine.calls, isEmpty);
    },
  );

  test(
    'same value and closed root do not notify or issue audio commands',
    () async {
      var notifications = 0;
      player.addListener(() => notifications++);
      player.setContinueAfterTrack(true);
      expect(notifications, 0);
      player.setContinueAfterTrack(false);
      expect(notifications, 1);
      expect(engine.calls, isEmpty);
      await player.close();
      player.setContinueAfterTrack(true);
      expect(player.continueAfterTrack, isFalse);
    },
  );
}
