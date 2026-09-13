import '../../domain/models/domain_failure.dart';
import '../../domain/models/sleep_timer_snapshot.dart';
import '../../domain/repositories/sleep_timer_repository.dart';
import '../database/app_database.dart';
import '../sleep_timer_snapshot_codec.dart';

/// Serial access to one setting. The owning app scope closes the database.
final class DriftSleepTimerRepository implements SleepTimerRepository {
  DriftSleepTimerRepository(this._database, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  static const settingKey = 'playbackSleepTimer';
  final AppDatabase _database;
  final DateTime Function() _clock;
  Future<void> _tail = Future<void>.value();
  Future<void>? _closeFuture;
  bool _disposed = false;

  @override
  Future<SleepTimerSnapshot?> read() => _run('read', () async {
    final row = await (_database.select(
      _database.appSettingRecords,
    )..where((row) => row.settingKey.equals(settingKey))).getSingleOrNull();
    if (row == null) return null;
    try {
      return SleepTimerSnapshotCodec.decode(row.valueJson);
    } on FormatException {
      throw const _InvalidSleepRecord();
    }
  });

  @override
  Future<void> save(SleepTimerSnapshot value) => _run('save', () async {
    await _database
        .into(_database.appSettingRecords)
        .insertOnConflictUpdate(
          AppSettingRecordsCompanion.insert(
            settingKey: settingKey,
            valueJson: SleepTimerSnapshotCodec.encode(value),
            updatedAtMs: _clock().toUtc().millisecondsSinceEpoch,
          ),
        );
  });

  @override
  Future<void> clear() => _run('clear', () async {
    await (_database.delete(
      _database.appSettingRecords,
    )..where((row) => row.settingKey.equals(settingKey))).go();
  });

  Future<T> _run<T>(String operation, Future<T> Function() action) {
    if (_disposed) throw StateError('Sleep timer repository closed');
    // then is asynchronous: the tail is registered before dependency reentry.
    final result = _tail.then((_) async {
      try {
        return await action();
      } on _InvalidSleepRecord {
        throw DomainFailure(
          code: DomainFailureCode.schemaMismatch,
          diagnosticId: 'sleepTimer.$operation',
        );
      } catch (_) {
        throw DomainFailure(
          code: DomainFailureCode.databaseCorrupted,
          diagnosticId: 'sleepTimer.$operation',
          retryable: true,
        );
      }
    });
    _tail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  @override
  Future<void> dispose() {
    _disposed = true;
    return _closeFuture ??= _tail;
  }
}

final class _InvalidSleepRecord implements Exception {
  const _InvalidSleepRecord();
}
