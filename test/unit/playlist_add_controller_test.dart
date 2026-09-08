import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/domain/models/load_state.dart';
import 'package:yymusic/domain/models/pagination.dart';
import 'package:yymusic/features/playlists/common/playlist_add_controller.dart';

import '../support/playlist_content_fixture.dart';
import '../support/playlist_content_probe.dart';

Future<void> waitForPicker(PlaylistAddController c, bool Function() predicate) {
  final done = Completer<void>();
  void check() {
    if (!done.isCompleted && predicate()) done.complete();
  }

  c.addListener(check);
  check();
  return done.future
      .timeout(const Duration(seconds: 5))
      .whenComplete(() => c.removeListener(check));
}

Future<PlaylistAddController> startPicker(PlaylistContentFixture f) async {
  await f.initialize();
  final c = f.graph.playlistAdds.open(
    f.tracks.first.ref,
    title: f.tracks.first.title,
  )..start();
  await waitForPicker(c, () => c.isCurrent);
  return c;
}

void main() {
  test('idle registry has no reads, selection is bounded and filtering reaches later playlists', () async {
    final f = PlaylistContentFixture(count: 5);
    addTearDown(f.close);
    expect(f.collection.contentWatchCount, 0);
    expect(f.collection.selectionReadCalls, isEmpty);
    for (var i = 0; i < 235; i++) {
      await f.collection.createPlaylist(contentPlaylist('p-$i', name: '目标$i'));
    }
    final c = await startPicker(f);
    expect(c.snapshot!.items.length, 20);
    expect(f.collection.playlistWatchCount, 0);
    for (var count = 40; count <= 200; count += 20) {
      c.loadMore();
      await waitForPicker(
        c,
        () => c.isCurrent && c.snapshot!.items.length == count,
      );
    }
    expect(c.capped, isTrue);
    expect(c.canLoadMore, isFalse);
    c.filter('目标234');
    await waitForPicker(c, () => c.isCurrent);
    expect(c.snapshot!.items.single.id, 'p-234');
    expect(c.capped, isFalse);
    expect(f.collection.selectionReadCalls.last.page.limit, 20);
    expect(f.engine.calls, isEmpty);
  });
  test(
    'invalid filter stays non-actionable through notifications and can recover',
    () async {
      final f = PlaylistContentFixture(count: 5);
      addTearDown(f.close);
      final c = await startPicker(f);
      final old = c.snapshot!;
      c.filter('private\nmarker');
      expect(c.phase, LoadPhase.error);
      expect(c.error, isNot(contains('private')));
      final reads = f.collection.selectionReadCalls.length;
      f.collection.setContentTracks(f.tracks);
      c.refresh();
      await contentTick();
      expect(f.collection.selectionReadCalls.length, reads);
      expect(c.canAdd(f.id), isFalse);
      await c.addTo(f.id, old);
      expect(f.collection.playlistMutationCalls, ['create']);
      c.filter('');
      await waitForPicker(c, () => c.isCurrent);
      expect(c.canAdd(f.id), isTrue);
    },
  );
  test('old success and old failure cannot replace a newer filter', () async {
    final f = PlaylistContentFixture(count: 5);
    addTearDown(f.close);
    final c = await startPicker(f);
    for (final fail in [false, true]) {
      final gate = Completer<PageResult<Playlist>>();
      f.collection.selectionReader = (_, _) => gate.future;
      c.filter('old');
      await contentTick();
      c.filter('new');
      f.collection.selectionReader = (_, _) async => PageResult(
        items: [contentPlaylist('new', name: 'new')],
        hasMore: false,
      );
      if (fail) {
        gate.completeError(StateError('private-marker'));
      } else {
        gate.complete(
          PageResult(
            items: [contentPlaylist('old', name: 'old')],
            hasMore: false,
          ),
        );
      }
      await waitForPicker(c, () => c.isCurrent);
      expect(c.query.text, 'new');
      expect(c.snapshot!.items.single.id, 'new');
      expect(c.error, isNull);
    }
  });
  for (final failure in ['read', 'watch-error', 'watch-end', 'watch-throw']) {
    test(
      '$failure preserves stale rows but denies adding until a fresh read',
      () async {
        final f = PlaylistContentFixture(count: 5);
        addTearDown(f.close);
        final c = await startPicker(f);
        final old = c.snapshot!;
        final changes = StreamController<void>.broadcast(sync: true);
        addTearDown(changes.close);
        if (failure == 'read') {
          f.collection.selectionReader = (_, _) async =>
              throw StateError('private-marker');
        } else {
          f.collection.contentChangesReader = () {
            if (failure == 'watch-throw') throw StateError('private-marker');
            return changes.stream;
          };
        }
        c.refresh();
        await contentTick();
        if (failure == 'watch-error') {
          changes.addError(StateError('private-marker'));
        }
        if (failure == 'watch-end') await changes.close();
        await waitForPicker(c, () => c.phase == LoadPhase.error);
        expect(c.snapshot, isNotNull);
        expect(c.canAdd(f.id), isFalse);
        expect(c.error, isNot(contains('private')));
        await c.addTo(f.id, old);
        expect(f.collection.playlistMutationCalls, ['create']);
        f.collection.selectionReader = null;
        f.collection.contentChangesReader = null;
        c.refresh();
        await waitForPicker(c, () => c.isCurrent);
        expect(c.canAdd(f.id), isTrue);
      },
    );
  }
  test(
    'full reference and duplicate entries use the shared writer without audio',
    () async {
      final f = PlaylistContentFixture(count: 5);
      addTearDown(f.close);
      await f.initialize();
      for (var i = 0; i < 2; i++) {
        final c = f.graph.playlistAdds.open(
          f.tracks[2].ref,
          title: f.tracks[2].title,
        )..start();
        await waitForPicker(c, () => c.isCurrent);
        final old = c.snapshot!;
        await c.addTo(f.id, old);
        await c.addTo(f.id, old);
        expect(c.addedTo, '沿途的声音');
        await c.close();
      }
      final entries = await f.collection.getPlaylistEntries(f.id);
      expect(entries.length, 7);
      expect(entries.skip(5).every((e) => e.track == f.tracks[2].ref), isTrue);
      expect(entries.map((e) => e.id).toSet().length, 7);
      expect(f.engine.calls, isEmpty);
    },
  );
  test(
    'changed snapshot and inactive selection cannot execute old callbacks',
    () async {
      final f = PlaylistContentFixture(count: 5);
      addTearDown(f.close);
      final c = await startPicker(f);
      final old = c.snapshot!;
      c.refresh();
      await waitForPicker(c, () => c.isCurrent);
      await c.addTo(f.id, old);
      c.setActive(false);
      await c.addTo(f.id, c.snapshot!);
      expect(f.collection.playlistMutationCalls, ['create']);
      c.setActive(true);
      await c.addTo(f.id, c.snapshot!);
      expect(c.addedTo, isNotNull);
    },
  );
  test('shared writer is busy once, closed-route failure remains safe and does not retry', () async {
    final f = PlaylistContentFixture(count: 5);
    addTearDown(f.close);
    final c = await startPicker(f), other = await startPicker(f);
    final gate = Completer<void>();
    addTearDown(() {
      if (!gate.isCompleted) gate.complete();
    });
    f.collection.onPlaylistMutation = (_, _) async {
      await gate.future;
      throw StateError('private-marker');
    };
    final add = c.addTo(f.id, c.snapshot!);
    await other.addTo(f.id, other.snapshot!);
    await contentTick();
    expect(f.collection.playlistMutationCalls, ['create', 'append-entry']);
    final close = c.close();
    gate.complete();
    await add;
    await close;
    expect(f.graph.playlists.entryFailure, isNotNull);
    expect(f.graph.playlists.entryFailure, isNot(contains('private')));
    expect((await f.collection.getPlaylistEntries(f.id)).length, 5);
  });
  test('accepted add drains through synchronous root close inside writer notification', () async {
    final f = PlaylistContentFixture(count: 5);
    addTearDown(f.close);
    final c = await startPicker(f);
    final gate = Completer<void>();
    addTearDown(() {
      if (!gate.isCompleted) gate.complete();
    });
    f.collection.onPlaylistMutation = (_, _) => gate.future;
    Future<void>? closing;
    f.graph.playlists.addListener(() {
      if (f.graph.playlists.busy) closing ??= f.graph.close();
    });
    final add = c.addTo(f.id, c.snapshot!);
    await contentTick();
    expect(closing, isNotNull);
    expect(f.library.disposeCount, 0);
    gate.complete();
    await add;
    await closing;
    expect((await f.collection.getPlaylistEntries(f.id)).length, 6);
    expect(f.library.disposeCount, 1);
    expect(f.graph.playlistAdds.retainedSessionCount, 0);
  });
  test('close waits for the explicit repository future rather than just subscription cancel', () async {
    final f = PlaylistContentFixture(count: 5);
    addTearDown(f.close);
    final c = await startPicker(f);
    final gate = Completer<PageResult<Playlist>>();
    f.collection.selectionReader = (_, _) => gate.future;
    c.refresh();
    await contentTick();
    final closing = f.graph.close();
    await contentTick();
    expect(f.library.disposeCount, 0);
    gate.completeError(StateError('private-marker'));
    await closing;
    expect(f.library.disposeCount, 1);
    expect(f.graph.playlistAdds.retainedSessionCount, 0);
  });
  test(
    'malformed duplicate/system/mismatched/oversized pages fail closed',
    () async {
      final f = PlaylistContentFixture(count: 5);
      addTearDown(f.close);
      final c = await startPicker(f);
      final ordinary = contentPlaylist('p');
      final system = Playlist(
        id: 'system',
        name: 'system',
        createdAt: contentEpoch,
        updatedAt: contentEpoch,
        isSystem: true,
        systemType: SystemPlaylistType.favorites,
      );
      for (final result in [
        PageResult(items: [ordinary, ordinary], hasMore: false),
        PageResult(items: [system], hasMore: false),
        PageResult(items: [ordinary], hasMore: true),
        PageResult(
          items: List.generate(21, (i) => contentPlaylist('p$i')),
          hasMore: false,
        ),
      ]) {
        f.collection.selectionReader = (_, _) async => result;
        c.refresh();
        await waitForPicker(c, () => c.phase == LoadPhase.error);
        expect(c.canAdd('p'), isFalse);
      }
    },
  );
}
