import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/database_app_data_services.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/data/database/app_database.dart';
import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/domain/models/queue_edit.dart';
import 'package:yymusic/playback/queue_edit_result.dart';

import '../support/fake_audio_engine.dart';
import 'queue_edit_test.dart' show editFixture, queueEditEpoch;

void main() {
  for (final next in [false, true]) {
    for (final fails in [false, true]) {
      test(
        'real SQLite insertion and root restart next=$next rollback=$fails',
        () async {
          final directory = await Directory.systemTemp.createTemp(
            'yymusic-queue-insert-',
          );
          final file = File('${directory.path}/catalog.sqlite');
          DependencyGraph? graph;
          DatabaseAppDataServices? services;
          try {
            final database = AppDatabase(NativeDatabase(file));
            services = await DatabaseAppDataServices.open(database);
            final original = editFixture();
            await services.collection.saveQueue(original);
            final entry = QueueEntry(
              id: 'new',
              track: original.entries.first.track,
              position: 99,
              addedAt: queueEditEpoch.add(const Duration(days: 1)),
            );
            await services.collection.setFavorite(entry.track, favorite: true);
            final engine = FakeAudioEngine();
            graph = DependencyGraph(
              dataServices: services,
              audioEngine: engine,
            );
            await graph.initialize();
            final before = graph.queue.state;
            final request = next
                ? QueueEdit.playNext(before, entry)
                : QueueEdit.addToEnd(before, entry);
            if (fails) {
              await database.customStatement('''
              CREATE TRIGGER fail_queue_insert BEFORE INSERT ON queue_entries
              WHEN NEW.entry_id = 'new' BEGIN SELECT RAISE(ABORT, 'private-marker'); END
            ''');
              final failed = await graph.queue.submitEdit(request);
              expect(failed.status, QueueEditStatus.failed);
              expect(
                failed.failure!.failure.toString(),
                isNot(contains('private-marker')),
              );
              expect(graph.queue.state, same(before));
              final saved = await services.collection.loadQueue();
              expect(saved.entries.map((e) => e.id), ['a', 'b', 'c', 'd']);
              expect(saved.currentEntryId, 'b');
              expect(saved.updatedAt, before.updatedAt);
              await database.customStatement('DROP TRIGGER fail_queue_insert');
              expect(
                (await graph.queue.retryEdit(failed.failure!)).status,
                QueueEditStatus.applied,
              );
              expect(graph.queue.editFailure, isNull);
            } else {
              expect(
                (await graph.queue.submitEdit(request)).status,
                QueueEditStatus.applied,
              );
            }
            final ids = next
                ? ['a', 'b', 'new', 'c', 'd']
                : ['a', 'b', 'c', 'd', 'new'];
            expect(graph.queue.state.entries.map((e) => e.id), ids);
            expect(engine.calls, isEmpty);
            await graph.close();
            graph = null;
            services = await DatabaseAppDataServices.open(
              AppDatabase(NativeDatabase(file)),
            );
            graph = DependencyGraph(
              dataServices: services,
              audioEngine: FakeAudioEngine(),
            );
            await graph.initialize();
            final restored = graph.queue.state;
            expect(restored.entries.map((e) => e.id), ids);
            expect(restored.entries.map((e) => e.position), [0, 1, 2, 3, 4]);
            expect(restored.currentEntryId, 'b');
            final inserted = restored.entries.singleWhere((e) => e.id == 'new');
            expect(inserted.track, entry.track);
            expect(inserted.addedAt, entry.addedAt);
            expect(
              restored.entries.where((e) => e.track == entry.track),
              hasLength(2),
            );
            expect(
              (await services.collection.watchFavorites().first).single.track,
              entry.track,
            );
          } finally {
            await graph?.close();
            await services?.dispose();
            final parent = Directory.systemTemp.absolute.path;
            final target = directory.absolute.path;
            if (!target.startsWith('$parent${Platform.pathSeparator}') ||
                !directory.uri.pathSegments
                    .where((e) => e.isNotEmpty)
                    .last
                    .startsWith('yymusic-queue-insert-')) {
              throw StateError('Unexpected queue insertion test cleanup path');
            }
            await directory.delete(recursive: true);
          }
        },
      );
    }
  }
}
