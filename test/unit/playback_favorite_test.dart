import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/playback/audio_engine_state.dart';
import 'package:yymusic/playback/playback_favorite_controller.dart';

import '../support/catalog_detail_probe.dart';
import '../support/system_playlist_fixture.dart';
import 'catalog_detail_favorites_test.dart' show ReentrantListenStream;

Future<void> waitFavorite(
  PlaybackFavoriteController c,
  bool Function() condition,
) {
  final done = Completer<void>();
  void check() {
    if (!done.isCompleted && condition()) done.complete();
  }

  c.addListener(check);
  check();
  return done.future
      .timeout(const Duration(seconds: 5))
      .whenComplete(() => c.removeListener(check));
}

Future<void> favoriteTick() async {
  for (var i = 0; i < 8; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  test(
    'accepted write keeps its original track when current selection changes',
    () async {
      final f = SystemPlaylistFixture();
      addTearDown(f.close);
      await f.initialize();
      final c = f.graph.playbackFavorite;
      await waitFavorite(c, () => c.ready);
      final old = c.state,
          gate = Completer<void>(),
          entered = Completer<void>();
      addTearDown(() {
        if (!gate.isCompleted) gate.complete();
      });
      f.collection.onFavoriteSet = (_, _) async {
        entered.complete();
        await gate.future;
      };
      final writing = c.setFavorite(old, favorite: false);
      await entered.future;
      await f.graph.queue.replace(old.queue.entries, currentEntryId: 'q-4');
      expect(c.state.reference, f.tracks[4].ref);
      gate.complete();
      expect(await writing, PlaybackFavoriteEditResult.applied);
      await favoriteTick();
      expect(c.state.isFavorite, isTrue);
      final favorites = await f.collection.watchFavorites().first;
      expect(favorites.any((e) => e.track == old.reference), isFalse);
      expect(favorites.any((e) => e.track == f.tracks[4].ref), isTrue);
      expect(f.engine.calls, isEmpty);
    },
  );
  test(
    'successful persistence alone never fabricates a favorite stream update',
    () async {
      final f = SystemPlaylistFixture();
      final stream = StreamController<List<FavoriteEntry>>.broadcast(
        sync: true,
      );
      addTearDown(stream.close);
      addTearDown(f.close);
      f.collection.favoriteReader = () => stream.stream;
      await f.initialize();
      await favoriteTick();
      final c = f.graph.playbackFavorite;
      stream.add([]);
      final old = c.state;
      expect(
        await c.setFavorite(old, favorite: true),
        PlaybackFavoriteEditResult.applied,
      );
      expect(c.state, same(old));
      expect(c.state.isFavorite, isFalse);
      stream.add([
        FavoriteEntry(track: old.reference!, addedAt: DateTime.utc(2026)),
      ]);
      expect(c.state.isFavorite, isTrue);
    },
  );
  test(
    'empty startup stays query-free until the first selected queue entry',
    () async {
      final f = SystemPlaylistFixture(count: 0);
      addTearDown(f.close);
      await f.initialize();
      final c = f.graph.playbackFavorite;
      await favoriteTick();
      expect(f.collection.favoriteWatchCount, 0);
      expect(c.ready, isFalse);
      final track = detailTrack('late');
      await f.graph.queue.replace([
        QueueEntry(
          id: 'late-entry',
          track: track.ref,
          position: 0,
          addedAt: DateTime.utc(2026),
        ),
      ], currentEntryId: 'late-entry');
      await waitFavorite(c, () => c.ready);
      expect(f.collection.favoriteWatchCount, 1);
      expect(c.state.reference, track.ref);
      expect(c.state.isFavorite, isFalse);
    },
  );
  for (final close in [false, true]) {
    test(
      'reentrant page permission ${close ? 'close' : 'refresh'} cannot admit a write',
      () async {
        final f = SystemPlaylistFixture();
        addTearDown(f.close);
        await f.initialize();
        final c = f.graph.playbackFavorite;
        await waitFavorite(c, () => c.ready);
        expect(
          await c.setFavorite(
            c.state,
            favorite: false,
            canEdit: () {
              if (close) {
                c.dispose();
              } else {
                c.retryRead();
              }
              return true;
            },
          ),
          PlaybackFavoriteEditResult.cancelled,
        );
        expect(f.collection.favoriteWriteCount, 0);
      },
    );
  }
  test(
    'retry and shutdown retain a pending subscription cancellation',
    () async {
      final f = SystemPlaylistFixture();
      final gate = Completer<void>();
      final stream = StreamController<List<FavoriteEntry>>(
        onCancel: () => gate.future,
      );
      f.collection.favoriteReader = () => stream.stream;
      await f.initialize();
      await favoriteTick();
      final c = f.graph.playbackFavorite;
      stream.add([]);
      await waitFavorite(c, () => c.ready);
      f.collection.favoriteReader = null;
      c.retryRead();
      await favoriteTick();
      expect(c.ready, isFalse);
      var closed = false;
      final closing = f.graph.close().then((_) => closed = true);
      await favoriteTick();
      expect(closed, isFalse);
      expect(f.engine.disposalCount, 0);
      gate.complete();
      await closing;
      expect(f.collection.favoriteWatchCount, 1);
      await stream.close();
      await f.collection.dispose();
    },
  );
  test('subscription cancellation error is sanitized and remaining root resources close', () async {
    final f = SystemPlaylistFixture();
    final stream = StreamController<List<FavoriteEntry>>(
      onCancel: () => throw StateError('private-marker'),
    );
    f.collection.favoriteReader = () => stream.stream;
    await f.initialize();
    await favoriteTick();
    await expectLater(
      f.graph.close(),
      throwsA(
        predicate<Object>(
          (error) => !error.toString().contains('private-marker'),
        ),
      ),
    );
    expect(f.engine.disposalCount, 1);
    await stream.close();
    await f.collection.dispose();
  });
  test(
    'construction is idle, graph starts once and unknown is not false',
    () async {
      final f = SystemPlaylistFixture();
      addTearDown(f.close);
      final c = f.graph.playbackFavorite;
      expect(f.collection.favoriteWatchCount, 0);
      expect(c.state.isFavorite, isNull);
      expect(c.canSet(c.state), isFalse);
      await f.initialize();
      await waitFavorite(c, () => c.ready);
      c.start();
      await f.graph.initialize();
      await favoriteTick();
      expect(f.collection.favoriteWatchCount, 1);
      expect(c.state.entryId, 'q-0');
      expect(c.state.reference, f.tracks.first.ref);
      expect(c.state.isFavorite, isTrue);
    },
  );
  test(
    'empty queue and missing repository cannot accept favorite edits',
    () async {
      final f = SystemPlaylistFixture(count: 0);
      addTearDown(f.close);
      await f.initialize();
      final c = f.graph.playbackFavorite;
      await favoriteTick();
      expect(c.state.reference, isNull);
      expect(
        await c.setFavorite(c.state, favorite: true),
        PlaybackFavoriteEditResult.cancelled,
      );
      final unavailable = PlaybackFavoriteController(playback: f.graph.playback)
        ..retryRead();
      addTearDown(unavailable.close);
      await waitFavorite(unavailable, () => unavailable.failure != null);
      expect(unavailable.ready, isFalse);
      expect(unavailable.failure!.kind, PlaybackFavoriteFailureKind.read);
    },
  );
  test('favorite writes do not alter queue/history/audio and only stream changes truth', () async {
    final f = SystemPlaylistFixture();
    addTearDown(f.close);
    await f.initialize();
    final c = f.graph.playbackFavorite;
    await waitFavorite(c, () => c.ready);
    final queue = f.graph.queue.state,
        history = await f.collection.watchHistory().first;
    final gate = Completer<void>();
    addTearDown(() {
      if (!gate.isCompleted) gate.complete();
    });
    f.collection.favoriteGate = gate.future;
    final old = c.state;
    final writing = c.setFavorite(old, favorite: false);
    expect(c.busy, isTrue);
    expect(
      await c.setFavorite(old, favorite: false),
      PlaybackFavoriteEditResult.busy,
    );
    await favoriteTick();
    expect(c.state.isFavorite, isTrue);
    gate.complete();
    expect(await writing, PlaybackFavoriteEditResult.applied);
    await waitFavorite(c, () => c.state.isFavorite == false);
    expect(f.collection.favoriteWriteCount, 1);
    expect(f.graph.queue.state, same(queue));
    expect(await f.collection.watchHistory().first, history);
    expect(f.engine.calls, isEmpty);
    expect(
      await c.setFavorite(c.state, favorite: false),
      PlaybackFavoriteEditResult.unchanged,
    );
    expect(f.collection.favoriteWriteCount, 1);
  });
  test(
    'position updates preserve read identity and never resubscribe',
    () async {
      final f = SystemPlaylistFixture();
      addTearDown(f.close);
      await f.initialize();
      final c = f.graph.playbackFavorite;
      await waitFavorite(c, () => c.ready);
      await f.graph.playback.playEntry('q-0');
      final state = c.state, count = f.collection.favoriteWatchCount;
      f.engine.events.add(
        AudioEngineState(
          phase: AudioEnginePhase.playing,
          position: const Duration(seconds: 18),
        ),
      );
      expect(c.state, same(state));
      expect(f.collection.favoriteWatchCount, count);
    },
  );
  for (final reason in [
    'same-queue',
    'duplicate-entry',
    'read',
    'external',
    'close',
  ]) {
    test('old favorite projection stays revoked after $reason', () async {
      final f = SystemPlaylistFixture();
      addTearDown(f.close);
      await f.initialize();
      final c = f.graph.playbackFavorite;
      await waitFavorite(c, () => c.ready);
      final old = c.state;
      switch (reason) {
        case 'same-queue':
          await f.graph.queue.replace(old.queue.entries, currentEntryId: 'q-0');
        case 'duplicate-entry':
          await f.graph.queue.replace(old.queue.entries, currentEntryId: 'q-1');
        case 'read':
          c.retryRead();
          await waitFavorite(c, () => c.ready);
        case 'external':
          await f.collection.setFavorite(f.tracks[4].ref, favorite: false);
          await favoriteTick();
        case 'close':
          await c.close();
      }
      final count = f.collection.favoriteWriteCount;
      expect(
        await c.setFavorite(old, favorite: false),
        PlaybackFavoriteEditResult.cancelled,
      );
      expect(f.collection.favoriteWriteCount, count);
    });
  }
  for (final reason in ['permit', 'refresh', 'close', 'reentrant-close']) {
    test(
      'favorite edit not accepted by repository is cancelled after $reason',
      () async {
        final f = SystemPlaylistFixture();
        addTearDown(f.close);
        await f.initialize();
        final c = f.graph.playbackFavorite;
        await waitFavorite(c, () => c.ready);
        var allowed = true;
        if (reason == 'reentrant-close') {
          c.addListener(() {
            if (c.busy) c.dispose();
          });
        }
        final writing = c.setFavorite(
          c.state,
          favorite: false,
          canEdit: () => allowed,
        );
        switch (reason) {
          case 'permit':
            allowed = false;
          case 'refresh':
            c.retryRead();
          case 'close':
            c.dispose();
        }
        expect(await writing, PlaybackFavoriteEditResult.cancelled);
        expect(f.collection.favoriteWriteCount, 0);
        expect(c.busy, isFalse);
      },
    );
  }
  for (final fail in [false, true]) {
    test(
      'accepted favorite write fail=$fail drains before graph releases resources',
      () async {
        final f = SystemPlaylistFixture();
        await f.initialize();
        final c = f.graph.playbackFavorite;
        await waitFavorite(c, () => c.ready);
        final gate = Completer<void>(), entered = Completer<void>();
        f.collection.onFavoriteSet = (_, _) async {
          entered.complete();
          await gate.future;
          if (fail) throw StateError('private-marker');
        };
        final writing = c.setFavorite(c.state, favorite: false);
        await entered.future;
        var closed = false;
        final close = f.graph.close().then((_) => closed = true);
        await favoriteTick();
        expect(closed, isFalse);
        expect(f.engine.disposalCount, 0);
        gate.complete();
        expect(
          await writing,
          fail
              ? PlaybackFavoriteEditResult.failed
              : PlaybackFavoriteEditResult.applied,
        );
        await close;
        expect(closed, isTrue);
        expect(f.engine.disposalCount, 1);
        expect(f.collection.favoriteWriteCount, fail ? 0 : 1);
        await f.collection.dispose();
      },
    );
  }
  test(
    'failed edit is safe and retry sets the same target, not a fresh toggle',
    () async {
      final f = SystemPlaylistFixture();
      addTearDown(f.close);
      await f.initialize();
      final c = f.graph.playbackFavorite;
      await waitFavorite(c, () => c.ready);
      f.collection.onFavoriteSet = (_, _) async =>
          throw StateError('private-marker');
      expect(
        await c.setFavorite(c.state, favorite: false),
        PlaybackFavoriteEditResult.failed,
      );
      final failure = c.failure!;
      expect(failure.message, isNot(contains('private-marker')));
      expect(failure.favorite, isFalse);
      expect(c.canRetry(failure), isTrue);
      f.collection.onFavoriteSet = null;
      expect(await c.retry(failure), PlaybackFavoriteEditResult.applied);
      await waitFavorite(c, () => c.state.isFavorite == false);
      expect(c.failure, isNull);
      expect(await c.retry(failure), PlaybackFavoriteEditResult.cancelled);
    },
  );
  test(
    'old failure cannot retry or dismiss a newer failure or another track',
    () async {
      final f = SystemPlaylistFixture();
      addTearDown(f.close);
      await f.initialize();
      final c = f.graph.playbackFavorite;
      await waitFavorite(c, () => c.ready);
      f.collection.onFavoriteSet = (_, _) async =>
          throw StateError('private-marker');
      await c.setFavorite(c.state, favorite: false);
      final old = c.failure!;
      await c.retry(old);
      final newer = c.failure!;
      c.dismissFailure(old);
      expect(c.failure, same(newer));
      expect(await c.retry(old), PlaybackFavoriteEditResult.cancelled);
      await f.graph.queue.replace(c.state.queue.entries, currentEntryId: 'q-4');
      expect(c.canRetry(newer), isFalse);
      expect(await c.retry(newer), PlaybackFavoriteEditResult.cancelled);
      c.dismissFailure(newer);
      expect(c.failure, isNull);
    },
  );
  for (final end in [false, true]) {
    test(
      'favorite read ${end ? 'end' : 'error'} disables editing until explicit retry',
      () async {
        final f = SystemPlaylistFixture();
        final stream = StreamController<List<FavoriteEntry>>.broadcast(
          sync: true,
        );
        addTearDown(stream.close);
        addTearDown(f.close);
        f.collection.favoriteReader = () => stream.stream;
        await f.initialize();
        await favoriteTick();
        final c = f.graph.playbackFavorite;
        stream.add([]);
        expect(c.state.isFavorite, isFalse);
        if (end) {
          await stream.close();
        } else {
          stream.addError(StateError('private-marker'));
        }
        expect(c.ready, isFalse);
        expect(c.state.isFavorite, isNull);
        expect(c.canSet(c.state), isFalse);
        if (!end) {
          stream.add([]);
          expect(c.ready, isFalse);
        }
        f.collection.favoriteReader = null;
        c.retryRead();
        await waitFavorite(c, () => c.ready);
        expect(c.state.isFavorite, isTrue);
        expect(c.failure, isNull);
      },
    );
  }
  test('reentrant listen close waits for the newly created subscription cancellation', () async {
    final f = SystemPlaylistFixture();
    final cancel = Completer<void>();
    final stream = StreamController<List<FavoriteEntry>>(
      onCancel: () => cancel.future,
    );
    Future<void>? closing;
    var closed = false;
    f.collection.favoriteReader = () => ReentrantListenStream(
      stream.stream,
      () => closing ??= f.graph.close().then((_) => closed = true),
    );
    await f.initialize();
    await favoriteTick();
    expect(closing, isNotNull);
    expect(closed, isFalse);
    cancel.complete();
    await closing;
    expect(closed, isTrue);
    await stream.close();
    await f.collection.dispose();
  });
}
