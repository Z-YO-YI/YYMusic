import 'package:drift/drift.dart';

/// Test-only query instrumentation; never installed by production bootstrap.
final class SearchQueryProbe extends QueryInterceptor {
  final selects = <({String sql, List<Object?> args, int rows})>[];
  Future<void> Function()? afterSelect;
  Future<void> Function()? beforeInsert;
  int closeCount = 0;
  int transactionCount = 0;

  @override
  TransactionExecutor beginTransaction(QueryExecutor parent) {
    transactionCount++;
    return parent.beginTransaction();
  }

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) async {
    final result = await executor.runSelect(statement, args);
    selects.add((sql: statement, args: List.of(args), rows: result.length));
    await afterSelect?.call();
    return result;
  }

  @override
  Future<int> runInsert(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) async {
    await beforeInsert?.call();
    return executor.runInsert(statement, args);
  }

  @override
  Future<void> close(QueryExecutor executor) async {
    closeCount++;
    await executor.close();
  }
}
