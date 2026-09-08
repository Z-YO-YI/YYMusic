import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/domain/models/load_state.dart';
import 'package:yymusic/features/playlists/common/playlist_command_result.dart';
import 'package:yymusic/features/playlists/common/playlist_controller.dart';

import '../support/fake_domain_repositories.dart';
import '../support/playlist_content_fixture.dart';
import '../support/playlist_content_probe.dart';
import 'playlist_add_controller_test.dart' show startPicker, waitForPicker;
import 'playlist_controller_test.dart' show playlistEpoch;
import 'playlist_create_with_entry_test.dart' show firstDraft;

void main() {
  test(
    'one root command creates both IDs and one timestamp without extra calls',
    () async {
      final r = FakeCollectionRepository();
      var parents = 0, entries = 0, clocks = 0;
      final c = PlaylistController(
        collection: r,
        idFactory: () {
          parents++;
          return 'parent';
        },
        entryIdFactory: () {
          entries++;
          return 'entry';
        },
        clock: () {
          clocks++;
          return playlistEpoch;
        },
      );
      addTearDown(() async {
        await c.close();
        await r.dispose();
      });
      final result = await c.createPlaylistWithTrack(
        '  同名歌单  ',
        firstDraft('unused').track,
      );
      expect(result.playlistId, 'parent');
      expect((parents, entries, clocks), (1, 1, 1));
      expect(r.playlistMutationCalls, ['create-with-entry']);
      expect(r.playlistReadCount, 0);
      final parent = (await r.getPlaylist('parent'))!;
      final entry = (await r.getPlaylistEntries('parent')).single;
      expect(parent.name, '同名歌单');
      expect(parent.createdAt, playlistEpoch);
      expect(parent.updatedAt, playlistEpoch);
      expect(entry.addedAt, playlistEpoch);
      expect(entry.id, 'entry');
      expect(entry.track, firstDraft('unused').track);
    },
  );
  test('invalid names cannot allocate IDs or issue writes', () async {
    final r = FakeCollectionRepository();
    final c = PlaylistController(
      collection: r,
      idFactory: () => throw StateError('must not run'),
    );
    addTearDown(() async {
      await c.close();
      await r.dispose();
    });
    for (final name in ['', '   ', 'a' * 513, 'bad\nname', 'bad\u0085name']) {
      expect(
        (await c.createPlaylistWithTrack(
          name,
          firstDraft('unused').track,
        )).status,
        PlaylistCommandStatus.invalidName,
      );
    }
    expect(r.playlistMutationCalls, isEmpty);
  });
  for (final broken in ['parent', 'entry', 'clock']) {
    test(
      '$broken factory failure is safe and never leaves either row',
      () async {
        final r = FakeCollectionRepository();
        final c = PlaylistController(
          collection: r,
          idFactory: () => broken == 'parent' ? ' invalid' : 'parent',
          entryIdFactory: () => broken == 'entry' ? ' invalid' : 'entry',
          clock: () => broken == 'clock'
              ? throw StateError('private-marker')
              : playlistEpoch,
        );
        addTearDown(() async {
          await c.close();
          await r.dispose();
        });
        expect(
          (await c.createPlaylistWithTrack(
            '歌单',
            firstDraft('unused').track,
          )).status,
          PlaylistCommandStatus.failed,
        );
        expect(c.entryFailure, isNot(contains('private-marker')));
        expect(r.playlistMutationCalls, isEmpty);
        expect(await r.getPlaylist('parent'), isNull);
        expect(c.busy, isFalse);
      },
    );
  }
  test('shared busy blocks all second commands and close drains the accepted atomic write', () async {
    final r = FakeCollectionRepository();
    final gate = Completer<void>();
    r.onPlaylistMutation = (_, _) => gate.future;
    final c = PlaylistController(
      collection: r,
      idFactory: () => 'p',
      entryIdFactory: () => 'e',
    );
    addTearDown(() async {
      if (!gate.isCompleted) gate.complete();
      await c.close();
      await r.dispose();
    });
    final pending = c.createPlaylistWithTrack('歌单', firstDraft('unused').track);
    expect((await c.createPlaylist('第二份')).status, PlaylistCommandStatus.busy);
    expect(
      (await c.addTrack('p', firstDraft('unused').track)).status,
      PlaylistCommandStatus.busy,
    );
    var closed = false;
    final closing = c.close().then((_) => closed = true);
    await contentTick();
    expect(closed, isFalse);
    expect(await r.getPlaylist('p'), isNull);
    gate.complete();
    expect((await pending).succeeded, isTrue);
    await closing;
    expect((await r.getPlaylistEntries('p')).length, 1);
    expect(r.playlistMutationCalls, ['create-with-entry']);
    expect(
      (await c.createPlaylistWithTrack(
        '再次',
        firstDraft('unused').track,
      )).status,
      PlaylistCommandStatus.unavailable,
    );
  });
  test('selection read failure and invalid filter do not fabricate or prevent an independent atomic create', () async {
    final f = PlaylistContentFixture(count: 5);
    addTearDown(f.close);
    final picker = await startPicker(f);
    f.collection.selectionReader = (_, _) async =>
        throw StateError('private-marker');
    picker.refresh();
    await waitForPicker(picker, () => picker.phase == LoadPhase.error);
    picker.filter('bad\nfilter');
    expect(picker.canCreate, isTrue);
    await picker.createAndAdd(' ');
    expect(picker.actionError, contains('请输入'));
    expect(f.collection.playlistMutationCalls, ['create']);
    await picker.createAndAdd('  新的夜晚  ');
    expect(picker.created, isTrue);
    expect(picker.addedTo, '新的夜晚');
    await picker.createAndAdd('重复');
    expect(f.collection.playlistMutationCalls, ['create', 'create-with-entry']);
    expect(f.engine.calls, isEmpty);
  });
  test('inactive or closed picker cannot create and closed accepted failure remains on the root', () async {
    final f = PlaylistContentFixture(count: 5);
    addTearDown(f.close);
    final picker = await startPicker(f);
    picker.setActive(false);
    await picker.createAndAdd('禁止');
    expect(f.collection.playlistMutationCalls, ['create']);
    picker.setActive(true);
    final gate = Completer<void>();
    addTearDown(() {
      if (!gate.isCompleted) gate.complete();
    });
    f.collection.onPlaylistMutation = (_, _) async {
      await gate.future;
      throw StateError('private-marker');
    };
    final adding = picker.createAndAdd('失败');
    final closing = picker.close();
    await contentTick();
    gate.complete();
    await adding;
    await closing;
    await picker.createAndAdd('已经关闭');
    expect(f.collection.playlistMutationCalls, ['create', 'create-with-entry']);
    expect(f.graph.playlists.entryFailure, isNotNull);
    expect(f.graph.playlists.entryFailure, isNot(contains('private-marker')));
    expect(picker.created, isFalse);
    expect(picker.addedTo, isNull);
  });
  test('synchronous root close in writer notification still drains the create session', () async {
    final f = PlaylistContentFixture(count: 5);
    addTearDown(f.close);
    final picker = await startPicker(f);
    final gate = Completer<void>();
    addTearDown(() {
      if (!gate.isCompleted) gate.complete();
    });
    f.collection.onPlaylistMutation = (_, _) => gate.future;
    Future<void>? closing;
    f.graph.playlists.addListener(() {
      if (f.graph.playlists.busy) closing ??= f.graph.close();
    });
    final adding = picker.createAndAdd('保存期间关闭');
    await contentTick();
    expect(closing, isNotNull);
    expect(f.library.disposeCount, 0);
    gate.complete();
    await adding;
    await closing;
    expect(f.library.disposeCount, 1);
    expect(f.graph.playlistAdds.retainedSessionCount, 0);
    expect((await f.collection.watchPlaylists().first).length, 2);
  });
}
