import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/database_app_data_services.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/data/database/app_database.dart';
import 'package:yymusic/data/repositories/drift_library_repository.dart';
import 'package:yymusic/data/repositories/library_row_mapper.dart';
import 'package:yymusic/domain/models/catalog_browse.dart';
import 'package:yymusic/domain/models/catalog_reference.dart';
import 'package:yymusic/domain/models/catalog_search.dart';
import 'package:yymusic/domain/models/domain_failure.dart';
import 'package:yymusic/domain/models/pagination.dart';
import 'package:yymusic/domain/models/track.dart';
import 'package:yymusic/domain/repositories/catalog_browse_repository.dart';

import '../support/search_query_probe.dart';

void main() {
  late AppDatabase database;
  late DriftLibraryRepository library;
  late SearchQueryProbe probe;
  setUp(() async {
    probe = SearchQueryProbe();
    database = AppDatabase(NativeDatabase.memory().interceptWith(probe));
    library = DriftLibraryRepository(database);
    await library.initialize();
    probe.selects.clear();
  });
  tearDown(() async {
    await library.dispose();
    await database.close();
  });

  test('source-scoped references are distinct, validated and redacted', () {
    final a = AlbumRef(sourceId: 'source-a', albumId: 'same');
    final b = AlbumRef(sourceId: 'source-b', albumId: 'same');
    expect(a, AlbumRef(sourceId: 'source-a', albumId: 'same'));
    expect({a, b}.length, 2);
    final x = ArtistRef(sourceId: 'source-a', artistId: 'same');
    expect({x, ArtistRef(sourceId: 'source-b', artistId: 'same')}.length, 2);
    expect(x, ArtistRef(sourceId: 'source-a', artistId: 'same'));
    for (final invalid in [
      '',
      ' private-marker',
      'private-marker\n',
      'x' * 257,
    ]) {
      for (final create in <Object Function()>[
        () => AlbumRef(sourceId: invalid, albumId: 'a'),
        () => AlbumRef(sourceId: 'a', albumId: invalid),
        () => ArtistRef(sourceId: invalid, artistId: 'a'),
        () => ArtistRef(sourceId: 'a', artistId: invalid),
        () => CatalogFilter(sourceId: invalid),
      ]) {
        expect(
          create,
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.toString(),
              'safe',
              isNot(contains('private-marker')),
            ),
          ),
        );
      }
    }
    expect(a.toString(), isNot(contains('source-a')));
    expect(x.toString(), isNot(contains('source-a')));
  });

  test(
    'availability filters are immutable copies and empty means all states',
    () {
      final states = [TrackAvailability.localMissing];
      final filter = CatalogFilter(
        sourceId: 'private-marker',
        availability: states,
      );
      states.add(TrackAvailability.available);
      expect(filter.availability, {TrackAvailability.localMissing});
      expect(() => filter.availability.clear(), throwsUnsupportedError);
      expect(filter.isAll, isFalse);
      expect(const CatalogFilter.all().isAll, isTrue);
      expect(CatalogFilter().isAll, isTrue);
      expect(filter.toString(), isNot(contains('private-marker')));
    },
  );

  test('empty catalog and missing entities are real empty results, with zero writes', () async {
    final CatalogBrowseRepository repository = library;
    probe.transactionCount = 0;
    expect(
      (await repository.browseTracks(
        const CatalogTrackQuery(),
        PageRequest(),
      )).items,
      isEmpty,
    );
    expect(
      (await repository.browseAlbums(
        const CatalogAlbumQuery(),
        PageRequest(),
      )).items,
      isEmpty,
    );
    expect(
      (await repository.browseArtists(
        const CatalogArtistQuery(),
        PageRequest(),
      )).items,
      isEmpty,
    );
    expect(
      await repository.getAlbum(AlbumRef(sourceId: 'a', albumId: 'missing')),
      isNull,
    );
    expect(
      await repository.getArtist(ArtistRef(sourceId: 'a', artistId: 'missing')),
      isNull,
    );
    expect(probe.selects.length, 5);
    expect(probe.transactionCount, 0);
    expect(await database.searchHistoryRecords.count().getSingle(), 0);
  });

  test('all track sort modes support ascending descending and NULL-last dates/albums', () async {
    await library.upsertTracks([
      track(
        'a',
        title: 'beta',
        artists: ['Zulu', 'AAA'],
        album: 'alpha',
        seconds: 300,
      ),
      track(
        'b',
        title: 'Alpha',
        artists: ['beta'],
        album: 'Zeta',
        seconds: 100,
      ),
      track('c', title: 'Charlie', artists: ['Alpha'], seconds: 200),
    ]);
    await database.customStatement(
      "UPDATE tracks SET added_at_ms = CASE track_id WHEN 'a' THEN 30 WHEN 'b' THEN 10 ELSE NULL END",
    );
    for (final (sort, asc, desc) in [
      (CatalogTrackSort.title, ['b', 'a', 'c'], ['c', 'a', 'b']),
      (CatalogTrackSort.artist, ['c', 'b', 'a'], ['a', 'b', 'c']),
      (CatalogTrackSort.album, ['a', 'b', 'c'], ['b', 'a', 'c']),
      (CatalogTrackSort.duration, ['b', 'c', 'a'], ['a', 'c', 'b']),
      (CatalogTrackSort.addedAt, ['b', 'a', 'c'], ['a', 'b', 'c']),
    ]) {
      for (final (direction, expected) in [
        (CatalogDirection.ascending, asc),
        (CatalogDirection.descending, desc),
      ]) {
        probe.selects.clear();
        final result = await library.browseTracks(
          CatalogTrackQuery(sort: sort, direction: direction),
          PageRequest(),
        );
        expect(
          result.items.map((t) => t.id),
          expected,
          reason: '$sort $direction',
        );
        expect(probe.selects.length, 1);
        expect(result.items.firstWhere((t) => t.id == 'a').artists, [
          'Zulu',
          'AAA',
        ]);
      }
    }
  });

  test(
    'same-name track pages retain full identities and deterministic ties',
    () async {
      final tracks = [
        track('same', source: 'b'),
        track('same', source: 'a'),
        track('same', source: 'a', type: MusicSourceType.rest),
        track('z', source: 'a'),
      ];
      await library.upsertTracks(tracks);
      final expected = [
        tracks[1].ref,
        tracks[3].ref,
        tracks[0].ref,
        tracks[2].ref,
      ];
      for (final direction in CatalogDirection.values) {
        final actual = <TrackRef>[];
        for (var offset = 0; offset < 4; offset++) {
          final page = await library.browseTracks(
            CatalogTrackQuery(direction: direction),
            PageRequest(offset: offset, limit: 1),
          );
          actual.add(page.items.single.ref);
          expect(page.hasMore, offset < 3);
        }
        expect(actual, expected);
      }
      expect(
        (await library.browseTracks(
          const CatalogTrackQuery(),
          PageRequest(offset: 4),
        )).items,
        isEmpty,
      );
    },
  );

  test('source type ID and availability combine without requiring a live source config', () async {
    await library.upsertTracks([
      track('a'),
      track('b', availability: TrackAvailability.localMissing),
      track('c', source: 'b', availability: TrackAvailability.localMissing),
      track(
        'd',
        type: MusicSourceType.rest,
        availability: TrackAvailability.sourceDisabled,
      ),
      track(
        'e',
        type: MusicSourceType.rest,
        availability: TrackAvailability.sourceRemoved,
      ),
    ]);
    final missing = await library.browseTracks(
      CatalogTrackQuery(
        filter: CatalogFilter(
          sourceType: MusicSourceType.local,
          sourceId: 'a',
          availability: [TrackAvailability.localMissing],
        ),
      ),
      PageRequest(),
    );
    expect(missing.items.single.id, 'b');
    final unavailable = await library.browseTracks(
      CatalogTrackQuery(
        filter: CatalogFilter(
          sourceType: MusicSourceType.rest,
          availability: [
            TrackAvailability.sourceRemoved,
            TrackAvailability.sourceDisabled,
          ],
        ),
      ),
      PageRequest(),
    );
    expect(unavailable.items.map((t) => t.id), ['d', 'e']);
    expect(
      (await library.browseTracks(
        CatalogTrackQuery(filter: CatalogFilter(sourceId: 'missing')),
        PageRequest(),
      )).items,
      isEmpty,
    );
  });

  test(
    'all album sort modes preserve multi-artist details and catalog totals',
    () async {
      await library.upsertTracks([
        for (var i = 0; i < 2; i++)
          track('a$i', album: 'alpha', artists: ['Zulu', 'AAA']),
        for (var i = 0; i < 3; i++)
          track('b$i', album: 'Charlie', artists: ['beta']),
        track('c', album: 'Beta', artists: ['Alpha']),
      ]);
      await database.customStatement(
        "UPDATE albums SET year = CASE album_id WHEN 'alpha' THEN 2000 WHEN 'Charlie' THEN 2025 ELSE NULL END",
      );
      for (final (sort, asc, desc) in [
        (
          CatalogAlbumSort.title,
          ['alpha', 'Beta', 'Charlie'],
          ['Charlie', 'Beta', 'alpha'],
        ),
        (
          CatalogAlbumSort.artist,
          ['Beta', 'Charlie', 'alpha'],
          ['alpha', 'Charlie', 'Beta'],
        ),
        (
          CatalogAlbumSort.year,
          ['alpha', 'Charlie', 'Beta'],
          ['Charlie', 'alpha', 'Beta'],
        ),
        (
          CatalogAlbumSort.trackCount,
          ['Beta', 'alpha', 'Charlie'],
          ['Charlie', 'alpha', 'Beta'],
        ),
      ]) {
        for (final (direction, expected) in [
          (CatalogDirection.ascending, asc),
          (CatalogDirection.descending, desc),
        ]) {
          probe.selects.clear();
          final result = await library.browseAlbums(
            CatalogAlbumQuery(sort: sort, direction: direction),
            PageRequest(),
          );
          expect(
            result.items.map((a) => a.id),
            expected,
            reason: '$sort $direction',
          );
          expect(probe.selects.length, 1);
        }
      }
      final album = (await library.getAlbum(
        AlbumRef(sourceId: 'a', albumId: 'alpha'),
      ))!;
      expect(album.artists.map((a) => a.name), ['Zulu', 'AAA']);
      expect(album.trackCount, 2);
      expect(album.year, 2000);
      expect(album.ref, AlbumRef(sourceId: 'a', albumId: 'alpha'));
    },
  );

  test(
    'artist sorts use real aggregate counts and stable secondary names',
    () async {
      await library.upsertTracks([
        track('a', album: 'one', artists: ['Alpha']),
        track('b', album: 'two', artists: ['Alpha']),
        track('c', album: 'three', artists: ['BETA']),
        track('d', album: 'three', artists: ['BETA']),
        track('e', artists: ['Zulu']),
      ]);
      for (final (sort, asc, desc) in [
        (
          CatalogArtistSort.name,
          ['Alpha', 'BETA', 'Zulu'],
          ['Zulu', 'BETA', 'Alpha'],
        ),
        (
          CatalogArtistSort.albumCount,
          ['Zulu', 'BETA', 'Alpha'],
          ['Alpha', 'BETA', 'Zulu'],
        ),
        (
          CatalogArtistSort.trackCount,
          ['Zulu', 'Alpha', 'BETA'],
          ['Alpha', 'BETA', 'Zulu'],
        ),
      ]) {
        for (final (direction, expected) in [
          (CatalogDirection.ascending, asc),
          (CatalogDirection.descending, desc),
        ]) {
          final result = await library.browseArtists(
            CatalogArtistQuery(sort: sort, direction: direction),
            PageRequest(),
          );
          expect(
            result.items.map((a) => a.name),
            expected,
            reason: '$sort $direction',
          );
        }
      }
      final artist = (await library.getArtist(artistRef('Alpha')))!;
      expect(artist.albumCount, 2);
      expect(artist.trackCount, 2);
      expect(artist.ref, artistRef('Alpha'));
    },
  );

  test('album and artist filtering requires the same track to satisfy all conditions', () async {
    await library.upsertTracks([
      track(
        'a',
        album: 'shared',
        artists: ['Local'],
        availability: TrackAvailability.localMissing,
      ),
      track(
        'b',
        album: 'shared',
        artists: ['Remote'],
        type: MusicSourceType.rest,
      ),
      track('c', album: 'other', artists: ['Local']),
    ]);
    final online = CatalogFilter(
      sourceType: MusicSourceType.rest,
      availability: [TrackAvailability.available],
    );
    final noMatch = await library.browseAlbums(
      CatalogAlbumQuery(filter: online, artist: artistRef('Local')),
      PageRequest(),
    );
    expect(noMatch.items, isEmpty);
    final matched = await library.browseAlbums(
      CatalogAlbumQuery(filter: online, artist: artistRef('Remote')),
      PageRequest(),
    );
    expect(matched.items.single.id, 'shared');
    expect(
      matched.items.single.trackCount,
      2,
    ); // Full entity count, not filtered count.
    expect(
      (await library.browseArtists(
        CatalogArtistQuery(filter: online),
        PageRequest(),
      )).items.single.name,
      'Remote',
    );
    final missing = CatalogFilter(
      sourceType: MusicSourceType.local,
      availability: [TrackAvailability.localMissing],
    );
    expect(
      (await library.browseAlbums(
        CatalogAlbumQuery(filter: missing),
        PageRequest(),
      )).items.single.id,
      'shared',
    );
    expect(
      (await library.browseArtists(
        CatalogArtistQuery(filter: missing),
        PageRequest(),
      )).items.single.name,
      'Local',
    );
    final all = await library.browseAlbums(
      const CatalogAlbumQuery(),
      PageRequest(),
    );
    expect(all.items.length, 2);
  });

  test(
    'source-scoped detail browsing cannot cross an album or artist identity',
    () async {
      await library.upsertTracks([
        track('one', album: 'same', artists: ['Artist', 'Guest']),
        track('two', album: 'same', artists: ['Artist']),
        track('one', source: 'b', album: 'same', artists: ['Artist']),
      ]);
      final album = AlbumRef(sourceId: 'a', albumId: 'same');
      final page = await library.browseTracks(
        CatalogTrackQuery(album: album, artist: artistRef('Guest')),
        PageRequest(limit: 1),
      );
      expect(page.items.single.id, 'one');
      expect(page.items.single.sourceId, 'a');
      expect(page.items.single.artists, ['Artist', 'Guest']);
      expect(page.hasMore, isFalse);
      expect(
        (await library.browseTracks(
          CatalogTrackQuery(
            album: album,
            artist: artistRef('Artist', source: 'b'),
          ),
          PageRequest(),
        )).items,
        isEmpty,
      );
      expect(
        (await library.browseAlbums(
          CatalogAlbumQuery(artist: artistRef('Artist', source: 'b')),
          PageRequest(),
        )).items.single.sourceId,
        'b',
      );
      expect(
        (await library.getAlbum(AlbumRef(sourceId: 'b', albumId: 'same')))!
            .trackCount,
        1,
      );
      expect((await library.getAlbum(album))!.trackCount, 2);
      await database
          .into(database.artistRecords)
          .insert(
            ArtistRecordsCompanion.insert(
              sourceId: 'x',
              artistId: 'same-id',
              name: 'X',
            ),
          );
      await database
          .into(database.artistRecords)
          .insert(
            ArtistRecordsCompanion.insert(
              sourceId: 'y',
              artistId: 'same-id',
              name: 'Y',
            ),
          );
      expect(
        (await library.getArtist(
          ArtistRef(sourceId: 'x', artistId: 'same-id'),
        ))!.name,
        'X',
      );
      expect(
        (await library.getArtist(
          ArtistRef(sourceId: 'y', artistId: 'same-id'),
        ))!.name,
        'Y',
      );
    },
  );

  test('450 entities are paginated before artist expansion using one SELECT and no write transaction', () async {
    await library.upsertTracks([
      for (var i = 0; i < 450; i++)
        track(
          'id-${i.toString().padLeft(3, '0')}',
          album: 'album-${i.toString().padLeft(3, '0')}',
          artists: [
            'First ${i.toString().padLeft(3, '0')}',
            'Second ${i.toString().padLeft(3, '0')}',
          ],
        ),
    ]);
    probe.transactionCount = 0;
    probe.selects.clear();
    final tracks = await library.browseTracks(
      const CatalogTrackQuery(),
      PageRequest(offset: 200, limit: 200),
    );
    expect(tracks.items.length, 200);
    expect(tracks.items.first.id, 'id-200');
    expect(tracks.items.last.id, 'id-399');
    expect(tracks.items.every((t) => t.artists.length == 2), isTrue);
    expect(tracks.hasMore, isTrue);
    expect(probe.selects.single.rows, 402); // 201 entities, 2 credits each.
    expect(probe.selects.single.args, [201, 200]);
    probe.selects.clear();
    final albums = await library.browseAlbums(
      const CatalogAlbumQuery(),
      PageRequest(offset: 200, limit: 200),
    );
    expect(albums.items.first.id, 'album-200');
    expect(albums.items.every((a) => a.artists.length == 2), isTrue);
    expect(probe.selects.single.rows, 402);
    probe.selects.clear();
    final artists = await library.browseArtists(
      const CatalogArtistQuery(),
      PageRequest(offset: 200, limit: 200),
    );
    expect(artists.items.length, 200);
    expect(probe.selects.single.rows, 201);
    expect(probe.transactionCount, 0);
    expect(() => tracks.items.clear(), throwsUnsupportedError);
  });

  test('source and detail identifiers are bound literals including SQL punctuation', () async {
    const source = "private-source' OR 1=1 --";
    const album = "private-album'%_";
    await library.upsertTracks([
      track('a', source: source, album: album),
      track('b', album: album),
    ]);
    probe.selects.clear();
    final result = await library.browseTracks(
      CatalogTrackQuery(
        filter: CatalogFilter(sourceId: source),
        album: AlbumRef(sourceId: source, albumId: album),
      ),
      PageRequest(),
    );
    expect(result.items.single.sourceId, source);
    expect(probe.selects.single.sql, isNot(contains(source)));
    expect(probe.selects.single.sql, isNot(contains(album)));
    expect(probe.selects.single.args, containsAll([source, album]));
    expect(
      (await library.getAlbum(AlbumRef(sourceId: source, albumId: album)))!
          .sourceId,
      source,
    );
  });

  test('pre-cancel and late cancel never deliver pages or become database corruption', () async {
    await library.upsertTracks([track('a', album: 'one')]);
    for (final late in [false, true]) {
      for (final query in <Future<Object?> Function(SearchCancellation)>[
        (c) => library.browseTracks(
          const CatalogTrackQuery(),
          PageRequest(),
          cancellation: c,
        ),
        (c) => library.browseAlbums(
          const CatalogAlbumQuery(),
          PageRequest(),
          cancellation: c,
        ),
        (c) => library.browseArtists(
          const CatalogArtistQuery(),
          PageRequest(),
          cancellation: c,
        ),
        (c) => library.getAlbum(
          AlbumRef(sourceId: 'a', albumId: 'one'),
          cancellation: c,
        ),
        (c) => library.getArtist(artistRef('Artist'), cancellation: c),
      ]) {
        final token = SearchCancellation();
        if (!late) token.cancel();
        probe.selects.clear();
        probe.afterSelect = late ? () async => token.cancel() : null;
        await expectLater(() => query(token), throwsA(isA<SearchCancelled>()));
        expect(probe.selects.length, late ? 1 : 0);
      }
    }
    probe.afterSelect = null;
  });

  test('uninitialized disposed and corrupt data fail safely without leaking stored content', () async {
    final unopened = DriftLibraryRepository(database);
    expect(
      () => unopened.browseTracks(const CatalogTrackQuery(), PageRequest()),
      throwsStateError,
    );
    await unopened.dispose();
    await library.upsertTracks([track('a', album: 'one')]);
    await database.customStatement(
      "UPDATE tracks SET metadata_json = 'private-corrupt-marker'",
    );
    await expectLater(
      library.browseTracks(const CatalogTrackQuery(), PageRequest()),
      throwsA(
        isA<DomainFailure>().having(
          (e) => e.toString(),
          'safe',
          isNot(contains('private-corrupt-marker')),
        ),
      ),
    );
    await database.customStatement('DELETE FROM album_artists');
    await expectLater(
      library.getAlbum(AlbumRef(sourceId: 'a', albumId: 'one')),
      throwsA(isA<DomainFailure>()),
    );
    await library.dispose();
    expect(
      () => library.browseAlbums(const CatalogAlbumQuery(), PageRequest()),
      throwsStateError,
    );
    expect(() => library.getArtist(artistRef('Artist')), throwsStateError);
  });

  test('one-page snapshot stays internally consistent across a concurrent SQLite writer', () async {
    final directory = await Directory.systemTemp.createTemp(
      'yymusic-browse-snapshot-',
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
        track('a', album: 'one', artists: ['Old', 'Guest']),
      ]);
      readerProbe.selects.clear();
      readerProbe.transactionCount = 0;
      readerProbe.afterSelect = () async {
        if (readerProbe.selects.length == 1) {
          await writer.upsertTracks([
            track('a', album: 'one', title: 'Changed', artists: ['New']),
          ]);
        }
      };
      final page = await reader.browseTracks(
        const CatalogTrackQuery(),
        PageRequest(),
      );
      expect(page.items.single.title, 'Shared');
      expect(page.items.single.artists, ['Old', 'Guest']);
      expect(readerProbe.transactionCount, 0);
      readerProbe.afterSelect = null;
      final next = await reader.browseTracks(
        const CatalogTrackQuery(),
        PageRequest(),
      );
      expect(next.items.single.title, 'Changed');
      expect(next.items.single.artists, ['New']);
    } finally {
      await reader.dispose();
      await writer.dispose();
      await readerDb.close();
      await writerDb.close();
      // Only this test's exact fresh temporary directory is removed.
      await directory.delete(recursive: true);
    }
  });

  test(
    'root data scope shares one catalog instance and closes its database once',
    () async {
      final ownedProbe = SearchQueryProbe();
      final db = AppDatabase(NativeDatabase.memory().interceptWith(ownedProbe));
      final services = await DatabaseAppDataServices.open(db);
      final graph = DependencyGraph(dataServices: services);
      expect(graph.catalogBrowse, same(services.library));
      expect(graph.catalogBrowse, same(graph.catalogSearch));
      await services.library.upsertTracks([track('a', album: 'one')]);
      expect(
        (await graph.catalogBrowse!.browseAlbums(
          const CatalogAlbumQuery(),
          PageRequest(),
        )).items.single.id,
        'one',
      );
      await graph.close();
      await graph.close();
      expect(ownedProbe.closeCount, 1);
    },
  );
}

ArtistRef artistRef(String name, {String source = 'a'}) => ArtistRef(
  sourceId: source,
  artistId: const LibraryRowMapper().artistId(sourceId: source, name: name),
);
Track track(
  String id, {
  String source = 'a',
  MusicSourceType type = MusicSourceType.local,
  String title = 'Shared',
  List<String> artists = const ['Artist'],
  String? album,
  int seconds = 180,
  TrackAvailability availability = TrackAvailability.available,
}) => Track(
  id: id,
  sourceId: source,
  sourceType: type,
  title: title,
  artists: artists,
  albumId: album,
  albumTitle: album,
  duration: Duration(seconds: seconds),
  availability: availability,
  localPath: type == MusicSourceType.local ? '/fixture-only/$id.wav' : null,
);
