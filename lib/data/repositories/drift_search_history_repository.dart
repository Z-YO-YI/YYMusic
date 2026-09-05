import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';

import '../../domain/models/catalog_search.dart';
import '../../domain/models/domain_failure.dart';
import '../../domain/repositories/search_history_repository.dart';
import '../database/app_database.dart';

/// Shares the database by default. Query text stays in the user's local DB;
/// it must not be copied into logs, diagnostics, or network requests.
final class DriftSearchHistoryRepository implements SearchHistoryRepository {
  DriftSearchHistoryRepository(
    this._database, {
    bool closeDatabaseOnDispose = false,
    DateTime Function()? clock,
  }) : _ownsDatabase = closeDatabaseOnDispose,
       _clock = clock ?? DateTime.now;

  final AppDatabase _database;
  final bool _ownsDatabase;
  final DateTime Function() _clock;
  final _pending = <Future<void>>{};
  var _disposed = false;
  Future<void>? _closeFuture;

  @override
  Future<List<SearchHistoryEntry>> listHistory() => _run('list', () async {
    final rows =
        await (_database.select(_database.searchHistoryRecords)
              ..orderBy([
                (row) => OrderingTerm(
                  expression: row.searchedAtMs,
                  mode: OrderingMode.desc,
                ),
                (row) => OrderingTerm(expression: row.searchId),
              ])
              ..limit(20))
            .get();
    return List<SearchHistoryEntry>.unmodifiable([
      for (final row in rows)
        SearchHistoryEntry(
          id: row.searchId,
          query: row.query,
          sourceId: row.sourceId,
          searchedAt: DateTime.fromMillisecondsSinceEpoch(
            row.searchedAtMs,
            isUtc: true,
          ),
        ),
    ]);
  });

  @override
  Future<void> record(String query, {String? sourceId}) {
    _requireReady();
    final input = CatalogQuery(query, sourceId: sourceId);
    if (input.text.isEmpty) throw ArgumentError('Empty search history query');
    final id = sha256
        .convert(
          utf8.encode(jsonEncode([input.sourceId, foldSearchText(input.text)])),
        )
        .toString();
    return _run(
      'record',
      () => _database.transaction(() async {
        // Also replace matching legacy rows whose IDs predate this repository.
        // All values remain bound; the nullable source is part of the identity.
        await _database.customUpdate(
          'DELETE FROM search_history WHERE lower(trim(query)) = ? AND '
          '${input.sourceId == null ? 'source_id IS NULL' : 'source_id = ?'}',
          variables: [
            Variable<String>(foldSearchText(input.text)),
            if (input.sourceId != null) Variable<String>(input.sourceId!),
          ],
          updates: {_database.searchHistoryRecords},
          updateKind: UpdateKind.delete,
        );
        await _database
            .into(_database.searchHistoryRecords)
            .insertOnConflictUpdate(
              SearchHistoryRecordsCompanion.insert(
                searchId: id,
                query: input.text,
                sourceId: Value(input.sourceId),
                searchedAtMs: _clock().toUtc().millisecondsSinceEpoch,
              ),
            );
        await _database.customUpdate(
          'DELETE FROM search_history WHERE search_id NOT IN ('
          'SELECT search_id FROM search_history '
          'ORDER BY searched_at_ms DESC, search_id LIMIT 20)',
          updates: {_database.searchHistoryRecords},
          updateKind: UpdateKind.delete,
        );
      }),
    );
  }

  @override
  Future<void> clear() => _run('clear', () async {
    await _database.delete(_database.searchHistoryRecords).go();
  });

  Future<T> _run<T>(String operation, Future<T> Function() action) {
    _requireReady();
    final result = Future<T>.sync(() async {
      try {
        return await action();
      } catch (_) {
        // Includes corrupt stored rows and database errors; never echoes query.
        throw DomainFailure(
          code: DomainFailureCode.databaseCorrupted,
          diagnosticId: 'search-history.$operation',
        );
      }
    });
    late final Future<void> settled;
    settled = result
        .then<void>((_) {}, onError: (Object _) {})
        .whenComplete(() => _pending.remove(settled));
    _pending.add(settled);
    return result;
  }

  void _requireReady() {
    if (_disposed) throw StateError('SearchHistoryRepository is disposed');
  }

  @override
  Future<void> dispose() {
    if (_closeFuture != null) return _closeFuture!;
    _disposed = true;
    return _closeFuture = _close();
  }

  Future<void> _close() async {
    await Future.wait(_pending);
    if (_ownsDatabase) await _database.close();
  }
}
