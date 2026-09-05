import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/database_app_data_services.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/data/database/app_database.dart';
import 'package:yymusic/data/repositories/library_row_mapper.dart';
import 'package:yymusic/domain/models/catalog_reference.dart';
import 'package:yymusic/domain/models/load_state.dart';
import 'package:yymusic/domain/models/track.dart';
import 'package:yymusic/features/catalog_detail/common/catalog_detail_state.dart';

import '../support/catalog_detail_probe.dart';
import '../support/search_query_probe.dart';

void main() {
  late SearchQueryProbe probe;
  late AppDatabase database;
  late DatabaseAppDataServices services;
  late DependencyGraph graph;
  setUp(() async {
    probe = SearchQueryProbe();
    database = AppDatabase(NativeDatabase.memory().interceptWith(probe));
    services = await DatabaseAppDataServices.open(database);
    graph = DependencyGraph(dataServices: services);
  });
  tearDown(() async => graph.close());

  test('root sessions use real source-scoped SQLite pages, including unavailable references', () async {
    final tracks = [
      for (var i = 0; i < 45; i++) detailTrack(i.toString().padLeft(3, '0')),
      detailTrack(
        '000',
        type: MusicSourceType.rest,
        availability: TrackAvailability.sourceRemoved,
      ),
      detailTrack('000', source: 'other-source'),
      detailTrack('other-album', album: 'other-album'),
    ];
    await services.library.upsertTracks(tracks);
    probe.selects.clear();
    probe.transactionCount = 0;
    expect(graph.catalogDetails.repository, same(graph.catalogBrowse));
    expect(graph.catalogBrowse, same(graph.library));
    final controller = graph.catalogDetails.open(
      AlbumDetailTarget(AlbumRef(sourceId: 'source-a', albumId: 'album-a')),
    );
    await controller.start();
    expect(controller.summary.phase, LoadPhase.data);
    expect(controller.summary.data!.trackCount, 46);
    expect(controller.tracks.items.length, 20);
    expect(probe.selects.length, 3); // Summary, tracks, public source lookup.
    expect(probe.transactionCount, 0);
    final firstRows = controller.tracks;
    await controller.loadMoreTracks();
    await controller.loadMoreTracks();
    expect(controller.tracks.items.length, 46);
    expect(firstRows.items.length, 20);
    expect(
      controller.tracks.items.map((track) => track.ref).toSet().length,
      46,
    );
    expect(
      controller.tracks.items.every(
        (track) => track.sourceId == 'source-a' && track.albumId == 'album-a',
      ),
      isTrue,
    );
    expect(
      controller.tracks.items
          .where(
            (track) => track.availability == TrackAvailability.sourceRemoved,
          )
          .length,
      1,
    );
    expect(controller.tracks.hasMore, isFalse);
    expect(probe.selects.length, 5);
    expect(
      probe.selects
          .where((read) => read.sql.contains('FROM tracks item'))
          .map((read) => read.args),
      [
        ['source-a', 'album-a', 21, 0],
        ['source-a', 'album-a', 21, 20],
        ['source-a', 'album-a', 21, 40],
      ],
    );
    expect((await services.collection.loadQueue()).entries, isEmpty);
    expect(await services.collection.watchFavorites().first, isEmpty);
    expect(await services.collection.watchHistory().first, isEmpty);
    expect(await services.searchHistory.listHistory(), isEmpty);
  });

  test(
    'artist compilation uses track credits even when album artists differ',
    () async {
      await services.library.upsertTracks([
        detailTrack('one'),
        detailTrack('two', album: 'second-album'),
        detailTrack('one', source: 'other-source'),
      ]);
      // Model a compilation album artist independently of its participating tracks.
      await database.customStatement(
        'INSERT INTO artists (source_id, artist_id, name, album_count, track_count) VALUES (?, ?, ?, ?, ?)',
        ['source-a', 'compilation-credit', 'Various Artists', 1, 0],
      );
      await database.customStatement(
        'UPDATE album_artists SET artist_id = ? WHERE album_source_id = ? AND album_id = ?',
        ['compilation-credit', 'source-a', 'album-a'],
      );
      final reference = ArtistRef(
        sourceId: 'source-a',
        artistId: const LibraryRowMapper().artistId(
          sourceId: 'source-a',
          name: '测试曲目艺人',
        ),
      );
      final controller = graph.catalogDetails.open(
        ArtistDetailTarget(reference),
      );
      probe.selects.clear();
      probe.transactionCount = 0;
      await controller.start();
      expect(controller.summary.data, isA<ArtistDetailSummary>());
      expect(controller.tracks.items.map((track) => track.id).toSet(), {
        'one',
        'two',
      });
      expect(controller.albums.phase, LoadPhase.data);
      expect(controller.albums.items.map((album) => album.id).toSet(), {
        'album-a',
        'second-album',
      });
      expect(
        controller.albums.items
            .firstWhere((album) => album.id == 'album-a')
            .artists
            .single
            .id,
        'compilation-credit',
      );
      expect(probe.selects.length, 4); // Plus one independent source lookup.
      expect(probe.transactionCount, 0);
    },
  );

  test('real missing entity never triggers child reads and malformed storage is not empty', () async {
    final controller = graph.catalogDetails.open(
      AlbumDetailTarget(AlbumRef(sourceId: 'source-a', albumId: 'album-a')),
    );
    probe.selects.clear();
    await controller.start();
    expect(controller.summary.phase, LoadPhase.empty);
    expect(
      probe.selects.length,
      2,
    ); // No child query; public source lookup remains.
    await services.library.upsertTracks([detailTrack('one')]);
    await database.customStatement('DELETE FROM album_artists');
    probe.selects.clear();
    await controller.refresh();
    expect(controller.summary.phase, LoadPhase.error);
    expect(controller.tracks.phase, LoadPhase.idle);
    expect(probe.selects.length, 2);
  });

  test(
    'root storage remains open until a cancelled real SQLite read drains',
    () async {
      await services.library.upsertTracks([detailTrack('one')]);
      final gate = Completer<void>();
      final entered = Completer<void>();
      probe.afterSelect = () async {
        if (!entered.isCompleted) {
          entered.complete();
          await gate.future;
        }
      };
      final controller = graph.catalogDetails.open(
        AlbumDetailTarget(AlbumRef(sourceId: 'source-a', albumId: 'album-a')),
      );
      final load = controller.start();
      await entered.future.timeout(const Duration(seconds: 5));
      final localClose = controller.close();
      final rootClose = graph.close();
      await Future<void>.delayed(Duration.zero);
      expect(probe.closeCount, 0);
      expect(graph.catalogDetails.retainedSessionCount, 1);
      gate.complete();
      await load;
      await localClose;
      await rootClose;
      expect(probe.closeCount, 1);
      expect(graph.catalogDetails.retainedSessionCount, 0);
      await graph.close();
      expect(probe.closeCount, 1);
    },
  );
}
