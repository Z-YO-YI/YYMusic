import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/domain/models/domain_failure.dart';
import 'package:yymusic/features/playlists/common/system_playlist_controller.dart';
import 'package:yymusic/features/playlists/common/system_playlist_writer.dart';
import 'package:yymusic/playback/playback_history_recorder.dart';

import '../support/fake_domain_repositories.dart';
import '../support/playback_history_probe.dart';
import '../support/playlist_content_probe.dart';
import '../support/system_playlist_fixture.dart';
import '../support/system_playlist_probe.dart';

void main() {
  late SystemPlaylistFixture f;
  setUp(() => f = SystemPlaylistFixture());
  tearDown(() => f.close());

  test('unavailable and unresolved favorites can be removed without touching music or queue', () async {
    final c = await f.open(SystemPlaylistType.favorites);
    final queue = f.graph.playback.state.queue;
    for (final id in [2, 3]) {
      final snapshot = c.content!;
      final entry = snapshot.entries.firstWhere(
        (e) => e.reference == f.tracks[id].ref,
      );
      expect(c.canPlayEntry(snapshot, entry.identity), isFalse);
      expect(c.canRemoveFavorite(snapshot, entry.identity), isTrue);
      await c.removeFavorite(snapshot, entry.identity);
      await waitForSystem(
        c,
        () =>
            c.isCurrent &&
            !c.content!.entries.any((e) => e.identity == entry.identity),
      );
    }
    expect((await f.collection.watchFavorites().first), hasLength(2));
    expect(await f.collection.watchHistory().first, hasLength(4));
    expect(f.graph.playback.state.queue, same(queue));
    expect(await f.library.getTrack(f.tracks[2].ref), isNotNull);
    expect(await f.collection.watchPlaylists().first, isEmpty);
    expect(f.engine.calls, isEmpty);
  });

  test('wrong type, missing identity, stale refresh, hidden and closed callbacks do not write', () async {
    var writes = 0;
    f.collection.onFavoriteSet = (_, _) async => writes++;
    final c = await f.open(SystemPlaylistType.favorites);
    final old = c.content!, id = old.entries.first.identity;
    await c.removeFavorite(old, 'not-a-reference');
    c.setActive(false);
    await c.removeFavorite(old, id);
    c.setActive(true);
    c.refresh();
    await c.removeFavorite(old, id);
    await waitForSystem(c, () => c.isCurrent);
    await c.removeFavorite(old, id);
    await c.clearHistory(c.content!);
    final queue = await f.open(SystemPlaylistType.queue);
    await queue.removeFavorite(
      queue.content!,
      queue.content!.entries.first.identity,
    );
    await queue.clearHistory(queue.content!);
    final current = c.content!;
    await c.close();
    await c.removeFavorite(current, current.entries.first.identity);
    expect(writes, 0);
    expect(await f.collection.watchHistory().first, hasLength(4));
  });

  test(
    'clear is recent-only, keeps all other collections and disables when empty',
    () async {
      final c = await f.open(SystemPlaylistType.recent);
      final queue = f.graph.playback.state.queue;
      expect(c.canClearHistory(c.content!), isTrue);
      await c.clearHistory(c.content!);
      await waitForSystem(c, () => c.isCurrent && c.content!.totalCount == 0);
      expect(c.canClearHistory(c.content!), isFalse);
      expect(await f.collection.watchFavorites().first, hasLength(4));
      expect(f.graph.playback.state.queue, same(queue));
      expect(f.engine.calls, isEmpty);
    },
  );

  test(
    'a shared busy writer rejects duplicate commands across open system views',
    () async {
      final a = await f.open(SystemPlaylistType.favorites);
      final b = await f.open(SystemPlaylistType.recent);
      final gate = Completer<void>();
      addTearDown(() {
        if (!gate.isCompleted) gate.complete();
      });
      var writes = 0, clears = 0;
      f.collection.onFavoriteSet = (_, _) async {
        writes++;
        await gate.future;
      };
      f.collection.onHistoryClear = () async => clears++;
      final snapshot = a.content!;
      final first = a.removeFavorite(snapshot, snapshot.entries.first.identity);
      expect(a.busy, isTrue);
      expect(b.busy, isTrue);
      await a.removeFavorite(snapshot, snapshot.entries.last.identity);
      await b.clearHistory(b.content!);
      gate.complete();
      await first;
      expect(writes, 1);
      expect(clears, 0);
      expect(f.graph.systemPlaylists.writer.busy, isFalse);
    },
  );

  test('write failure survives page close and retry succeeds from a new current session', () async {
    final c = await f.open(SystemPlaylistType.favorites);
    final snapshot = c.content!, id = snapshot.entries.first.identity;
    final gate = Completer<void>();
    addTearDown(() {
      if (!gate.isCompleted) gate.complete();
    });
    f.collection.onFavoriteSet = (_, _) async {
      await gate.future;
      throw StateError('private-marker');
    };
    final writing = c.removeFavorite(snapshot, id);
    await c.close();
    gate.complete();
    await writing;
    final next = await f.open(SystemPlaylistType.favorites);
    final failure = next.writeFailure!;
    expect(failure.failure, isA<DomainFailure>());
    expect(failure.message, isNot(contains('private-marker')));
    expect(failure.reference, snapshot.entries.first.reference);
    f.collection.onFavoriteSet = null;
    await next.removeFavorite(next.content!, id);
    expect(next.writeFailure, isNull);
  });

  test('success for another reference preserves failure and stale acknowledgements are ignored', () async {
    await f.initialize();
    final writer = f.graph.systemPlaylists.writer;
    f.collection.onFavoriteSet = (_, _) async {
      throw StateError('private-marker');
    };
    await writer.removeFavorite(f.tracks[0].ref);
    final old = writer.failure!;
    f.collection.onFavoriteSet = null;
    await writer.removeFavorite(f.tracks[4].ref);
    expect(writer.failure, same(old));
    f.collection.onHistoryClear = () async {
      throw StateError('private-marker');
    };
    await writer.clearHistory();
    final current = writer.failure!;
    writer.dismissFailure(old);
    expect(writer.failure, same(current));
    writer.dismissFailure(current);
    expect(writer.failure, isNull);
  });

  test(
    'missing and mismatched repositories cannot authorize history clearing',
    () async {
      final other = FakeCollectionRepository();
      final history = PlaybackHistoryRecorder(collection: other);
      final mismatch = SystemPlaylistWriter(
        repository: f.collection,
        history: history,
      );
      final absent = SystemPlaylistWriter();
      expect(absent.canRemoveFavorite, isFalse);
      expect(mismatch.canClearHistory, isFalse);
      await mismatch.clearHistory();
      expect(await f.collection.watchHistory().first, hasLength(4));
      await mismatch.close();
      await absent.close();
      await history.close();
      await other.dispose();
    },
  );

  for (final clear in [false, true]) {
    test(
      'reentrant root close drains the accepted ${clear ? 'clear' : 'favorite'} dependency',
      () async {
        await f.initialize();
        final writer = f.graph.systemPlaylists.writer;
        final gate = Completer<void>(), entered = Completer<void>();
        addTearDown(() {
          if (!gate.isCompleted) gate.complete();
        });
        Future<void>? closing;
        var closed = false;
        Future<void> dependency() async {
          closing = f.graph.close().then((_) => closed = true);
          entered.complete();
          await gate.future;
        }

        f.collection.onFavoriteSet = (_, _) => dependency();
        f.collection.onHistoryClear = dependency;
        final work = clear
            ? writer.clearHistory()
            : writer.removeFavorite(f.tracks[0].ref);
        await entered.future;
        await contentTick();
        expect(closed, isFalse);
        expect(writer.canClearHistory, isFalse);
        expect(writer.canRemoveFavorite, isFalse);
        gate.complete();
        await work;
        await closing;
        expect(writer.failure, isNull);
        expect(writer.busy, isFalse);
      },
    );
  }

  test('root close immediately after accepting clear still waits for older history saves', () async {
    final c = await f.open(SystemPlaylistType.recent);
    final gate = Completer<void>(), entered = Completer<void>();
    addTearDown(() {
      if (!gate.isCompleted) gate.complete();
    });
    f.collection.onHistoryRecord = (_) async {
      entered.complete();
      await gate.future;
    };
    await f.graph.playback.play();
    f.engine.events.add(historyState(100));
    await entered.future;
    final clear = c.clearHistory(c.content!);
    var closed = false;
    final closing = f.graph.close().then((_) => closed = true);
    await contentTick();
    expect(closed, isFalse);
    gate.complete();
    await clear;
    await closing;
    expect(await f.collection.watchHistory().first, isEmpty);
    expect(f.graph.systemPlaylists.writer.failure, isNull);
  });
}
