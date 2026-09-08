part of 'drift_collection_repository.dart';

extension _PlaylistEntryCommands on DriftCollectionRepository {
  Future<void> _createWithEntry(Playlist playlist, PlaylistEntryDraft entry) {
    _requireReady();
    final name = PlaylistName.normalize(playlist.name);
    return _guard(
      'create-playlist-with-entry',
      () => _database.transaction(() async {
        await _insertCustomPlaylist(playlist, name);
        final collision = await (_database.select(
          _database.playlistEntryRecords,
        )..where((t) => t.entryId.equals(entry.id))).getSingleOrNull();
        if (collision != null) throw _forbidden('playlist-entry-id-exists');
        await _database
            .into(_database.playlistEntryRecords)
            .insert(
              _mapper.playlistEntryToCompanion(
                PlaylistEntry(
                  id: entry.id,
                  playlistId: playlist.id,
                  track: entry.track,
                  position: 0,
                  addedAt: entry.addedAt,
                ),
              ),
            );
      }),
    );
  }

  Future<void> _appendEntry(String playlistId, PlaylistEntryDraft entry) {
    _requireReady();
    DomainValidation.identifier(playlistId, 'playlistId');
    return _guard(
      'append-playlist-entry',
      () => _database.transaction(() async {
        final playlist = await _editablePlaylist(playlistId);
        final count = await _entryCount(playlistId);
        final collision = await (_database.select(
          _database.playlistEntryRecords,
        )..where((t) => t.entryId.equals(entry.id))).getSingleOrNull();
        if (collision != null) throw _forbidden('playlist-entry-id-exists');
        await _database
            .into(_database.playlistEntryRecords)
            .insert(
              _mapper.playlistEntryToCompanion(
                PlaylistEntry(
                  id: entry.id,
                  playlistId: playlistId,
                  track: entry.track,
                  position: count,
                  addedAt: entry.addedAt,
                ),
              ),
            );
        await _touchPlaylist(playlist);
      }),
    );
  }

  Future<void> _removeEntry(String playlistId, String entryId) {
    _requireReady();
    DomainValidation.identifier(playlistId, 'playlistId');
    DomainValidation.identifier(entryId, 'entryId');
    return _guard(
      'remove-playlist-entry',
      () => _database.transaction(() async {
        final playlist = await _editablePlaylist(playlistId);
        final count = await _entryCount(playlistId);
        final entry = await _scopedEntry(playlistId, entryId);
        if (entry == null) return;
        await (_database.delete(_database.playlistEntryRecords)..where(
              (t) =>
                  t.playlistId.equals(playlistId) & t.entryId.equals(entryId),
            ))
            .go();
        await _shiftPositions(
          playlistId,
          entry.position + 1,
          count - 1,
          -1,
          count,
        );
        await _touchPlaylist(playlist);
      }),
    );
  }

  Future<void> _moveEntry(
    String playlistId,
    String entryId,
    String? beforeEntryId,
  ) {
    _requireReady();
    DomainValidation.identifier(playlistId, 'playlistId');
    DomainValidation.identifier(entryId, 'entryId');
    if (beforeEntryId != null) {
      DomainValidation.identifier(beforeEntryId, 'beforeEntryId');
    }
    return _guard(
      'move-playlist-entry',
      () => _database.transaction(() async {
        final playlist = await _editablePlaylist(playlistId);
        final count = await _entryCount(playlistId);
        final entry = await _scopedEntry(playlistId, entryId);
        if (entry == null) throw _entryNotFound();
        final from = entry.position;
        int to = count - 1;
        if (beforeEntryId != null) {
          final anchor = await _scopedEntry(playlistId, beforeEntryId);
          if (anchor == null) throw _entryNotFound();
          if (anchor.entryId == entryId) return;
          to = anchor.position > from ? anchor.position - 1 : anchor.position;
        }
        if (from == to) return;
        // count is vacant; neighbours use a still higher positive range.
        await _setPosition(playlistId, entryId, count);
        if (from < to) {
          await _shiftPositions(playlistId, from + 1, to, -1, count + 1);
        } else {
          await _shiftPositions(playlistId, to, from - 1, 1, count + 1);
        }
        await _setPosition(playlistId, entryId, to);
        await _touchPlaylist(playlist);
      }),
    );
  }

  Future<PlaylistRow> _editablePlaylist(String id) async {
    final playlist = await (_database.select(
      _database.playlistRecords,
    )..where((t) => t.playlistId.equals(id))).getSingleOrNull();
    if (playlist == null) {
      throw DomainFailure(
        code: DomainFailureCode.notFound,
        diagnosticId: 'collection-repository.playlist-not-found',
      );
    }
    if (playlist.isSystem) throw _forbidden('playlist-system-entries');
    return playlist;
  }

  Future<PlaylistEntryRow?> _scopedEntry(
    String playlistId,
    String entryId,
  ) async {
    final entry = await (_database.select(
      _database.playlistEntryRecords,
    )..where((t) => t.entryId.equals(entryId))).getSingleOrNull();
    if (entry != null && entry.playlistId != playlistId) throw _entryNotFound();
    return entry;
  }

  Future<int> _entryCount(String playlistId) async {
    final row = await _database
        .customSelect(
          'SELECT COUNT(*) AS n, MAX(position) AS last FROM playlist_entries WHERE playlist_id = ?',
          variables: [Variable<String>(playlistId)],
          readsFrom: {_database.playlistEntryRecords},
        )
        .getSingle();
    final count = row.read<int>('n');
    // Unique, nonnegative positions plus max == count - 1 imply contiguity.
    if ((row.readNullable<int>('last') ?? -1) != count - 1) {
      throw _failure('playlist-entry-positions');
    }
    return count;
  }

  Future<void> _setPosition(
    String playlistId,
    String entryId,
    int position,
  ) async {
    await (_database.update(_database.playlistEntryRecords)..where(
          (t) => t.playlistId.equals(playlistId) & t.entryId.equals(entryId),
        ))
        .write(PlaylistEntryRecordsCompanion(position: Value(position)));
  }

  Future<void> _shiftPositions(
    String playlistId,
    int first,
    int last,
    int delta,
    int offset,
  ) async {
    if (first > last) return;
    // A direct +/- 1 update can violate immediate UNIQUE checks mid-statement.
    await _database.customUpdate(
      'UPDATE playlist_entries SET position = position + ? WHERE playlist_id = ? AND position BETWEEN ? AND ?',
      variables: [
        Variable<int>(offset),
        Variable<String>(playlistId),
        Variable<int>(first),
        Variable<int>(last),
      ],
      updates: {_database.playlistEntryRecords},
    );
    await _database.customUpdate(
      'UPDATE playlist_entries SET position = position - ? + ? WHERE playlist_id = ? AND position BETWEEN ? AND ?',
      variables: [
        Variable<int>(offset),
        Variable<int>(delta),
        Variable<String>(playlistId),
        Variable<int>(first + offset),
        Variable<int>(last + offset),
      ],
      updates: {_database.playlistEntryRecords},
    );
  }

  Future<void> _touchPlaylist(PlaylistRow playlist) async {
    final now = _clock().toUtc().millisecondsSinceEpoch;
    await (_database.update(
      _database.playlistRecords,
    )..where((t) => t.playlistId.equals(playlist.playlistId))).write(
      PlaylistRecordsCompanion(
        updatedAtMs: Value(
          now < playlist.updatedAtMs ? playlist.updatedAtMs : now,
        ),
      ),
    );
  }

  DomainFailure _entryNotFound() => DomainFailure(
    code: DomainFailureCode.notFound,
    diagnosticId: 'collection-repository.playlist-entry-not-found',
  );
}
