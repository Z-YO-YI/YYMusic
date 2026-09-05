import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/data/database/app_database.dart';
import 'package:yymusic/data/repositories/drift_collection_repository.dart';
import 'package:yymusic/data/repositories/drift_library_repository.dart';
import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/domain/models/domain_failure.dart';
import 'package:yymusic/domain/models/track.dart';
import 'package:yymusic/features/library/common/library_controller.dart';

import '../support/fake_audio_engine.dart';
import '../support/fake_playback_dependencies.dart';
import 'playlist_controller_test.dart' show playlistEpoch, commandPlaylist;

Matcher playlistFailure(DomainFailureCode code) => isA<DomainFailure>()
    .having((failure) => failure.code, 'code', code)
    .having(
      (failure) => failure.toString(),
      'safe error',
      isNot(contains('private-marker')),
    );

PlaylistEntry metadataEntry(
  String playlistId, {
  String id = 'entry',
  int position = 0,
}) => PlaylistEntry(
  id: id,
  playlistId: playlistId,
  track: TrackRef(
    sourceType: MusicSourceType.rest,
    sourceId: 'source-a',
    trackId: 'same-id',
  ),
  position: position,
  addedAt: playlistEpoch,
);

Future<void> waitForPlaylistProjection(
  DependencyGraph graph,
  bool Function(List<Playlist>) matches,
) {
  final completion = Completer<void>();
  void check() {
    if (!completion.isCompleted &&
        matches(
          graph.libraryController.page.items.whereType<Playlist>().toList(),
        )) {
      completion.complete();
    }
  }

  graph.libraryController.addListener(check);
  check();
  return completion.future
      .timeout(const Duration(seconds: 5))
      .whenComplete(() => graph.libraryController.removeListener(check));
}

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

  test('create-only normalizes names, preserves metadata and never overwrites a collided ID', () async {
    final playlist = Playlist(
      id: 'custom',
      name: '  新歌单  ',
      description: '保留说明',
      createdAt: playlistEpoch,
      updatedAt: playlistEpoch,
    );
    await repository.createPlaylist(playlist);
    await repository.replacePlaylistEntries(playlist.id, [
      metadataEntry(playlist.id),
    ]);
    await expectLater(
      repository.createPlaylist(commandPlaylist(playlist.id)),
      throwsA(playlistFailure(DomainFailureCode.forbidden)),
    );
    final stored = (await repository.getPlaylist(playlist.id))!;
    expect(stored.name, '新歌单');
    expect(stored.description, '保留说明');
    expect(stored.createdAt, playlistEpoch);
    expect(stored.updatedAt, playlistEpoch);
    expect(
      (await repository.getPlaylistEntries(playlist.id)).single.track,
      metadataEntry(playlist.id).track,
    );
    await repository.createPlaylist(
      Playlist(
        id: 'second',
        name: stored.name,
        createdAt: playlistEpoch,
        updatedAt: playlistEpoch,
      ),
    );
    expect((await repository.watchPlaylists().first).length, 2);
  });

  test('concurrent create attempts on one identity commit once instead of last-writer overwrite', () async {
    final a = commandPlaylist('collision');
    final b = Playlist(
      id: a.id,
      name: '第二次写入',
      createdAt: playlistEpoch,
      updatedAt: playlistEpoch,
    );
    Future<bool> create(Playlist value) async {
      try {
        await repository.createPlaylist(value);
        return true;
      } on DomainFailure catch (error) {
        expect(error.code, DomainFailureCode.forbidden);
        return false;
      }
    }

    final outcomes = await Future.wait([create(a), create(b)]);
    expect(outcomes.where((ok) => ok).length, 1);
    expect((await repository.watchPlaylists().first).length, 1);
    expect(
      (await repository.getPlaylist(a.id))!.name,
      outcomes.first ? a.name : b.name,
    );
  });

  test('all system identities reject user create rename and delete without changing stored values', () async {
    for (final type in SystemPlaylistType.values) {
      final system = Playlist(
        id: 'system-${type.name}',
        name: '系统-${type.name}',
        createdAt: playlistEpoch,
        updatedAt: playlistEpoch,
        isSystem: true,
        systemType: type,
      );
      await expectLater(
        repository.createPlaylist(system),
        throwsA(playlistFailure(DomainFailureCode.forbidden)),
      );
      await repository.savePlaylist(system);
      await expectLater(
        repository.renamePlaylist(system.id, '不允许'),
        throwsA(playlistFailure(DomainFailureCode.forbidden)),
      );
      await expectLater(
        repository.deletePlaylist(system.id),
        throwsA(playlistFailure(DomainFailureCode.forbidden)),
      );
      expect((await repository.getPlaylist(system.id))!.name, system.name);
    }
    expect((await repository.watchPlaylists().first).length, 3);
  });

  test('rename only changes name and monotonic updatedAt, preserving metadata and mixed entries', () async {
    final playlist = commandPlaylist('custom');
    await repository.createPlaylist(playlist);
    final entries = [
      metadataEntry(playlist.id),
      PlaylistEntry(
        id: 'local',
        playlistId: playlist.id,
        track: TrackRef(
          sourceType: MusicSourceType.local,
          sourceId: 'source-b',
          trackId: 'same-id',
        ),
        position: 1,
        addedAt: playlistEpoch,
      ),
    ];
    await repository.replacePlaylistEntries(playlist.id, entries);
    now = playlistEpoch.subtract(const Duration(days: 1));
    await repository.renamePlaylist(playlist.id, '  新的名称  ');
    var stored = (await repository.getPlaylist(playlist.id))!;
    expect(stored.name, '新的名称');
    expect(stored.description, playlist.description);
    expect(stored.createdAt, playlist.createdAt);
    expect(stored.updatedAt, playlist.updatedAt);
    now = playlistEpoch.add(const Duration(hours: 1));
    await repository.renamePlaylist(playlist.id, '再次改名');
    stored = (await repository.getPlaylist(playlist.id))!;
    expect(stored.updatedAt, now);
    final retained = await repository.getPlaylistEntries(playlist.id);
    expect(retained.map((e) => e.id), entries.map((e) => e.id));
    expect(retained.map((e) => e.track), entries.map((e) => e.track));
    expect(retained.map((e) => e.addedAt), entries.map((e) => e.addedAt));
    expect(retained.map((e) => e.position), [0, 1]);
  });

  test(
    'missing or invalid rename never inserts a target or partially edits one',
    () async {
      await repository.createPlaylist(commandPlaylist('custom'));
      await repository.deletePlaylist('custom');
      await expectLater(
        repository.renamePlaylist('custom', '不能复活'),
        throwsA(playlistFailure(DomainFailureCode.notFound)),
      );
      expect(await repository.getPlaylist('custom'), isNull);
      await repository.createPlaylist(commandPlaylist('custom'));
      for (final invalid in [
        '',
        '  ',
        '名称\n',
        '名称\u007f',
        List.filled(513, '字').join(),
      ]) {
        expect(
          () => repository.renamePlaylist('custom', invalid),
          throwsArgumentError,
        );
      }
      final invalid = Playlist(
        id: 'invalid',
        name: '名称\n',
        createdAt: playlistEpoch,
        updatedAt: playlistEpoch,
      );
      expect(() => repository.createPlaylist(invalid), throwsArgumentError);
      expect(await repository.getPlaylist('invalid'), isNull);
      expect((await repository.getPlaylist('custom'))!.name, '原名称');
    },
  );

  test('delete removes only its playlist and entries, preserving tracks favorites history queue and other playlists', () async {
    final library = DriftLibraryRepository(database);
    addTearDown(library.dispose);
    await library.initialize();
    await library.upsertTracks([playbackFixtureTrack]);
    final reference = playbackFixtureTrack.ref;
    await repository.setFavorite(reference, favorite: true);
    await repository.recordHistory(
      PlayHistoryEntry(
        id: 'history',
        track: reference,
        startedAt: playlistEpoch,
        lastPosition: Duration.zero,
      ),
    );
    await repository.saveQueue(
      QueueSnapshot(
        entries: [
          QueueEntry(
            id: 'queue',
            track: reference,
            position: 0,
            addedAt: playlistEpoch,
          ),
        ],
        currentEntryId: 'queue',
        updatedAt: playlistEpoch,
      ),
    );
    await repository.createPlaylist(commandPlaylist('remove'));
    await repository.createPlaylist(commandPlaylist('keep'));
    await repository.replacePlaylistEntries('remove', [
      metadataEntry('remove'),
    ]);
    await repository.replacePlaylistEntries('keep', [
      metadataEntry('keep', id: 'kept-entry'),
    ]);
    await repository.deletePlaylist('remove');
    await repository.deletePlaylist('remove');
    expect(await repository.getPlaylist('remove'), isNull);
    expect(await repository.getPlaylistEntries('remove'), isEmpty);
    expect(
      (await repository.getPlaylistEntries('keep')).single.id,
      'kept-entry',
    );
    expect((await library.getTrack(reference))!.ref, reference);
    expect((await repository.watchFavorites().first).single.track, reference);
    expect((await repository.watchHistory().first).single.track, reference);
    expect((await repository.loadQueue()).currentEntryId, 'queue');
    expect((await repository.loadQueue()).entries.single.track, reference);
  });

  test(
    'SQLite abort rolls rename and cascading delete back and sanitizes failure',
    () async {
      await repository.createPlaylist(commandPlaylist('custom'));
      await repository.replacePlaylistEntries('custom', [
        metadataEntry('custom'),
      ]);
      await database.customStatement(
        "CREATE TRIGGER fail_metadata_update BEFORE UPDATE ON playlists BEGIN SELECT RAISE(ABORT, 'private-marker'); END",
      );
      await expectLater(
        repository.renamePlaylist('custom', '不能写入'),
        throwsA(playlistFailure(DomainFailureCode.databaseCorrupted)),
      );
      expect((await repository.getPlaylist('custom'))!.name, '原名称');
      await database.customStatement('DROP TRIGGER fail_metadata_update');
      await database.customStatement(
        "CREATE TRIGGER fail_entry_delete BEFORE DELETE ON playlist_entries BEGIN SELECT RAISE(ABORT, 'private-marker'); END",
      );
      await expectLater(
        repository.deletePlaylist('custom'),
        throwsA(playlistFailure(DomainFailureCode.databaseCorrupted)),
      );
      expect(await repository.getPlaylist('custom'), isNotNull);
      expect((await repository.getPlaylistEntries('custom')).length, 1);
      await database.customStatement('DROP TRIGGER fail_entry_delete');
      await repository.deletePlaylist('custom');
      expect(await repository.getPlaylist('custom'), isNull);
    },
  );

  test('root commands update the existing Library SQLite projection without another playlist cache or playback', () async {
    final engine = FakeAudioEngine();
    final graph = DependencyGraph(collection: repository, audioEngine: engine);
    addTearDown(graph.close);
    graph.libraryController.start();
    graph.libraryController.selectCategory(LibraryCategory.playlists);
    final createdProjection = waitForPlaylistProjection(
      graph,
      (items) => items.any((p) => p.name == '命令创建'),
    );
    final result = await graph.playlists.createPlaylist('命令创建');
    expect(result.succeeded, isTrue);
    await createdProjection;
    final renamedProjection = waitForPlaylistProjection(
      graph,
      (items) =>
          items.any((p) => p.id == result.playlistId && p.name == '命令改名'),
    );
    expect(
      (await graph.playlists.renamePlaylist(
        result.playlistId!,
        '命令改名',
      )).succeeded,
      isTrue,
    );
    await renamedProjection;
    final deletedProjection = waitForPlaylistProjection(
      graph,
      (items) => items.isEmpty,
    );
    expect(
      (await graph.playlists.deletePlaylist(result.playlistId!)).succeeded,
      isTrue,
    );
    await deletedProjection;
    expect(engine.calls, isEmpty);
  });
}
