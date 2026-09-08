part of 'drift_collection_repository.dart';

extension _PlaylistContentRead on DriftCollectionRepository {
  Future<PlaylistContent?> _readContent(String playlistId, PageRequest page) {
    _requireReady();
    DomainValidation.identifier(playlistId, 'playlistId');
    return _guard('read-playlist-content', () async {
      // Page entries BEFORE artist fan-out. All values, including paging, are bound.
      final rows = await _database
          .customSelect(
            '''
        WITH target AS (SELECT * FROM playlists WHERE playlist_id = ?),
        totals AS (
          SELECT COUNT(*) AS n, MAX(e.position) AS last
          FROM playlist_entries e JOIN target p ON p.playlist_id = e.playlist_id
        ),
        page AS (
          SELECT e.* FROM playlist_entries e JOIN target p ON p.playlist_id = e.playlist_id
          ORDER BY e.position, e.entry_id LIMIT ? OFFSET ?
        )
        SELECT p.*, totals.n AS content_count, totals.last AS content_last,
          e.entry_id, e.track_source_type, e.track_source_id,
          e.track_id AS entry_track_id, e.position AS entry_position,
          e.added_at_ms AS entry_added_at_ms,
          t.*, artist.name AS content_artist_name
        FROM target p CROSS JOIN totals
        LEFT JOIN page e ON e.playlist_id = p.playlist_id
        LEFT JOIN tracks t ON t.source_type = e.track_source_type
          AND t.source_id = e.track_source_id AND t.track_id = e.track_id
        LEFT JOIN track_artists credit ON credit.track_source_type = t.source_type
          AND credit.track_source_id = t.source_id AND credit.track_id = t.track_id
        LEFT JOIN artists artist ON artist.source_id = credit.artist_source_id
          AND artist.artist_id = credit.artist_id
        ORDER BY e.position, e.entry_id, credit.position
      ''',
            variables: [
              Variable<String>(playlistId),
              Variable<int>(page.limit),
              Variable<int>(page.offset),
            ],
          )
          .get();
      if (rows.isEmpty) return null;
      final playlist = _mapper.playlistFromRow(
        _database.playlistRecords.map(rows.first.data),
      );
      if (playlist.isSystem) throw _forbidden('playlist-system-content');
      final count = rows.first.read<int>('content_count');
      if ((rows.first.readNullable<int>('content_last') ?? -1) != count - 1) {
        throw _failure('playlist-entry-positions');
      }
      final entries = <String, _JoinedPlaylistEntry>{};
      for (final row in rows) {
        final id = row.readNullable<String>('entry_id');
        if (id == null) continue;
        final group = entries.putIfAbsent(
          id,
          () => _JoinedPlaylistEntry(
            _mapper.playlistEntryFromRow(
              PlaylistEntryRow(
                entryId: id,
                playlistId: playlist.id,
                trackSourceType: row.read<String>('track_source_type'),
                trackSourceId: row.read<String>('track_source_id'),
                trackId: row.read<String>('entry_track_id'),
                position: row.read<int>('entry_position'),
                addedAtMs: row.read<int>('entry_added_at_ms'),
              ),
            ),
            row.readNullable<String>('track_id') == null
                ? null
                : _database.trackRecords.map(row.data),
          ),
        );
        final artist = row.readNullable<String>('content_artist_name');
        if (artist != null) group.artists.add(artist);
      }
      return PlaylistContent(
        playlist: playlist,
        page: page,
        totalCount: count,
        entries: entries.values.map(
          (group) => PlaylistContentEntry(
            entry: group.entry,
            track: group.track == null
                ? null
                : const LibraryRowMapper().trackFromRow(
                    group.track!,
                    group.artists,
                  ),
          ),
        ),
      );
    });
  }
}

final class _JoinedPlaylistEntry {
  _JoinedPlaylistEntry(this.entry, this.track);
  final PlaylistEntry entry;
  final TrackRow? track;
  final artists = <String>[];
}
