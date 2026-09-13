import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/data/database/app_database.dart';
import 'package:yymusic/data/repositories/drift_sleep_timer_repository.dart';
import 'package:yymusic/data/sleep_timer_snapshot_codec.dart';
import 'package:yymusic/domain/models/domain_failure.dart';
import 'package:yymusic/domain/models/sleep_timer_snapshot.dart';

import '../support/search_query_probe.dart';

void main() {
  final epoch = DateTime.utc(2026, 9, 13, 2);
  SleepTimerSnapshot snapshot([int minutes = 15]) => SleepTimerSnapshot(
    durationMinutes: minutes,
    deadline: epoch.add(Duration(minutes: minutes, microseconds: 123)),
  );
  (AppDatabase, DriftSleepTimerRepository) memory({SearchQueryProbe? probe}) {
    final executor = NativeDatabase.memory();
    final db = AppDatabase(
      probe == null ? executor : executor.interceptWith(probe),
    );
    final repo = DriftSleepTimerRepository(db, clock: () => epoch);
    addTearDown(db.close);
    addTearDown(repo.dispose);
    return (db, repo);
  }

  Future<void> insert(AppDatabase db, String key, String value) => db
      .into(db.appSettingRecords)
      .insertOnConflictUpdate(
        AppSettingRecordsCompanion.insert(
          settingKey: key,
          valueJson: value,
          updatedAtMs: 1,
        ),
      );
  Matcher failure(DomainFailureCode code) => isA<DomainFailure>()
      .having((e) => e.code, 'code', code)
      .having((e) => e.toString(), 'safe', isNot(contains('private-marker')));

  test('missing read and repeated clear never create settings', () async {
    final (db, repo) = memory();
    expect(await repo.read(), isNull);
    await repo.clear();
    await repo.clear();
    expect(await db.select(db.appSettingRecords).get(), isEmpty);
  });
  for (final minutes in [15, 30, 60]) {
    test(
      '$minutes minute upsert preserves exact snapshot and timestamp',
      () async {
        final (db, repo) = memory();
        await repo.save(snapshot());
        await repo.save(snapshot(minutes));
        expect(await repo.read(), snapshot(minutes));
        final row = await db.select(db.appSettingRecords).getSingle();
        expect(
          row.valueJson,
          SleepTimerSnapshotCodec.encode(snapshot(minutes)),
        );
        expect(row.updatedAtMs, epoch.millisecondsSinceEpoch);
      },
    );
  }
  test(
    'read save clear isolate the dedicated key and unrelated raw bytes',
    () async {
      final probe = SearchQueryProbe();
      final (db, repo) = memory(probe: probe);
      await insert(db, 'unrelated', 'not-json-private-marker');
      await repo.save(snapshot());
      probe.selects.clear();
      expect(await repo.read(), snapshot());
      expect(probe.selects.single.args, [DriftSleepTimerRepository.settingKey]);
      expect(probe.selects.single.rows, 1);
      await repo.clear();
      final row = await db.select(db.appSettingRecords).getSingle();
      expect(row.settingKey, 'unrelated');
      expect(row.valueJson, 'not-json-private-marker');
      expect(row.updatedAtMs, 1);
    },
  );
  test('unawaited save read clear read execute in accepted order', () async {
    final (_, repo) = memory();
    final saving = repo.save(snapshot(30));
    final reading = repo.read();
    final clearing = repo.clear();
    final empty = repo.read();
    await saving;
    expect(await reading, snapshot(30));
    await clearing;
    expect(await empty, isNull);
  });
  for (final blocked in ['read', 'save']) {
    test('blocked $blocked drains queued save clear before dispose', () async {
      final probe = SearchQueryProbe();
      final (db, repo) = memory(probe: probe);
      await repo.read(); // Open/migrate before installing the barrier.
      final gate = Completer<void>(), entered = Completer<void>();
      Future<void> block() async {
        if (!entered.isCompleted) entered.complete();
        await gate.future;
      }

      if (blocked == 'read') {
        probe.afterSelect = block;
      } else {
        probe.beforeInsert = block;
      }
      final first = blocked == 'read' ? repo.read() : repo.save(snapshot());
      try {
        await entered.future;
        var saved = false, cleared = false, closed = false;
        final saving = repo.save(snapshot(60)).then((_) => saved = true);
        final clearing = repo.clear().then((_) => cleared = true);
        final closing = repo.dispose();
        expect(repo.dispose(), same(closing));
        final done = closing.then((_) => closed = true);
        for (var i = 0; i < 4; i++) {
          await Future<void>.delayed(Duration.zero);
        }
        expect([saved, cleared, closed], [false, false, false]);
        expect(() => repo.read(), throwsStateError);
        expect(() => repo.save(snapshot()), throwsStateError);
        expect(() => repo.clear(), throwsStateError);
        gate.complete();
        await first;
        await saving;
        await clearing;
        await done;
        probe.afterSelect = null;
        expect(await db.select(db.appSettingRecords).get(), isEmpty);
        expect(probe.closeCount, 0);
      } finally {
        if (!gate.isCompleted) gate.complete();
        probe.afterSelect = null;
        probe.beforeInsert = null;
      }
    });
  }
  for (final raw in [
    'private-marker',
    'null',
    '{}',
    'x' * 513,
    '{"version":2,"durationMinutes":15,"deadlineUtc":"2026-09-13T02:15:00.000Z"}',
  ]) {
    test(
      'invalid record ${raw.length} remains untouched and can be explicitly cleared',
      () async {
        final (db, repo) = memory();
        await insert(db, DriftSleepTimerRepository.settingKey, raw);
        await expectLater(
          repo.read(),
          throwsA(failure(DomainFailureCode.schemaMismatch)),
        );
        expect(
          (await db.select(db.appSettingRecords).getSingle()).valueJson,
          raw,
        );
        await repo.clear();
        expect(await repo.read(), isNull);
      },
    );
  }
  for (final operation in ['save', 'clear']) {
    test('$operation SQL failure preserves data and does not poison the queue', () async {
      final (db, repo) = memory();
      await repo.save(snapshot());
      final event = operation == 'save' ? 'UPDATE' : 'DELETE';
      await db.customStatement(
        "CREATE TRIGGER fail_sleep BEFORE $event ON app_settings BEGIN SELECT RAISE(ABORT, 'private-marker'); END",
      );
      await expectLater(
        operation == 'save' ? repo.save(snapshot(60)) : repo.clear(),
        throwsA(failure(DomainFailureCode.databaseCorrupted)),
      );
      expect(await repo.read(), snapshot());
      await db.customStatement('DROP TRIGGER fail_sleep');
      await repo.save(snapshot(30));
      expect(await repo.read(), snapshot(30));
      await repo.clear();
      expect(await repo.read(), isNull);
    });
  }
  test(
    'clock failure is safe and later accepted clear still succeeds',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      final repo = DriftSleepTimerRepository(
        db,
        clock: () => throw StateError('private-marker'),
      );
      addTearDown(db.close);
      addTearDown(repo.dispose);
      await expectLater(
        repo.save(snapshot()),
        throwsA(failure(DomainFailureCode.databaseCorrupted)),
      );
      await repo.clear();
      expect(await repo.read(), isNull);
    },
  );
  test('read I/O failure is not missing and later read can recover', () async {
    final probe = SearchQueryProbe();
    final (_, repo) = memory(probe: probe);
    await repo.save(snapshot());
    probe.afterSelect = () async => throw StateError('private-marker');
    await expectLater(
      repo.read(),
      throwsA(failure(DomainFailureCode.databaseCorrupted)),
    );
    probe.afterSelect = null;
    expect(await repo.read(), snapshot());
  });
  test(
    'dispose drains failed accepted work while caller retains the error',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      final repo = DriftSleepTimerRepository(
        db,
        clock: () => throw StateError('private-marker'),
      );
      addTearDown(db.close);
      final failed = expectLater(
        repo.save(snapshot()),
        throwsA(failure(DomainFailureCode.databaseCorrupted)),
      );
      final closing = repo.dispose();
      await failed;
      await closing;
      expect(await db.select(db.appSettingRecords).get(), isEmpty);
      expect(() => repo.read(), throwsStateError);
    },
  );
  test('reentrant clock close includes the write that invoked it', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    late DriftSleepTimerRepository repo;
    Future<void>? closing;
    repo = DriftSleepTimerRepository(
      db,
      clock: () {
        closing = repo.dispose();
        return epoch;
      },
    );
    await repo.save(snapshot());
    await closing;
    expect(
      (await db.select(db.appSettingRecords).getSingle()).valueJson,
      SleepTimerSnapshotCodec.encode(snapshot()),
    );
    expect(() => repo.clear(), throwsStateError);
  });
  test('real SQLite file survives reopen and explicit clear survives another reopen', () async {
    final directory = await Directory.systemTemp.createTemp(
      'yymusic-sleep-test-',
    );
    addTearDown(() async {
      final parent = Directory.systemTemp.absolute.path;
      expect(
        directory.absolute.path.startsWith('$parent${Platform.pathSeparator}'),
        isTrue,
      );
      await directory.delete(recursive: true);
    });
    final file = File('${directory.path}${Platform.pathSeparator}sleep.sqlite');
    for (var step = 0; step < 3; step++) {
      final db = AppDatabase(NativeDatabase(file));
      final repo = DriftSleepTimerRepository(db);
      try {
        if (step == 0) {
          await repo.save(snapshot(60));
        }
        if (step == 1) {
          expect(await repo.read(), snapshot(60));
          await repo.clear();
        }
        if (step == 2) {
          expect(await repo.read(), isNull);
        }
      } finally {
        await repo.dispose();
        await db.close();
      }
    }
  });
}
