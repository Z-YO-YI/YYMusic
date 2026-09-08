part of 'drift_collection_repository.dart';

extension _SystemPlaylistRead on DriftCollectionRepository {
  Future<SystemPlaylistContent> _readSystemContent(
    SystemPlaylistType type,
    PageRequest page,
  ) {
    _requireReady();
    // SQL fragments are selected only from this closed enum, never user text.
    final source = switch (type) {
      SystemPlaylistType.favorites =>
        '''
        SELECT NULL AS entry_id, track_source_type, track_source_id, track_id,
          added_at_ms, ROW_NUMBER() OVER (ORDER BY added_at_ms DESC,
            track_source_type, track_source_id, track_id) - 1 AS position
        FROM favorites
      ''',
      SystemPlaylistType.recent =>
        '''
        SELECT history_id AS entry_id, track_source_type, track_source_id, track_id,
          started_at_ms AS added_at_ms,
          ROW_NUMBER() OVER (ORDER BY started_at_ms DESC, history_id) - 1 AS position
        FROM play_history ORDER BY started_at_ms DESC, history_id LIMIT 20
      ''',
      SystemPlaylistType.queue => 'SELECT * FROM queue_entries',
    };
    final state = type == SystemPlaylistType.queue
        ? '''
      SELECT (SELECT current_entry_id FROM queue_state WHERE singleton_id = 1) AS current_id,
        (SELECT COUNT(*) FROM queue_state WHERE singleton_id = 1) AS state_count
    '''
        : 'SELECT NULL AS current_id, 1 AS state_count';
    return _guard('read-system-playlist', () async {
      final rows = await _database
          .customSelect(
            '''
        WITH source AS ($source), state AS ($state),
        totals AS (SELECT COUNT(*) AS n, MIN(position) AS first, MAX(position) AS last FROM source),
        page AS (SELECT * FROM source ORDER BY position LIMIT ? OFFSET ?)
        SELECT totals.n AS system_count, totals.first AS system_first, totals.last AS system_last,
          state.current_id, state.state_count,
          (state.current_id IS NULL OR EXISTS
            (SELECT 1 FROM source WHERE entry_id = state.current_id)) AS current_valid,
          e.entry_id AS system_entry_id, e.position AS system_position,
          e.track_source_type AS ref_type, e.track_source_id AS ref_source,
          e.track_id AS ref_id, e.added_at_ms AS system_added_at,
          t.*, artist.name AS system_artist_name
        FROM totals CROSS JOIN state
        LEFT JOIN page e ON 1 = 1
        LEFT JOIN tracks t ON t.source_type = e.track_source_type
          AND t.source_id = e.track_source_id AND t.track_id = e.track_id
        LEFT JOIN track_artists credit ON credit.track_source_type = t.source_type
          AND credit.track_source_id = t.source_id AND credit.track_id = t.track_id
        LEFT JOIN artists artist ON artist.source_id = credit.artist_source_id
          AND artist.artist_id = credit.artist_id
        ORDER BY e.position, credit.position
      ''',
            variables: [Variable<int>(page.limit), Variable<int>(page.offset)],
          )
          .get();
      final first = rows.first;
      final count = first.read<int>('system_count');
      if ((first.readNullable<int>('system_first') ?? 0) != 0 ||
          (first.readNullable<int>('system_last') ?? -1) != count - 1 ||
          first.read<int>('state_count') != 1 ||
          first.read<int>('current_valid') != 1) {
        throw _failure('system-playlist-state');
      }
      final groups = <int, _JoinedSystemEntry>{};
      for (final row in rows) {
        final position = row.readNullable<int>('system_position');
        if (position == null) continue;
        final group = groups.putIfAbsent(
          position,
          () => _JoinedSystemEntry(row),
        );
        final name = row.readNullable<String>('system_artist_name');
        if (name != null) group.artists.add(name);
      }
      return SystemPlaylistContent(
        type: type,
        page: page,
        totalCount: count,
        currentQueueEntryId: first.readNullable<String>('current_id'),
        entries: groups.entries.map((group) {
          final row = group.value.row;
          return SystemPlaylistEntry(
            reference: _mapper.trackRef(
              sourceType: row.read<String>('ref_type'),
              sourceId: row.read<String>('ref_source'),
              trackId: row.read<String>('ref_id'),
            ),
            position: group.key,
            addedAt: DateTime.fromMillisecondsSinceEpoch(
              row.read<int>('system_added_at'),
              isUtc: true,
            ),
            entryId: row.readNullable<String>('system_entry_id'),
            track: row.readNullable<String>('track_id') == null
                ? null
                : const LibraryRowMapper().trackFromRow(
                    _database.trackRecords.map(row.data),
                    group.value.artists,
                  ),
          );
        }),
      );
    });
  }

  Stream<void> _watchSystemChanges(SystemPlaylistType type) {
    _requireReady();
    return _database
        .tableUpdates(
          TableUpdateQuery.onAllTables([
            _database.trackRecords,
            _database.trackArtistRecords,
            _database.artistRecords,
            if (type == SystemPlaylistType.favorites) _database.favoriteRecords,
            if (type == SystemPlaylistType.recent) _database.playHistoryRecords,
            if (type == SystemPlaylistType.queue) ...[
              _database.queueEntryRecords,
              _database.queueStateRecords,
            ],
          ]),
        )
        .map<void>((_) {})
        .transform(
          StreamTransformer.fromHandlers(
            handleError: (Object error, StackTrace stack, sink) {
              sink.addError(
                _failureFor(error, 'system-playlist-changes'),
                stack,
              );
            },
          ),
        );
  }
}

final class _JoinedSystemEntry {
  _JoinedSystemEntry(this.row);
  final QueryRow row;
  final artists = <String>[];
}
