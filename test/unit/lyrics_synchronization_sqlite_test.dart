import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/database_app_data_services.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/data/database/app_database.dart';
import 'package:yymusic/domain/models/load_state.dart';

import '../support/fake_audio_engine.dart';
import '../support/fake_playback_dependencies.dart';
import '../support/lyrics_fixture.dart';
import '../support/search_query_probe.dart';

void main() {
  test(
    'root reads real SQLite lyrics by full source and applies persisted offset',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      final services = await DatabaseAppDataServices.open(db);
      final graph = DependencyGraph(
        dataServices: services,
        audioEngine: FakeAudioEngine(),
        playbackSourceResolver: FakePlaybackSourceResolver(),
      );
      addTearDown(graph.close);
      await services.library.upsertTracks(lyricsTracks);
      await services.lyrics.saveLyrics(timedLyrics(lyricsTracks[0].ref));
      await services.lyrics.saveLyrics(
        timedLyrics(lyricsTracks[1].ref, offset: const Duration(seconds: -2)),
      );
      await graph.initialize();
      await graph.queue.replace(lyricsEntries(), currentEntryId: 'entry-1');
      await graph.playback.play();
      graph.lyricsController.setActive(true);
      await flushLyrics();
      final snapshot = graph.lyricsController.state;
      expect(snapshot.phase, LoadPhase.data);
      expect(snapshot.data!.track, lyricsTracks[1].ref);
      expect(snapshot.data!.lines.first.translation, '测试行 0');
      await graph.lyricsController.seekLine(0, expectedState: snapshot);
      expect(graph.playback.state.position, const Duration(seconds: 8));
      expect(graph.lyricsController.activeIndex, 0);
      await graph.playback.playEntry('entry-2');
      await flushLyrics();
      expect(graph.lyricsController.state.phase, LoadPhase.empty);
    },
  );

  test('root close drains delayed actual SQLite SELECT before shared scope disposal', () async {
    final probe = SearchQueryProbe();
    final db = AppDatabase(NativeDatabase.memory().interceptWith(probe));
    final services = await DatabaseAppDataServices.open(db);
    final engine = FakeAudioEngine();
    final graph = DependencyGraph(
      dataServices: services,
      audioEngine: engine,
      playbackSourceResolver: FakePlaybackSourceResolver(),
    );
    addTearDown(graph.close);
    await services.library.upsertTracks(lyricsTracks);
    await services.lyrics.saveLyrics(timedLyrics(lyricsTracks.first.ref));
    await graph.initialize();
    await graph.queue.replace(lyricsEntries(), currentEntryId: 'entry-0');
    await graph.playback.play();
    final gate = Completer<void>(), entered = Completer<void>();
    probe.afterSelect = () async {
      if (probe.selects.last.sql.contains('lyrics_cache')) {
        if (!entered.isCompleted) entered.complete();
        await gate.future;
      }
    };
    graph.lyricsController.setActive(true);
    await entered.future;
    var closed = false;
    final closing = graph.close().then((_) => closed = true);
    await flushLyrics();
    expect(closed, isFalse);
    expect(probe.closeCount, 0);
    expect(engine.disposalCount, 0);
    gate.complete();
    await closing;
    expect(probe.closeCount, 1);
    expect(engine.disposalCount, 1);
    expect(graph.lyricsController.state.phase, LoadPhase.idle);
  });
}
