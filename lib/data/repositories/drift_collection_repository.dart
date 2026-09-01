import 'dart:async';

import 'package:drift/drift.dart';

import '../../domain/models/collection_models.dart';
import '../../domain/models/domain_failure.dart';
import '../../domain/models/domain_validation.dart';
import '../../domain/models/track.dart';
import '../../domain/repositories/collection_repository.dart';
import '../database/app_database.dart';
import 'collection_row_mapper.dart';

final class DriftCollectionRepository implements CollectionRepository {
  factory DriftCollectionRepository(
    AppDatabase database, {
    bool closeDatabaseOnDispose = false,
    CollectionRowMapper mapper = const CollectionRowMapper(),
    DateTime Function()? clock,
  }) => DriftCollectionRepository._(
    database,
    closeDatabaseOnDispose,
    mapper,
    clock ?? _utcNow,
  );

  factory DriftCollectionRepository.owned(
    AppDatabase database, {
    CollectionRowMapper mapper = const CollectionRowMapper(),
    DateTime Function()? clock,
  }) => DriftCollectionRepository._(database, true, mapper, clock ?? _utcNow);

  DriftCollectionRepository._(
    this._database,
    this._closeDatabaseOnDispose,
    this._mapper,
    this._clock,
  );

  final AppDatabase _database;
  final bool _closeDatabaseOnDispose;
  final CollectionRowMapper _mapper;
  final DateTime Function() _clock;

  bool _disposed = false;

  @override
  Stream<List<Playlist>> watchPlaylists() {
    _requireReady();
    final query = _database.select(_database.playlistRecords);
    return query
        .watch()
        .map(_playlistsFromRows)
        .transform(
          StreamTransformer.fromHandlers(
            handleError: (Object error, StackTrace stackTrace, sink) {
              sink.addError(_failureFor(error, 'watch-playlists'), stackTrace);
            },
          ),
        );
  }

  @override
  Future<Playlist?> getPlaylist(String id) {
    _requireReady();
    final playlistId = DomainValidation.identifier(id, 'id');
    return _guard('get-playlist', () async {
      final query = _database.select(_database.playlistRecords)
        ..where((table) => table.playlistId.equals(playlistId));
      final row = await query.getSingleOrNull();
      return row == null ? null : _mapper.playlistFromRow(row);
    });
  }

  @override
  Future<void> savePlaylist(Playlist playlist) {
    _requireReady();
    return _guard('save-playlist', () async {
      await _database.transaction(() async {
        final existingQuery = _database.select(_database.playlistRecords)
          ..where((table) => table.playlistId.equals(playlist.id));
        final existing = await existingQuery.getSingleOrNull();
        if (existing != null &&
            (existing.isSystem != playlist.isSystem ||
                existing.systemType != playlist.systemType?.name)) {
          throw _forbidden('playlist-system-identity');
        }
        if (playlist.isSystem) {
          final sameTypeQuery = _database.select(_database.playlistRecords)
            ..where(
              (table) => table.systemType.equals(playlist.systemType!.name),
            );
          final sameType = await sameTypeQuery.get();
          if (sameType.any((row) => row.playlistId != playlist.id)) {
            throw _forbidden('playlist-system-duplicate');
          }
        }
        await _database
            .into(_database.playlistRecords)
            .insertOnConflictUpdate(_mapper.playlistToCompanion(playlist));
      });
    });
  }

  @override
  Future<void> deletePlaylist(String id) {
    _requireReady();
    final playlistId = DomainValidation.identifier(id, 'id');
    return _guard('delete-playlist', () async {
      await _database.transaction(() async {
        final query = _database.select(_database.playlistRecords)
          ..where((table) => table.playlistId.equals(playlistId));
        final row = await query.getSingleOrNull();
        if (row == null) return;
        if (row.isSystem) throw _forbidden('playlist-system-delete');
        await (_database.delete(
          _database.playlistRecords,
        )..where((table) => table.playlistId.equals(playlistId))).go();
      });
    });
  }

  @override
  Future<List<PlaylistEntry>> getPlaylistEntries(String playlistId) {
    _requireReady();
    final safeId = DomainValidation.identifier(playlistId, 'playlistId');
    return _guard('get-playlist-entries', () async {
      final query = _database.select(_database.playlistEntryRecords)
        ..where((table) => table.playlistId.equals(safeId))
        ..orderBy([
          (table) => OrderingTerm(expression: table.position),
          (table) => OrderingTerm(expression: table.entryId),
        ]);
      final rows = await query.get();
      return _validatePlaylistEntries(
        safeId,
        rows.map(_mapper.playlistEntryFromRow),
      );
    });
  }

  @override
  Future<void> replacePlaylistEntries(
    String playlistId,
    Iterable<PlaylistEntry> entries,
  ) {
    _requireReady();
    final safeId = DomainValidation.identifier(playlistId, 'playlistId');
    final copy = _validatePlaylistEntries(safeId, entries);
    return _guard('replace-playlist-entries', () async {
      await _database.transaction(() async {
        final playlistQuery = _database.select(_database.playlistRecords)
          ..where((table) => table.playlistId.equals(safeId));
        if (await playlistQuery.getSingleOrNull() == null) {
          throw DomainFailure(
            code: DomainFailureCode.notFound,
            diagnosticId: 'collection-playlist.not-found',
          );
        }
        await (_database.delete(
          _database.playlistEntryRecords,
        )..where((table) => table.playlistId.equals(safeId))).go();
        if (copy.isNotEmpty) {
          await _database.batch((batch) {
            batch.insertAll(
              _database.playlistEntryRecords,
              copy.map(_mapper.playlistEntryToCompanion),
            );
          });
        }
      });
    });
  }

  @override
  Stream<QueueSnapshot> watchQueue() {
    _requireReady();
    return _queueQuery()
        .watch()
        .map(_queueFromRows)
        .transform(
          StreamTransformer.fromHandlers(
            handleError: (Object error, StackTrace stackTrace, sink) {
              sink.addError(_failureFor(error, 'watch-queue'), stackTrace);
            },
          ),
        );
  }

  @override
  Future<QueueSnapshot> loadQueue() {
    _requireReady();
    return _guard(
      'load-queue',
      () async => _queueFromRows(await _queueQuery().get()),
    );
  }

  @override
  Future<void> saveQueue(QueueSnapshot snapshot) {
    _requireReady();
    return _guard('save-queue', () async {
      await _database.transaction(() async {
        final clearCurrent = _database.update(_database.queueStateRecords)
          ..where((table) => table.singletonId.equals(1));
        if (await clearCurrent.write(
              const QueueStateRecordsCompanion(currentEntryId: Value(null)),
            ) !=
            1) {
          throw _failure('queue-state-missing');
        }
        await _database.delete(_database.queueEntryRecords).go();
        if (snapshot.entries.isNotEmpty) {
          await _database.batch((batch) {
            batch.insertAll(
              _database.queueEntryRecords,
              snapshot.entries.map(_mapper.queueEntryToCompanion),
            );
          });
        }
        final updateState = _database.update(_database.queueStateRecords)
          ..where((table) => table.singletonId.equals(1));
        if (await updateState.write(
              QueueStateRecordsCompanion(
                currentEntryId: Value(snapshot.currentEntryId),
                updatedAtMs: Value(snapshot.updatedAt.millisecondsSinceEpoch),
              ),
            ) !=
            1) {
          throw _failure('queue-state-missing');
        }
      });
    });
  }

  @override
  Stream<List<FavoriteEntry>> watchFavorites() {
    _requireReady();
    final query = _database.select(_database.favoriteRecords)
      ..orderBy([
        (table) =>
            OrderingTerm(expression: table.addedAtMs, mode: OrderingMode.desc),
        (table) => OrderingTerm(expression: table.trackSourceType),
        (table) => OrderingTerm(expression: table.trackSourceId),
        (table) => OrderingTerm(expression: table.trackId),
      ]);
    return query
        .watch()
        .map(
          (rows) => List<FavoriteEntry>.unmodifiable(
            rows.map(_mapper.favoriteFromRow),
          ),
        )
        .transform(
          StreamTransformer.fromHandlers(
            handleError: (Object error, StackTrace stackTrace, sink) {
              sink.addError(_failureFor(error, 'watch-favorites'), stackTrace);
            },
          ),
        );
  }

  @override
  Future<void> setFavorite(TrackRef track, {required bool favorite}) {
    _requireReady();
    return _guard('set-favorite', () async {
      await _database.transaction(() async {
        final delete = _database.delete(_database.favoriteRecords)
          ..where(
            (table) =>
                table.trackSourceType.equals(track.sourceType.name) &
                table.trackSourceId.equals(track.sourceId) &
                table.trackId.equals(track.trackId),
          );
        await delete.go();
        if (favorite) {
          await _database
              .into(_database.favoriteRecords)
              .insert(_mapper.favoriteToCompanion(track, _clock().toUtc()));
        }
      });
    });
  }

  @override
  Stream<List<PlayHistoryEntry>> watchHistory() {
    _requireReady();
    final query = _database.select(_database.playHistoryRecords)
      ..orderBy([
        (table) => OrderingTerm(
          expression: table.startedAtMs,
          mode: OrderingMode.desc,
        ),
        (table) => OrderingTerm(expression: table.historyId),
      ])
      ..limit(20);
    return query
        .watch()
        .map(_historyFromRows)
        .transform(
          StreamTransformer.fromHandlers(
            handleError: (Object error, StackTrace stackTrace, sink) {
              sink.addError(_failureFor(error, 'watch-history'), stackTrace);
            },
          ),
        );
  }

  @override
  Future<void> recordHistory(PlayHistoryEntry entry) {
    _requireReady();
    return _guard('record-history', () async {
      await _database.transaction(() async {
        await (_database.delete(_database.playHistoryRecords)..where(
              (table) =>
                  table.trackSourceType.equals(entry.track.sourceType.name) &
                  table.trackSourceId.equals(entry.track.sourceId) &
                  table.trackId.equals(entry.track.trackId),
            ))
            .go();
        await _database
            .into(_database.playHistoryRecords)
            .insertOnConflictUpdate(_mapper.historyToCompanion(entry));

        final ordered =
            await (_database.select(_database.playHistoryRecords)..orderBy([
                  (table) => OrderingTerm(
                    expression: table.startedAtMs,
                    mode: OrderingMode.desc,
                  ),
                  (table) => OrderingTerm(expression: table.historyId),
                ]))
                .get();
        final expired = ordered.skip(20).map((row) => row.historyId).toList();
        if (expired.isNotEmpty) {
          await (_database.delete(
            _database.playHistoryRecords,
          )..where((table) => table.historyId.isIn(expired))).go();
        }
      });
    });
  }

  @override
  Future<void> clearHistory() {
    _requireReady();
    return _guard(
      'clear-history',
      () async => _database.delete(_database.playHistoryRecords).go(),
    );
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    if (_closeDatabaseOnDispose) await _database.close();
  }

  Selectable<QueryRow> _queueQuery() => _database.customSelect(
    '''
      SELECT
        queue_state.current_entry_id,
        queue_state.updated_at_ms,
        queue_entries.entry_id,
        queue_entries.track_source_type,
        queue_entries.track_source_id,
        queue_entries.track_id,
        queue_entries.position,
        queue_entries.added_at_ms
      FROM queue_state
      LEFT JOIN queue_entries ON 1 = 1
      WHERE queue_state.singleton_id = 1
      ORDER BY queue_entries.position, queue_entries.entry_id
    ''',
    readsFrom: {_database.queueStateRecords, _database.queueEntryRecords},
  );

  QueueSnapshot _queueFromRows(List<QueryRow> rows) {
    try {
      if (rows.isEmpty) throw const FormatException('Missing queue state');
      final currentEntryId = rows.first.readNullable<String>(
        'current_entry_id',
      );
      final updatedAtMs = rows.first.read<int>('updated_at_ms');
      final entries = <QueueEntry>[];
      for (final row in rows) {
        if (row.read<int>('updated_at_ms') != updatedAtMs ||
            row.readNullable<String>('current_entry_id') != currentEntryId) {
          throw const FormatException('Inconsistent queue state');
        }
        final entryId = row.readNullable<String>('entry_id');
        if (entryId == null) continue;
        entries.add(
          _mapper.queueEntryFromValues(
            id: entryId,
            sourceType: row.read<String>('track_source_type'),
            sourceId: row.read<String>('track_source_id'),
            trackId: row.read<String>('track_id'),
            position: row.read<int>('position'),
            addedAtMs: row.read<int>('added_at_ms'),
          ),
        );
      }
      return QueueSnapshot(
        entries: entries,
        currentEntryId: currentEntryId,
        updatedAt: DateTime.fromMillisecondsSinceEpoch(
          updatedAtMs,
          isUtc: true,
        ),
      );
    } on DomainFailure {
      rethrow;
    } catch (_) {
      throw _failure('queue-decode');
    }
  }

  List<Playlist> _playlistsFromRows(List<PlaylistRow> rows) {
    final playlists = rows.map(_mapper.playlistFromRow).toList();
    final systemTypes = <SystemPlaylistType>{};
    for (final playlist in playlists) {
      if (playlist.isSystem && !systemTypes.add(playlist.systemType!)) {
        throw _failure('playlist-system-duplicate');
      }
    }
    playlists.sort(_comparePlaylists);
    return List<Playlist>.unmodifiable(playlists);
  }

  List<PlayHistoryEntry> _historyFromRows(List<PlayHistoryRow> rows) {
    final history = rows.map(_mapper.historyFromRow).toList();
    final tracks = <TrackRef>{};
    for (final entry in history) {
      if (!tracks.add(entry.track)) throw _failure('history-duplicate');
    }
    return List<PlayHistoryEntry>.unmodifiable(history);
  }

  List<PlaylistEntry> _validatePlaylistEntries(
    String playlistId,
    Iterable<PlaylistEntry> entries,
  ) {
    final copy = List<PlaylistEntry>.unmodifiable(entries);
    final ids = <String>{};
    for (var index = 0; index < copy.length; index++) {
      final entry = copy[index];
      if (entry.playlistId != playlistId) {
        throw ArgumentError('Playlist entries belong to another playlist');
      }
      if (!ids.add(entry.id)) {
        throw ArgumentError('Playlist entry IDs must be unique');
      }
      if (entry.position != index) {
        throw ArgumentError(
          'Playlist entries must be sorted with contiguous positions',
        );
      }
    }
    return copy;
  }

  Future<T> _guard<T>(String operation, Future<T> Function() body) async {
    try {
      return await body();
    } on DomainFailure {
      rethrow;
    } catch (_) {
      throw _failure(operation);
    }
  }

  DomainFailure _failureFor(Object error, String operation) =>
      error is DomainFailure ? error : _failure(operation);

  DomainFailure _failure(String operation) => DomainFailure(
    code: DomainFailureCode.databaseCorrupted,
    diagnosticId: 'collection-repository.$operation',
  );

  DomainFailure _forbidden(String operation) => DomainFailure(
    code: DomainFailureCode.forbidden,
    diagnosticId: 'collection-repository.$operation',
  );

  void _requireReady() {
    if (_disposed) throw StateError('CollectionRepository is disposed');
  }
}

DateTime _utcNow() => DateTime.now().toUtc();

int _comparePlaylists(Playlist left, Playlist right) {
  if (left.isSystem != right.isSystem) return left.isSystem ? -1 : 1;
  if (left.isSystem) {
    final typeComparison = left.systemType!.index.compareTo(
      right.systemType!.index,
    );
    if (typeComparison != 0) return typeComparison;
  }
  final updatedComparison = right.updatedAt.compareTo(left.updatedAt);
  if (updatedComparison != 0) return updatedComparison;
  final nameComparison = left.name.compareTo(right.name);
  return nameComparison == 0 ? left.id.compareTo(right.id) : nameComparison;
}
