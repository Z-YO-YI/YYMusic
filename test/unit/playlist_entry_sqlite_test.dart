import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/data/database/app_database.dart';
import 'package:yymusic/data/repositories/drift_collection_repository.dart';
import 'package:yymusic/data/repositories/drift_library_repository.dart';
import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/domain/models/domain_failure.dart';
import 'package:yymusic/features/library/common/library_controller.dart';

import '../support/fake_audio_engine.dart';
import '../support/fake_playback_dependencies.dart';
import 'playlist_controller_test.dart' show playlistEpoch;
import 'playlist_entry_repository_test.dart'
    show entryDraft, seedEntries, expectEntryOrder;
import 'playlist_metadata_sqlite_test.dart'
    show playlistFailure, waitForPlaylistProjection;

void main() {
  late AppDatabase database;
  late DriftCollectionRepository repository;
  late DateTime now;
  setUp(() {
    now = playlistEpoch;
    database = AppDatabase(NativeDatabase.memory());
    repository = DriftCollectionRepository(database, clock: () => now);
  });
  tearDown(() async {
    await repository.dispose();
    await database.close();
  });

  for (final stage in [
    'insert',
    'delete',
    'temporary',
    'refill',
    'target',
    'parent',
  ]) {
    test('SQLite abort at $stage rolls every entry position and parent timestamp back', () async {
      await seedEntries(repository, 'p', ['a', 'b', 'c', 'd']);
      await seedEntries(repository, 'other', ['foreign']);
      now = now.add(const Duration(hours: 1));
      final trigger = switch (stage) {
        'insert' => 'BEFORE INSERT ON playlist_entries',
        'delete' => 'BEFORE DELETE ON playlist_entries',
        'temporary' =>
          'BEFORE UPDATE OF position ON playlist_entries WHEN NEW.position > 4',
        'refill' => 'BEFORE UPDATE OF position ON playlist_entries WHEN OLD.position > 4 AND NEW.position < 4',
        'target' => "BEFORE UPDATE OF position ON playlist_entries WHEN OLD.entry_id = 'a' AND OLD.position = 4",
        _ => 'BEFORE UPDATE ON playlists',
      };
      await database.customStatement(
        "CREATE TRIGGER fail_entry_command $trigger BEGIN SELECT RAISE(ABORT, 'private-marker'); END",
      );
      final command = switch (stage) {
        'insert' => repository.appendPlaylistEntry('p', entryDraft('new')),
        'delete' => repository.removePlaylistEntry('p', 'b'),
        _ => repository.movePlaylistEntry('p', 'a'),
      };
      await expectLater(
        command,
        throwsA(playlistFailure(DomainFailureCode.databaseCorrupted)),
      );
      await expectEntryOrder(repository, 'p', ['a', 'b', 'c', 'd']);
      await expectEntryOrder(repository, 'other', ['foreign']);
      expect((await repository.getPlaylist('p'))!.updatedAt, playlistEpoch);
      await database.customStatement('DROP TRIGGER fail_entry_command');
      await repository.movePlaylistEntry('p', 'a');
      await expectEntryOrder(repository, 'p', ['b', 'c', 'd', 'a']);
    });
  }

  test('append and remove also roll back when the final parent timestamp update fails', () async {
    await seedEntries(repository, 'p', ['a', 'b', 'c']);
    await database.customStatement(
      "CREATE TRIGGER fail_parent BEFORE UPDATE ON playlists BEGIN SELECT RAISE(ABORT, 'private-marker'); END",
    );
    for (final command in <Future<void> Function()>[
      () => repository.appendPlaylistEntry('p', entryDraft('new')),
      () => repository.removePlaylistEntry('p', 'a'),
    ]) {
      await expectLater(
        command(),
        throwsA(playlistFailure(DomainFailureCode.databaseCorrupted)),
      );
      await expectEntryOrder(repository, 'p', ['a', 'b', 'c']);
    }
  });

  test('corrupt noncontiguous positions fail closed without silently repairing or deleting user data', () async {
    await seedEntries(repository, 'p', ['a', 'b']);
    await database.customStatement(
      "UPDATE playlist_entries SET position = 9 WHERE entry_id = 'b'",
    );
    for (final command in <Future<void> Function()>[
      () => repository.appendPlaylistEntry('p', entryDraft('new')),
      () => repository.removePlaylistEntry('p', 'a'),
      () => repository.movePlaylistEntry('p', 'b', beforeEntryId: 'a'),
    ]) {
      await expectLater(
        command(),
        throwsA(playlistFailure(DomainFailureCode.databaseCorrupted)),
      );
    }
    final rows = await database
        .customSelect(
          'SELECT entry_id, position FROM playlist_entries ORDER BY position',
        )
        .get();
    expect(rows.map((r) => r.read<String>('entry_id')), ['a', 'b']);
    expect(rows.map((r) => r.read<int>('position')), [0, 9]);
    expect((await repository.getPlaylist('p'))!.updatedAt, playlistEpoch);
  });

  test('entry-only edits do not alter tracks favorites history queue or other playlists', () async {
    final library = DriftLibraryRepository(database);
    addTearDown(library.dispose);
    await library.initialize();
    await library.upsertTracks([playbackFixtureTrack]);
    final ref = playbackFixtureTrack.ref;
    await repository.setFavorite(ref, favorite: true);
    await repository.recordHistory(
      PlayHistoryEntry(
        id: 'history',
        track: ref,
        startedAt: playlistEpoch,
        lastPosition: const Duration(seconds: 3),
      ),
    );
    await repository.saveQueue(
      QueueSnapshot(
        entries: [
          QueueEntry(
            id: 'queue',
            track: ref,
            position: 0,
            addedAt: playlistEpoch,
          ),
        ],
        currentEntryId: 'queue',
        updatedAt: playlistEpoch,
      ),
    );
    await seedEntries(repository, 'p', ['a']);
    await seedEntries(repository, 'other', ['foreign']);
    await repository.appendPlaylistEntry('p', entryDraft('b', track: ref));
    await repository.movePlaylistEntry('p', 'b', beforeEntryId: 'a');
    await repository.removePlaylistEntry('p', 'b');
    await expectEntryOrder(repository, 'p', ['a']);
    await expectEntryOrder(repository, 'other', ['foreign']);
    expect((await library.getTrack(ref))!.ref, ref);
    expect((await repository.watchFavorites().first).single.track, ref);
    expect(
      (await repository.watchHistory().first).single.lastPosition,
      const Duration(seconds: 3),
    );
    expect((await repository.loadQueue()).currentEntryId, 'queue');
    expect((await repository.loadQueue()).entries.single.track, ref);
  });

  test('existing Library projection sees each root entry command without a second list or playback', () async {
    await seedEntries(repository, 'p', ['a', 'b']);
    final engine = FakeAudioEngine();
    final graph = DependencyGraph(collection: repository, audioEngine: engine);
    addTearDown(graph.close);
    graph.libraryController.start();
    graph.libraryController.selectCategory(LibraryCategory.playlists);
    await waitForPlaylistProjection(
      graph,
      (items) => items.any((p) => p.id == 'p'),
    );
    for (var i = 0; i < 3; i++) {
      now = now.add(const Duration(hours: 1));
      final projection = waitForPlaylistProjection(
        graph,
        (items) => items.any((p) => p.id == 'p' && p.updatedAt == now),
      );
      final result = await switch (i) {
        0 => graph.playlists.addTrack('p', playbackFixtureTrack.ref),
        1 => graph.playlists.moveEntry('p', 'b', beforeEntryId: 'a'),
        _ => graph.playlists.removeEntry('p', 'a'),
      };
      expect(result.succeeded, isTrue);
      await projection;
    }
    expect((await repository.getPlaylistEntries('p')).length, 2);
    expect(engine.calls, isEmpty);
  });

  test('disposed SQLite repository rejects every new entry command', () async {
    await repository.dispose();
    for (final command in <Future<void> Function()>[
      () => repository.appendPlaylistEntry('p', entryDraft('new')),
      () => repository.removePlaylistEntry('p', 'a'),
      () => repository.movePlaylistEntry('p', 'a'),
    ]) {
      expect(command, throwsStateError);
    }
  });
}
