import 'dart:async';

import 'package:drift/drift.dart';

import '../../domain/models/domain_failure.dart';
import '../../domain/models/domain_validation.dart';
import '../../domain/models/music_source.dart';
import '../../domain/repositories/music_source_repository.dart';
import '../database/app_database.dart';
import 'music_source_row_mapper.dart';

final class DriftMusicSourceRepository implements MusicSourceRepository {
  factory DriftMusicSourceRepository(
    AppDatabase database, {
    bool closeDatabaseOnDispose = false,
    MusicSourceRowMapper mapper = const MusicSourceRowMapper(),
  }) => DriftMusicSourceRepository._(database, closeDatabaseOnDispose, mapper);

  factory DriftMusicSourceRepository.owned(
    AppDatabase database, {
    MusicSourceRowMapper mapper = const MusicSourceRowMapper(),
  }) => DriftMusicSourceRepository._(database, true, mapper);

  DriftMusicSourceRepository._(
    this._database,
    this._closeDatabaseOnDispose,
    this._mapper,
  );

  final AppDatabase _database;
  final bool _closeDatabaseOnDispose;
  final MusicSourceRowMapper _mapper;

  bool _disposed = false;

  @override
  Stream<List<MusicSourceConfig>> watchSources() {
    _requireReady();
    final query = _database.select(_database.musicSourceRecords)
      ..orderBy([(table) => OrderingTerm(expression: table.sourceId)]);
    return query
        .watch()
        .map(
          (rows) =>
              List<MusicSourceConfig>.unmodifiable(rows.map(_mapper.fromRow)),
        )
        .transform(
          StreamTransformer.fromHandlers(
            handleError: (Object error, StackTrace stackTrace, sink) {
              sink.addError(_failureFor(error, 'watch'), stackTrace);
            },
          ),
        );
  }

  @override
  Future<MusicSourceConfig?> getSource(String id) {
    _requireReady();
    final sourceId = DomainValidation.identifier(id, 'id');
    return _guard('get', () async {
      final query = _database.select(_database.musicSourceRecords)
        ..where((table) => table.sourceId.equals(sourceId));
      final row = await query.getSingleOrNull();
      return row == null ? null : _mapper.fromRow(row);
    });
  }

  @override
  Future<void> saveSource(MusicSourceConfig source) {
    _requireReady();
    return _guard('save', () async {
      await _database.transaction(() async {
        final query = _database.select(_database.musicSourceRecords)
          ..where((table) => table.sourceId.equals(source.id));
        final existing = await query.getSingleOrNull();
        final existingSource = existing == null
            ? null
            : _mapper.fromRow(existing);
        if (existingSource != null &&
            (existingSource.type != source.type ||
                existingSource.builtIn != source.builtIn)) {
          throw _forbidden('identity');
        }
        await _database
            .into(_database.musicSourceRecords)
            .insertOnConflictUpdate(_mapper.toCompanion(source));
      });
    });
  }

  @override
  Future<void> deleteSource(String id) {
    _requireReady();
    final sourceId = DomainValidation.identifier(id, 'id');
    return _guard('delete', () async {
      await _database.transaction(() async {
        final query = _database.select(_database.musicSourceRecords)
          ..where((table) => table.sourceId.equals(sourceId));
        final existing = await query.getSingleOrNull();
        if (existing == null) return;
        if (_mapper.fromRow(existing).builtIn) {
          throw _forbidden('built-in-delete');
        }
        await (_database.delete(
          _database.musicSourceRecords,
        )..where((table) => table.sourceId.equals(sourceId))).go();
      });
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

  DomainFailure _failureFor(Object error, String operation) =>
      error is DomainFailure ? error : _failure(operation);

  DomainFailure _failure(String operation) => DomainFailure(
    code: DomainFailureCode.databaseCorrupted,
    diagnosticId: 'music-source-repository.$operation',
  );

  DomainFailure _forbidden(String operation) => DomainFailure(
    code: DomainFailureCode.forbidden,
    diagnosticId: 'music-source-repository.$operation',
  );

  void _requireReady() {
    if (_disposed) throw StateError('MusicSourceRepository is disposed');
  }
}
