import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/database_app_data_services.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/data/database/app_database.dart';
import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/domain/models/domain_failure.dart';
import 'package:yymusic/domain/models/queue_edit.dart';

import '../support/fake_audio_engine.dart';
import 'queue_edit_test.dart' show editFixture, queueEditEpoch;

void main() {
  late AppDatabase database;
  late DatabaseAppDataServices services;
  late DependencyGraph graph;
  late FakeAudioEngine engine;
  late _QueueDeleteProbe probe;
  setUp(() async {
    probe = _QueueDeleteProbe();
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
  test('actual SQLite reorder and removal preserve full soft references and other collections', () async {
    final original = graph.queue.state;
    final track = original.entries.first.track;
    await services.collection.setFavorite(track, favorite: true);
    await services.collection.recordHistory(
      PlayHistoryEntry(
        id: 'history',
        track: track,
        startedAt: queueEditEpoch,
        lastPosition: const Duration(seconds: 7),
      ),
    );
    expect(
      await graph.queue.edit(QueueEdit.move(original, 'd', beforeEntryId: 'b')),
      isTrue,
    );
    final moved = await services.collection.loadQueue();
    expect(moved.entries.map((e) => e.id), ['a', 'd', 'b', 'c']);
    for (final entry in moved.entries) {
      final old = original.entries.singleWhere((e) => e.id == entry.id);
      expect(entry.track, old.track);
      expect(entry.addedAt, old.addedAt);
    }
    expect(
      await graph.queue.edit(QueueEdit.remove(graph.queue.state, 'a')),
      isTrue,
    );
    final removed = await services.collection.loadQueue();
    expect(removed.entries.map((e) => e.position), [0, 1, 2]);
    expect(removed.currentEntryId, 'b');
    expect(
      (await services.collection.watchFavorites().first).single.track,
      track,
    );
    expect(
      (await services.collection.watchHistory().first).single.id,
      'history',
    );
    expect(engine.calls, isEmpty);
  });
  test('insert failure after DELETE rolls back complete queue and accepts explicit retry', () async {
    final original = graph.queue.state;
    await database.customStatement('''
      CREATE TRIGGER fail_queue_insert BEFORE INSERT ON queue_entries
      WHEN NEW.entry_id = 'b' BEGIN SELECT RAISE(ABORT, 'private-marker'); END
    ''');
    final request = QueueEdit.move(original, 'a');
    await expectLater(
      graph.queue.edit(request),
      throwsA(
        isA<DomainFailure>()
            .having((e) => e.code, 'code', DomainFailureCode.databaseCorrupted)
            .having((e) => e.diagnosticId, 'safe ID', 'queue.edit-failed')
            .having(
              (e) => e.toString(),
              'private text absent',
              isNot(contains('private-marker')),
            ),
      ),
    );
    expect(graph.queue.state, same(original));
    final stored = await services.collection.loadQueue();
    expect(stored.entries.map((e) => e.id), ['a', 'b', 'c', 'd']);
    expect(stored.currentEntryId, 'b');
    expect(stored.updatedAt, original.updatedAt);
    await database.customStatement('DROP TRIGGER fail_queue_insert');
    expect(await graph.queue.edit(request), isTrue);
    expect((await services.collection.loadQueue()).entries.last.id, 'a');
  });
  test(
    'failure at final clear state update restores deleted rows and current ID',
    () async {
      final original = graph.queue.state;
      await database.customStatement('''
      CREATE TRIGGER fail_queue_final BEFORE UPDATE ON queue_state
      WHEN NEW.updated_at_ms != OLD.updated_at_ms
      BEGIN SELECT RAISE(ABORT, 'private-marker'); END
    ''');
      await expectLater(
        graph.queue.edit(QueueEdit.clear(original)),
        throwsA(isA<DomainFailure>()),
      );
      final stored = await services.collection.loadQueue();
      expect(stored.entries.map((e) => e.id), ['a', 'b', 'c', 'd']);
      expect(stored.currentEntryId, 'b');
      expect(graph.queue.state, same(original));
      await database.customStatement('DROP TRIGGER fail_queue_final');
      expect(await graph.queue.edit(QueueEdit.clear(original)), isTrue);
      final empty = await services.collection.loadQueue();
      expect(empty.entries, isEmpty);
      expect(empty.currentEntryId, isNull);
    },
  );
  test(
    'leaving after transaction begins still commits exact accepted snapshot',
    () async {
      final original = graph.queue.state;
      var allowed = true;
      probe.enabled = true;
      final editing = graph.queue.edit(
        QueueEdit.remove(original, 'a'),
        canEdit: () => allowed,
      );
      await probe.entered.future.timeout(const Duration(seconds: 5));
      allowed = false;
      expect(graph.queue.state, same(original));
      probe.gate.complete();
      expect(await editing, isTrue);
      final stored = await services.collection.loadQueue();
      expect(stored.entries.map((e) => e.id), ['b', 'c', 'd']);
      expect(graph.queue.state.entries.map((e) => e.id), ['b', 'c', 'd']);
    },
  );
  test(
    'complete 1003-entry queue is edited without metadata reads or truncation',
    () async {
      final many = editFixture(count: 1003, current: null);
      await graph.queue.replace(many.entries);
      probe.catalogReads = 0;
      expect(
        await graph.queue.edit(QueueEdit.move(graph.queue.state, 'a')),
        isTrue,
      );
      final stored = await services.collection.loadQueue();
      expect(stored.entries.length, 1003);
      expect(stored.entries.last.id, 'a');
      expect(stored.entries.last.position, 1002);
      expect(stored.currentEntryId, isNull);
      expect(probe.catalogReads, 0);
      expect(engine.calls, isEmpty);
    },
  );
  for (final fails in [false, true]) {
    test(
      'root drains accepted SQL before storage close and reopen, failure=$fails',
      () async {
        await graph.close();
        final directory = await Directory.systemTemp.createTemp(
          'yymusic-queue-edit-',
        );
        final file = File('${directory.path}/catalog.sqlite');
        final diskProbe = _QueueDeleteProbe();
        final diskDatabase = AppDatabase(
          NativeDatabase(file).interceptWith(diskProbe),
        );
        DatabaseAppDataServices? diskServices;
        DependencyGraph? diskGraph;
        try {
          diskServices = await DatabaseAppDataServices.open(diskDatabase);
          await diskServices.collection.saveQueue(editFixture());
          final diskEngine = FakeAudioEngine();
          diskGraph = DependencyGraph(
            dataServices: diskServices,
            audioEngine: diskEngine,
          );
          await diskGraph.initialize();
          if (fails) {
            await diskDatabase.customStatement('''
            CREATE TRIGGER fail_queue_insert BEFORE INSERT ON queue_entries
            BEGIN SELECT RAISE(ABORT, 'private-marker'); END
          ''');
          }
          diskProbe.enabled = true;
          final editing = diskGraph.queue.edit(
            QueueEdit.remove(diskGraph.queue.state, 'a'),
          );
          final result = fails
              ? expectLater(editing, throwsA(isA<DomainFailure>()))
              : expectLater(editing, completion(isTrue));
          await diskProbe.entered.future.timeout(const Duration(seconds: 5));
          var closed = false;
          final closing = diskGraph.close().then((_) => closed = true);
          await Future<void>.delayed(Duration.zero);
          expect(closed, isFalse);
          expect(diskProbe.closeCount, 0);
          expect(diskEngine.disposalCount, 0);
          diskProbe.gate.complete();
          await result;
          await closing;
          expect(diskProbe.closeCount, 1);
          expect(diskEngine.disposalCount, 1);
          diskServices = await DatabaseAppDataServices.open(
            AppDatabase(NativeDatabase(file)),
          );
          final restored = await diskServices.collection.loadQueue();
          expect(
            restored.entries.map((e) => e.id),
            fails ? ['a', 'b', 'c', 'd'] : ['b', 'c', 'd'],
          );
          expect(restored.currentEntryId, 'b');
        } finally {
          if (!diskProbe.gate.isCompleted) diskProbe.gate.complete();
          await diskGraph?.close();
          await diskServices?.dispose();
          // Only remove this test-owned temp child, never an unresolved broad path.
          final parent = Directory.systemTemp.absolute.path;
          final target = directory.absolute.path;
          if (!target.startsWith('$parent${Platform.pathSeparator}') ||
              !directory.uri.pathSegments
                  .where((e) => e.isNotEmpty)
                  .last
                  .startsWith('yymusic-queue-edit-')) {
            throw StateError('Unexpected queue test cleanup path');
          }
          await directory.delete(recursive: true);
        }
      },
    );
  }
}

final class _QueueDeleteProbe extends QueryInterceptor {
  final entered = Completer<void>(), gate = Completer<void>();
  bool enabled = false;
  int closeCount = 0;
  int catalogReads = 0;
  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) async {
    if (RegExp(r'\btracks\b', caseSensitive: false).hasMatch(statement)) {
      catalogReads++;
    }
    return executor.runSelect(statement, args);
  }

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
