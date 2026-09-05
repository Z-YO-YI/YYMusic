part of 'drift_library_repository.dart';

/// Internal implementation sharing the existing connection, lifecycle and mapper.
extension _CatalogBrowseQueries on DriftLibraryRepository {
  Future<PageResult<Track>> _browseTracks(
    CatalogTrackQuery query,
    PageRequest page,
    SearchCancellation? cancellation,
  ) {
    _searchCheckpoint(cancellation);
    return _guard('browse-tracks', () async {
      final where = _trackFilter(query.filter, 'item');
      if (query.album case final album?) {
        where.add('item.source_id = ?', album.sourceId);
        where.add('item.album_id = ?', album.albumId);
      }
      if (query.artist case final artist?) _filterArtist(where, 'item', artist);
      final rows = await _browseRows(
        table: 'tracks',
        where: where,
        page: page,
        direction: query.direction,
        sort: switch (query.sort) {
          CatalogTrackSort.title => 'lower(item.title)',
          CatalogTrackSort.artist =>
            '''(
            SELECT lower(a.name) FROM track_artists credit JOIN artists a
              ON a.source_id = credit.artist_source_id AND a.artist_id = credit.artist_id
            WHERE credit.track_source_type = item.source_type
              AND credit.track_source_id = item.source_id AND credit.track_id = item.track_id
            ORDER BY credit.position, a.source_id, a.artist_id LIMIT 1
          )''',
          CatalogTrackSort.album => 'lower(item.album_title)',
          CatalogTrackSort.duration => 'item.duration_ms',
          CatalogTrackSort.addedAt => 'item.added_at_ms',
        },
        tie: 'item.title, item.source_type, item.source_id, item.track_id',
        artistJoin: '''
          LEFT JOIN track_artists credit ON credit.track_source_type = item.source_type
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
        final artist = result.readNullable<String>('browse_artist_name');
        if (artist != null) entry.artists.add(artist);
      }
      final items = grouped.values
          .take(page.limit)
          .map((entry) => _mapper.trackFromRow(entry.row, entry.artists))
          .toList(growable: false);
      _searchCheckpoint(cancellation);
      return PageResult(items: items, hasMore: grouped.length > page.limit);
    });
  }

  Future<PageResult<Album>> _browseAlbums(
    CatalogAlbumQuery query,
    PageRequest page,
    SearchCancellation? cancellation, {
    AlbumRef? exact,
  }) {
    _searchCheckpoint(cancellation);
    return _guard('browse-albums', () async {
      final where = _BrowseWhere();
      if (exact != null) {
        where.add('item.source_id = ?', exact.sourceId);
        where.add('item.album_id = ?', exact.albumId);
      }
      if (query.filter.sourceId case final source?) {
        where.add('item.source_id = ?', source);
      }
      if (!query.filter.isAll || query.artist != null) {
        final tracks = _trackFilter(query.filter, 't');
        tracks.clauses.add(
          't.source_id = item.source_id AND t.album_id = item.album_id',
        );
        if (query.artist case final artist?) _filterArtist(tracks, 't', artist);
        where.clauses.add(
          'EXISTS (SELECT 1 FROM tracks t WHERE ${tracks.sql})',
        );
        where.variables.addAll(tracks.variables);
      }
      final rows = await _browseRows(
        table: 'albums',
        where: where,
        page: page,
        direction: query.direction,
        sort: switch (query.sort) {
          CatalogAlbumSort.title => 'lower(item.title)',
          CatalogAlbumSort.artist =>
            '''(
            SELECT lower(a.name) FROM album_artists credit JOIN artists a
              ON a.source_id = credit.artist_source_id AND a.artist_id = credit.artist_id
            WHERE credit.album_source_id = item.source_id AND credit.album_id = item.album_id
            ORDER BY credit.position, a.source_id, a.artist_id LIMIT 1
          )''',
          CatalogAlbumSort.year => 'item.year',
          CatalogAlbumSort.trackCount => 'item.track_count',
        },
        tie: 'item.title, item.source_id, item.album_id',
        artistJoin: '''
          LEFT JOIN album_artists credit ON credit.album_source_id = item.source_id
            AND credit.album_id = item.album_id
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
        final name = result.readNullable<String>('browse_artist_name');
        final id = result.readNullable<String>('browse_artist_id');
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

  Future<PageResult<Artist>> _browseArtists(
    CatalogArtistQuery query,
    PageRequest page,
    SearchCancellation? cancellation, {
    ArtistRef? exact,
  }) {
    _searchCheckpoint(cancellation);
    return _guard('browse-artists', () async {
      final where = _BrowseWhere();
      if (exact != null) {
        where.add('item.source_id = ?', exact.sourceId);
        where.add('item.artist_id = ?', exact.artistId);
      }
      if (query.filter.sourceId case final source?) {
        where.add('item.source_id = ?', source);
      }
      if (!query.filter.isAll) {
        final tracks = _trackFilter(query.filter, 't');
        tracks.clauses.add(
          'link.artist_source_id = item.source_id AND link.artist_id = item.artist_id',
        );
        where.clauses.add(
          '''EXISTS (SELECT 1 FROM tracks t JOIN track_artists link
          ON link.track_source_type = t.source_type AND link.track_source_id = t.source_id
            AND link.track_id = t.track_id WHERE ${tracks.sql})''',
        );
        where.variables.addAll(tracks.variables);
      }
      final rows = await _browseRows(
        table: 'artists',
        where: where,
        page: page,
        direction: query.direction,
        sort: switch (query.sort) {
          CatalogArtistSort.name => 'lower(item.name)',
          CatalogArtistSort.albumCount => 'item.album_count',
          CatalogArtistSort.trackCount => 'item.track_count',
        },
        tie: 'item.name, item.source_id, item.artist_id',
      );
      _searchCheckpoint(cancellation);
      final items = rows
          .take(page.limit)
          .map(
            (result) =>
                _mapper.artistFromRow(_database.artistRecords.map(result.data)),
          )
          .toList(growable: false);
      _searchCheckpoint(cancellation);
      return PageResult(items: items, hasMore: rows.length > page.limit);
    });
  }

  /// All SQL fragments are private, closed mappings above. User values are bound.
  Future<List<QueryRow>> _browseRows({
    required String table,
    required _BrowseWhere where,
    required PageRequest page,
    required CatalogDirection direction,
    required String sort,
    required String tie,
    String? artistJoin,
  }) {
    final order =
        '(item.browse_sort IS NULL) ASC, item.browse_sort '
        '${direction == CatalogDirection.ascending ? 'ASC' : 'DESC'}, $tie';
    return _database
        .customSelect(
          '''
      WITH ranked AS (SELECT item.*, $sort AS browse_sort FROM $table item WHERE ${where.sql}),
      page AS (SELECT item.* FROM ranked item ORDER BY $order LIMIT ? OFFSET ?)
      SELECT item.*${artistJoin == null ? '' : ', artist.name AS browse_artist_name, artist.artist_id AS browse_artist_id'}
      FROM page item ${artistJoin ?? ''}
      ORDER BY $order${artistJoin == null ? '' : ', credit.position, artist.source_id, artist.artist_id'}
    ''',
          variables: [
            ...where.variables,
            Variable<int>(page.limit + 1),
            Variable<int>(page.offset),
          ],
        )
        .get();
  }
}

final class _BrowseWhere {
  final clauses = <String>[];
  final variables = <Variable>[];
  String get sql => clauses.isEmpty
      ? '1'
      : clauses.map((clause) => '($clause)').join(' AND ');
  void add(String clause, String value) {
    clauses.add(clause);
    variables.add(Variable<String>(value));
  }
}

_BrowseWhere _trackFilter(CatalogFilter filter, String alias) {
  final where = _BrowseWhere();
  if (filter.sourceType case final type?) {
    where.add('$alias.source_type = ?', type.name);
  }
  if (filter.sourceId case final id?) where.add('$alias.source_id = ?', id);
  if (filter.availability.isNotEmpty) {
    final states = TrackAvailability.values
        .where(filter.availability.contains)
        .toList();
    where.clauses.add(
      '$alias.availability IN (${List.filled(states.length, '?').join(', ')})',
    );
    where.variables.addAll(states.map((state) => Variable<String>(state.name)));
  }
  return where;
}

void _filterArtist(_BrowseWhere where, String trackAlias, ArtistRef artist) {
  where.clauses.add('''EXISTS (SELECT 1 FROM track_artists artist_link
    WHERE artist_link.track_source_type = $trackAlias.source_type
      AND artist_link.track_source_id = $trackAlias.source_id AND artist_link.track_id = $trackAlias.track_id
      AND artist_link.artist_source_id = ? AND artist_link.artist_id = ?)''');
  where.variables.addAll([
    Variable<String>(artist.sourceId),
    Variable<String>(artist.artistId),
  ]);
}
