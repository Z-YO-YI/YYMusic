import 'dart:async';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/database_app_data_services.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/data/database/app_database.dart';
import 'package:yymusic/domain/models/track.dart';

import '../support/catalog_detail_probe.dart';
import '../support/playlist_content_probe.dart';
import 'system_playlist_repository_test.dart' show systemHistory, systemQueue;

void main() {
  test('real SQLite removes only the complete favorite reference and clearing preserves library/favorites/queue', () async {
    final services = await DatabaseAppDataServices.open(
      AppDatabase(NativeDatabase.memory()),
    );
    final tracks = [
      detailTrack('same', source: 's', type: MusicSourceType.local),
      detailTrack('same', source: 's', type: MusicSourceType.rest),
      detailTrack('same', source: 'other', type: MusicSourceType.local),
    ];
    final graph = DependencyGraph(dataServices: services);
    addTearDown(graph.close);
    await services.library.upsertTracks(tracks);
    for (var i = 0; i < tracks.length; i++) {
      await services.collection.setFavorite(tracks[i].ref, favorite: true);
      await services.collection.recordHistory(
        systemHistory('h-$i', tracks[i].ref, contentEpoch),
      );
    }
    await services.collection.saveQueue(
      systemQueue(tracks.map((t) => t.ref).toList(), current: 'q-1'),
    );
    await graph.initialize();
    final queue = await services.collection.loadQueue();
    await graph.systemPlaylists.writer.removeFavorite(tracks[1].ref);
    expect(
      (await services.collection.watchFavorites().first)
          .map((e) => e.track)
          .toSet(),
      {tracks[0].ref, tracks[2].ref},
    );
    await graph.systemPlaylists.writer.clearHistory();
    expect(await services.collection.watchHistory().first, isEmpty);
    expect(await services.collection.watchFavorites().first, hasLength(2));
    final savedQueue = await services.collection.loadQueue();
    expect(savedQueue.currentEntryId, queue.currentEntryId);
    expect(
      savedQueue.entries.map((e) => (e.id, e.track)),
      queue.entries.map((e) => (e.id, e.track)),
    );
    for (final track in tracks) {
      expect(await services.library.getTrack(track.ref), isNotNull);
    }
    expect(await services.collection.watchPlaylists().first, isEmpty);
    expect(graph.systemPlaylists.writer.failure, isNull);
  });

  for (final clear in [false, true]) {
    test(
      'real SQLite ${clear ? 'history' : 'favorite'} delete failure rolls back and explicit retry succeeds',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        final services = await DatabaseAppDataServices.open(db);
        final graph = DependencyGraph(dataServices: services);
        addTearDown(graph.close);
        final track = detailTrack('failure');
        await services.library.upsertTracks([track]);
        await services.collection.setFavorite(track.ref, favorite: true);
        await services.collection.recordHistory(
          systemHistory('h', track.ref, contentEpoch),
        );
        await graph.initialize();
        await db.customStatement(
          "CREATE TRIGGER management_failure BEFORE DELETE ON ${clear ? 'play_history' : 'favorites'} BEGIN SELECT RAISE(ABORT, 'private-marker'); END",
        );
        final writer = graph.systemPlaylists.writer;
        Future<void> command() =>
            clear ? writer.clearHistory() : writer.removeFavorite(track.ref);
        await command();
        expect(writer.failure, isNotNull);
        expect(writer.failure!.message, isNot(contains('private-marker')));
        expect(await services.collection.watchFavorites().first, hasLength(1));
        expect(await services.collection.watchHistory().first, hasLength(1));
        await db.customStatement('DROP TRIGGER management_failure');
        await command();
        expect(writer.failure, isNull);
        expect(
          await services.collection.watchFavorites().first,
          hasLength(clear ? 1 : 0),
        );
        expect(
          await services.collection.watchHistory().first,
          hasLength(clear ? 0 : 1),
        );
        expect(await services.library.getTrack(track.ref), isNotNull);
      },
    );

    test(
      'root keeps actual SQLite open until accepted ${clear ? 'history' : 'favorite'} deletion drains',
      () async {
        final probe = _DeleteProbe();
        addTearDown(() {
          if (!probe.gate.isCompleted) probe.gate.complete();
        });
        final services = await DatabaseAppDataServices.open(
          AppDatabase(NativeDatabase.memory().interceptWith(probe)),
        );
        final graph = DependencyGraph(dataServices: services);
        addTearDown(graph.close);
        final track = detailTrack('drain');
        await services.collection.setFavorite(track.ref, favorite: true);
        await services.collection.recordHistory(
          systemHistory('h', track.ref, contentEpoch),
        );
        await graph.initialize();
        probe.enabled = true;
        final writer = graph.systemPlaylists.writer;
        final command = clear
            ? writer.clearHistory()
            : writer.removeFavorite(track.ref);
        await probe.entered.future.timeout(const Duration(seconds: 5));
        var closed = false;
        final closing = graph.close().then((_) => closed = true);
        await contentTick();
        expect(closed, isFalse);
        expect(probe.closeCount, 0);
        probe.gate.complete();
        await command;
        await closing;
        expect(probe.closeCount, 1);
        expect(writer.failure, isNull);
      },
    );
  }
}

final class _DeleteProbe extends QueryInterceptor {
  final entered = Completer<void>(), gate = Completer<void>();
  bool enabled = false;
  int closeCount = 0;
  @override
  Future<int> runDelete(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) async {
    if (enabled && !entered.isCompleted) {
      entered.complete();
      await gate.future;
    }
    return executor.runDelete(statement, args);
  }

  @override
  Future<void> close(QueryExecutor executor) async {
    closeCount++;
    await executor.close();
  }
}
