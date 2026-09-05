import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/data/database/app_database.dart';
import 'package:yymusic/data/repositories/drift_library_repository.dart';
import 'package:yymusic/domain/models/domain_failure.dart';
import 'package:yymusic/domain/models/pagination.dart';
import 'package:yymusic/domain/models/track.dart';

import '../support/fake_domain_repositories.dart';

void main() {
  final epoch = DateTime.utc(2026, 9, 5);
  late DateTime now;
  late AppDatabase db;
  late DriftLibraryRepository library;
  var clockFails = false;
  setUp(() async {
    now = epoch;
    clockFails = false;
    db = AppDatabase(NativeDatabase.memory(), clock: () => epoch);
    library = DriftLibraryRepository(
      db,
      clock: () {
        if (clockFails) throw StateError('fixture clock failure');
        return now;
      },
    );
    await library.initialize();
  });
  tearDown(() async {
    await library.dispose();
    await db.close();
  });
  Future<List<Track>> recent() async => (await library.listRecentlyAdded(
    PageRequest(),
    since: epoch,
    until: epoch,
  )).items;

  test(
    'new rows use insertion time and rescanning metadata never resets it',
    () async {
      final original = _track('a', modified: DateTime.utc(2030));
      await library.upsertTracks([original]);
      expect((await recent()).single.ref, original.ref);
      final inserted = (await db.select(db.trackRecords).getSingle()).addedAtMs;
      expect(inserted, epoch.millisecondsSinceEpoch);
      now = epoch.add(const Duration(days: 2));
      await library.upsertTracks([_track('a', title: 'Updated title')]);
      await library.setAvailability(
        original.ref,
        TrackAvailability.sourceDisabled,
      );
      final record = await db.select(db.trackRecords).getSingle();
      expect(record.addedAtMs, inserted);
      expect((await recent()).single.title, 'Updated title');
      expect(
        (await recent()).single.availability,
        TrackAvailability.sourceDisabled,
      );
      expect(
        (await library.listRecentlyAdded(
          PageRequest(),
          since: now,
          until: now,
        )).items,
        isEmpty,
      );
    },
  );

  test(
    'inclusive time window excludes older newer and unknown records',
    () async {
      now = epoch.subtract(const Duration(days: 8));
      await library.upsertTracks([_track('old')]);
      now = epoch.subtract(const Duration(days: 7));
      await library.upsertTracks([_track('start')]);
      now = epoch;
      await library.upsertTracks([_track('end')]);
      now = epoch.add(const Duration(milliseconds: 1));
      await library.upsertTracks([_track('future')]);
      await db.customStatement(
        "UPDATE tracks SET added_at_ms=NULL WHERE track_id='old'",
      );
      final page = await library.listRecentlyAdded(
        PageRequest(),
        since: epoch.subtract(const Duration(days: 7)),
        until: epoch,
      );
      expect(page.items.map((track) => track.id), ['end', 'start']);
      expect(page.hasMore, isFalse);
    },
  );

  test(
    'equal timestamps sort by complete track identity with exact paging',
    () async {
      final rows = [
        _track('b', source: 'b'),
        _track('a', source: 'b'),
        _track('a', source: 'a'),
        _track('a', source: 'a', local: true),
      ];
      await library.upsertTracks(rows);
      final first = await library.listRecentlyAdded(
        PageRequest(limit: 2),
        since: epoch,
        until: epoch,
      );
      final second = await library.listRecentlyAdded(
        PageRequest(limit: 2, offset: 2),
        since: epoch,
        until: epoch,
      );
      final beyond = await library.listRecentlyAdded(
        PageRequest(limit: 2, offset: 4),
        since: epoch,
        until: epoch,
      );
      expect(first.items.map((track) => track.ref), [rows[3].ref, rows[2].ref]);
      expect(second.items.map((track) => track.ref), [
        rows[1].ref,
        rows[0].ref,
      ]);
      expect(first.hasMore, isTrue);
      expect(second.hasMore, isFalse);
      expect(beyond.items, isEmpty);
      expect(beyond.hasMore, isFalse);
    },
  );

  test(
    'large catalog query is bounded and its sorting uses the v2 index',
    () async {
      await library.upsertTracks([
        for (var i = 0; i < 450; i++)
          _track('track-${i.toString().padLeft(3, '0')}'),
      ]);
      final page = await library.listRecentlyAdded(
        PageRequest(limit: 200, offset: 200),
        since: epoch,
        until: epoch,
      );
      expect(page.items.length, 200);
      expect(page.items.first.id, 'track-200');
      expect(page.hasMore, isTrue);
      final plan = await db
          .customSelect(
            'EXPLAIN QUERY PLAN SELECT * FROM tracks '
            'WHERE added_at_ms BETWEEN 0 AND 2000000000000 '
            'ORDER BY added_at_ms DESC,source_type,source_id,track_id LIMIT 9',
          )
          .get();
      final details = plan.map((row) => row.read<String>('detail')).join(' ');
      expect(details, contains('USING INDEX tracks_by_added'));
      expect(details, isNot(contains('TEMP B-TREE')));
    },
  );

  test('invalid time windows lifecycle and corrupt data fail safely', () async {
    expect(
      () => library.listRecentlyAdded(
        PageRequest(),
        since: epoch.add(const Duration(seconds: 1)),
        until: epoch,
      ),
      throwsArgumentError,
    );
    final unopened = DriftLibraryRepository(db);
    expect(
      () =>
          unopened.listRecentlyAdded(PageRequest(), since: epoch, until: epoch),
      throwsStateError,
    );
    await unopened.dispose();
    await library.upsertTracks([_track('a')]);
    await db.customStatement(
      "UPDATE tracks SET metadata_json='private-invalid-data'",
    );
    await expectLater(
      recent(),
      throwsA(
        isA<DomainFailure>().having(
          (error) => error.toString(),
          'redacted',
          isNot(contains('private-invalid-data')),
        ),
      ),
    );
    await library.dispose();
    expect(
      () =>
          library.listRecentlyAdded(PageRequest(), since: epoch, until: epoch),
      throwsStateError,
    );
  });

  test(
    'failed upsert rolls back artist links and newly assigned dates',
    () async {
      await library.upsertTracks([_track('a')]);
      clockFails = true;
      await expectLater(
        library.upsertTracks([
          _track('a', title: 'Must roll back'),
          _track('b'),
        ]),
        throwsA(isA<DomainFailure>()),
      );
      final rows = await recent();
      expect(rows.single.title, 'Track a');
      expect(rows.single.artists, ['Artist']);
      clockFails = false;
      now = epoch.add(const Duration(days: 1));
      await library.upsertTracks([_track('b')]);
      expect((await recent()).single.id, 'a');
      expect(
        (await library.listRecentlyAdded(
          PageRequest(),
          since: now,
          until: now,
        )).items.single.id,
        'b',
      );
    },
  );

  test(
    'concurrent repository updates preserve the first writer timestamp',
    () async {
      await library.upsertTracks([_track('a')]);
      now = epoch.add(const Duration(days: 1));
      final second = DriftLibraryRepository(
        db,
        clock: () => epoch.add(const Duration(days: 2)),
      );
      await second.initialize();
      try {
        await Future.wait([
          library.upsertTracks([_track('a', title: 'Writer one')]),
          second.upsertTracks([_track('a', title: 'Writer two')]),
        ]);
        expect(
          (await db.select(db.trackRecords).getSingle()).addedAtMs,
          epoch.millisecondsSinceEpoch,
        );
        expect((await recent()).length, 1);
      } finally {
        await second.dispose();
      }
    },
  );

  test(
    'Fake recent catalog obeys the same window ordering and update contract',
    () async {
      final rows = [_track('b'), _track('a'), _track('a', local: true)];
      final fake = FakeLibraryRepository(clock: () => now);
      try {
        await fake.upsertTracks(rows);
        await library.upsertTracks(rows);
        now = epoch.add(const Duration(days: 1));
        await fake.upsertTracks([_track('a', title: 'Updated')]);
        await library.upsertTracks([_track('a', title: 'Updated')]);
        final actual = await fake.listRecentlyAdded(
          PageRequest(limit: 2),
          since: epoch,
          until: epoch,
        );
        final expected = await library.listRecentlyAdded(
          PageRequest(limit: 2),
          since: epoch,
          until: epoch,
        );
        expect(
          actual.items.map((track) => track.ref),
          expected.items.map((track) => track.ref),
        );
        expect(actual.hasMore, expected.hasMore);
        expect(actual.items.last.title, 'Updated');
      } finally {
        await fake.dispose();
      }
    },
  );
}

Track _track(
  String id, {
  String source = 'source-a',
  bool local = false,
  String? title,
  DateTime? modified,
}) => Track(
  id: id,
  sourceId: source,
  sourceType: local ? MusicSourceType.local : MusicSourceType.rest,
  title: title ?? 'Track $id',
  artists: const ['Artist'],
  duration: const Duration(minutes: 2),
  modifiedAt: modified,
  localPath: local ? 'fixture-only.wav' : null,
);
