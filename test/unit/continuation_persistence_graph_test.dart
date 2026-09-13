import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/database_app_data_services.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/data/database/app_database.dart';

import '../support/fake_audio_engine.dart';
import '../support/search_query_probe.dart';
import 'continuation_persistence_controller_test.dart' show flushContinuation;

void main() {
  test(
    'production startup preserves damaged SQLite record until explicit choice',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      final services = await DatabaseAppDataServices.open(db);
      await db
          .into(db.appSettingRecords)
          .insert(
            AppSettingRecordsCompanion.insert(
              settingKey: 'playbackContinueAfterTrack',
              valueJson: '{"version":99,"continueAfterTrack":false}',
              updatedAtMs: 1,
            ),
          );
      final graph = DependencyGraph(
        dataServices: services,
        audioEngine: FakeAudioEngine(),
      );
      try {
        await graph.initialize();
        expect(graph.playback.continueAfterTrack, isTrue);
        expect(graph.continuationPersistence.failure, isNotNull);
        final row =
            await (db.select(db.appSettingRecords)..where(
                  (row) => row.settingKey.equals('playbackContinueAfterTrack'),
                ))
                .getSingle();
        expect(row.valueJson, '{"version":99,"continueAfterTrack":false}');
        graph.continuationPersistence.setEnabled(true);
        await flushContinuation();
        expect(await services.playbackContinuation.read(), isTrue);
      } finally {
        await graph.close();
      }
    },
  );

  test(
    'production graph restores preference across three SQLite opens',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'yymusic-continuation-graph-',
      );
      addTearDown(() async {
        expect(
          directory.absolute.path.startsWith(
            '${Directory.systemTemp.absolute.path}${Platform.pathSeparator}',
          ),
          isTrue,
        );
        await directory.delete(recursive: true);
      });
      final file = File(
        '${directory.path}${Platform.pathSeparator}settings.sqlite',
      );
      for (var step = 0; step < 3; step++) {
        final services = await DatabaseAppDataServices.open(
          AppDatabase(NativeDatabase(file)),
        );
        final engine = FakeAudioEngine();
        final graph = DependencyGraph(
          dataServices: services,
          audioEngine: engine,
        );
        try {
          await graph.initialize();
          expect(
            graph.continuationPersistence.repository,
            same(services.playbackContinuation),
          );
          expect(graph.playback.continueAfterTrack, step != 1);
          if (step < 2) graph.continuationPersistence.setEnabled(step == 1);
          expect(engine.calls.where((call) => call == 'play'), isEmpty);
        } finally {
          await graph.close();
        }
      }
    },
  );

  test('graph waits for accepted SQL write before closing database', () async {
    final probe = SearchQueryProbe();
    final services = await DatabaseAppDataServices.open(
      AppDatabase(NativeDatabase.memory().interceptWith(probe)),
    );
    final graph = DependencyGraph(
      dataServices: services,
      audioEngine: FakeAudioEngine(),
    );
    await graph.initialize();
    final gate = Completer<void>(), entered = Completer<void>();
    probe.beforeInsert = () async {
      if (!entered.isCompleted) entered.complete();
      await gate.future;
    };
    try {
      graph.continuationPersistence.setEnabled(false);
      await entered.future;
      final closing = graph.close();
      await flushContinuation();
      expect(probe.closeCount, 0);
      gate.complete();
      await closing;
      expect(probe.closeCount, 1);
    } finally {
      if (!gate.isCompleted) gate.complete();
      await graph.close();
    }
  });
}
