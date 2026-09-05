import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/data/database/app_database.dart';
import 'package:yymusic/data/repositories/drift_library_repository.dart';
import 'package:yymusic/data/repositories/drift_search_history_repository.dart';
import 'package:yymusic/domain/models/catalog_search.dart';
import 'package:yymusic/domain/models/domain_failure.dart';
import 'package:yymusic/domain/models/track.dart';

import '../support/search_query_probe.dart';

void main() {
  late AppDatabase db;
  late DriftSearchHistoryRepository history;
  late DateTime now;
  late SearchQueryProbe probe;
  setUp(() {
    now = DateTime.utc(2026, 9, 5);
    probe = SearchQueryProbe();
    db = AppDatabase(NativeDatabase.memory().interceptWith(probe));
    history = DriftSearchHistoryRepository(db, clock: () => now);
  });
  tearDown(() async {
    await history.dispose();
    await db.close();
  });

  test('trimmed ASCII duplicate updates while source and non-ASCII identity remain separate', () async {
    await history.record('  Quiet 夜  ');
    final first = (await history.listHistory()).single;
    expect(first.query, 'Quiet 夜');
    expect(first.toString(), isNot(contains('Quiet')));
    now = now.add(const Duration(seconds: 1));
    await history.record('QUIET 夜');
    var values = await history.listHistory();
    expect(values.single.id, first.id);
    expect(values.single.query, 'QUIET 夜');
    expect(values.single.searchedAt, now);
    await history.record('quiet 夜', sourceId: 'source-one');
    await history.record('quiet 夜', sourceId: 'source-two');
    await history.record('Ä');
    await history.record('ä');
    values = await history.listHistory();
    expect(values.length, 5);
    expect(values.map((e) => e.id).toSet().length, 5);
    expect(() => values.clear(), throwsUnsupportedError);
  });

  test(
    'history is newest first with exact 20-row pruning and stable ties',
    () async {
      for (var i = 0; i < 25; i++) {
        now = now.add(const Duration(seconds: 1));
        await history.record('query-$i');
      }
      var entries = await history.listHistory();
      expect(entries.length, 20);
      expect(entries.first.query, 'query-24');
      expect(entries.last.query, 'query-5');
      expect((await db.select(db.searchHistoryRecords).get()).length, 20);
      await history.clear();
      await Future.wait([
        for (var i = 0; i < 25; i++) history.record('tied-$i'),
      ]);
      entries = await history.listHistory();
      final ids = entries.map((e) => e.id).toList();
      expect(ids, orderedEquals([...ids]..sort()));
      expect(ids.length, 20);
    },
  );

  test('concurrent same-query submissions are one atomic identity', () async {
    await Future.wait([
      for (var i = 0; i < 30; i++) history.record(i.isEven ? 'Quiet' : 'QUIET'),
    ]);
    expect((await history.listHistory()).length, 1);
    expect((await db.select(db.searchHistoryRecords).get()).length, 1);
  });

  test('record replaces legacy duplicate IDs without erasing another source history', () async {
    for (final id in ['legacy-one', 'legacy-two']) {
      await db
          .into(db.searchHistoryRecords)
          .insert(
            SearchHistoryRecordsCompanion.insert(
              searchId: id,
              query: ' Quiet ',
              searchedAtMs: now.millisecondsSinceEpoch,
            ),
          );
    }
    await history.record('QUIET', sourceId: 'another-source');
    await history.record('quiet');
    final rows = await history.listHistory();
    expect(rows.length, 2);
    expect(rows.where((row) => row.sourceId == null).single.query, 'quiet');
    expect(rows.map((row) => row.id), isNot(contains('legacy-one')));
    expect(
      rows.where((row) => row.sourceId != null).single.sourceId,
      'another-source',
    );
  });

  test(
    'prune or clear failure rolls back and returns only fixed diagnostics',
    () async {
      for (var i = 0; i < 20; i++) {
        now = now.add(const Duration(seconds: 1));
        await history.record('old-$i');
      }
      final before = (await history.listHistory()).map((e) => e.id).toList();
      await db.customStatement(
        "CREATE TRIGGER deny_history_delete BEFORE DELETE ON search_history BEGIN SELECT RAISE(ABORT, 'private-query-marker'); END",
      );
      now = now.add(const Duration(seconds: 1));
      final safeFailure = throwsA(
        isA<DomainFailure>().having(
          (e) => e.toString(),
          'redacted',
          isNot(contains('private-query-marker')),
        ),
      );
      await expectLater(history.record('private-query-marker'), safeFailure);
      await expectLater(history.clear(), safeFailure);
      expect((await history.listHistory()).map((e) => e.id), before);
      await db.customStatement('DROP TRIGGER deny_history_delete');
      await history.clear();
      expect(await history.listHistory(), isEmpty);
    },
  );

  test('clear affects only history and preserves real catalog data', () async {
    final library = DriftLibraryRepository(db);
    await library.initialize();
    final track = Track(
      id: 'one',
      sourceId: 'local',
      sourceType: MusicSourceType.local,
      title: '曲目',
      artists: const ['艺人'],
      duration: Duration.zero,
      localPath: '/fixture-only.wav',
    );
    await library.upsertTracks([track]);
    await history.record('曲目');
    await history.clear();
    await history.clear();
    expect(await history.listHistory(), isEmpty);
    expect((await library.getTrack(track.ref))!.title, '曲目');
    await library.dispose();
  });

  test('invalid input corrupt rows and clock errors are safe', () async {
    for (final text in ['', '   ', 'private\u0000value', 'x' * 2049]) {
      expect(() => history.record(text), throwsArgumentError);
    }
    expect(() => history.record('valid', sourceId: ''), throwsArgumentError);
    expect(
      () => SearchHistoryEntry(id: 'one', query: ' ', searchedAt: now),
      throwsArgumentError,
    );
    expect(await history.listHistory(), isEmpty);
    final brokenClock = DriftSearchHistoryRepository(
      db,
      clock: () => throw StateError('private-clock'),
    );
    await expectLater(
      brokenClock.record('private-query'),
      throwsA(
        isA<DomainFailure>().having(
          (e) => e.toString(),
          'safe',
          isNot(contains('private')),
        ),
      ),
    );
    await brokenClock.dispose();
    await db
        .into(db.searchHistoryRecords)
        .insert(
          SearchHistoryRecordsCompanion.insert(
            searchId: 'corrupt',
            query: 'bad\u0000query',
            searchedAtMs: now.millisecondsSinceEpoch,
          ),
        );
    await expectLater(
      history.listHistory(),
      throwsA(
        isA<DomainFailure>().having(
          (e) => e.toString(),
          'safe',
          isNot(contains('bad')),
        ),
      ),
    );
  });

  test('shared close drains in-flight work and rejects new operations without closing DB', () async {
    await history.listHistory();
    final started = Completer<void>();
    final release = Completer<void>();
    probe.beforeInsert = () async {
      started.complete();
      await release.future;
    };
    final write = history.record('in-flight');
    await started.future;
    var closed = false;
    final closing = history.dispose().then((_) => closed = true);
    expect(() => history.record('new'), throwsStateError);
    expect(() => history.listHistory(), throwsStateError);
    expect(() => history.clear(), throwsStateError);
    await Future<void>.delayed(Duration.zero);
    expect(closed, isFalse);
    release.complete();
    await write;
    await closing;
    await history.dispose();
    expect(probe.closeCount, 0);
    expect(
      (await db.select(db.searchHistoryRecords).get()).single.query,
      'in-flight',
    );
  });

  test(
    'owned repository persists across file reopen and closes once',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'yymusic-search-history-',
      );
      final file = File('${directory.path}/history.sqlite');
      final ownedProbe = SearchQueryProbe();
      final ownedDb = AppDatabase(
        NativeDatabase(file).interceptWith(ownedProbe),
      );
      final owned = DriftSearchHistoryRepository(
        ownedDb,
        closeDatabaseOnDispose: true,
        clock: () => now,
      );
      try {
        await owned.record('保存的搜索', sourceId: 'fixture-source');
        final before = (await owned.listHistory()).single;
        await Future.wait([owned.dispose(), owned.dispose()]);
        expect(ownedProbe.closeCount, 1);
        final reopenedDb = AppDatabase(NativeDatabase(file));
        final reopened = DriftSearchHistoryRepository(
          reopenedDb,
          closeDatabaseOnDispose: true,
        );
        try {
          final after = (await reopened.listHistory()).single;
          expect(after.id, before.id);
          expect(after.query, before.query);
          expect(after.sourceId, before.sourceId);
          expect(after.searchedAt, before.searchedAt);
          await reopened.clear();
        } finally {
          await reopened.dispose();
        }
      } finally {
        await owned.dispose();
        await directory.delete(recursive: true);
      }
    },
  );
}
