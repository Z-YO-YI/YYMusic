import 'dart:async';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/database_app_data_services.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/data/database/app_database.dart';
import 'package:yymusic/domain/models/domain_failure.dart';
import 'package:yymusic/domain/models/track.dart';
import 'package:yymusic/playback/playback_history_recorder.dart';
import 'package:yymusic/playback/playback_state.dart';

import '../support/catalog_detail_probe.dart';
import '../support/fake_audio_engine.dart';
import '../support/fake_domain_repositories.dart';
import '../support/fake_playback_dependencies.dart';
import '../support/playback_history_probe.dart';
import '../support/playlist_content_probe.dart';
import '../support/search_query_probe.dart';
import 'system_playlist_repository_test.dart' show systemHistory, systemQueue;

void main() {
  for (final fake in [false, true]) {
    test(
      '${fake ? 'Fake' : 'SQLite'} history collision cannot overwrite another full source reference',
      () async {
        final services = await DatabaseAppDataServices.open(
          AppDatabase(NativeDatabase.memory()),
        );
        final memory = FakeCollectionRepository();
        final repository = fake ? memory : services.collection;
        final a = detailTrack('same', source: 'a').ref,
            b = detailTrack('same', source: 'b').ref;
        await repository.recordHistory(
          systemHistory('original', b, contentEpoch),
        );
        await repository.recordHistory(
          systemHistory('collision', a, contentEpoch),
        );
        await expectLater(
          repository.recordHistory(systemHistory('collision', b, contentEpoch)),
          throwsA(
            isA<DomainFailure>().having(
              (e) => e.code,
              'code',
              DomainFailureCode.schemaMismatch,
            ),
          ),
        );
        final saved = await repository.watchHistory().first;
        expect(saved.map((e) => e.id).toSet(), {'original', 'collision'});
        expect(saved.singleWhere((e) => e.id == 'collision').track, a);
        await repository.recordHistory(
          systemHistory(
            'original',
            b,
            contentEpoch.add(const Duration(seconds: 1)),
          ),
        );
        expect((await repository.watchHistory().first).length, 2);
        await services.dispose();
        await memory.dispose();
      },
    );
  }

  test('real SQLite recording retains 20 and keeps source type/source ID distinctions', () async {
    final services = await DatabaseAppDataServices.open(
      AppDatabase(NativeDatabase.memory()),
    );
    var id = 0;
    final h = PlaybackHistoryRecorder(
      collection: services.collection,
      clock: () => contentEpoch,
      idFactory: () => 'h-${id++}',
    );
    for (var i = 0; i < 24; i++) {
      h.begin(
        detailTrack(
          'same',
          source: 's-${i ~/ 2}',
          type: i.isEven ? MusicSourceType.local : MusicSourceType.rest,
        ).ref,
      );
      h.activate();
      h.observe(historyState(0));
      h.observe(historyState(100));
    }
    await h.close();
    final saved = await services.collection.watchHistory().first;
    expect(saved.length, 20);
    expect(saved.map((e) => e.track).toSet().length, 20);
    expect(saved.first.id, 'h-23');
    expect(saved.last.id, 'h-4');
    expect(await services.collection.watchPlaylists().first, isEmpty);
    await services.dispose();
  });

  test('SQLite abort rolls back same-track deletion and latest retry restores one frozen record', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final services = await DatabaseAppDataServices.open(database);
    final track = detailTrack('a').ref;
    await services.collection.recordHistory(
      systemHistory('old', track, contentEpoch),
    );
    await database.customStatement(
      "CREATE TRIGGER history_failure BEFORE INSERT ON play_history WHEN NEW.history_id = 'retry' BEGIN SELECT RAISE(ABORT, 'private-marker'); END",
    );
    final h = PlaybackHistoryRecorder(
      collection: services.collection,
      clock: () => contentEpoch,
      idFactory: () => 'retry',
    );
    h.begin(track);
    h.activate();
    h.observe(historyState(0));
    h.observe(historyState(100));
    await waitHistory(h);
    expect(h.failure, isNotNull);
    expect((await services.collection.watchHistory().first).single.id, 'old');
    await database.customStatement('DROP TRIGGER history_failure');
    await h.retry(h.failure!);
    final saved = (await services.collection.watchHistory().first).single;
    expect(saved.id, 'retry');
    expect(saved.startedAt, contentEpoch.add(const Duration(milliseconds: 1)));
    await h.close();
    await services.dispose();
  });

  for (final stage in ['read', 'write']) {
    test(
      'root close drains actual SQLite history $stage before closing shared storage',
      () async {
        final probe = SearchQueryProbe();
        final services = await DatabaseAppDataServices.open(
          AppDatabase(NativeDatabase.memory().interceptWith(probe)),
        );
        final track = detailTrack('actual');
        await services.library.upsertTracks([track]);
        await services.collection.saveQueue(
          systemQueue([track.ref], current: 'q-0'),
        );
        final engine = FakeAudioEngine();
        final graph = DependencyGraph(
          dataServices: services,
          audioEngine: engine,
          playbackSourceResolver: FakePlaybackSourceResolver(),
        );
        await graph.initialize();
        await graph.playback.play();
        final entered = Completer<void>(), gate = Completer<void>();
        addTearDown(() {
          if (!gate.isCompleted) gate.complete();
        });
        if (stage == 'read') {
          probe.afterSelect = () async {
            if (probe.selects.last.sql.contains('play_history') &&
                !entered.isCompleted) {
              entered.complete();
              await gate.future;
            }
          };
        } else {
          probe.beforeInsert = () async {
            if (!entered.isCompleted) {
              entered.complete();
              await gate.future;
            }
          };
        }
        engine.events.add(historyState(100));
        await entered.future.timeout(const Duration(seconds: 5));
        expect(graph.playback.state.phase, PlaybackPhase.playing);
        var closed = false;
        final closing = graph.close().then((_) => closed = true);
        await contentTick();
        expect(closed, isFalse);
        expect(probe.closeCount, 0);
        gate.complete();
        await closing;
        expect(probe.closeCount, 1);
        expect(graph.playback.history.busy, isFalse);
        expect(engine.calls.where((e) => e == 'play').length, 1);
      },
    );
  }
}
