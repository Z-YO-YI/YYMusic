import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/features/playlists/common/playlist_command_result.dart';
import 'package:yymusic/features/playlists/common/playlist_controller.dart';

import '../support/fake_domain_repositories.dart';
import '../support/fake_playback_dependencies.dart';
import 'playlist_controller_test.dart'
    show playlistEpoch, commandPlaylist, drainPlaylistWork;
import 'playlist_entry_repository_test.dart'
    show entryDraft, seedEntries, expectEntryOrder;

void main() {
  test('entry commands borrow storage, preserve full refs and generate independent IDs even for duplicates', () async {
    final repository = FakeCollectionRepository(
      playlists: [commandPlaylist('p')],
    );
    final controller = PlaylistController(
      collection: repository,
      clock: () => playlistEpoch.toLocal(),
    );
    addTearDown(() async {
      await controller.close();
      await repository.dispose();
    });
    expect(repository.playlistReadCount, 0);
    expect(repository.playlistWatchCount, 0);
    final ref = playbackFixtureTrack.ref;
    for (var i = 0; i < 32; i++) {
      final result = await controller.addTrack('p', ref);
      expect(result.succeeded, isTrue);
      expect(result.playlistId, 'p');
    }
    final entries = await repository.getPlaylistEntries('p');
    expect(entries.map((e) => e.id).toSet().length, 32);
    for (final entry in entries) {
      expect(entry.id, matches(RegExp(r'^playlist-entry-[0-9a-f]{32}$')));
      expect(entry.addedAt, playlistEpoch);
      expect(entry.track, ref);
    }
    expect(
      (await controller.moveEntry(
        'p',
        entries.last.id,
        beforeEntryId: entries.first.id,
      )).succeeded,
      isTrue,
    );
    expect(
      (await controller.removeEntry('p', entries.first.id)).succeeded,
      isTrue,
    );
    expect(repository.playlistWatchCount, 0);
    expect(repository.playlistReadCount, 0);
  });

  test('entry and metadata commands share busy before notification and rejected attempts do not call factories', () async {
    final repository = FakeCollectionRepository(
      playlists: [commandPlaylist('p')],
    );
    final gate = Completer<void>();
    repository.onPlaylistMutation = (_, _) => gate.future;
    var ids = 0;
    var clocks = 0;
    final controller = PlaylistController(
      collection: repository,
      entryIdFactory: () => 'e-${ids++}',
      clock: () {
        clocks++;
        return playlistEpoch;
      },
    );
    addTearDown(() async {
      if (!gate.isCompleted) gate.complete();
      await controller.close();
      await repository.dispose();
    });
    Future<PlaylistCommandResult>? reentrant;
    controller.addListener(() {
      if (controller.busy) reentrant ??= controller.createPlaylist('重入');
    });
    final write = controller.addTrack('p', playbackFixtureTrack.ref);
    expect(controller.busy, isTrue);
    expect((await reentrant!).status, PlaylistCommandStatus.busy);
    for (final result in [
      await controller.addTrack('p', playbackFixtureTrack.ref),
      await controller.renamePlaylist('p', '更名'),
      await controller.deletePlaylist('p'),
      await controller.removeEntry('p', 'a'),
      await controller.moveEntry('p', 'a'),
    ]) {
      expect(result.status, PlaylistCommandStatus.busy);
    }
    await drainPlaylistWork();
    expect(ids, 1);
    expect(clocks, 1);
    expect(repository.playlistMutationCalls, ['append-entry']);
    gate.complete();
    expect((await write).succeeded, isTrue);
    expect(controller.busy, isFalse);
  });

  test('system missing collision and storage failures return fixed safe outcomes and permit explicit retry', () async {
    final repository = FakeCollectionRepository(
      playlists: [commandPlaylist('system', system: true)],
    );
    await seedEntries(repository, 'p', ['collision']);
    final controller = PlaylistController(
      collection: repository,
      entryIdFactory: () => 'collision',
    );
    addTearDown(() async {
      await controller.close();
      await repository.dispose();
    });
    for (final result in [
      await controller.addTrack('system', playbackFixtureTrack.ref),
      await controller.removeEntry('system', 'absent'),
      await controller.moveEntry('system', 'absent'),
    ]) {
      expect(result.status, PlaylistCommandStatus.protectedPlaylist);
    }
    expect(
      (await controller.addTrack('p', playbackFixtureTrack.ref)).status,
      PlaylistCommandStatus.failed,
    );
    for (final result in [
      await controller.addTrack('missing', playbackFixtureTrack.ref),
      await controller.removeEntry('missing', 'a'),
      await controller.moveEntry('p', 'missing'),
      await controller.moveEntry('p', 'collision', beforeEntryId: 'missing'),
    ]) {
      expect(result.status, PlaylistCommandStatus.notFound);
      expect(result.message, '此歌单或歌曲条目已不存在，请刷新列表。');
    }
    repository.onPlaylistMutation = (_, _) async =>
        throw StateError('private-marker');
    final failure = await controller.removeEntry('p', 'collision');
    expect(failure.status, PlaylistCommandStatus.failed);
    expect(failure.playlistId, isNull);
    expect(failure.message, isNot(contains('private-marker')));
    repository.onPlaylistMutation = null;
    expect((await controller.removeEntry('p', 'collision')).succeeded, isTrue);
    expect(
      (await controller.addTrack('p', playbackFixtureTrack.ref)).succeeded,
      isTrue,
    );
  });

  test(
    'invalid IDs and unavailable or closed controller make no repository calls',
    () async {
      final repository = FakeCollectionRepository();
      final controller = PlaylistController(collection: repository);
      for (final result in [
        await controller.addTrack(' bad ', playbackFixtureTrack.ref),
        await controller.removeEntry('p', ''),
        await controller.moveEntry('p', 'a', beforeEntryId: '\n'),
      ]) {
        expect(result.status, PlaylistCommandStatus.failed);
      }
      expect(repository.playlistMutationCalls, isEmpty);
      await controller.close();
      final absent = PlaylistController();
      for (final c in [controller, absent]) {
        for (final result in [
          await c.addTrack('p', playbackFixtureTrack.ref),
          await c.removeEntry('p', 'a'),
          await c.moveEntry('p', 'a'),
        ]) {
          expect(result.status, PlaylistCommandStatus.unavailable);
        }
      }
      await absent.close();
      await repository.dispose();
    },
  );

  for (final operation in ['append', 'remove', 'move']) {
    for (final fail in [false, true]) {
      test(
        'root close drains accepted $operation (failure=$fail) before disposing shared storage',
        () async {
          final repository = FakeCollectionRepository();
          await seedEntries(repository, 'p', ['a', 'b']);
          final library = FakeLibraryRepository();
          final graph = DependencyGraph(
            collection: repository,
            library: library,
          );
          final gate = Completer<void>();
          repository.onPlaylistMutation = (_, _) => gate.future;
          final write = switch (operation) {
            'append' => graph.playlists.addTrack('p', playbackFixtureTrack.ref),
            'remove' => graph.playlists.removeEntry('p', 'a'),
            _ => graph.playlists.moveEntry('p', 'b', beforeEntryId: 'a'),
          };
          var closed = false;
          final close = graph.close().then((_) => closed = true);
          await drainPlaylistWork();
          expect(graph.playlists.isAvailable, isFalse);
          expect(closed, isFalse);
          expect(library.disposeCount, 0);
          if (fail) {
            gate.completeError(StateError('private-marker'));
          } else {
            gate.complete();
          }
          expect(
            (await write).status,
            fail
                ? PlaylistCommandStatus.failed
                : PlaylistCommandStatus.succeeded,
          );
          await close;
          expect(library.disposeCount, 1);
          if (fail) await expectEntryOrder(repository, 'p', ['a', 'b']);
          await graph.close();
          expect(library.disposeCount, 1);
          await repository.dispose();
        },
      );
    }
  }

  test('entry factory reentrant close waits for registered write while factory failure is safe and recoverable', () async {
    final repository = FakeCollectionRepository(
      playlists: [commandPlaylist('p')],
    );
    late PlaylistController controller;
    Future<void>? closed;
    var failFactory = true;
    controller = PlaylistController(
      collection: repository,
      entryIdFactory: () {
        if (failFactory) throw StateError('private-marker');
        closed = controller.close();
        return 'accepted';
      },
    );
    expect(
      (await controller.addTrack('p', entryDraft('unused').track)).status,
      PlaylistCommandStatus.failed,
    );
    expect(repository.playlistMutationCalls, isEmpty);
    failFactory = false;
    expect(
      (await controller.addTrack('p', entryDraft('unused').track)).succeeded,
      isTrue,
    );
    await closed;
    expect(controller.isAvailable, isFalse);
    expect((await repository.getPlaylistEntries('p')).single.id, 'accepted');
    await repository.dispose();
  });
}
