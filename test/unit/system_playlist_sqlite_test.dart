import 'dart:async';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/database_app_data_services.dart';
import 'package:yymusic/data/database/app_database.dart';
import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/domain/models/domain_failure.dart';
import 'package:yymusic/domain/models/pagination.dart';
import 'package:yymusic/domain/models/track.dart';

import '../support/catalog_detail_probe.dart';
import '../support/playlist_content_probe.dart';
import '../support/search_query_probe.dart';
import 'playlist_metadata_sqlite_test.dart' show playlistFailure;
import 'system_playlist_repository_test.dart' show systemQueue;

void main() {
  late AppDatabase database;
  late DatabaseAppDataServices services;
  late SearchQueryProbe probe;
  setUp(() async {
    probe = SearchQueryProbe();
    database = AppDatabase(NativeDatabase.memory().interceptWith(probe));
    services = await DatabaseAppDataServices.open(database);
  });
  tearDown(() => services.dispose());
  final multi = Track(
    id: 'same',
    sourceId: 's',
    sourceType: MusicSourceType.rest,
    title: '多人歌曲',
    artists: ['甲', '乙', '丙'],
    duration: const Duration(minutes: 3),
  );

  test('1003 queue entries page before credit fan-out with one statement and no write', () async {
    await services.library.upsertTracks([multi]);
    await services.collection.saveQueue(
      systemQueue(List.filled(1003, multi.ref), current: 'q-1002'),
    );
    probe.selects.clear();
    final transactions = probe.transactionCount;
    final page = await services.collection.readSystemPlaylistContent(
      SystemPlaylistType.queue,
      PageRequest(offset: 1000, limit: 2),
    );
    expect(page.totalCount, 1003);
    expect(page.entries.map((e) => e.entryId), ['q-1000', 'q-1001']);
    expect(page.entries.map((e) => e.track!.artists.join(',')), [
      '甲,乙,丙',
      '甲,乙,丙',
    ]);
    expect(page.currentQueueEntryId, 'q-1002');
    expect(probe.selects.single.args, [2, 1000]);
    expect(probe.selects.single.rows, 6);
    expect(probe.transactionCount, transactions);
    probe.selects.clear();
    final last = await services.collection.readSystemPlaylistContent(
      SystemPlaylistType.queue,
      PageRequest(offset: 1002, limit: 200),
    );
    expect(last.entries.single.entryId, 'q-1002');
    expect(last.hasMore, isFalse);
    expect(probe.selects.single.rows, 3);
  });
  test('1003 favorites use stable timestamp ties and complete source ordering before a bounded join', () async {
    final tracks = [
      for (var i = 0; i < 1003; i++)
        Track(
          id: '$i'.padLeft(4, '0'),
          sourceId: 's',
          sourceType: MusicSourceType.rest,
          title: 'T$i',
          artists: ['甲', '乙'],
          duration: const Duration(seconds: 1),
        ),
    ];
    await services.library.upsertTracks(tracks);
    await database.batch(
      (batch) => batch.insertAll(database.favoriteRecords, [
        for (final track in tracks)
          FavoriteRecordsCompanion.insert(
            trackSourceType: track.sourceType.name,
            trackSourceId: track.sourceId,
            trackId: track.id,
            addedAtMs: contentEpoch.millisecondsSinceEpoch,
          ),
      ]),
    );
    probe.selects.clear();
    final page = await services.collection.readSystemPlaylistContent(
      SystemPlaylistType.favorites,
      PageRequest(offset: 998, limit: 3),
    );
    expect(page.totalCount, 1003);
    expect(page.entries.map((e) => e.reference.trackId), [
      '0998',
      '0999',
      '1000',
    ]);
    expect(page.entries.every((e) => e.entryId == null), isTrue);
    expect(probe.selects.single.rows, 6);
    expect(probe.selects.single.args, [3, 998]);
    expect(await services.collection.watchPlaylists().first, isEmpty);
  });
  test('history snapshot stays at 20 even with oversized legacy storage and uses ID ties', () async {
    await services.library.upsertTracks([multi]);
    await database.batch(
      (batch) => batch.insertAll(database.playHistoryRecords, [
        for (var i = 24; i >= 0; i--)
          PlayHistoryRecordsCompanion.insert(
            historyId: 'h-${'$i'.padLeft(2, '0')}',
            trackSourceType: multi.sourceType.name,
            trackSourceId: multi.sourceId,
            trackId: multi.id,
            startedAtMs: contentEpoch.millisecondsSinceEpoch,
            lastPositionMs: 0,
          ),
      ]),
    );
    probe.selects.clear();
    final data = await services.collection.readSystemPlaylistContent(
      SystemPlaylistType.recent,
      PageRequest(offset: 18),
    );
    expect(data.totalCount, 20);
    expect(data.entries.map((e) => e.entryId), ['h-18', 'h-19']);
    expect(probe.selects.single.rows, 6);
    expect(data.hasMore, isFalse);
  });
  test('metadata outside the requested page is not decoded; bad visible data fails safely', () async {
    final a = detailTrack('a'), b = detailTrack('b');
    await services.library.upsertTracks([a, b]);
    await services.collection.saveQueue(systemQueue([a.ref, b.ref]));
    await database.customStatement(
      "UPDATE tracks SET metadata_json = 'private-marker' WHERE track_id = 'b'",
    );
    expect(
      (await services.collection.readSystemPlaylistContent(
        SystemPlaylistType.queue,
        PageRequest(limit: 1),
      )).entries.single.track!.ref,
      a.ref,
    );
    await expectLater(
      services.collection.readSystemPlaylistContent(
        SystemPlaylistType.queue,
        PageRequest(offset: 1),
      ),
      throwsA(playlistFailure(DomainFailureCode.databaseCorrupted)),
    );
  });
  for (final corrupt in [
    'position',
    'negative-position',
    'missing-state',
    'dangling-current',
  ]) {
    test(
      '$corrupt anywhere in queue fails even when outside requested page',
      () async {
        await services.collection.saveQueue(
          systemQueue([multi.ref, multi.ref], current: 'q-0'),
        );
        if (corrupt == 'position') {
          await database.customStatement(
            "UPDATE queue_entries SET position = 5 WHERE entry_id = 'q-1'",
          );
        }
        if (corrupt == 'negative-position') {
          await database.customStatement(
            'PRAGMA ignore_check_constraints = ON',
          );
          await database.customStatement(
            "UPDATE queue_entries SET position = -1 WHERE entry_id = 'q-0'",
          );
          await database.customStatement(
            'PRAGMA ignore_check_constraints = OFF',
          );
        }
        if (corrupt == 'missing-state') {
          await database.customStatement('DELETE FROM queue_state');
        }
        if (corrupt == 'dangling-current') {
          // Corrupt only a test database, then restore FK enforcement.
          await database.customStatement('PRAGMA foreign_keys = OFF');
          await database.customStatement(
            "UPDATE queue_state SET current_entry_id = 'private-marker'",
          );
          await database.customStatement('PRAGMA foreign_keys = ON');
        }
        await expectLater(
          services.collection.readSystemPlaylistContent(
            SystemPlaylistType.queue,
            PageRequest(
              offset: corrupt == 'negative-position' ? 1 : 0,
              limit: 1,
            ),
          ),
          throwsA(playlistFailure(DomainFailureCode.databaseCorrupted)),
        );
        // Queue corruption must not hide unrelated favorite/history views.
        expect(
          (await services.collection.readSystemPlaylistContent(
            SystemPlaylistType.favorites,
            PageRequest(),
          )).totalCount,
          0,
        );
        expect(
          (await services.collection.readSystemPlaylistContent(
            SystemPlaylistType.recent,
            PageRequest(),
          )).totalCount,
          0,
        );
      },
    );
  }
  test('invalidation observes artist and queue-state changes without implicit queries or custom playlist events', () async {
    await services.library.upsertTracks([multi]);
    await services.collection.saveQueue(systemQueue([multi.ref]));
    final counts = {for (final type in SystemPlaylistType.values) type: 0};
    final subs = [
      for (final type in SystemPlaylistType.values)
        services.collection
            .watchSystemPlaylistChanges(type)
            .listen((_) => counts[type] = counts[type]! + 1),
    ];
    addTearDown(() async {
      for (final sub in subs) {
        await sub.cancel();
      }
    });
    probe.selects.clear();
    await contentTick();
    expect(probe.selects, isEmpty);
    await services.collection.createPlaylist(contentPlaylist('unrelated'));
    await contentTick();
    expect(counts.values, everyElement(0));
    probe.selects.clear();
    await (database.update(database.artistRecords)
          ..where((row) => row.name.equals('甲')))
        .write(const ArtistRecordsCompanion(name: Value('改名')));
    await contentTick();
    expect(counts.values, everyElement(greaterThan(0)));
    expect(probe.selects, isEmpty);
    for (final type in counts.keys) {
      counts[type] = 0;
    }
    await database
        .update(database.queueStateRecords)
        .write(const QueueStateRecordsCompanion(currentEntryId: Value('q-0')));
    await contentTick();
    expect(counts[SystemPlaylistType.queue], greaterThan(0));
    expect(counts[SystemPlaylistType.favorites], 0);
    expect(counts[SystemPlaylistType.recent], 0);
  });
  test('one captured snapshot cannot mix an accepted later mutation into its total', () async {
    await services.collection.setFavorite(multi.ref, favorite: true);
    final entered = Completer<void>(), gate = Completer<void>();
    addTearDown(() {
      if (!gate.isCompleted) gate.complete();
    });
    probe.afterSelect = () async {
      if (probe.selects.last.sql.contains('system_count') &&
          !entered.isCompleted) {
        entered.complete();
        await gate.future;
      }
    };
    final read = services.collection.readSystemPlaylistContent(
      SystemPlaylistType.favorites,
      PageRequest(),
    );
    await entered.future;
    final write = services.collection.setFavorite(
      detailTrack('later').ref,
      favorite: true,
    );
    gate.complete();
    final before = await read;
    await write;
    expect(before.totalCount, 1);
    expect(before.entries.single.reference, multi.ref);
    expect(
      (await services.collection.readSystemPlaylistContent(
        SystemPlaylistType.favorites,
        PageRequest(),
      )).totalCount,
      2,
    );
  });
  test('closed repositories refuse reads and subscriptions without accessing SQLite', () async {
    await services.dispose();
    probe.selects.clear();
    for (final type in SystemPlaylistType.values) {
      expect(
        () =>
            services.collection.readSystemPlaylistContent(type, PageRequest()),
        throwsStateError,
      );
      expect(
        () => services.collection.watchSystemPlaylistChanges(type),
        throwsStateError,
      );
    }
    expect(probe.selects, isEmpty);
  });
}
