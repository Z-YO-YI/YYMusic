import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/data/database/app_database.dart';
import 'package:yymusic/data/repositories/drift_library_repository.dart';
import 'package:yymusic/data/repositories/drift_music_source_repository.dart';
import 'package:yymusic/domain/models/catalog_search.dart';
import 'package:yymusic/domain/models/domain_failure.dart';
import 'package:yymusic/domain/models/music_source.dart';
import 'package:yymusic/domain/models/pagination.dart';
import 'package:yymusic/domain/models/track.dart';
import 'package:yymusic/domain/repositories/catalog_search_repository.dart';

import '../support/search_query_probe.dart';

void main() {
  late AppDatabase db;
  late DriftLibraryRepository library;
  late SearchQueryProbe probe;
  setUp(() async {
    probe = SearchQueryProbe();
    db = AppDatabase(NativeDatabase.memory().interceptWith(probe));
    library = DriftLibraryRepository(db);
    await library.initialize();
    probe.selects.clear();
  });
  tearDown(() async {
    await library.dispose();
    await db.close();
  });

  test('query validation and diagnostics do not echo private input', () {
    final query = CatalogQuery('  私密 Quiet  ');
    expect(query.text, '私密 Quiet');
    expect(query.toString(), isNot(contains('私密')));
    for (final text in ['private\u0000query', 'private\nquery', 'x' * 2049]) {
      expect(
        () => CatalogQuery(text),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.toString(),
            'redacted',
            isNot(contains(text)),
          ),
        ),
      );
    }
    expect(CatalogQuery('x' * 2048).text.length, 2048);
    expect(() => CatalogQuery('x', sourceId: ' invalid '), throwsArgumentError);
    expect(foldSearchText('ÄΣQuiet夜'), 'ÄΣquiet夜');
    expect(() => PageRequest(limit: 201), throwsArgumentError);
  });

  test(
    'blank and pre-cancelled queries perform no SQL for every kind',
    () async {
      final CatalogSearchRepository repository = library;
      final cancelled = SearchCancellation()..cancel();
      for (final search in [
        repository.searchTracks,
        repository.searchAlbums,
        repository.searchArtists,
      ]) {
        final empty = await search(CatalogQuery('   '), PageRequest());
        expect(empty.items, isEmpty);
        expect(empty.hasMore, isFalse);
        expect(
          () => search(
            CatalogQuery('private'),
            PageRequest(),
            cancellation: cancelled,
          ),
          throwsA(isA<SearchCancelled>()),
        );
      }
      expect(probe.selects, isEmpty);
    },
  );

  test('literal Chinese ASCII and special characters match metadata, never private fields', () async {
    await library.upsertTracks([
      _track('one', title: '夜雨 Quiet 100%_single', artists: ['林', 'River']),
      _track('two', title: "D'Angelo"),
      _track('three', title: 'Álbum'),
    ]);
    for (final text in ['夜雨', 'qUIET', '100%_', 'River', '专辑 one']) {
      expect(
        (await library.searchTracks(
          CatalogQuery(text),
          PageRequest(),
        )).items.single.id,
        'one',
      );
    }
    expect(
      (await library.searchTracks(
        CatalogQuery("D'Angelo"),
        PageRequest(),
      )).items.single.id,
      'two',
    );
    for (final text in [
      "' OR 1=1 --",
      'fixture-path-marker',
      'private-metadata-marker',
      'álbum',
    ]) {
      expect(
        (await library.searchTracks(CatalogQuery(text), PageRequest())).items,
        isEmpty,
      );
    }
    final statement = probe.selects.last;
    expect(statement.sql, isNot(contains('álbum')));
    expect(statement.args.first, 'álbum');
    expect((await db.select(db.searchHistoryRecords).get()), isEmpty);
  });

  test(
    'public source name matches without reading endpoints or credentials',
    () async {
      final sources = DriftMusicSourceRepository(db);
      addTearDown(sources.dispose);
      await sources.saveSource(
        MusicSourceConfig(
          id: 'remote',
          name: '客厅来源',
          type: MusicSourceType.rest,
          baseUrl: Uri.parse('https://endpoint-marker.invalid'),
          authType: MusicSourceAuthType.none,
          enabled: false,
          status: MusicSourceStatus.unauthorized,
        ),
      );
      await library.upsertTracks([
        _track('remote', source: 'remote', local: false),
      ]);
      final tracks = await library.searchTracks(
        CatalogQuery('客厅'),
        PageRequest(),
      );
      expect(tracks.items.single.sourceId, 'remote');
      expect(
        (await library.searchAlbums(
          CatalogQuery('客厅'),
          PageRequest(),
        )).items.length,
        1,
      );
      expect(
        (await library.searchArtists(
          CatalogQuery('客厅'),
          PageRequest(),
        )).items.length,
        1,
      );
      expect(
        (await library.searchTracks(
          CatalogQuery('endpoint-marker'),
          PageRequest(),
        )).items,
        isEmpty,
      );
      await sources.deleteSource('remote');
      expect(
        (await library.searchTracks(
          CatalogQuery('Shared'),
          PageRequest(),
        )).items.single.id,
        'remote',
      );
      expect(
        (await library.searchTracks(CatalogQuery('客厅'), PageRequest())).items,
        isEmpty,
      );
    },
  );

  test(
    'full track identity is preserved with stable pages and source filters',
    () async {
      final items = [
        _track('b', source: 'b'),
        _track('a', source: 'b'),
        _track('a', source: 'a', local: false),
        _track('a', source: 'a'),
      ];
      await library.upsertTracks(items);
      final first = await library.searchTracks(
        CatalogQuery('Shared'),
        PageRequest(limit: 2),
      );
      final second = await library.searchTracks(
        CatalogQuery('Shared'),
        PageRequest(limit: 2, offset: 2),
      );
      expect(first.items.map((t) => t.ref), [items[3].ref, items[1].ref]);
      expect(second.items.map((t) => t.ref), [items[0].ref, items[2].ref]);
      expect(first.hasMore, isTrue);
      expect(second.hasMore, isFalse);
      expect(
        (await library.searchTracks(
          CatalogQuery('Shared'),
          PageRequest(offset: 4),
        )).items,
        isEmpty,
      );
      expect(
        (await library.searchTracks(
          CatalogQuery(
            'Shared',
            sourceType: MusicSourceType.rest,
            sourceId: 'a',
          ),
          PageRequest(),
        )).items.single.ref,
        items[2].ref,
      );
      expect(() => first.items.clear(), throwsUnsupportedError);
      await library.setAvailability(
        items[3].ref,
        TrackAvailability.localMissing,
      );
      expect(
        (await library.searchTracks(
          CatalogQuery(
            'Shared',
            sourceType: MusicSourceType.local,
            sourceId: 'a',
          ),
          PageRequest(),
        )).items.single.availability,
        TrackAvailability.localMissing,
      );
    },
  );

  test('album and artist joins deduplicate while keeping credits and source identity', () async {
    await library.upsertTracks([
      _track(
        'a',
        source: 'local',
        albumId: 'same',
        artists: ['Artist Match', 'Other Match'],
      ),
      _track(
        'b',
        source: 'local',
        albumId: 'same',
        artists: ['Artist Match', 'Other Match'],
      ),
      _track(
        'a',
        source: 'remote',
        local: false,
        albumId: 'same',
        artists: ['Artist Match'],
      ),
    ]);
    final albums = await library.searchAlbums(
      CatalogQuery('Match'),
      PageRequest(limit: 1),
    );
    expect(albums.items.single.sourceId, 'local');
    expect(albums.items.single.trackCount, 2);
    expect(albums.items.single.artists.map((a) => a.name), [
      'Artist Match',
      'Other Match',
    ]);
    expect(albums.hasMore, isTrue);
    final next = await library.searchAlbums(
      CatalogQuery('Match'),
      PageRequest(limit: 1, offset: 1),
    );
    expect(next.items.single.sourceId, 'remote');
    expect(next.hasMore, isFalse);
    expect(
      (await library.searchAlbums(
        CatalogQuery('Match', sourceType: MusicSourceType.rest),
        PageRequest(),
      )).items.single.sourceId,
      'remote',
    );
    final artists = await library.searchArtists(
      CatalogQuery('Match'),
      PageRequest(),
    );
    expect(artists.items.length, 3);
    expect(artists.items.first.trackCount, 2);
    expect(
      (await library.searchArtists(
        CatalogQuery(
          'Match',
          sourceType: MusicSourceType.rest,
          sourceId: 'remote',
        ),
        PageRequest(),
      )).items.single.name,
      'Artist Match',
    );
    final last = await library.searchArtists(
      CatalogQuery('Match'),
      PageRequest(limit: 1, offset: 2),
    );
    expect(last.items.single.name, 'Other Match');
    expect(last.hasMore, isFalse);
    expect(
      (await library.searchAlbums(
        CatalogQuery('Match'),
        PageRequest(offset: 2),
      )).items,
      isEmpty,
    );
  });

  test(
    '450-track page uses one read statement without a write transaction',
    () async {
      await library.upsertTracks([
        for (var i = 0; i < 450; i++)
          _track('id-${i.toString().padLeft(3, '0')}'),
      ]);
      probe.selects.clear();
      probe.transactionCount = 0;
      final result = await library.searchTracks(
        CatalogQuery('Shared'),
        PageRequest(offset: 200, limit: 200),
      );
      expect(result.items.length, 200);
      expect(result.items.first.id, 'id-200');
      expect(result.items.last.id, 'id-399');
      expect(result.hasMore, isTrue);
      expect(probe.selects.length, 1);
      expect(probe.transactionCount, 0);
      expect(probe.selects.first.rows, 201);
      expect(probe.selects.first.args, ['Shared', 201, 200]);
    },
  );

  test(
    'pagination limits entities before expanding multiple artist credits',
    () async {
      await library.upsertTracks([
        for (final id in ['a', 'b', 'c'])
          _track(id, artists: const ['First Artist', 'Second Artist']),
      ]);
      probe.selects.clear();
      probe.transactionCount = 0;
      final first = await library.searchTracks(
        CatalogQuery('Artist'),
        PageRequest(limit: 1),
      );
      expect(first.items.single.id, 'a');
      expect(first.items.single.artists, ['First Artist', 'Second Artist']);
      expect(first.hasMore, isTrue);
      expect(probe.selects.single.rows, 4); // Two entities, two credits each.
      for (final search in [library.searchAlbums, library.searchArtists]) {
        probe.selects.clear();
        await search(CatalogQuery('Artist'), PageRequest(limit: 1));
        expect(probe.selects.length, 1);
      }
      expect(probe.transactionCount, 0);
      final last = await library.searchTracks(
        CatalogQuery('Artist'),
        PageRequest(limit: 1, offset: 2),
      );
      expect(last.items.single.id, 'c');
      expect(last.items.single.artists.length, 2);
      expect(last.hasMore, isFalse);
    },
  );

  test(
    'cancellation after the single read never delivers a late page',
    () async {
      await library.upsertTracks([_track('one')]);
      for (final search in [
        library.searchTracks,
        library.searchAlbums,
        library.searchArtists,
      ]) {
        final cancellation = SearchCancellation();
        probe.selects.clear();
        probe.afterSelect = () async => cancellation.cancel();
        await expectLater(
          search(
            CatalogQuery('Artist'),
            PageRequest(),
            cancellation: cancellation,
          ),
          throwsA(isA<SearchCancelled>()),
        );
        expect(probe.selects.length, 1);
        probe.afterSelect = null;
      }
      expect(
        (await library.searchTracks(
          CatalogQuery('Shared'),
          PageRequest(),
        )).items.single.id,
        'one',
      );
    },
  );

  test('uninitialized disposed and corrupted catalog fail without exposing queries', () async {
    final unopened = DriftLibraryRepository(db);
    expect(
      () => unopened.searchTracks(CatalogQuery('private'), PageRequest()),
      throwsStateError,
    );
    await unopened.dispose();
    await library.upsertTracks([_track('one')]);
    await db.customStatement(
      "UPDATE tracks SET metadata_json='private-corrupt' WHERE track_id='one'",
    );
    await expectLater(
      library.searchTracks(CatalogQuery('Shared'), PageRequest()),
      throwsA(
        isA<DomainFailure>().having(
          (e) => e.toString(),
          'safe',
          isNot(contains('private-corrupt')),
        ),
      ),
    );
    await library.dispose();
    for (final search in [
      library.searchTracks,
      library.searchAlbums,
      library.searchArtists,
    ]) {
      expect(
        () => search(CatalogQuery('Shared'), PageRequest()),
        throwsStateError,
      );
    }
  });

  test(
    'page and credits use one SQLite snapshot across a concurrent writer',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'yymusic-search-snapshot-',
      );
      final file = File('${directory.path}/catalog.sqlite');
      final readerProbe = SearchQueryProbe();
      final readerDb = AppDatabase(
        NativeDatabase(file).interceptWith(readerProbe),
      );
      final writerDb = AppDatabase(NativeDatabase(file));
      final reader = DriftLibraryRepository(readerDb);
      final writer = DriftLibraryRepository(writerDb);
      try {
        await reader.initialize();
        await readerDb.customSelect('PRAGMA journal_mode=WAL').get();
        await writer.initialize();
        await writer.upsertTracks([
          _track('one', artists: ['Original Artist']),
        ]);
        readerProbe.selects.clear();
        readerProbe.afterSelect = () async {
          if (readerProbe.selects.length == 1) {
            await writer.upsertTracks([
              _track('one', title: 'Renamed', artists: ['New Artist']),
            ]);
          }
        };
        final result = await reader.searchTracks(
          CatalogQuery('Shared'),
          PageRequest(),
        );
        expect(result.items.single.title, 'Shared');
        expect(result.items.single.artists, ['Original Artist']);
        readerProbe.afterSelect = null;
        expect((await reader.getTrack(result.items.single.ref))!.artists, [
          'New Artist',
        ]);
      } finally {
        await reader.dispose();
        await writer.dispose();
        await readerDb.close();
        await writerDb.close();
        await directory.delete(recursive: true);
      }
    },
  );
}

Track _track(
  String id, {
  String title = 'Shared',
  String source = 'local',
  bool local = true,
  List<String> artists = const ['Artist'],
  String? albumId,
}) => Track(
  id: id,
  sourceId: source,
  sourceType: local ? MusicSourceType.local : MusicSourceType.rest,
  title: title,
  artists: artists,
  duration: const Duration(seconds: 180),
  albumId: albumId ?? id,
  albumTitle: '专辑 ${albumId ?? id}',
  localPath: local ? '/fixture-path-marker/$id.wav' : null,
  metadata: const {'fixture': 'private-metadata-marker'},
);
