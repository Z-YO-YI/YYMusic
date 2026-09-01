import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/data/database/app_database.dart';
import 'package:yymusic/data/repositories/drift_collection_repository.dart';
import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/domain/models/domain_failure.dart';
import 'package:yymusic/domain/models/track.dart';

void main() {
  late AppDatabase database;
  late DriftCollectionRepository repository;
  late DateTime now;

  setUp(() {
    now = _epoch;
    database = AppDatabase(NativeDatabase.memory(), clock: () => _epoch);
    repository = DriftCollectionRepository(database, clock: () => now);
  });

  tearDown(() async {
    await repository.dispose();
    await database.close();
  });

  test(
    'persists deterministic playlists and protects system identity',
    () async {
      final custom = _playlist(id: 'custom', name: 'Custom');
      final recent = _playlist(
        id: 'system-recent',
        name: 'Recently played',
        isSystem: true,
        systemType: SystemPlaylistType.recent,
      );
      final favorites = _playlist(
        id: 'system-favorites',
        name: 'Favorites',
        isSystem: true,
        systemType: SystemPlaylistType.favorites,
      );
      await repository.savePlaylist(custom);
      await repository.savePlaylist(recent);
      await repository.savePlaylist(favorites);

      final playlists = await repository.watchPlaylists().first;
      expect(playlists.map((playlist) => playlist.id), [
        'system-favorites',
        'system-recent',
        'custom',
      ]);
      expect(() => playlists.add(custom), throwsUnsupportedError);
      expect((await repository.getPlaylist('custom'))!.name, 'Custom');

      await repository.savePlaylist(
        _playlist(
          id: 'custom',
          name: 'Renamed',
          updatedAt: _epoch.add(const Duration(minutes: 1)),
        ),
      );
      expect((await repository.getPlaylist('custom'))!.name, 'Renamed');

      await expectLater(
        repository.savePlaylist(
          _playlist(
            id: 'custom',
            name: 'Converted',
            isSystem: true,
            systemType: SystemPlaylistType.queue,
          ),
        ),
        throwsA(_failureWith(DomainFailureCode.forbidden)),
      );
      await expectLater(
        repository.savePlaylist(
          _playlist(
            id: 'duplicate-favorites',
            name: 'Duplicate',
            isSystem: true,
            systemType: SystemPlaylistType.favorites,
          ),
        ),
        throwsA(_failureWith(DomainFailureCode.forbidden)),
      );
      await expectLater(
        repository.deletePlaylist('system-favorites'),
        throwsA(_failureWith(DomainFailureCode.forbidden)),
      );
      await repository.deletePlaylist('custom');
      expect(await repository.getPlaylist('custom'), isNull);
    },
  );

  test('replaces mixed-source playlist entries without catalog rows', () async {
    await repository.savePlaylist(_playlist(id: 'playlist', name: 'Mixed'));
    final entries = [
      _playlistEntry(
        id: 'entry-0',
        playlistId: 'playlist',
        track: _ref('same', sourceId: 'remote', type: MusicSourceType.rest),
        position: 0,
      ),
      _playlistEntry(
        id: 'entry-1',
        playlistId: 'playlist',
        track: _ref('same', sourceId: 'local', type: MusicSourceType.local),
        position: 1,
      ),
    ];
    await repository.replacePlaylistEntries('playlist', entries);

    var stored = await repository.getPlaylistEntries('playlist');
    expect(stored.map((entry) => entry.id), ['entry-0', 'entry-1']);
    expect(stored.map((entry) => entry.track.sourceType), [
      MusicSourceType.rest,
      MusicSourceType.local,
    ]);
    expect(() => stored.add(entries.first), throwsUnsupportedError);
    expect(await _count(database, 'tracks'), 0);

    await repository.replacePlaylistEntries('playlist', [
      _playlistEntry(
        id: 'entry-1',
        playlistId: 'playlist',
        track: entries.last.track,
        position: 0,
      ),
    ]);
    stored = await repository.getPlaylistEntries('playlist');
    expect(stored.single.id, 'entry-1');
    await repository.deletePlaylist('playlist');
    expect(await _count(database, 'playlist_entries'), 0);
    expect(await _count(database, 'tracks'), 0);
  });

  test('validates playlist replacement before writing', () async {
    await repository.savePlaylist(_playlist(id: 'playlist', name: 'Valid'));
    final valid = _playlistEntry(
      id: 'entry',
      playlistId: 'playlist',
      track: _ref('track'),
      position: 0,
    );
    await repository.replacePlaylistEntries('playlist', [valid]);

    expect(
      () => repository.replacePlaylistEntries('playlist', [
        _playlistEntry(
          id: 'foreign',
          playlistId: 'another',
          track: _ref('track'),
          position: 0,
        ),
      ]),
      throwsArgumentError,
    );
    expect(
      () => repository.replacePlaylistEntries('playlist', [
        valid,
        _playlistEntry(
          id: 'entry',
          playlistId: 'playlist',
          track: _ref('other'),
          position: 1,
        ),
      ]),
      throwsArgumentError,
    );
    expect(
      () => repository.replacePlaylistEntries('playlist', [
        _playlistEntry(
          id: 'gap',
          playlistId: 'playlist',
          track: _ref('track'),
          position: 1,
        ),
      ]),
      throwsArgumentError,
    );
    await expectLater(
      repository.replacePlaylistEntries('missing', const []),
      throwsA(_failureWith(DomainFailureCode.notFound)),
    );
    expect(
      (await repository.getPlaylistEntries('playlist')).single.id,
      'entry',
    );
  });

  test('rolls back playlist replacement and redacts SQLite errors', () async {
    await repository.savePlaylist(_playlist(id: 'playlist', name: 'Atomic'));
    final original = _playlistEntry(
      id: 'original',
      playlistId: 'playlist',
      track: _ref('original'),
      position: 0,
    );
    await repository.replacePlaylistEntries('playlist', [original]);
    await database.customStatement('''
      CREATE TRIGGER fail_playlist_entry
      BEFORE INSERT ON playlist_entries
      WHEN NEW.entry_id = 'trigger-fail'
      BEGIN
        SELECT RAISE(ABORT, 'private playlist payload');
      END
    ''');

    DomainFailure? failure;
    try {
      await repository.replacePlaylistEntries('playlist', [
        _playlistEntry(
          id: 'good',
          playlistId: 'playlist',
          track: _ref('good'),
          position: 0,
        ),
        _playlistEntry(
          id: 'trigger-fail',
          playlistId: 'playlist',
          track: _ref('bad'),
          position: 1,
        ),
      ]);
    } on DomainFailure catch (error) {
      failure = error;
    }

    expect(failure, isNotNull);
    expect(failure!.code, DomainFailureCode.databaseCorrupted);
    expect(failure.toString(), isNot(contains('private playlist payload')));
    expect(
      (await repository.getPlaylistEntries('playlist')).single.id,
      'original',
    );
  });

  test(
    'persists duplicate queue refs and emits one committed snapshot',
    () async {
      final emissions = <QueueSnapshot>[];
      final initial = Completer<void>();
      final committed = Completer<void>();
      final subscription = repository.watchQueue().listen((snapshot) {
        emissions.add(snapshot);
        if (emissions.length == 1) initial.complete();
        if (emissions.length == 2) committed.complete();
      });
      addTearDown(subscription.cancel);
      await initial.future.timeout(const Duration(seconds: 2));

      final track = _ref('duplicate');
      final snapshot = QueueSnapshot(
        entries: [
          _queueEntry(id: 'queue-0', track: track, position: 0),
          _queueEntry(id: 'queue-1', track: track, position: 1),
        ],
        currentEntryId: 'queue-1',
        updatedAt: _epoch.add(const Duration(minutes: 1)),
      );
      await repository.saveQueue(snapshot);
      await committed.future.timeout(const Duration(seconds: 2));
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(emissions.map((item) => item.entries.length), [0, 2]);
      expect(emissions.last.entries.map((entry) => entry.id), [
        'queue-0',
        'queue-1',
      ]);
      expect(emissions.last.currentEntryId, 'queue-1');
      final loaded = await repository.loadQueue();
      expect(loaded.entries.map((entry) => entry.track), [track, track]);
      expect(loaded.updatedAt.isUtc, isTrue);
      expect(await _count(database, 'tracks'), 0);
    },
  );

  test('rolls back a failed queue replacement', () async {
    final original = QueueSnapshot(
      entries: [_queueEntry(id: 'original', track: _ref('old'), position: 0)],
      currentEntryId: 'original',
      updatedAt: _epoch,
    );
    await repository.saveQueue(original);
    await database.customStatement('''
      CREATE TRIGGER fail_queue_entry
      BEFORE INSERT ON queue_entries
      WHEN NEW.entry_id = 'trigger-fail'
      BEGIN
        SELECT RAISE(ABORT, 'private queue payload');
      END
    ''');

    DomainFailure? failure;
    try {
      await repository.saveQueue(
        QueueSnapshot(
          entries: [
            _queueEntry(id: 'good', track: _ref('new'), position: 0),
            _queueEntry(id: 'trigger-fail', track: _ref('bad'), position: 1),
          ],
          currentEntryId: 'good',
          updatedAt: _epoch.add(const Duration(minutes: 1)),
        ),
      );
    } on DomainFailure catch (error) {
      failure = error;
    }

    expect(failure, isNotNull);
    expect(failure!.code, DomainFailureCode.databaseCorrupted);
    expect(failure.toString(), isNot(contains('private queue payload')));
    final loaded = await repository.loadQueue();
    expect(loaded.entries.single.id, 'original');
    expect(loaded.currentEntryId, 'original');
    expect(loaded.updatedAt, _epoch);
  });

  test('favorites are idempotent and retain cross-source identity', () async {
    final remote = _ref('same', sourceId: 'remote', type: MusicSourceType.rest);
    final local = _ref('same', sourceId: 'local', type: MusicSourceType.local);
    await repository.setFavorite(remote, favorite: true);
    now = now.add(const Duration(seconds: 1));
    await repository.setFavorite(local, favorite: true);
    now = now.add(const Duration(seconds: 1));
    await repository.setFavorite(remote, favorite: true);

    var favorites = await repository.watchFavorites().first;
    expect(favorites.map((entry) => entry.track), [remote, local]);
    expect(favorites.first.addedAt, now);
    expect(await _count(database, 'favorites'), 2);
    await repository.setFavorite(remote, favorite: false);
    favorites = await repository.watchFavorites().first;
    expect(favorites.single.track, local);
  });

  test(
    'deduplicates history by TrackRef and retains only latest twenty',
    () async {
      for (var index = 0; index < 21; index++) {
        await repository.recordHistory(
          _history(
            id: 'history-$index',
            track: _ref('track-$index'),
            startedAt: _epoch.add(Duration(minutes: index)),
          ),
        );
      }
      await repository.recordHistory(
        _history(
          id: 'history-5-new',
          track: _ref('track-5'),
          startedAt: _epoch.add(const Duration(days: 1)),
        ),
      );

      var history = await repository.watchHistory().first;
      expect(history, hasLength(20));
      expect(history.first.id, 'history-5-new');
      expect(
        history.where((entry) => entry.track == _ref('track-5')),
        hasLength(1),
      );
      expect(history.any((entry) => entry.track == _ref('track-0')), isFalse);
      expect(history.every((entry) => entry.startedAt.isUtc), isTrue);
      await repository.clearHistory();
      history = await repository.watchHistory().first;
      expect(history, isEmpty);
    },
  );

  test('turns corrupt collection rows into redacted failures', () async {
    const privateValue = 'private-source-type';
    await database
        .into(database.queueEntryRecords)
        .insert(
          QueueEntryRecordsCompanion.insert(
            entryId: 'corrupt-entry',
            trackSourceType: privateValue,
            trackSourceId: 'source',
            trackId: 'track',
            position: 0,
            addedAtMs: _epoch.millisecondsSinceEpoch,
          ),
        );
    await (database.update(
      database.queueStateRecords,
    )..where((table) => table.singletonId.equals(1))).write(
      QueueStateRecordsCompanion(
        currentEntryId: const Value('corrupt-entry'),
        updatedAtMs: Value(_epoch.millisecondsSinceEpoch),
      ),
    );

    DomainFailure? failure;
    try {
      await repository.loadQueue();
    } on DomainFailure catch (error) {
      failure = error;
    }
    expect(failure, isNotNull);
    expect(failure!.code, DomainFailureCode.databaseCorrupted);
    expect(failure.toString(), isNot(contains(privateValue)));

    await database.delete(database.queueEntryRecords).go();
    await repository.savePlaylist(_playlist(id: 'corrupt-list', name: 'List'));
    await database.batch((batch) {
      batch.insert(
        database.playlistEntryRecords,
        PlaylistEntryRecordsCompanion.insert(
          entryId: 'gap-entry',
          playlistId: 'corrupt-list',
          trackSourceType: MusicSourceType.rest.name,
          trackSourceId: 'source',
          trackId: 'track',
          position: 2,
          addedAtMs: _epoch.millisecondsSinceEpoch,
        ),
      );
    });
    await expectLater(
      repository.getPlaylistEntries('corrupt-list'),
      throwsA(_failureWith(DomainFailureCode.databaseCorrupted)),
    );
  });

  test('supports shared and owned database disposal', () async {
    await repository.dispose();
    await repository.dispose();
    expect(() => repository.watchQueue(), throwsStateError);
    expect(await _count(database, 'queue_state'), 1);

    final ownedRepository = DriftCollectionRepository.owned(database);
    expect((await ownedRepository.loadQueue()).entries, isEmpty);
    await ownedRepository.dispose();
    await ownedRepository.dispose();
    await expectLater(
      database.customSelect('SELECT 1').get(),
      throwsA(anything),
    );
  });
}

final DateTime _epoch = DateTime.utc(2026, 9, 1, 8);

Playlist _playlist({
  required String id,
  required String name,
  DateTime? updatedAt,
  bool isSystem = false,
  SystemPlaylistType? systemType,
}) => Playlist(
  id: id,
  name: name,
  createdAt: _epoch,
  updatedAt: updatedAt ?? _epoch,
  isSystem: isSystem,
  systemType: systemType,
);

TrackRef _ref(
  String id, {
  String sourceId = 'source-a',
  MusicSourceType type = MusicSourceType.rest,
}) => TrackRef(trackId: id, sourceId: sourceId, sourceType: type);

PlaylistEntry _playlistEntry({
  required String id,
  required String playlistId,
  required TrackRef track,
  required int position,
}) => PlaylistEntry(
  id: id,
  playlistId: playlistId,
  track: track,
  position: position,
  addedAt: _epoch.add(Duration(seconds: position)),
);

QueueEntry _queueEntry({
  required String id,
  required TrackRef track,
  required int position,
}) => QueueEntry(
  id: id,
  track: track,
  position: position,
  addedAt: _epoch.add(Duration(seconds: position)),
);

PlayHistoryEntry _history({
  required String id,
  required TrackRef track,
  required DateTime startedAt,
}) => PlayHistoryEntry(
  id: id,
  track: track,
  startedAt: startedAt,
  lastPosition: const Duration(seconds: 30),
);

Matcher _failureWith(DomainFailureCode code) =>
    isA<DomainFailure>().having((failure) => failure.code, 'code', code);

Future<int> _count(AppDatabase database, String table) async {
  final row = await database
      .customSelect('SELECT COUNT(*) AS n FROM $table')
      .getSingle();
  return row.read<int>('n');
}
