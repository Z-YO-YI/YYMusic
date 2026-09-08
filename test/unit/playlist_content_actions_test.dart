import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/playlist_location.dart';
import 'package:yymusic/features/playlists/common/playlist_content_controller.dart';

import '../support/playlist_content_fixture.dart';
import '../support/playlist_content_probe.dart';

Future<PlaylistContentController> startContent(PlaylistContentFixture f) async {
  await f.initialize();
  final c = f.graph.playlistContents.open(f.id)..start();
  await waitForContent(c, () => c.isCurrent);
  return c;
}

void main() {
  test('opaque playlist links round-trip, ambiguous and external links fail closed', () {
    for (final id in [
      'custom',
      'a/b?c#d',
      '%2F',
      '中 文+%',
      '.',
      '..',
      'a' * 256,
    ]) {
      expect(parsePlaylistLocation(playlistLocation(id)), id);
    }
    for (final value in [
      '/playlist',
      '/playlist?id=',
      '/playlist?id=a&id=b',
      '/playlist?id=a&extra=b',
      '/playlist?id=a#f',
      '/playlist/?id=a',
      '/other?id=a',
      '/playlist?id=%0Aprivate',
      '/playlist?id=%20a',
      '/playlist?id=${'a' * 257}',
      'https://example.invalid/playlist?id=a',
      '//example.invalid/playlist?id=a',
    ]) {
      expect(parsePlaylistLocation(Uri.parse(value)), isNull, reason: value);
    }
  });

  test('entry actions use full identity and root queue without deduplicating playlist entries', () async {
    final f = PlaylistContentFixture(count: 5);
    addTearDown(f.close);
    final c = await startContent(f);
    expect(c.canPlayEntry('e-2'), isFalse);
    expect(c.canPlayEntry('e-3'), isFalse);
    expect(c.canPlayEntry('absent'), isFalse);
    await c.playEntry('e-0');
    await c.playEntry('e-1');
    expect(f.graph.playback.state.queue.entries.length, 1);
    expect(f.engine.calls.where((e) => e == 'play').length, 2);
    expect((await f.collection.getPlaylistEntries(f.id)).length, 5);
    c.setActive(false);
    await c.playEntry('e-4');
    await c.removeEntry('e-2');
    expect(f.collection.playlistMutationCalls, ['create']);
    expect(f.engine.calls.where((e) => e == 'play').length, 2);
  });

  test('remove and adjacent moves retain duplicate tracks and cannot cross an unknown page boundary', () async {
    final f = PlaylistContentFixture();
    addTearDown(f.close);
    final c = await startContent(f);
    expect(c.canMoveEntry('e-0', up: true), isFalse);
    expect(c.canMoveEntry('e-18', up: false), isFalse);
    expect(c.canMoveEntry('e-19', up: false), isFalse);
    await c.moveEntry('e-18', up: false);
    expect(f.collection.playlistMutationCalls, ['create']);
    await c.moveEntry('e-1', up: true);
    await waitForContent(
      c,
      () => c.isCurrent && c.content!.entries.first.entry.id == 'e-1',
    );
    expect(
      c.content!.entries.take(2).map((e) => e.entry.track).toSet().length,
      1,
    );
    await c.moveEntry('e-1', up: false);
    await waitForContent(
      c,
      () => c.isCurrent && c.content!.entries.first.entry.id == 'e-0',
    );
    c.loadMore();
    await waitForContent(
      c,
      () => c.isCurrent && c.content!.entries.length == 25,
    );
    await c.moveEntry('e-23', up: false);
    await waitForContent(
      c,
      () => c.isCurrent && c.content!.entries.last.entry.id == 'e-23',
    );
    await c.removeEntry('e-3');
    await waitForContent(c, () => c.isCurrent && c.content!.totalCount == 24);
    expect(c.entryFor('e-3'), isNull);
    expect(f.engine.calls, isEmpty);
  });

  for (final revoke in [
    'leave',
    'refresh',
    'invalidate',
    'watch-error',
    'watch-end',
    'close',
  ]) {
    test(
      '$revoke cancels delayed playback without abandoning its future',
      () async {
        final f = PlaylistContentFixture(count: 5);
        addTearDown(f.close);
        final changes = StreamController<void>.broadcast(sync: true);
        addTearDown(changes.close);
        if (revoke.startsWith('watch-')) {
          f.collection.contentChangesReader = () => changes.stream;
        }
        final c = await startContent(f);
        final gate = Completer<void>();
        addTearDown(() {
          if (!gate.isCompleted) gate.complete();
        });
        f.engine.loadGate = gate.future;
        final play = c.playEntry('e-0');
        await contentTick();
        expect(f.engine.calls, contains('load'));
        Future<void>? close;
        if (revoke == 'leave') c.setActive(false);
        if (revoke == 'refresh') c.refresh();
        if (revoke == 'invalidate') f.collection.setContentTracks(f.tracks);
        if (revoke == 'watch-error') {
          changes.addError(StateError('private-marker'));
        }
        if (revoke == 'watch-end') await changes.close();
        if (revoke == 'close') close = c.close();
        gate.complete();
        await play;
        await close;
        expect(f.engine.calls, isNot(contains('play')));
        expect(c.busy, isFalse);
      },
    );
  }

  test('accepted write survives immediate reentrant root close from writer notification', () async {
    final f = PlaylistContentFixture(count: 5);
    addTearDown(f.close);
    final c = await startContent(f);
    final gate = Completer<void>();
    addTearDown(() {
      if (!gate.isCompleted) gate.complete();
    });
    f.collection.onPlaylistMutation = (_, _) => gate.future;
    Future<void>? close;
    f.graph.playlists.addListener(() {
      if (f.graph.playlists.busy) close ??= f.graph.close();
    });
    final write = c.removeEntry('e-0');
    await contentTick();
    expect(close, isNotNull);
    expect(f.library.disposeCount, 0);
    gate.complete();
    await write;
    await close;
    expect(
      (await f.collection.getPlaylistEntries(f.id)).map((e) => e.id),
      isNot(contains('e-0')),
    );
    expect(f.library.disposeCount, 1);
    expect(f.graph.playlistContents.retainedSessionCount, 0);
  });

  test('shared busy rejects duplicates and closed-route failures remain safe in the root writer', () async {
    final f = PlaylistContentFixture(count: 5);
    addTearDown(f.close);
    final c = await startContent(f);
    final gate = Completer<void>();
    addTearDown(() {
      if (!gate.isCompleted) gate.complete();
    });
    f.collection.onPlaylistMutation = (_, _) async {
      await gate.future;
      throw StateError('private-marker');
    };
    final write = c.removeEntry('e-0');
    await c.removeEntry('e-1');
    await contentTick();
    expect(f.collection.playlistMutationCalls, ['create', 'remove-entry']);
    final closing = c.close();
    gate.complete();
    await write;
    await closing;
    expect(f.graph.playlists.entryFailure, isNotNull);
    expect(f.graph.playlists.entryFailure, isNot(contains('private-marker')));
    expect((await f.collection.getPlaylistEntries(f.id)).length, 5);
    f.graph.playlists.dismissEntryFailure();
    expect(f.graph.playlists.entryFailure, isNull);
  });
}
