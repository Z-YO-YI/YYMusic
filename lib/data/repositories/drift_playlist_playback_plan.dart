part of 'drift_collection_repository.dart';

extension _PlaylistPlaybackRead on DriftCollectionRepository {
  Future<PlaylistPlaybackPlan?> _readPlaybackPlan(String playlistId) {
    _requireReady();
    DomainValidation.identifier(playlistId, 'playlistId');
    return _guard('read-playlist-playback-plan', () async {
      final rows = await _database
          .customSelect(
            '''
        SELECT p.playlist_id, p.is_system, e.entry_id, e.position,
          e.track_source_type, e.track_source_id, e.track_id,
          t.availability
        FROM playlists p
        LEFT JOIN playlist_entries e ON e.playlist_id = p.playlist_id
        LEFT JOIN tracks t ON t.source_type = e.track_source_type
          AND t.source_id = e.track_source_id AND t.track_id = e.track_id
        WHERE p.playlist_id = ?
        ORDER BY e.position, e.entry_id
      ''',
            variables: [Variable<String>(playlistId)],
          )
          .get();
      if (rows.isEmpty) return null;
      if (rows.first.read<int>('is_system') != 0) {
        throw _forbidden('playlist-system-playback');
      }
      return PlaylistPlaybackPlan(
        playlistId: rows.first.read<String>('playlist_id'),
        entries: [
          for (final row in rows)
            if (row.readNullable<String>('entry_id') case final id?)
              PlaylistPlaybackEntry(
                id: id,
                position: row.read<int>('position'),
                track: _mapper.trackRef(
                  sourceType: row.read<String>('track_source_type'),
                  sourceId: row.read<String>('track_source_id'),
                  trackId: row.read<String>('track_id'),
                ),
                availability: row.readNullable<String>('availability') == null
                    ? null
                    : TrackAvailability.values.byName(
                        row.read<String>('availability'),
                      ),
              ),
        ],
      );
    });
  }
}
