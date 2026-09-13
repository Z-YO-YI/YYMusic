import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/database_app_data_services.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/data/database/app_database.dart';
import 'package:yymusic/data/repositories/drift_sleep_timer_repository.dart';
import 'package:yymusic/domain/models/sleep_timer_snapshot.dart';
import 'package:yymusic/playback/playback_sleep_timer_state.dart';

import '../support/fake_audio_engine.dart';
import '../support/search_query_probe.dart';
import 'sleep_persistence_controller_test.dart' show flushSleepPersistence;

void main() {
  test('production data scope and graph restore original timer across SQLite reopen', () async {
    var now = DateTime.utc(2026, 9, 13);
    final directory = await Directory.systemTemp.createTemp(
      'yymusic-sleep-graph-',
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
    final file = File('${directory.path}${Platform.pathSeparator}sleep.sqlite');
    DateTime? original;
    for (var step = 0; step < 3; step++) {
      final services = await DatabaseAppDataServices.open(
        AppDatabase(NativeDatabase(file)),
      );
      final engine = FakeAudioEngine();
      final graph = DependencyGraph(
        dataServices: services,
        audioEngine: engine,
        playbackClock: () => now,
      );
      try {
        await graph.initialize();
        expect(graph.sleepPersistence.repository, same(services.sleepTimers));
        if (step == 0) {
          graph.playback.setSleepTimer(PlaybackSleepDuration.fifteen);
          original = graph.playback.sleepTimer.deadline;
        } else if (step == 1) {
          expect(graph.playback.sleepTimer.deadline, original);
          expect(graph.playback.sleepRemaining, const Duration(minutes: 13));
          expect(
            graph.playback.sleepTimer.duration,
            PlaybackSleepDuration.fifteen,
          );
          expect(
            graph.playbackPresenter.sleepPersistenceMessage,
            contains('保留原截止'),
          );
          graph.playback.setSleepTimer(null);
        } else {
          expect(graph.playback.sleepTimer.phase, PlaybackSleepPhase.off);
          expect(await services.sleepTimers.read(), isNull);
        }
        expect(engine.calls.where((e) => e == 'play'), isEmpty);
      } finally {
        await graph.close();
      }
      now = now.add(const Duration(minutes: 2));
    }
  });
  test('root shutdown waits for accepted SQLite write before data connection closes', () async {
    final probe = SearchQueryProbe();
    final db = AppDatabase(NativeDatabase.memory().interceptWith(probe));
    final services = await DatabaseAppDataServices.open(db);
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
      graph.playback.setSleepTimer(PlaybackSleepDuration.fifteen);
      await entered.future;
      var closed = false;
      final closing = graph.close().then((_) => closed = true);
      await flushSleepPersistence();
      expect(closed, isFalse);
      expect(probe.closeCount, 0);
      gate.complete();
      await closing;
      expect(probe.closeCount, 1);
    } finally {
      if (!gate.isCompleted) gate.complete();
      await graph.close();
    }
  });
  for (final invalid in [false, true]) {
    test(
      'startup clears ${invalid ? 'invalid' : 'expired'} persisted timer safely',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        final services = await DatabaseAppDataServices.open(db);
        final now = DateTime.utc(2026, 9, 13);
        if (invalid) {
          await db
              .into(db.appSettingRecords)
              .insertOnConflictUpdate(
                AppSettingRecordsCompanion.insert(
                  settingKey: DriftSleepTimerRepository.settingKey,
                  valueJson: 'private-marker',
                  updatedAtMs: 1,
                ),
              );
        } else {
          await services.sleepTimers.save(
            SleepTimerSnapshot(durationMinutes: 15, deadline: now),
          );
        }
        final engine = FakeAudioEngine();
        final graph = DependencyGraph(
          dataServices: services,
          audioEngine: engine,
          playbackClock: () => now,
        );
        try {
          await graph.initialize();
          expect(await services.sleepTimers.read(), isNull);
          expect(graph.playback.sleepTimer.phase, PlaybackSleepPhase.off);
          expect(
            engine.calls.where((e) => e == 'play' || e == 'pause'),
            isEmpty,
          );
        } finally {
          await graph.close();
        }
      },
    );
  }
}
