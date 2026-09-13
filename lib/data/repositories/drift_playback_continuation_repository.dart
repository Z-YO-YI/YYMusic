import '../../domain/models/domain_failure.dart';
import '../../domain/repositories/playback_continuation_repository.dart';
import '../database/app_database.dart';
import '../playback_continuation_codec.dart';

/// One app setting in the existing table; the application owns the connection.
final class DriftPlaybackContinuationRepository
    implements PlaybackContinuationRepository {
  DriftPlaybackContinuationRepository(
    this._database, {
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  static const settingKey = 'playbackContinueAfterTrack';
  final AppDatabase _database;
  final DateTime Function() _clock;
  Future<void> _tail = Future<void>.value();
  Future<void>? _closing;
  bool _closed = false;

  @override
  Future<bool?> read() => _run('read', () async {
    final row = await (_database.select(
      _database.appSettingRecords,
    )..where((row) => row.settingKey.equals(settingKey))).getSingleOrNull();
    if (row == null) return null;
    try {
      return PlaybackContinuationCodec.decode(row.valueJson);
    } on FormatException {
      throw const _InvalidRecord();
    }
  });

  @override
  Future<void> save(bool enabled) => _run('save', () async {
    await _database
        .into(_database.appSettingRecords)
        .insertOnConflictUpdate(
          AppSettingRecordsCompanion.insert(
            settingKey: settingKey,
            valueJson: PlaybackContinuationCodec.encode(enabled),
            updatedAtMs: _clock().toUtc().millisecondsSinceEpoch,
          ),
        );
  });

  Future<T> _run<T>(String operation, Future<T> Function() action) {
    if (_closed) throw StateError('Playback continuation repository closed');
    final result = _tail.then((_) async {
      try {
        return await action();
      } on _InvalidRecord {
        throw DomainFailure(
          code: DomainFailureCode.schemaMismatch,
          diagnosticId: 'playback-continuation.$operation',
        );
      } catch (_) {
        throw DomainFailure(
          code: DomainFailureCode.databaseCorrupted,
          diagnosticId: 'playback-continuation.$operation',
          retryable: true,
        );
      }
    });
    // Preserve operation failures for their callers without poisoning later work.
    _tail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  @override
  Future<void> dispose() {
    _closed = true;
    return _closing ??= _tail;
  }
}

final class _InvalidRecord implements Exception {
  const _InvalidRecord();
}
