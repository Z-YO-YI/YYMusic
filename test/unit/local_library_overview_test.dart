import 'dart:async';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/data/database/app_database.dart';
import 'package:yymusic/data/repositories/drift_library_repository.dart';
import 'package:yymusic/domain/models/catalog_search.dart';
import 'package:yymusic/domain/models/domain_failure.dart';
import 'package:yymusic/domain/models/local_library_overview.dart';
import 'package:yymusic/domain/models/pagination.dart';
import 'package:yymusic/domain/models/track.dart';
import 'package:yymusic/domain/repositories/local_library_repository.dart';

import '../support/fake_local_library_repository.dart';
import '../support/search_query_probe.dart';

void main() {
  late AppDatabase db;
  late DriftLibraryRepository library;
  late SearchQueryProbe probe;
  setUp(() async {
    probe = SearchQueryProbe();
    db = AppDatabase(NativeDatabase.memory().interceptWith(probe));
    library = DriftLibraryRepository(db);
    await library.initialize();
    probe.selects.clear();
    probe.transactionCount = 0;
  });
  tearDown(() async {
    probe.afterSelect = null;
    await library.dispose();
    await db.close();
  });

  test(
    'empty overview returns actual zeros with one bounded read and no writes',
    () async {
      final LocalLibraryRepository repository = library;
      final result = await repository.readLocalOverview(PageRequest(limit: 20));
      expect(result.tracks.totalCount, 0);
      expect(result.tracks.availableCount, 0);
      expect(result.tracks.totalDuration, Duration.zero);
      expect(result.folderCount, 0);
      expect(result.enabledFolderCount, 0);
      expect(result.folders, isEmpty);
      expect(result.hasMore, isFalse);
      expect(probe.selects.single.rows, 1);
      expect(probe.selects.single.args, [20, 0]);
      expect(probe.transactionCount, 0);
    },
  );

  test('full local identities and availability are counted once without artist fan-out', () async {
    await library.upsertTracks([
      for (final state in TrackAvailability.values)
        localTrack('same', source: state.name, availability: state),
      localTrack('same', source: 'available', remote: true),
    ]);
    probe.selects.clear();
    final result = await library.readLocalOverview(PageRequest());
    expect(result.tracks.totalCount, 5);
    expect(result.tracks.counts.values, everyElement(1));
    expect(result.tracks.availableCount, 1);
    expect(result.tracks.unavailableCount, 4);
    expect(result.tracks.totalDuration, const Duration(seconds: 600));
    expect(probe.selects, hasLength(1));
    expect(probe.selects.single.sql, isNot(contains('track_artists')));
  });

  test(
    'stored Windows Android unknown and disabled folders never imply access',
    () async {
      await insertFolder(db, 'win', name: 'A', scanned: 1000);
      await insertFolder(
        db,
        'android',
        name: 'B',
        platform: 'android',
        enabled: false,
      );
      await insertFolder(db, 'future', name: 'C', platform: 'future');
      probe.selects.clear();
      final result = await library.readLocalOverview(PageRequest());
      expect(result.folderCount, 3);
      expect(result.enabledFolderCount, 2);
      expect(result.folders.map((f) => f.platform), LocalFolderPlatform.values);
      expect(
        result.folders.first.lastScannedAt,
        DateTime.fromMillisecondsSinceEpoch(1000, isUtc: true),
      );
      expect(result.folders[1].lastScannedAt, isNull);
      expect(result.folders[1].enabled, isFalse);
      expect(result.folders.first.toString(), 'LocalFolderSummary(<redacted>)');
      expect(result.toString(), 'LocalLibraryOverview(<redacted>)');
      final query = probe.selects.single.sql;
      for (final privateField in ['local_path', 'content_uri', 'grant_ref']) {
        expect(query, isNot(contains(privateField)));
      }
    },
  );

  test(
    'same-name stable pages and out-of-range window retain complete statistics',
    () async {
      await library.upsertTracks([localTrack('a')]);
      await insertFolder(db, 'b', name: 'Music');
      await insertFolder(db, 'a', name: 'Music');
      await insertFolder(db, 'lower', name: 'music');
      for (var i = 0; i < 5; i++) {
        final result = await library.readLocalOverview(
          PageRequest(offset: i, limit: 1),
        );
        expect(result.folderCount, 3);
        expect(result.tracks.totalCount, 1);
        expect(
          result.folders.map((f) => f.id),
          i < 3
              ? [
                  ['a', 'b', 'lower'][i],
                ]
              : isEmpty,
        );
        expect(result.hasMore, i < 2);
      }
    },
  );

  test(
    'large folder collections return at most the requested 200 rows',
    () async {
      await db.batch((batch) {
        batch.insertAll(db.localFolderRecords, [
          for (var i = 0; i < 425; i++)
            folderRow('f-${i.toString().padLeft(3, '0')}'),
        ]);
      });
      probe.selects.clear();
      final result = await library.readLocalOverview(
        PageRequest(offset: 200, limit: 200),
      );
      expect(result.folders, hasLength(200));
      expect(result.folders.first.id, 'f-200');
      expect(result.folders.last.id, 'f-399');
      expect(result.folderCount, 425);
      expect(result.hasMore, isTrue);
      expect(probe.selects.single.rows, 200);
      expect(probe.selects.single.args, [200, 200]);
    },
  );

  for (final late in [false, true]) {
    test(
      '${late ? 'late' : 'pre'} cancellation discards overview without unsafe errors',
      () async {
        final token = SearchCancellation();
        if (late) {
          probe.afterSelect = () async => token.cancel();
        } else {
          token.cancel();
        }
        await expectLater(
          () => library.readLocalOverview(PageRequest(), cancellation: token),
          throwsA(isA<SearchCancelled>()),
        );
        expect(probe.selects.length, late ? 1 : 0);
      },
    );
  }

  test(
    'summary does not decode unrelated corrupt track metadata or private media',
    () async {
      await library.upsertTracks([localTrack('a')]);
      await db.customStatement(
        "UPDATE tracks SET metadata_json = 'private-corrupt-marker'",
      );
      final result = await library.readLocalOverview(PageRequest());
      expect(result.tracks.totalCount, 1);
    },
  );

  test('malformed folder display text becomes a safe domain failure', () async {
    await insertFolder(db, 'a', name: 'private-marker\n');
    await expectLater(
      library.readLocalOverview(PageRequest()),
      throwsA(
        isA<DomainFailure>()
            .having(
              (e) => e.diagnosticId,
              'id',
              'library-repository.local-overview',
            )
            .having(
              (e) => e.toString(),
              'safe',
              isNot(contains('private-marker')),
            ),
      ),
    );
  });

  test(
    'query exceptions are sanitized and unchanged data can be reread',
    () async {
      probe.afterSelect = () async => throw StateError('private-marker');
      await expectLater(
        library.readLocalOverview(PageRequest()),
        throwsA(
          isA<DomainFailure>().having(
            (e) => e.toString(),
            'safe',
            isNot(contains('private-marker')),
          ),
        ),
      );
      probe.afterSelect = null;
      expect((await library.readLocalOverview(PageRequest())).folderCount, 0);
    },
  );

  test(
    'watch invalidates local writes and folder updates without querying tracks',
    () async {
      var signals = 0;
      var next = Completer<void>();
      final subscription = library.watchLocalChanges().listen((_) {
        signals++;
        if (!next.isCompleted) next.complete();
      });
      addTearDown(subscription.cancel);
      expect(probe.selects, isEmpty);
      await library.upsertTracks([localTrack('a')]);
      await next.future.timeout(const Duration(seconds: 3));
      expect(signals, greaterThan(0));
      next = Completer<void>();
      probe.selects.clear();
      await insertFolder(db, 'a');
      await next.future.timeout(const Duration(seconds: 3));
      expect(probe.selects, isEmpty);
      next = Completer<void>();
      await (db.update(db.localFolderRecords)
            ..where((f) => f.folderId.equals('a')))
          .write(const LocalFolderRecordsCompanion(enabled: Value(false)));
      await next.future.timeout(const Duration(seconds: 3));
      expect(
        (await library.readLocalOverview(PageRequest())).enabledFolderCount,
        0,
      );
      await subscription.cancel();
      final oldSignals = signals;
      await library.upsertTracks([localTrack('b')]);
      await library.readLocalOverview(PageRequest());
      expect(signals, oldSignals);
    },
  );

  test(
    'overview holds one snapshot even if data changes before result delivery',
    () async {
      await insertFolder(db, 'a');
      probe.afterSelect = () async {
        probe.afterSelect = null;
        await insertFolder(db, 'b');
      };
      final old = await library.readLocalOverview(PageRequest());
      expect(old.folderCount, 1);
      expect(old.folders, hasLength(1));
      expect((await library.readLocalOverview(PageRequest())).folderCount, 2);
    },
  );

  test(
    'uninitialized and disposed repository reject reads and watches',
    () async {
      final uninitialized = DriftLibraryRepository(db);
      expect(
        () => uninitialized.readLocalOverview(PageRequest()),
        throwsStateError,
      );
      expect(uninitialized.watchLocalChanges, throwsStateError);
      await uninitialized.dispose();
      await library.dispose();
      expect(() => library.readLocalOverview(PageRequest()), throwsStateError);
      expect(library.watchLocalChanges, throwsStateError);
      expect(
        probe.closeCount,
        0,
      ); // Borrowed connection remains owned by the scope.
    },
  );

  test(
    'models copy mutable collections and reject negative or ambiguous data',
    () {
      final counts = {TrackAvailability.available: 1};
      final summary = LocalTrackSummary(
        counts: counts,
        totalDuration: Duration.zero,
      );
      counts.clear();
      expect(summary.totalCount, 1);
      expect(() => summary.counts.clear(), throwsUnsupportedError);
      expect(
        () => LocalTrackSummary(
          counts: {TrackAvailability.unsupported: -1},
          totalDuration: Duration.zero,
        ),
        throwsArgumentError,
      );
      expect(
        () => LocalTrackSummary(
          counts: {},
          totalDuration: const Duration(seconds: -1),
        ),
        throwsArgumentError,
      );
      final folder = LocalFolderSummary(
        id: 'a',
        displayName: 'Private',
        platform: LocalFolderPlatform.windows,
        enabled: true,
      );
      final folders = [folder];
      final result = LocalLibraryOverview(
        tracks: summary,
        folderCount: 1,
        enabledFolderCount: 1,
        page: PageRequest(),
        folders: folders,
      );
      folders.clear();
      expect(result.folders, hasLength(1));
      expect(() => result.folders.clear(), throwsUnsupportedError);
      for (final input in [
        (count: -1, enabled: 0, folders: <LocalFolderSummary>[]),
        (count: 0, enabled: -1, folders: <LocalFolderSummary>[]),
        (count: 0, enabled: 1, folders: <LocalFolderSummary>[]),
        (count: 1, enabled: 0, folders: <LocalFolderSummary>[]),
        (count: 1, enabled: 0, folders: [folder]),
        (
          count: 1,
          enabled: 1,
          folders: [
            LocalFolderSummary(
              id: 'disabled',
              displayName: 'Music',
              platform: LocalFolderPlatform.android,
              enabled: false,
            ),
          ],
        ),
        (count: 2, enabled: 1, folders: [folder, folder]),
      ]) {
        expect(
          () => LocalLibraryOverview(
            tracks: summary,
            folderCount: input.count,
            enabledFolderCount: input.enabled,
            page: PageRequest(),
            folders: input.folders,
          ),
          throwsArgumentError,
        );
      }
    },
  );

  test(
    'folder validation rejects private invalid inputs without echoing them',
    () {
      for (final invalid in ['', 'private-marker\n', 'x' * 513]) {
        expect(
          () => LocalFolderSummary(
            id: 'a',
            displayName: invalid,
            platform: LocalFolderPlatform.unknown,
            enabled: true,
          ),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.toString(),
              'safe',
              isNot(contains('private-marker')),
            ),
          ),
        );
      }
      expect(
        () => LocalFolderSummary(
          id: 'private-marker\n',
          displayName: 'A',
          platform: LocalFolderPlatform.android,
          enabled: true,
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.toString(),
            'safe',
            isNot(contains('private-marker')),
          ),
        ),
      );
      expect(
        () => LocalFolderSummary(
          id: 'a',
          displayName: 'A',
          platform: LocalFolderPlatform.android,
          enabled: true,
          lastScannedAt: DateTime(2026),
        ),
        throwsArgumentError,
      );
    },
  );

  test(
    'replaceable fake follows local-only counts stable pages and cancellation',
    () async {
      final fake = FakeLocalLibraryRepository();
      addTearDown(fake.close);
      fake.tracks.addAll([localTrack('a'), localTrack('b', remote: true)]);
      fake.folders.addAll([
        for (final id in ['b', 'a'])
          LocalFolderSummary(
            id: id,
            displayName: 'Music',
            platform: LocalFolderPlatform.windows,
            enabled: id == 'a',
          ),
      ]);
      final result = await fake.readLocalOverview(PageRequest(limit: 1));
      expect(result.tracks.totalCount, 1);
      expect(result.folderCount, 2);
      expect(result.enabledFolderCount, 1);
      expect(result.folders.single.id, 'a');
      expect(result.hasMore, isTrue);
      final token = SearchCancellation();
      fake.beforeRead = () async => token.cancel();
      await expectLater(
        fake.readLocalOverview(PageRequest(), cancellation: token),
        throwsA(isA<SearchCancelled>()),
      );
      final signal = fake.watchLocalChanges().first;
      fake.changed();
      await signal;
    },
  );
}

Track localTrack(
  String id, {
  String source = 'local',
  bool remote = false,
  TrackAvailability availability = TrackAvailability.available,
}) => Track(
  id: id,
  sourceId: source,
  sourceType: remote ? MusicSourceType.rest : MusicSourceType.local,
  title: id,
  artists: ['One', 'Two'],
  duration: const Duration(seconds: 120),
  localPath: remote ? null : '/test-only/private-marker/$id.wav',
  availability: availability,
);

LocalFolderRecordsCompanion folderRow(
  String id, {
  String name = 'Music',
  String platform = 'windows',
  bool enabled = true,
  int? scanned,
}) => LocalFolderRecordsCompanion.insert(
  folderId: id,
  platform: platform,
  displayName: name,
  localPath: platform == 'android'
      ? const Value.absent()
      : const Value('/test-only/private-path'),
  contentUri: platform == 'android'
      ? const Value('content://test-only/private-uri')
      : const Value.absent(),
  grantRef: const Value('test-only-private-grant'),
  createdAtMs: 0,
  updatedAtMs: 1000,
  lastScannedAtMs: Value(scanned),
  enabled: Value(enabled),
);

Future<void> insertFolder(
  AppDatabase db,
  String id, {
  String name = 'Music',
  String platform = 'windows',
  bool enabled = true,
  int? scanned,
}) async {
  await db
      .into(db.localFolderRecords)
      .insert(
        folderRow(
          id,
          name: name,
          platform: platform,
          enabled: enabled,
          scanned: scanned,
        ),
      );
}
