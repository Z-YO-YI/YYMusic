import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/domain/models/playlist_playback_plan.dart';
import 'package:yymusic/features/playlists/common/playlist_content_controller.dart';

import '../support/playlist_content_fixture.dart';
import '../support/playlist_content_probe.dart';
import 'playlist_content_actions_test.dart' show startContent;
import 'playlist_window_navigation_test.dart' show expandWindow;

void main() {
  test('later 200-window plays the whole playlist and preserves duplicate and unavailable entries', () async {
    final f = PlaylistContentFixture(count: 405);
    addTearDown(f.close);
    final c = await startContent(f);
    await expandWindow(c);
    c.showNextWindow(c.content!);
    await waitForContent(c, () => c.isCurrent);
    expect(c.content!.page.offset, 200);
    final reads = f.collection.contentReadCalls.length;
    await c.playAll(c.content!, shuffle: false);
    expect(f.collection.playbackPlanReadCalls, [f.id]);
    expect(f.collection.contentReadCalls.length, reads);
    final queue = f.graph.playback.state.queue;
    expect(queue.entries.length, 403);
    expect(queue.entries.take(2).map((e) => e.track).toSet().length, 1);
    expect(queue.entries.last.track, f.tracks.last.ref);
    expect(f.graph.playback.state.currentTrack!.ref, f.tracks.first.ref);
    expect(c.actionNote, contains('跳过 2 条不可用引用'));
    expect(c.actionError, isNull);
    expect((await f.collection.getPlaylistEntries(f.id)).length, 405);
    expect(f.collection.queueWrites.length, 1);
    c.setActive(false);
    expect(f.engine.calls, isNot(contains('stop')));
  });
  test('all unavailable entries do not replace the previous queue', () async {
    final f = PlaylistContentFixture(count: 5);
    addTearDown(f.close);
    final c = await startContent(f);
    await c.playEntry('e-0');
    final queue = f.graph.playback.state.queue;
    f.collection.setContentTracks([]);
    await waitForContent(
      c,
      () => c.isCurrent && !c.content!.entries.first.isAvailable,
    );
    await c.playAll(c.content!, shuffle: true);
    expect(f.graph.playback.state.queue, same(queue));
    expect(c.actionNote, '歌单中没有可播放的歌曲，当前队列未改变。');
    expect((await f.collection.getPlaylistEntries(f.id)).length, 5);
  });
  for (final error in ['missing', 'wrong-id', 'failure']) {
    test(
      '$error produces safe feedback and no replacement; retry works',
      () async {
        final f = PlaylistContentFixture(count: 5);
        addTearDown(f.close);
        final c = await startContent(f);
        f.collection.playbackPlanReader = (_) async {
          if (error == 'missing') return null;
          if (error == 'wrong-id') {
            return PlaylistPlaybackPlan(playlistId: 'other', entries: []);
          }
          throw StateError('private-marker');
        };
        await c.playAll(c.content!, shuffle: false);
        expect(c.actionError, isNotNull);
        expect(c.actionError, isNot(contains('private-marker')));
        expect(f.engine.calls, isEmpty);
        expect(f.collection.queueWrites, isEmpty);
        f.collection.playbackPlanReader = null;
        await c.playAll(c.content!, shuffle: true);
        expect(c.actionError, isNull);
        expect(f.graph.playback.state.shuffleEnabled, isTrue);
      },
    );
  }
  for (final revoke in [
    'leave',
    'refresh',
    'invalidate',
    'watch-error',
    'watch-end',
    'root-close',
  ]) {
    test(
      '$revoke revokes delayed full read and duplicate commands are not accepted',
      () async {
        final f = PlaylistContentFixture(count: 5);
        addTearDown(f.close);
        final changes = StreamController<void>.broadcast(sync: true);
        addTearDown(changes.close);
        if (revoke.startsWith('watch-')) {
          f.collection.contentChangesReader = () => changes.stream;
        }
        final c = await startContent(f);
        final plan = await f.collection.readPlaylistPlaybackPlan(f.id);
        f.collection.playbackPlanReadCalls.clear();
        final gate = Completer<PlaylistPlaybackPlan?>();
        addTearDown(() {
          if (!gate.isCompleted) gate.complete(plan);
        });
        f.collection.playbackPlanReader = (_) => gate.future;
        final data = c.content!;
        final play = c.playAll(data, shuffle: false);
        await c.playAll(data, shuffle: true);
        await c.playEntry('e-0');
        await contentTick();
        expect(f.collection.playbackPlanReadCalls, [f.id]);
        expect(c.busy, isTrue);
        Future<void>? close;
        if (revoke == 'leave') c.setActive(false);
        if (revoke == 'refresh') c.refresh();
        if (revoke == 'invalidate') f.collection.setContentTracks(f.tracks);
        if (revoke == 'watch-error') {
          changes.addError(StateError('private-marker'));
        }
        if (revoke == 'watch-end') await changes.close();
        if (revoke == 'root-close') {
          close = f.graph.close();
          await contentTick();
          expect(f.library.disposeCount, 0);
          expect(f.engine.disposalCount, 0);
        }
        gate.complete(plan);
        await play;
        await close;
        expect(f.collection.queueWrites, isEmpty);
        expect(f.engine.calls, isEmpty);
        expect(c.busy, isFalse);
        expect(c.actionNote, isNull);
        if (revoke == 'root-close') expect(f.library.disposeCount, 1);
      },
    );
  }
  test('empty and stale snapshots cannot initiate a complete read', () async {
    final f = PlaylistContentFixture(count: 0);
    addTearDown(f.close);
    final c = await startContent(f);
    final old = c.content!;
    expect(c.canPlayAll, isFalse);
    await c.playAll(old, shuffle: false);
    c.refresh();
    await waitForContent(c, () => c.isCurrent);
    await c.playAll(old, shuffle: true);
    expect(f.collection.playbackPlanReadCalls, isEmpty);
  });
  test(
    'root close during native load waits for accepted command and never plays',
    () async {
      final f = PlaylistContentFixture(count: 5);
      addTearDown(f.close);
      final c = await startContent(f);
      final gate = Completer<void>();
      addTearDown(() {
        if (!gate.isCompleted) gate.complete();
      });
      f.engine.loadGate = gate.future;
      final play = c.playAll(c.content!, shuffle: true);
      await contentTick();
      expect(f.engine.calls, ['load']);
      final close = f.graph.close();
      await contentTick();
      expect(f.engine.disposalCount, 0);
      expect(f.library.disposeCount, 0);
      gate.complete();
      await play;
      await close;
      expect(f.engine.calls, isNot(contains('play')));
      expect(f.engine.disposalCount, 1);
      expect((await f.collection.loadQueue()).entries.length, 3);
    },
  );
}
