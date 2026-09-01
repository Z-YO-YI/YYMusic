import 'package:drift/drift.dart';

import '../../domain/models/domain_failure.dart';
import '../../domain/models/lyrics.dart';
import '../../domain/models/track.dart';
import '../../domain/repositories/lyrics_repository.dart';
import '../database/app_database.dart';
import 'lyrics_row_mapper.dart';

final class DriftLyricsRepository implements LyricsRepository {
  factory DriftLyricsRepository(
    AppDatabase database, {
    bool closeDatabaseOnDispose = false,
    LyricsRowMapper mapper = const LyricsRowMapper(),
    DateTime Function()? clock,
  }) => DriftLyricsRepository._(
    database,
    closeDatabaseOnDispose,
    mapper,
    clock ?? _utcNow,
  );

  factory DriftLyricsRepository.owned(
    AppDatabase database, {
    LyricsRowMapper mapper = const LyricsRowMapper(),
    DateTime Function()? clock,
  }) => DriftLyricsRepository._(database, true, mapper, clock ?? _utcNow);

  DriftLyricsRepository._(
    this._database,
    this._closeDatabaseOnDispose,
    this._mapper,
    this._clock,
  );

  final AppDatabase _database;
  final bool _closeDatabaseOnDispose;
  final LyricsRowMapper _mapper;
  final DateTime Function() _clock;

  bool _disposed = false;

  @override
  Future<LyricsDocument?> getLyrics(TrackRef track) {
    _requireReady();
    return _guard('get', () async {
      final query = _database.select(_database.lyricsCacheRecords)
        ..where(
          (table) =>
              table.trackSourceType.equals(track.sourceType.name) &
              table.trackSourceId.equals(track.sourceId) &
              table.trackId.equals(track.trackId),
        );
      final row = await query.getSingleOrNull();
      return row == null ? null : _mapper.fromRow(row);
    });
  }

  @override
  Future<void> saveLyrics(LyricsDocument document) {
    _requireReady();
    return _guard('save', () async {
      await _database
          .into(_database.lyricsCacheRecords)
          .insertOnConflictUpdate(
            _mapper.toCompanion(document, updatedAt: _clock().toUtc()),
          );
    });
  }

  @override
  Future<void> removeLyrics(TrackRef track) {
    _requireReady();
    return _guard('remove', () async {
      await (_database.delete(_database.lyricsCacheRecords)..where(
            (table) =>
                table.trackSourceType.equals(track.sourceType.name) &
                table.trackSourceId.equals(track.sourceId) &
                table.trackId.equals(track.trackId),
          ))
          .go();
    });
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    if (_closeDatabaseOnDispose) await _database.close();
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

  DomainFailure _failure(String operation) => DomainFailure(
    code: DomainFailureCode.databaseCorrupted,
    diagnosticId: 'lyrics-repository.$operation',
  );

  void _requireReady() {
    if (_disposed) throw StateError('LyricsRepository is disposed');
  }
}

DateTime _utcNow() => DateTime.now().toUtc();
