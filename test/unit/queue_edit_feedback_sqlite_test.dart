import 'dart:async';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/database_app_data_services.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/data/database/app_database.dart';
import 'package:yymusic/domain/models/queue_edit.dart';
import 'package:yymusic/playback/queue_edit_result.dart';

import '../support/fake_audio_engine.dart';
import 'queue_edit_test.dart' show editFixture;

void main() {
  late AppDatabase database;
  late DatabaseAppDataServices services;
  late DependencyGraph graph;
  late FakeAudioEngine engine;
  late _FeedbackDeleteProbe probe;
  setUp(() async {
    probe = _FeedbackDeleteProbe();
    database = AppDatabase(NativeDatabase.memory().interceptWith(probe));
    services = await DatabaseAppDataServices.open(database);
    await services.collection.saveQueue(editFixture());
    engine = FakeAudioEngine();
    graph = DependencyGraph(dataServices: services, audioEngine: engine);
    await graph.initialize();
  });
  tearDown(() async {
    if (!probe.gate.isCompleted) probe.gate.complete();
    await graph.close();
  });
  Future<void> failInsert() => database.customStatement('''
    CREATE TRIGGER fail_queue_feedback BEFORE INSERT ON queue_entries
    BEGIN SELECT RAISE(ABORT, 'private-marker'); END
  ''');
  test('real SQL rollback remains visible to a new subscriber and explicit retry commits', () async {
    await failInsert();
    var oldNotifications = 0;
    void oldPage() {
      oldNotifications++;
    }

    graph.queue.addListener(oldPage);
    probe.enabled = true;
    final work = graph.queue.submitEdit(
      QueueEdit.remove(graph.queue.state, 'a'),
    );
    await probe.entered.future.timeout(const Duration(seconds: 5));
    graph.queue.removeListener(oldPage);
    final oldCount = oldNotifications;
    probe.gate.complete();
    final result = await work;
    expect(result.status, QueueEditStatus.failed);
    expect(oldNotifications, oldCount);
    expect(graph.queue.editFailure, same(result.failure));
    expect((await services.collection.loadQueue()).entries.length, 4);
    var newNotifications = 0;
    graph.queue.addListener(() => newNotifications++);
    await database.customStatement('DROP TRIGGER fail_queue_feedback');
    expect(
      (await graph.queue.retryEdit(result.failure!)).status,
      QueueEditStatus.applied,
    );
    expect(graph.queue.editFailure, isNull);
    expect(newNotifications, greaterThanOrEqualTo(2));
    expect((await services.collection.loadQueue()).entries.map((e) => e.id), [
      'b',
      'c',
      'd',
    ]);
    expect(engine.calls, isEmpty);
  });
  for (final fails in [false, true]) {
    test(
      'actual root close drains SQL and feedback settlement, failure=$fails',
      () async {
        if (fails) await failInsert();
        probe.enabled = true;
        final work = graph.queue.submitEdit(
          QueueEdit.remove(graph.queue.state, 'a'),
        );
        await probe.entered.future.timeout(const Duration(seconds: 5));
        var closed = false;
        final closing = graph.close().then((_) => closed = true);
        await Future<void>.delayed(Duration.zero);
        expect(closed, isFalse);
        expect(graph.queue.editBusy, isTrue);
        expect(probe.closeCount, 0);
        expect(engine.disposalCount, 0);
        probe.gate.complete();
        final result = await work;
        await closing;
        expect(
          result.status,
          fails ? QueueEditStatus.failed : QueueEditStatus.applied,
        );
        expect(graph.queue.editBusy, isFalse);
        expect(probe.closeCount, 1);
        expect(engine.disposalCount, 1);
        if (fails) {
          expect(graph.queue.editFailure, same(result.failure));
          expect(result.failure!.message, isNot(contains('private-marker')));
          expect(graph.queue.canRetryEdit(result.failure!), isFalse);
        }
        await graph.close();
        expect(probe.closeCount, 1);
      },
    );
  }
}

final class _FeedbackDeleteProbe extends QueryInterceptor {
  final entered = Completer<void>(), gate = Completer<void>();
  bool enabled = false;
  int closeCount = 0;
  @override
  Future<int> runDelete(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) async {
    if (enabled &&
        statement.contains('queue_entries') &&
        !entered.isCompleted) {
      entered.complete();
      await gate.future;
    }
    return executor.runDelete(statement, args);
  }

  @override
  Future<void> close(QueryExecutor executor) async {
    closeCount++;
    await executor.close();
  }
}
