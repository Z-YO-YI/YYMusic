import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/features/playlists/common/playlist_command_result.dart';
import 'package:yymusic/features/playlists/common/playlist_controller.dart';

import '../support/fake_domain_repositories.dart';

final playlistEpoch = DateTime.utc(2026, 9, 6);
Playlist commandPlaylist(String id, {bool system = false}) => Playlist(
  id: id,
  name: '原名称',
  description: '保留说明',
  createdAt: playlistEpoch,
  updatedAt: playlistEpoch,
  isSystem: system,
  systemType: system ? SystemPlaylistType.favorites : null,
);

Future<void> drainPlaylistWork() async {
  for (var i = 0; i < 12; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  test('construction issues no reads or subscriptions and metadata commands share the borrowed repository', () async {
    final repository = FakeCollectionRepository(clock: () => playlistEpoch);
    final c = PlaylistController(
      collection: repository,
      idFactory: () => 'stable-id',
      clock: () => playlistEpoch,
    );
    addTearDown(() async {
      await c.close();
      await repository.dispose();
    });
    expect(repository.playlistReadCount, 0);
    expect(repository.playlistWatchCount, 0);
    expect(repository.playlistMutationCalls, isEmpty);
    final created = await c.createPlaylist('  我的歌单  ');
    expect(created.succeeded, isTrue);
    expect(created.playlistId, 'stable-id');
    var stored = (await repository.getPlaylist('stable-id'))!;
    expect(stored.name, '我的歌单');
    expect(stored.createdAt, playlistEpoch);
    expect(stored.updatedAt, playlistEpoch);
    final renamed = await c.renamePlaylist(stored.id, '新的名称');
    expect(renamed.succeeded, isTrue);
    stored = (await repository.getPlaylist(stored.id))!;
    expect(stored.name, '新的名称');
    expect((await c.deletePlaylist(stored.id)).succeeded, isTrue);
    expect(await repository.getPlaylist(stored.id), isNull);
    expect(repository.playlistMutationCalls, ['create', 'rename', 'delete']);
  });

  test(
    'name validation is safe and occurs before any repository writes',
    () async {
      final repository = FakeCollectionRepository();
      final c = PlaylistController(collection: repository);
      addTearDown(() async {
        await c.close();
        await repository.dispose();
      });
      for (final name in [
        '',
        '   ',
        '\n歌单',
        '歌\t单',
        '歌单\u007f',
        '歌单\u0085',
        '歌单\u009f',
        '\u0000歌单',
        List.filled(513, '字').join(),
      ]) {
        for (final result in [
          await c.createPlaylist(name),
          await c.renamePlaylist('id', name),
        ]) {
          expect(result.status, PlaylistCommandStatus.invalidName);
          expect(result.playlistId, isNull);
        }
      }
      expect(repository.playlistMutationCalls, isEmpty);
      final result = await c.createPlaylist(List.filled(512, '字').join());
      expect(result.succeeded, isTrue);
    },
  );

  test('system playlists are protected and same-name custom playlists remain distinct', () async {
    final system = commandPlaylist('system', system: true);
    final repository = FakeCollectionRepository(playlists: [system]);
    var sequence = 0;
    final c = PlaylistController(
      collection: repository,
      idFactory: () => 'custom-${sequence++}',
    );
    addTearDown(() async {
      await c.close();
      await repository.dispose();
    });
    expect(
      (await c.renamePlaylist('system', '新名称')).status,
      PlaylistCommandStatus.protectedPlaylist,
    );
    expect(
      (await c.deletePlaylist('system')).status,
      PlaylistCommandStatus.protectedPlaylist,
    );
    expect((await repository.getPlaylist('system'))!.name, system.name);
    final first = await c.createPlaylist('同名歌单');
    final second = await c.createPlaylist('同名歌单');
    expect(first.succeeded && second.succeeded, isTrue);
    expect(first.playlistId, isNot(second.playlistId));
  });

  test('collision never overwrites an existing playlist and a new attempt can recover', () async {
    final existing = commandPlaylist('same-id');
    final repository = FakeCollectionRepository(playlists: [existing]);
    var id = existing.id;
    final c = PlaylistController(collection: repository, idFactory: () => id);
    addTearDown(() async {
      await c.close();
      await repository.dispose();
    });
    expect(
      (await c.createPlaylist('不应覆盖')).status,
      PlaylistCommandStatus.failed,
    );
    expect(
      (await repository.getPlaylist(id))!.description,
      existing.description,
    );
    expect((await repository.getPlaylist(id))!.name, existing.name);
    id = 'new-id';
    expect((await c.createPlaylist('可重试')).succeeded, isTrue);
  });

  test('missing rename does not revive a target while repeated deletion stays idempotent', () async {
    final repository = FakeCollectionRepository();
    final c = PlaylistController(collection: repository);
    addTearDown(() async {
      await c.close();
      await repository.dispose();
    });
    expect(
      (await c.renamePlaylist('missing', '新名称')).status,
      PlaylistCommandStatus.notFound,
    );
    expect(await repository.getPlaylist('missing'), isNull);
    expect((await c.deletePlaylist('missing')).succeeded, isTrue);
    expect((await c.deletePlaylist('missing')).succeeded, isTrue);
  });

  test('busy is set before notification and duplicate commands cannot overlap an accepted write', () async {
    final repository = FakeCollectionRepository();
    final gate = Completer<void>();
    repository.onPlaylistMutation = (_, _) => gate.future;
    final c = PlaylistController(collection: repository);
    addTearDown(() async {
      if (!gate.isCompleted) gate.complete();
      await c.close();
      await repository.dispose();
    });
    Future<PlaylistCommandResult>? reentrant;
    c.addListener(() {
      if (c.busy) reentrant ??= c.createPlaylist('重入');
    });
    final operation = c.createPlaylist('第一次');
    expect(c.busy, isTrue);
    expect((await reentrant!).status, PlaylistCommandStatus.busy);
    expect(
      (await c.renamePlaylist('id', '重复')).status,
      PlaylistCommandStatus.busy,
    );
    expect((await c.deletePlaylist('id')).status, PlaylistCommandStatus.busy);
    await drainPlaylistWork();
    expect(repository.playlistMutationCalls, ['create']);
    gate.complete();
    expect((await operation).succeeded, isTrue);
    expect(c.busy, isFalse);
  });

  test('storage errors and invalid IDs never escape as raw exceptions or identifiers', () async {
    final repository = FakeCollectionRepository();
    final c = PlaylistController(collection: repository);
    addTearDown(() async {
      await c.close();
      await repository.dispose();
    });
    repository.onPlaylistMutation = (_, _) async =>
        throw StateError('private-marker');
    final failed = await c.createPlaylist('合法名称');
    expect(failed.status, PlaylistCommandStatus.failed);
    expect(failed.message, isNot(contains('private-marker')));
    expect(failed.playlistId, isNull);
    expect(
      (await c.deletePlaylist(' bad-id ')).status,
      PlaylistCommandStatus.failed,
    );
    repository.onPlaylistMutation = null;
    expect((await c.createPlaylist('恢复')).succeeded, isTrue);
  });

  test(
    'absent and disposed storage reject new commands without writes',
    () async {
      final unavailable = PlaylistController();
      expect(
        (await unavailable.createPlaylist('新歌单')).status,
        PlaylistCommandStatus.unavailable,
      );
      await unavailable.close();
      final repository = FakeCollectionRepository();
      final c = PlaylistController(collection: repository);
      await c.close();
      await c.close();
      expect(
        (await c.deletePlaylist('id')).status,
        PlaylistCommandStatus.unavailable,
      );
      expect(repository.playlistMutationCalls, isEmpty);
      await repository.dispose();
    },
  );

  for (final fail in [false, true]) {
    test(
      'root close drains the accepted deferred write before disposing shared storage (fail=$fail)',
      () async {
        final repository = FakeCollectionRepository();
        final library = FakeLibraryRepository();
        final graph = DependencyGraph(collection: repository, library: library);
        final gate = Completer<void>();
        repository.onPlaylistMutation = (_, _) => gate.future;
        final write = graph.playlists.createPlaylist('关闭期间保存');
        var closed = false;
        final close = graph.close().then((_) => closed = true);
        expect(graph.playlists.isAvailable, isFalse);
        await drainPlaylistWork();
        expect(closed, isFalse);
        expect(library.disposeCount, 0);
        expect(repository.playlistMutationCalls, ['create']);
        if (fail) {
          gate.completeError(StateError('private-marker'));
        } else {
          gate.complete();
        }
        expect(
          (await write).status,
          fail ? PlaylistCommandStatus.failed : PlaylistCommandStatus.succeeded,
        );
        await close;
        expect(closed, isTrue);
        expect(library.disposeCount, 1);
        await graph.close();
        expect(library.disposeCount, 1);
        await repository.dispose();
      },
    );
  }

  test('ID factory reentry closes the controller only after the already registered write drains', () async {
    final repository = FakeCollectionRepository();
    late PlaylistController c;
    Future<void>? close;
    c = PlaylistController(
      collection: repository,
      idFactory: () {
        close = c.close();
        return 'reentrant-id';
      },
    );
    expect((await c.createPlaylist('已接受')).succeeded, isTrue);
    await close;
    expect((await repository.getPlaylist('reentrant-id'))!.name, '已接受');
    expect(c.isAvailable, isFalse);
    await repository.dispose();
  });

  test(
    'default IDs have independent 128-bit identity even when names are equal',
    () async {
      final repository = FakeCollectionRepository();
      final c = PlaylistController(collection: repository);
      addTearDown(() async {
        await c.close();
        await repository.dispose();
      });
      final ids = <String>{};
      for (var i = 0; i < 32; i++) {
        final result = await c.createPlaylist('同名');
        expect(result.playlistId, matches(RegExp(r'^playlist-[0-9a-f]{32}$')));
        ids.add(result.playlistId!);
      }
      expect(ids.length, 32);
    },
  );
}
