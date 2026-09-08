import 'dart:async';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/database_app_data_services.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/data/database/app_database.dart';

import '../support/search_query_probe.dart';
import 'local_library_overview_test.dart' show insertFolder, localTrack;
import 'local_music_controller_test.dart' show flushLocal;

void main() {
  test(
    'root exposes one actual repository and refreshes persisted folder changes',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      final services = await DatabaseAppDataServices.open(db);
      final graph = DependencyGraph(dataServices: services);
      addTearDown(graph.close);
      await graph.initialize();
      expect(services.localLibrary, same(services.library));
      expect(graph.localMusic.repository, same(services.localLibrary));
      expect(graph.libraryController.localMusic, same(graph.localMusic));
      await services.library.upsertTracks([
        localTrack('a'),
        localTrack('b', remote: true),
      ]);
      await insertFolder(db, 'one');
      graph.localMusic.start();
      graph.localMusic.setActive(true);
      await flushLocal();
      expect(graph.localMusic.content!.tracks.totalCount, 1);
      expect(graph.localMusic.content!.enabledFolderCount, 1);
      await (db.update(db.localFolderRecords)
            ..where((f) => f.folderId.equals('one')))
          .write(const LocalFolderRecordsCompanion(enabled: Value(false)));
      await flushLocal();
      expect(graph.localMusic.content!.enabledFolderCount, 0);
      expect(graph.localMusic.content!.folders.single.enabled, isFalse);
    },
  );

  test('graph shutdown waits for actual SQLite overview before closing shared database', () async {
    final probe = SearchQueryProbe();
    final db = AppDatabase(NativeDatabase.memory().interceptWith(probe));
    final services = await DatabaseAppDataServices.open(db);
    final graph = DependencyGraph(dataServices: services);
    addTearDown(graph.close);
    await graph.initialize();
    final gate = Completer<void>();
    final entered = Completer<void>();
    probe.afterSelect = () async {
      entered.complete();
      await gate.future;
    };
    graph.localMusic.start();
    graph.localMusic.setActive(true);
    await entered.future;
    var closed = false;
    final closing = graph.close().then((_) => closed = true);
    await flushLocal();
    expect(closed, isFalse);
    expect(probe.closeCount, 0);
    gate.complete();
    await closing;
    expect(probe.closeCount, 1);
    expect(graph.localMusic.content, isNull);
  });
}
