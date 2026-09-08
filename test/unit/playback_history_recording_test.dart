import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/playback/audio_engine_state.dart';
import 'package:yymusic/playback/playback_state.dart';

import '../support/playback_history_probe.dart';
import '../support/playlist_content_probe.dart';

void main() {
  late PlaybackHistoryFixture f;
  setUp(() async {
    f = PlaybackHistoryFixture();
    await f.initialize();
  });
  tearDown(() => f.close());

  test('ack and stationary playing do not write; first real clock progress records once', () async {
    await f.player.play();
    expect(f.engine.calls, ['load', 'play']);
    f.tick(0);
    await contentTick();
    expect(f.writes, isEmpty);
    f.tick(150);
    await waitHistory(f.player.history);
    expect(f.writes.single.track, f.tracks.first.ref);
    expect(f.writes.single.lastPosition, const Duration(milliseconds: 150));
    f.tick(300);
    f.tick(1000);
    await contentTick();
    expect(f.writes.length, 1);
  });

  test(
    'unloaded, loading, buffering and ready progress cannot count as started',
    () async {
      f.tick(100);
      expect(f.writes, isEmpty);
      await f.player.play();
      for (final phase in [
        AudioEnginePhase.loading,
        AudioEnginePhase.buffering,
        AudioEnginePhase.ready,
      ]) {
        f.tick(100, phase: phase);
        f.tick(200, phase: phase);
      }
      await contentTick();
      expect(f.writes, isEmpty);
      f.tick(200);
      f.tick(250);
      await waitHistory(f.player.history);
      expect(f.writes.length, 1);
    },
  );

  test(
    'pause resume buffering and ordinary seeks retain one listening cycle',
    () async {
      await f.player.play();
      f.tick(100);
      await waitHistory(f.player.history);
      await f.player.pause();
      await f.player.play();
      f.tick(200);
      f.tick(400, phase: AudioEnginePhase.buffering);
      f.tick(450);
      f.tick(500);
      await f.player.seek(const Duration(seconds: 40));
      await f.player.play();
      f.tick(40100);
      await waitHistory(f.player.history);
      expect(f.writes.length, 1);
    },
  );

  test('seek before any elapsed audio resets baseline instead of fabricating history', () async {
    await f.player.play();
    await f.player.seek(const Duration(seconds: 60));
    f.tick(60000);
    f.tick(60000);
    await contentTick();
    expect(f.writes, isEmpty);
    f.tick(60050);
    await waitHistory(f.player.history);
    expect(f.writes.single.lastPosition, const Duration(milliseconds: 60050));
  });

  test(
    'stop and late playing facts do not resurrect a historical session',
    () async {
      await f.player.play();
      await f.player.stop();
      f.tick(10);
      f.tick(20);
      await contentTick();
      expect(f.writes, isEmpty);
    },
  );

  test('explicit replay records again and moves the full track reference to the top', () async {
    await f.player.playEntry('q-0');
    f.tick(100);
    await waitHistory(f.player.history);
    await f.player.playEntry('q-1');
    f.tick(100);
    await waitHistory(f.player.history);
    await f.player.playEntry('q-0');
    f.tick(100);
    await waitHistory(f.player.history);
    final history = await f.collection.watchHistory().first;
    expect(f.writes.length, 3);
    expect(history.map((e) => e.track), [f.tracks[0].ref, f.tracks[1].ref]);
    expect(history.first.id, 'record-2');
    expect(history.first.startedAt.isAfter(history.last.startedAt), isTrue);
    expect(f.player.state.queue.entries.map((e) => e.id), ['q-0', 'q-1']);
  });

  test(
    'natural next and repeat-one each start a new confirmed listening cycle',
    () async {
      await f.player.play();
      f.tick(100);
      await waitHistory(f.player.history);
      f.tick(120000, phase: AudioEnginePhase.completed);
      await contentTick();
      expect(f.player.state.queue.currentEntryId, 'q-1');
      f.tick(100);
      await waitHistory(f.player.history);
      f.player.setRepeatMode(RepeatMode.one);
      f.tick(120000, phase: AudioEnginePhase.completed);
      await contentTick();
      f.tick(100);
      await waitHistory(f.player.history);
      expect(f.writes.map((e) => e.track), [
        f.tracks[0].ref,
        f.tracks[1].ref,
        f.tracks[1].ref,
      ]);
    },
  );

  test(
    'short completed progress counts but no-clock completion does not',
    () async {
      await f.player.playEntry('q-1');
      f.tick(30, phase: AudioEnginePhase.completed);
      await waitHistory(f.player.history);
      expect(f.writes.length, 1);
      await f.player.playEntry('q-1');
      f.tick(0, phase: AudioEnginePhase.completed);
      await contentTick();
      expect(f.writes.length, 1);
    },
  );

  test('seek from completed can create a new cycle without treating the seek as elapsed audio', () async {
    await f.player.playEntry('q-1');
    f.tick(100);
    await waitHistory(f.player.history);
    f.tick(120000, phase: AudioEnginePhase.completed);
    await contentTick();
    await f.player.seek(const Duration(seconds: 10));
    f.tick(10000);
    expect(f.writes.length, 1);
    f.tick(10100);
    await waitHistory(f.player.history);
    expect(f.writes.length, 2);
  });
}
