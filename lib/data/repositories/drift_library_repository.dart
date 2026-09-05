import 'dart:async';

import 'package:drift/drift.dart';

import '../../domain/models/catalog_search.dart';
import '../../domain/models/domain_failure.dart';
import '../../domain/models/library_entities.dart';
import '../../domain/models/pagination.dart';
import '../../domain/models/track.dart';
import '../../domain/repositories/catalog_search_repository.dart';
import '../../domain/repositories/library_repository.dart';
import '../database/app_database.dart';
import 'library_row_mapper.dart';

final class DriftLibraryRepository
    implements LibraryRepository, CatalogSearchRepository {
  factory DriftLibraryRepository(
    AppDatabase database, {
    bool closeDatabaseOnDispose = false,
    LibraryRowMapper mapper = const LibraryRowMapper(),
    DateTime Function()? clock,
  }) => DriftLibraryRepository._(
    database,
    closeDatabaseOnDispose,
    mapper,
    clock ?? _utcNow,
  );

  factory DriftLibraryRepository.owned(
    AppDatabase database, {
    LibraryRowMapper mapper = const LibraryRowMapper(),
    DateTime Function()? clock,
  }) => DriftLibraryRepository._(database, true, mapper, clock ?? _utcNow);

  DriftLibraryRepository._(
    this._database,
    this._closeDatabaseOnDispose,
    this._mapper,
    this._clock,
  );

  final AppDatabase _database;
  final bool _closeDatabaseOnDispose;
  final LibraryRowMapper _mapper;
  final DateTime Function() _clock;

  bool _initialized = false;
  bool _disposed = false;

  @override
  Future<void> initialize() async {
    _requireNotDisposed();
    if (_initialized) return;
    await _guard('initialize', () async {
      final versionRow = await _database
          .customSelect('PRAGMA user_version')
          .getSingle();
      if (versionRow.read<int>('user_version') != _database.schemaVersion) {
        throw StateError('Unexpected database schema version');
      }
      final integrityRow = await _database
          .customSelect('PRAGMA quick_check')
          .getSingle();
      if (integrityRow.read<String>('quick_check') != 'ok') {
        throw StateError('Database integrity check failed');
      }
      final foreignKeys = await _database
          .customSelect('PRAGMA foreign_keys')
          .getSingle();
      if (foreignKeys.read<int>('foreign_keys') != 1) {
        throw StateError('Database foreign keys are disabled');
      }
    });
    _initialized = true;
  }

  @override
  Stream<List<Track>> watchTracks() {
    _requireReady();
    final tracks = _database.trackRecords;
    final links = _database.trackArtistRecords;
    final artists = _database.artistRecords;
    final query =
        _database.select(tracks).join([
          leftOuterJoin(
            links,
            links.trackSourceType.equalsExp(tracks.sourceType) &
                links.trackSourceId.equalsExp(tracks.sourceId) &
                links.trackId.equalsExp(tracks.trackId),
          ),
          leftOuterJoin(
            artists,
            artists.sourceId.equalsExp(links.artistSourceId) &
                artists.artistId.equalsExp(links.artistId),
          ),
        ])..orderBy([
          OrderingTerm(expression: tracks.title),
          OrderingTerm(expression: tracks.sourceType),
          OrderingTerm(expression: tracks.sourceId),
          OrderingTerm(expression: tracks.trackId),
          OrderingTerm(expression: links.position),
        ]);

    return query
        .watch()
        .map(_mapWatchedTracks)
        .transform(
          StreamTransformer.fromHandlers(
            handleError: (Object error, StackTrace stackTrace, sink) {
              sink.addError(_failureFor(error, 'watch-tracks'), stackTrace);
            },
          ),
        );
  }

  @override
  Future<PageResult<Track>> listTracks(PageRequest request) {
    _requireReady();
    return _guard('list-tracks', () async {
      final query = _database.select(_database.trackRecords)
        ..orderBy([
          (table) => OrderingTerm(expression: table.title),
          (table) => OrderingTerm(expression: table.sourceType),
          (table) => OrderingTerm(expression: table.sourceId),
          (table) => OrderingTerm(expression: table.trackId),
        ])
        ..limit(request.limit + 1, offset: request.offset);
      final rows = await query.get();
      final hasMore = rows.length > request.limit;
      final pageRows = rows.take(request.limit).toList(growable: false);
      return PageResult(
        items: await _tracksFromRows(pageRows),
        hasMore: hasMore,
      );
    });
  }

  @override
  Future<PageResult<Album>> listAlbums(PageRequest request) {
    _requireReady();
    return _guard('list-albums', () async {
      final query = _database.select(_database.albumRecords)
        ..orderBy([
          (table) => OrderingTerm(expression: table.title),
          (table) => OrderingTerm(expression: table.sourceId),
          (table) => OrderingTerm(expression: table.albumId),
        ])
        ..limit(request.limit + 1, offset: request.offset);
      final rows = await query.get();
      final hasMore = rows.length > request.limit;
      final pageRows = rows.take(request.limit).toList(growable: false);
      return PageResult(
        items: await _albumsFromRows(pageRows),
        hasMore: hasMore,
      );
    });
  }

  @override
  Future<PageResult<Track>> listRecentlyAdded(
    PageRequest request, {
    required DateTime since,
    required DateTime until,
  }) {
    _requireReady();
    final firstMs = since.toUtc().millisecondsSinceEpoch;
    final lastMs = until.toUtc().millisecondsSinceEpoch;
    if (since.isAfter(until)) {
      throw ArgumentError('Invalid catalog time window');
    }
    return _guard('recently-added', () async {
      final query = _database.select(_database.trackRecords)
        ..where((row) => row.addedAtMs.isBetweenValues(firstMs, lastMs))
        ..orderBy([
          (row) =>
              OrderingTerm(expression: row.addedAtMs, mode: OrderingMode.desc),
          (row) => OrderingTerm(expression: row.sourceType),
          (row) => OrderingTerm(expression: row.sourceId),
          (row) => OrderingTerm(expression: row.trackId),
        ])
        ..limit(request.limit + 1, offset: request.offset);
      final rows = await query.get();
      return PageResult(
        items: await _tracksFromRows(
          rows.take(request.limit).toList(growable: false),
        ),
        hasMore: rows.length > request.limit,
      );
    });
  }

  @override
  Future<PageResult<Artist>> listArtists(PageRequest request) {
    _requireReady();
    return _guard('list-artists', () async {
      final query = _database.select(_database.artistRecords)
        ..orderBy([
          (table) => OrderingTerm(expression: table.name),
          (table) => OrderingTerm(expression: table.sourceId),
          (table) => OrderingTerm(expression: table.artistId),
        ])
        ..limit(request.limit + 1, offset: request.offset);
      final rows = await query.get();
      final hasMore = rows.length > request.limit;
      return PageResult(
        items: rows.take(request.limit).map(_mapper.artistFromRow),
        hasMore: hasMore,
      );
    });
  }

  @override
  Future<Track?> getTrack(TrackRef reference) {
    _requireReady();
    return _guard('get-track', () async {
      final query = _database.select(_database.trackRecords)
        ..where(
          (table) =>
              table.sourceType.equals(reference.sourceType.name) &
              table.sourceId.equals(reference.sourceId) &
              table.trackId.equals(reference.trackId),
        );
      final row = await query.getSingleOrNull();
      if (row == null) return null;
      return (await _tracksFromRows([row])).single;
    });
  }

  @override
  Future<PageResult<Track>> searchTracks(
    CatalogQuery query,
    PageRequest page, {
    SearchCancellation? cancellation,
  }) {
    _searchCheckpoint(cancellation);
    if (query.text.isEmpty) {
      return Future.value(PageResult(items: const [], hasMore: false));
    }
    return _guard('search-tracks', () async {
      final rows = await _catalogSearchRows(
        query,
        page,
        from: 'tracks item',
        match: '''
          instr(lower(item.title), lower(input.term)) > 0
          OR instr(lower(COALESCE(item.album_title, '')), lower(input.term)) > 0
          OR EXISTS (
            SELECT 1 FROM track_artists ta JOIN artists a
              ON a.source_id = ta.artist_source_id AND a.artist_id = ta.artist_id
            WHERE ta.track_source_type = item.source_type
              AND ta.track_source_id = item.source_id AND ta.track_id = item.track_id
              AND instr(lower(a.name), lower(input.term)) > 0
          ) OR EXISTS (
            SELECT 1 FROM music_sources s WHERE s.source_id = item.source_id
              AND s.source_type = item.source_type
              AND instr(lower(s.name), lower(input.term)) > 0
          )
        ''',
        typePredicate: 'item.source_type = ?',
        order: 'item.title, item.source_type, item.source_id, item.track_id',
        artistJoin: '''
            LEFT JOIN track_artists credit
              ON credit.track_source_type = item.source_type
                AND credit.track_source_id = item.source_id AND credit.track_id = item.track_id
            LEFT JOIN artists artist ON artist.source_id = credit.artist_source_id
              AND artist.artist_id = credit.artist_id
          ''',
      );
      _searchCheckpoint(cancellation);
      final grouped = <_TrackKey, _WatchedTrack>{};
      for (final result in rows) {
        final row = _database.trackRecords.map(result.data);
        final entry = grouped.putIfAbsent(
          _TrackKey.fromRow(row),
          () => _WatchedTrack(row),
        );
        final name = result.readNullable<String>('search_artist_name');
        if (name != null) {
          entry.artists.add(name);
        }
      }
      final items = grouped.values
          .take(page.limit)
          .map((entry) => _mapper.trackFromRow(entry.row, entry.artists))
          .toList(growable: false);
      _searchCheckpoint(cancellation);
      return PageResult(items: items, hasMore: grouped.length > page.limit);
    });
  }

  @override
  Future<PageResult<Album>> searchAlbums(
    CatalogQuery query,
    PageRequest page, {
    SearchCancellation? cancellation,
  }) {
    _searchCheckpoint(cancellation);
    if (query.text.isEmpty) {
      return Future.value(PageResult(items: const [], hasMore: false));
    }
    return _guard('search-albums', () async {
      final rows = await _catalogSearchRows(
        query,
        page,
        from: 'albums item',
        match: '''
          instr(lower(item.title), lower(input.term)) > 0
          OR EXISTS (
            SELECT 1 FROM album_artists aa JOIN artists a
              ON a.source_id = aa.artist_source_id AND a.artist_id = aa.artist_id
            WHERE aa.album_source_id = item.source_id AND aa.album_id = item.album_id
              AND instr(lower(a.name), lower(input.term)) > 0
          ) OR EXISTS (
            SELECT 1 FROM music_sources s WHERE s.source_id = item.source_id
              AND instr(lower(s.name), lower(input.term)) > 0
          )
        ''',
        typePredicate: '''EXISTS (
          SELECT 1 FROM tracks t WHERE t.source_id = item.source_id
            AND t.album_id = item.album_id AND t.source_type = ?
        )''',
        order: 'item.title, item.source_id, item.album_id',
        artistJoin: '''
            LEFT JOIN album_artists credit
              ON credit.album_source_id = item.source_id AND credit.album_id = item.album_id
            LEFT JOIN artists artist ON artist.source_id = credit.artist_source_id
              AND artist.artist_id = credit.artist_id
          ''',
      );
      _searchCheckpoint(cancellation);
      final grouped =
          <_AlbumKey, ({AlbumRow row, List<ArtistCredit> artists})>{};
      for (final result in rows) {
        final row = _database.albumRecords.map(result.data);
        final entry = grouped.putIfAbsent(
          _AlbumKey.fromRow(row),
          () => (row: row, artists: []),
        );
        final name = result.readNullable<String>('search_artist_name');
        final id = result.readNullable<String>('search_artist_id');
        if (name != null && id != null) {
          entry.artists.add(ArtistCredit(id: id, name: name));
        }
      }
      final items = grouped.values
          .take(page.limit)
          .map((entry) => _mapper.albumFromRow(entry.row, entry.artists))
          .toList(growable: false);
      _searchCheckpoint(cancellation);
      return PageResult(items: items, hasMore: grouped.length > page.limit);
    });
  }

  @override
  Future<PageResult<Artist>> searchArtists(
    CatalogQuery query,
    PageRequest page, {
    SearchCancellation? cancellation,
  }) {
    _searchCheckpoint(cancellation);
    if (query.text.isEmpty) {
      return Future.value(PageResult(items: const [], hasMore: false));
    }
    return _guard('search-artists', () async {
      final rows = await _catalogSearchRows(
        query,
        page,
        from: 'artists item',
        match: '''
          instr(lower(item.name), lower(input.term)) > 0
          OR EXISTS (
            SELECT 1 FROM music_sources s WHERE s.source_id = item.source_id
              AND instr(lower(s.name), lower(input.term)) > 0
          )
        ''',
        typePredicate: '''EXISTS (
          SELECT 1 FROM track_artists ta JOIN tracks t
            ON t.source_type = ta.track_source_type AND t.source_id = ta.track_source_id
              AND t.track_id = ta.track_id
          WHERE ta.artist_source_id = item.source_id AND ta.artist_id = item.artist_id
            AND t.source_type = ?
        )''',
        order: 'item.name, item.source_id, item.artist_id',
      );
      _searchCheckpoint(cancellation);
      final items = [
        for (final row in rows.take(page.limit))
          _mapper.artistFromRow(_database.artistRecords.map(row.data)),
      ];
      _searchCheckpoint(cancellation);
      return PageResult(items: items, hasMore: rows.length > page.limit);
    });
  }

  // SQL fragments come only from the fixed entity queries above. Every input
  // value, including paging and source filters, is bound rather than interpolated.
  Future<List<QueryRow>> _catalogSearchRows(
    CatalogQuery query,
    PageRequest page, {
    required String from,
    required String match,
    required String typePredicate,
    required String order,
    String? artistJoin,
  }) {
    final filters = <String>[];
    final variables = <Variable>[
      Variable<String>(query.text),
      if (query.sourceType != null) Variable<String>(query.sourceType!.name),
      if (query.sourceId != null) Variable<String>(query.sourceId!),
      Variable<int>(page.limit + 1),
      Variable<int>(page.offset),
    ];
    if (query.sourceType != null) filters.add(typePredicate);
    if (query.sourceId != null) filters.add('item.source_id = ?');
    return _database
        .customSelect(
          'WITH input(term) AS (VALUES (?)), page AS ('
          'SELECT item.* FROM $from CROSS JOIN input WHERE ($match) '
          '${filters.isEmpty ? '' : 'AND ${filters.join(' AND ')}'} '
          'ORDER BY $order LIMIT ? OFFSET ?) '
          'SELECT item.*${artistJoin == null ? '' : ', artist.name AS search_artist_name, artist.artist_id AS search_artist_id'} '
          'FROM page item ${artistJoin ?? ''} '
          'ORDER BY $order${artistJoin == null ? '' : ', credit.position'}',
          variables: variables,
        )
        .get();
  }

  void _searchCheckpoint(SearchCancellation? cancellation) {
    cancellation?.throwIfCancelled();
    _requireReady();
  }

  @override
  Future<void> upsertTracks(Iterable<Track> tracks) {
    _requireReady();
    final catalog = _validateCatalog(tracks);
    if (catalog.tracks.isEmpty) return Future.value();
    return _guard('upsert-tracks', () async {
      await _database.transaction(() async {
        for (final chunk in _chunks(catalog.tracks, 200)) {
          Expression<bool> predicate = const Constant(false);
          for (final track in chunk) {
            predicate =
                predicate |
                (_database.trackArtistRecords.trackSourceType.equals(
                      track.sourceType.name,
                    ) &
                    _database.trackArtistRecords.trackSourceId.equals(
                      track.sourceId,
                    ) &
                    _database.trackArtistRecords.trackId.equals(track.id));
          }
          await (_database.delete(
            _database.trackArtistRecords,
          )..where((_) => predicate)).go();
        }

        await _database.batch((batch) {
          final addedAtMs = _clock().toUtc().millisecondsSinceEpoch;
          for (final track in catalog.tracks) {
            final metadata = _mapper.trackToCompanion(track);
            batch.insert(
              _database.trackRecords,
              metadata.copyWith(addedAtMs: Value(addedAtMs)),
              // No addedAtMs in this companion: preserve first insertion,
              // including unknown (NULL) dates from a migrated v1 catalog.
              onConflict: DoUpdate((_) => metadata),
            );
          }
          batch.insertAllOnConflictUpdate(
            _database.artistRecords,
            catalog.artists.values,
          );
          batch.insertAllOnConflictUpdate(
            _database.albumRecords,
            catalog.albums.values.map(
              (album) => _mapper.albumToCompanion(
                albumId: album.albumId,
                sourceId: album.sourceId,
                title: album.title,
                artworkUri: album.artworkUri,
              ),
            ),
          );
          batch.insertAll(_database.trackArtistRecords, catalog.trackArtists);
        });
        await _rebuildCatalogAggregates();
      });
    });
  }

  @override
  Future<void> setAvailability(
    TrackRef reference,
    TrackAvailability availability,
  ) {
    _requireReady();
    return _guard('set-availability', () async {
      final statement = _database.update(_database.trackRecords)
        ..where(
          (table) =>
              table.sourceType.equals(reference.sourceType.name) &
              table.sourceId.equals(reference.sourceId) &
              table.trackId.equals(reference.trackId),
        );
      final changed = await statement.write(
        TrackRecordsCompanion(availability: Value(availability.name)),
      );
      if (changed == 0) {
        throw DomainFailure(
          code: DomainFailureCode.notFound,
          diagnosticId: 'library-track.not-found',
          sourceId: reference.sourceId,
        );
      }
    });
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _initialized = false;
    if (_closeDatabaseOnDispose) {
      await _database.close();
    }
  }

  List<Track> _mapWatchedTracks(List<TypedResult> rows) {
    final grouped = <_TrackKey, _WatchedTrack>{};
    for (final result in rows) {
      final track = result.readTable(_database.trackRecords);
      final key = _TrackKey.fromRow(track);
      final entry = grouped.putIfAbsent(key, () => _WatchedTrack(track));
      final link = result.readTableOrNull(_database.trackArtistRecords);
      final artist = result.readTableOrNull(_database.artistRecords);
      if (link != null && artist == null) {
        throw _failure('watch-track-artist');
      }
      if (artist != null) entry.artists.add(artist.name);
    }
    return List<Track>.unmodifiable(
      grouped.values.map(
        (entry) => _mapper.trackFromRow(entry.row, entry.artists),
      ),
    );
  }

  Future<List<Track>> _tracksFromRows(List<TrackRow> rows) async {
    if (rows.isEmpty) return const [];
    final names = <_TrackKey, List<String>>{};
    final links = _database.trackArtistRecords;
    final artists = _database.artistRecords;
    Expression<bool> predicate = const Constant(false);
    for (final row in rows) {
      predicate =
          predicate |
          (links.trackSourceType.equals(row.sourceType) &
              links.trackSourceId.equals(row.sourceId) &
              links.trackId.equals(row.trackId));
    }
    final query =
        _database.select(links).join([
            innerJoin(
              artists,
              artists.sourceId.equalsExp(links.artistSourceId) &
                  artists.artistId.equalsExp(links.artistId),
            ),
          ])
          ..where(predicate)
          ..orderBy([
            OrderingTerm(expression: links.trackSourceType),
            OrderingTerm(expression: links.trackSourceId),
            OrderingTerm(expression: links.trackId),
            OrderingTerm(expression: links.position),
          ]);
    for (final result in await query.get()) {
      final link = result.readTable(links);
      final artist = result.readTable(artists);
      final key = _TrackKey(
        link.trackSourceType,
        link.trackSourceId,
        link.trackId,
      );
      names.putIfAbsent(key, () => []).add(artist.name);
    }
    return List<Track>.unmodifiable(
      rows.map(
        (row) => _mapper.trackFromRow(
          row,
          names[_TrackKey.fromRow(row)] ?? const [],
        ),
      ),
    );
  }

  Future<List<Album>> _albumsFromRows(List<AlbumRow> rows) async {
    if (rows.isEmpty) return const [];
    final credits = <_AlbumKey, List<ArtistCredit>>{};
    final links = _database.albumArtistRecords;
    final artists = _database.artistRecords;
    Expression<bool> predicate = const Constant(false);
    for (final row in rows) {
      predicate =
          predicate |
          (links.albumSourceId.equals(row.sourceId) &
              links.albumId.equals(row.albumId));
    }
    final query =
        _database.select(links).join([
            innerJoin(
              artists,
              artists.sourceId.equalsExp(links.artistSourceId) &
                  artists.artistId.equalsExp(links.artistId),
            ),
          ])
          ..where(predicate)
          ..orderBy([
            OrderingTerm(expression: links.albumSourceId),
            OrderingTerm(expression: links.albumId),
            OrderingTerm(expression: links.position),
          ]);
    for (final result in await query.get()) {
      final link = result.readTable(links);
      final artist = result.readTable(artists);
      credits
          .putIfAbsent(_AlbumKey(link.albumSourceId, link.albumId), () => [])
          .add(ArtistCredit(id: artist.artistId, name: artist.name));
    }
    return List<Album>.unmodifiable(
      rows.map(
        (row) => _mapper.albumFromRow(
          row,
          credits[_AlbumKey.fromRow(row)] ?? const [],
        ),
      ),
    );
  }

  _ValidatedCatalog _validateCatalog(Iterable<Track> input) {
    final tracks = input.toList(growable: false)
      ..sort((left, right) => _compareTrackRefs(left.ref, right.ref));
    final seenTracks = <_TrackKey>{};
    final artists = <_ArtistKey, ArtistRecordsCompanion>{};
    final albums = <_AlbumKey, _AlbumSeed>{};
    final trackArtists = <TrackArtistRecordsCompanion>[];
    for (final track in tracks) {
      if (!seenTracks.add(_TrackKey.fromTrack(track))) {
        throw ArgumentError('The catalog batch contains a duplicate TrackRef');
      }
      if ((track.albumId == null) != (track.albumTitle == null)) {
        throw ArgumentError(
          'A catalog track must provide albumId and albumTitle together',
        );
      }
      _mapper.trackToCompanion(track);
      final seenNames = <String>{};
      for (var position = 0; position < track.artists.length; position++) {
        final name = track.artists[position];
        if (!seenNames.add(name)) {
          throw ArgumentError('A track must not repeat an artist name');
        }
        final id = _mapper.artistId(sourceId: track.sourceId, name: name);
        final key = _ArtistKey(track.sourceId, id);
        final existing = artists[key];
        if (existing != null && existing.name.value != name) {
          throw ArgumentError('Derived artist identity collision');
        }
        artists[key] = _mapper.artistToCompanion(
          sourceId: track.sourceId,
          name: name,
        );
        trackArtists.add(
          TrackArtistRecordsCompanion.insert(
            trackSourceType: track.sourceType.name,
            trackSourceId: track.sourceId,
            trackId: track.id,
            artistSourceId: track.sourceId,
            artistId: id,
            position: position,
          ),
        );
      }
      if (track.albumId != null) {
        final key = _AlbumKey(track.sourceId, track.albumId!);
        final existing = albums[key];
        if (existing != null && existing.title != track.albumTitle) {
          throw ArgumentError('An album has conflicting titles in one batch');
        }
        albums[key] = _AlbumSeed(
          sourceId: track.sourceId,
          albumId: track.albumId!,
          title: track.albumTitle!,
          artworkUri: existing?.artworkUri ?? track.artworkUri,
        );
      }
    }
    return _ValidatedCatalog(
      tracks: tracks,
      artists: artists,
      albums: albums,
      trackArtists: trackArtists,
    );
  }

  Future<void> _rebuildCatalogAggregates() async {
    await _database.customStatement('DELETE FROM album_artists');
    await _database.customStatement('''
      UPDATE albums
      SET track_count = (
        SELECT COUNT(*)
        FROM tracks
        WHERE tracks.source_id = albums.source_id
          AND tracks.album_id = albums.album_id
      )
    ''');
    await _database.customStatement('DELETE FROM albums WHERE track_count = 0');
    await _database.customStatement('''
      INSERT INTO album_artists (
        album_source_id,
        album_id,
        artist_source_id,
        artist_id,
        position
      )
      SELECT
        source_id,
        album_id,
        artist_source_id,
        artist_id,
        ROW_NUMBER() OVER (
          PARTITION BY source_id, album_id
          ORDER BY first_track_id, first_position, artist_id
        ) - 1
      FROM (
        SELECT
          source_id,
          album_id,
          artist_source_id,
          artist_id,
          first_track_id,
          first_position
        FROM (
          SELECT
            tracks.source_id AS source_id,
            tracks.album_id AS album_id,
            track_artists.artist_source_id AS artist_source_id,
            track_artists.artist_id AS artist_id,
            tracks.track_id AS first_track_id,
            track_artists.position AS first_position,
            ROW_NUMBER() OVER (
              PARTITION BY
                tracks.source_id,
                tracks.album_id,
                track_artists.artist_source_id,
                track_artists.artist_id
              ORDER BY tracks.track_id, track_artists.position
            ) AS artist_occurrence
          FROM tracks
          INNER JOIN track_artists
            ON track_artists.track_source_type = tracks.source_type
            AND track_artists.track_source_id = tracks.source_id
            AND track_artists.track_id = tracks.track_id
          WHERE tracks.album_id IS NOT NULL
        ) AS artist_occurrences
        WHERE artist_occurrence = 1
      ) AS first_album_credits
    ''');
    await _database.customStatement('''
      UPDATE artists
      SET track_count = (
        SELECT COUNT(*)
        FROM track_artists
        WHERE track_artists.artist_source_id = artists.source_id
          AND track_artists.artist_id = artists.artist_id
      ),
      album_count = (
        SELECT COUNT(*)
        FROM album_artists
        WHERE album_artists.artist_source_id = artists.source_id
          AND album_artists.artist_id = artists.artist_id
      )
    ''');
    await _database.customStatement(
      'DELETE FROM artists WHERE track_count = 0 AND album_count = 0',
    );
  }

  Future<T> _guard<T>(String operation, Future<T> Function() body) async {
    try {
      return await body();
    } on DomainFailure {
      rethrow;
    } on SearchCancelled {
      rethrow;
    } catch (_) {
      throw _failure(operation);
    }
  }

  DomainFailure _failureFor(Object error, String operation) =>
      error is DomainFailure ? error : _failure(operation);

  DomainFailure _failure(String operation) => DomainFailure(
    code: DomainFailureCode.databaseCorrupted,
    diagnosticId: 'library-repository.$operation',
  );

  void _requireNotDisposed() {
    if (_disposed) throw StateError('LibraryRepository is disposed');
  }

  void _requireReady() {
    _requireNotDisposed();
    if (!_initialized) {
      throw StateError('LibraryRepository is not initialized');
    }
  }
}

final class _ValidatedCatalog {
  const _ValidatedCatalog({
    required this.tracks,
    required this.artists,
    required this.albums,
    required this.trackArtists,
  });

  final List<Track> tracks;
  final Map<_ArtistKey, ArtistRecordsCompanion> artists;
  final Map<_AlbumKey, _AlbumSeed> albums;
  final List<TrackArtistRecordsCompanion> trackArtists;
}

final class _AlbumSeed {
  const _AlbumSeed({
    required this.sourceId,
    required this.albumId,
    required this.title,
    required this.artworkUri,
  });

  final String sourceId;
  final String albumId;
  final String title;
  final Uri? artworkUri;
}

final class _WatchedTrack {
  _WatchedTrack(this.row);

  final TrackRow row;
  final List<String> artists = [];
}

final class _TrackKey {
  const _TrackKey(this.sourceType, this.sourceId, this.trackId);

  factory _TrackKey.fromRow(TrackRow row) =>
      _TrackKey(row.sourceType, row.sourceId, row.trackId);

  factory _TrackKey.fromTrack(Track track) =>
      _TrackKey(track.sourceType.name, track.sourceId, track.id);

  final String sourceType;
  final String sourceId;
  final String trackId;

  @override
  bool operator ==(Object other) =>
      other is _TrackKey &&
      sourceType == other.sourceType &&
      sourceId == other.sourceId &&
      trackId == other.trackId;

  @override
  int get hashCode => Object.hash(sourceType, sourceId, trackId);
}

final class _AlbumKey {
  const _AlbumKey(this.sourceId, this.albumId);

  factory _AlbumKey.fromRow(AlbumRow row) =>
      _AlbumKey(row.sourceId, row.albumId);

  final String sourceId;
  final String albumId;

  @override
  bool operator ==(Object other) =>
      other is _AlbumKey &&
      sourceId == other.sourceId &&
      albumId == other.albumId;

  @override
  int get hashCode => Object.hash(sourceId, albumId);
}

final class _ArtistKey {
  const _ArtistKey(this.sourceId, this.artistId);

  final String sourceId;
  final String artistId;

  @override
  bool operator ==(Object other) =>
      other is _ArtistKey &&
      sourceId == other.sourceId &&
      artistId == other.artistId;

  @override
  int get hashCode => Object.hash(sourceId, artistId);
}

Iterable<List<Track>> _chunks(List<Track> tracks, int size) sync* {
  for (var start = 0; start < tracks.length; start += size) {
    final end = start + size > tracks.length ? tracks.length : start + size;
    yield tracks.sublist(start, end);
  }
}

int _compareTrackRefs(TrackRef left, TrackRef right) {
  var comparison = left.sourceType.index.compareTo(right.sourceType.index);
  if (comparison != 0) return comparison;
  comparison = left.sourceId.compareTo(right.sourceId);
  if (comparison != 0) return comparison;
  return left.trackId.compareTo(right.trackId);
}

DateTime _utcNow() => DateTime.now().toUtc();
