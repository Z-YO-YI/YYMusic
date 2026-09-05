import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/database_app_data_services.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/data/database/app_database.dart';
import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/domain/models/load_state.dart';
import 'package:yymusic/domain/models/music_source.dart';
import 'package:yymusic/domain/models/track.dart';

import '../support/fake_audio_engine.dart';
import '../support/fake_playback_dependencies.dart';

void main() {
  test('Home reads and clears real SQLite data through the owned production repositories', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final services = await DatabaseAppDataServices.open(db);
    final track = Track(
      id: 'database-home',
      sourceId: 'local',
      sourceType: MusicSourceType.local,
      title: '数据库里的曲目',
      artists: const ['艺人'],
      duration: const Duration(seconds: 190),
      localPath: '/fixture-only.wav',
    );
    await services.library.upsertTracks([track]);
    await services.collection.recordHistory(
      PlayHistoryEntry(
        id: 'history',
        track: track.ref,
        startedAt: DateTime.now().toUtc(),
        lastPosition: const Duration(seconds: 20),
      ),
    );
    await services.musicSources.saveSource(
      MusicSourceConfig(
        id: 'source',
        name: '测试来源',
        type: MusicSourceType.rest,
        baseUrl: Uri.parse('https://fixture.invalid'),
        authType: MusicSourceAuthType.none,
        enabled: true,
        status: MusicSourceStatus.offline,
      ),
    );
    final graph = DependencyGraph(
      dataServices: services,
      audioEngine: FakeAudioEngine(),
      playbackSourceResolver: FakePlaybackSourceResolver(),
    );
    addTearDown(graph.close);
    await graph.initialize();
    final loaded = Completer<void>();
    void check() {
      if (graph.home.recent.phase == LoadPhase.data &&
          graph.home.history.phase == LoadPhase.data &&
          graph.home.sources.phase == LoadPhase.data &&
          !loaded.isCompleted) {
        loaded.complete();
      }
    }

    graph.home.addListener(check);
    graph.home.start();
    await loaded.future.timeout(const Duration(seconds: 5));
    graph.home.removeListener(check);
    expect(graph.home.recent.data!.single.ref, track.ref);
    expect(graph.home.history.data!.single.title, '数据库里的曲目');
    expect(graph.home.sources.data!.single.status, MusicSourceStatus.offline);
    await graph.home.play(track);
    expect(graph.playbackPresenter.data.playing, isTrue);
    final cleared = Completer<void>();
    void checkClear() {
      if (graph.home.history.phase == LoadPhase.empty && !cleared.isCompleted) {
        cleared.complete();
      }
    }

    graph.home.addListener(checkClear);
    await graph.home.clearHistory();
    await cleared.future.timeout(const Duration(seconds: 5));
    graph.home.removeListener(checkClear);
    expect(await services.library.getTrack(track.ref), isNotNull);
    expect(
      (await services.collection.loadQueue()).entries.single.track,
      track.ref,
    );
    expect(await db.select(db.playHistoryRecords).get(), isEmpty);
    await graph.close();
  });
}
