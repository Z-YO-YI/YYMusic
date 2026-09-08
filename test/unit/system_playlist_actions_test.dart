import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/system_playlist_location.dart';
import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/features/playlists/common/system_playlist_controller.dart';
import 'package:yymusic/playback/playback_state.dart';

import '../support/playlist_content_probe.dart';
import '../support/system_playlist_fixture.dart';
import '../support/system_playlist_probe.dart';

void main() {
  test(
    'system route accepts only a single closed enum and never custom IDs',
    () {
      for (final type in SystemPlaylistType.values) {
        expect(parseSystemPlaylistLocation(systemPlaylistLocation(type)), type);
      }
      for (final url in [
        '/system-playlist',
        '/system-playlist?type=',
        '/system-playlist?type=QUEUE',
        '/system-playlist?type=custom',
        '/system-playlist?type=queue&type=queue',
        '/system-playlist?type=queue&x=a',
        '/system-playlist?type=queue#x',
        '/system-playlist/?type=queue',
        '/playlist?type=queue',
        '/system-playlist?type=%20queue',
        'https://example.invalid/system-playlist?type=queue',
        '//example.invalid/system-playlist?type=queue',
      ]) {
        expect(
          parseSystemPlaylistLocation(Uri.parse(url)),
          isNull,
          reason: url,
        );
      }
    },
  );

  for (final type in SystemPlaylistType.values) {
    test(
      '$type plays via the one root queue and retains unavailable references',
      () async {
        final f = SystemPlaylistFixture();
        addTearDown(f.close);
        final c = await f.open(type), old = c.content!;
        final selected = type == SystemPlaylistType.queue
            ? 'q-1'
            : old.entries.first.identity;
        expect(old.entries.where((e) => !e.isAvailable).length, 2);
        for (final bad in old.entries.where((e) => !e.isAvailable)) {
          expect(c.canPlayEntry(old, bad.identity), isFalse);
        }
        expect(c.canPlayEntry(old, 'absent'), isFalse);
        final ids = f.graph.playback.state.queue.entries
            .map((e) => e.id)
            .toList();
        await c.playEntry(old, selected);
        expect(f.graph.playback.state.phase, PlaybackPhase.playing);
        expect(f.graph.playback.state.queue.entries.map((e) => e.id), ids);
        expect(
          f.graph.playback.state.queue.currentEntryId,
          type == SystemPlaylistType.queue ? 'q-1' : 'q-0',
        );
        expect(f.engine.calls, ['load', 'play']);
        expect(await f.collection.watchPlaylists().first, isEmpty);
        await c.close();
        expect(f.engine.calls, [
          'load',
          'play',
        ]); // Leaving does not stop started audio.
      },
    );
  }

  for (final type in [SystemPlaylistType.favorites, SystemPlaylistType.queue]) {
    for (final revoke in ['leave', 'refresh', 'watch-error', 'close']) {
      test('$type $revoke cancels pending load and drains it', () async {
        final f = SystemPlaylistFixture();
        addTearDown(f.close);
        final changes = StreamController<void>.broadcast(sync: true);
        addTearDown(changes.close);
        if (revoke == 'watch-error') {
          f.collection.systemChangesReader = (_) => changes.stream;
        }
        final c = await f.open(type), snapshot = c.content!;
        final id = type == SystemPlaylistType.queue
            ? 'q-1'
            : snapshot.entries.first.identity;
        final gate = Completer<void>();
        addTearDown(() {
          if (!gate.isCompleted) gate.complete();
        });
        f.engine.loadGate = gate.future;
        final play = c.playEntry(snapshot, id);
        await contentTick();
        expect(f.engine.calls, contains('load'));
        Future<void>? closing;
        if (revoke == 'leave') c.setActive(false);
        if (revoke == 'refresh') c.refresh();
        if (revoke == 'watch-error') {
          changes.addError(StateError('private-marker'));
        }
        if (revoke == 'close') closing = c.close();
        gate.complete();
        await play;
        await closing;
        expect(f.engine.calls, isNot(contains('play')));
        expect(c.busy, isFalse);
      });
    }
  }

  test('favorites invalidation revokes an accepted load but queue current-ID refresh does not', () async {
    final f = SystemPlaylistFixture();
    addTearDown(f.close);
    final c = await f.open(SystemPlaylistType.favorites), snapshot = c.content!;
    final gate = Completer<void>();
    addTearDown(() {
      if (!gate.isCompleted) gate.complete();
    });
    f.engine.loadGate = gate.future;
    final play = c.playEntry(snapshot, snapshot.entries.first.identity);
    await contentTick();
    await f.collection.setFavorite(
      snapshot.entries.first.reference,
      favorite: false,
    );
    gate.complete();
    await play;
    expect(f.engine.calls, isNot(contains('play')));
  });

  test(
    'stale snapshot, hidden view and root-removed queue entry cannot play',
    () async {
      final f = SystemPlaylistFixture();
      addTearDown(f.close);
      final c = await f.open(SystemPlaylistType.queue), old = c.content!;
      c.refresh();
      await waitForSystem(c, () => c.isCurrent);
      await c.playEntry(old, 'q-1');
      c.setActive(false);
      await c.playEntry(c.content!, 'q-1');
      c.setActive(true);
      final remove = f.graph.playback.removeQueueEntry('q-1');
      final play = c.playEntry(c.content!, 'q-1');
      await remove;
      await play;
      expect(f.engine.calls, isEmpty);
    },
  );

  test(
    'duplicate presses serialize once, load error is safe and retry works',
    () async {
      final f = SystemPlaylistFixture();
      addTearDown(f.close);
      final c = await f.open(SystemPlaylistType.queue), snapshot = c.content!;
      f.engine.loadError = StateError('private-marker');
      final first = c.playEntry(snapshot, 'q-1');
      await c.playEntry(snapshot, 'q-1');
      await first;
      expect(f.engine.calls, ['load']);
      expect(c.actionError, isNotNull);
      expect(c.actionError, isNot(contains('private-marker')));
      f.engine.loadError = null;
      await waitForSystem(c, () => c.isCurrent);
      await c.playEntry(c.content!, 'q-1');
      expect(f.engine.calls.where((e) => e == 'play').length, 1);
      expect(c.actionError, isNull);
    },
  );

  test(
    'root close waits for accepted engine load and never starts late playback',
    () async {
      final f = SystemPlaylistFixture();
      addTearDown(f.close);
      final c = await f.open(SystemPlaylistType.queue);
      final gate = Completer<void>();
      addTearDown(() {
        if (!gate.isCompleted) gate.complete();
      });
      f.engine.loadGate = gate.future;
      final play = c.playEntry(c.content!, 'q-1');
      await contentTick();
      var closed = false;
      final closing = f.graph.close().then((_) => closed = true);
      await contentTick();
      expect(closed, isFalse);
      expect(f.library.disposeCount, 0);
      gate.complete();
      await play;
      await closing;
      expect(f.library.disposeCount, 1);
      expect(f.engine.calls, isNot(contains('play')));
      expect(f.graph.systemPlaylists.retainedSessionCount, 0);
    },
  );
}
