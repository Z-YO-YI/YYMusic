import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/domain/models/domain_failure.dart';
import 'package:yymusic/domain/models/load_state.dart';
import 'package:yymusic/domain/models/pagination.dart';
import 'package:yymusic/domain/models/playlist_content.dart';
import 'package:yymusic/features/playlists/common/playlist_content_controller.dart';

import '../support/catalog_detail_probe.dart' show detailTrack;
import '../support/fake_domain_repositories.dart';
import '../support/playlist_content_probe.dart';

void main() {
  late FakeCollectionRepository repository;
  late PlaylistContentSessions sessions;
  setUp(() {
    repository = FakeCollectionRepository();
    repository.contentReader = (id, page) async =>
        contentWindow(id: id, limit: page.limit);
    sessions = PlaylistContentSessions(repository: repository);
  });
  tearDown(() async {
    await sessions.close();
    await repository.dispose();
  });

  test('construction and idle root sessions are read-free, independent and reject new work after close', () async {
    final graph = DependencyGraph(collection: repository);
    final first = graph.playlistContents.open('a');
    final second = graph.playlistContents.open('b');
    expect(first, isNot(same(second)));
    expect(first.phase, LoadPhase.idle);
    expect(repository.contentReadCalls, isEmpty);
    expect(repository.contentWatchCount, 0);
    expect(() => graph.playlistContents.open(' bad '), throwsArgumentError);
    await graph.close();
    first.start();
    first.refresh();
    first.loadMore();
    expect(first.isCurrent, isFalse);
    expect(repository.contentReadCalls, isEmpty);
    expect(() => graph.playlistContents.open('new'), throwsStateError);
    expect(graph.playlistContents.retainedSessionCount, 0);
  });

  test('start subscribes before the first read, runs once, and keeps missing distinct from existing empty', () async {
    var missing = false;
    repository.contentReader = (id, page) async {
      expect(repository.contentWatchCount, 1);
      return missing
          ? null
          : contentWindow(id: id, count: 0, limit: page.limit);
    };
    final c = sessions.open('p');
    c.start();
    c.start();
    await waitForContent(c, () => c.phase == LoadPhase.empty);
    expect(c.missing, isFalse);
    expect(c.content!.playlist.name, '测试歌单');
    expect(repository.contentReadCalls.length, 1);
    missing = true;
    repository.setContentTracks([]);
    await waitForContent(c, () => c.missing);
    expect(c.content, isNull);
    expect(c.canLoadMore, isFalse);
  });

  test('growing prefix reloads from offset zero and reports the 200-entry cap truthfully', () async {
    repository.contentReader = (id, page) async =>
        contentWindow(id: id, count: 237, limit: page.limit);
    final c = sessions.open('p')..start();
    for (var count = 20; count <= 200; count += 20) {
      await waitForContent(
        c,
        () => c.isCurrent && c.content!.entries.length == count,
      );
      expect(c.content!.totalCount, 237);
      if (count < 200) {
        c.loadMore();
        c.loadMore();
      }
    }
    expect(c.capped, isTrue);
    expect(c.canLoadMore, isFalse);
    c.loadMore();
    await contentTick();
    expect(
      repository.contentReadCalls.map((r) => r.page.limit),
      List.generate(10, (i) => (i + 1) * 20),
    );
    expect(
      repository.contentReadCalls.every((r) => r.page.offset == 0),
      isTrue,
    );
    expect(repository.contentWatchCount, 1);
    c.refresh();
    await waitForContent(c, () => c.isCurrent);
    expect(c.content!.entries.length, 200);
    expect(repository.contentReadCalls.last.page.limit, 200);
  });

  test('a changed order replaces the whole prefix without track deduplication or stale row accumulation', () async {
    var result = contentWindow(count: 3);
    repository.contentReader = (_, _) async => result;
    final c = sessions.open('p')..start();
    await waitForContent(c, () => c.isCurrent);
    final track = result.entries.first.track!;
    result = PlaylistContent(
      playlist: result.playlist,
      page: PageRequest(limit: 20),
      totalCount: 2,
      entries: [
        contentItem('p', 'another-entry', 0, track),
        contentItem('p', 'entry-0', 1, track),
      ],
    );
    repository.setContentTracks([]);
    await waitForContent(c, () => c.isCurrent && c.content!.totalCount == 2);
    expect(c.content!.entries.map((e) => e.entry.id), [
      'another-entry',
      'entry-0',
    ]);
    expect(c.content!.entries.map((e) => e.entry.track).toSet().length, 1);
  });

  test('invalidation bursts during an in-flight query coalesce and its stale success cannot win', () async {
    final gate = Completer<PlaylistContent?>();
    var calls = 0;
    repository.contentReader = (_, page) => calls++ == 0
        ? gate.future
        : Future.value(contentWindow(count: 4, limit: page.limit));
    addTearDown(() {
      if (!gate.isCompleted) gate.complete(null);
    });
    final c = sessions.open('p')..start();
    await contentTick();
    for (var i = 0; i < 100; i++) {
      repository.setContentTracks([]);
    }
    expect(repository.contentReadCalls.length, 1);
    final seenCounts = <int>[];
    c.addListener(() {
      if (c.isCurrent) seenCounts.add(c.content!.totalCount);
    });
    gate.complete(contentWindow(count: 1));
    await waitForContent(c, () => c.isCurrent);
    expect(seenCounts, [4]);
    expect(repository.contentReadCalls.length, 2);
  });

  test('refresh isolates an old failed query and later page failure keeps stale content until retry', () async {
    final gate = Completer<PlaylistContent?>();
    var calls = 0;
    repository.contentReader = (_, page) => calls++ == 0
        ? gate.future
        : Future.value(contentWindow(count: 35, limit: page.limit));
    addTearDown(() {
      if (!gate.isCompleted) gate.complete(null);
    });
    final c = sessions.open('p')..start();
    await contentTick();
    c.refresh();
    gate.completeError(StateError('private-marker'));
    await waitForContent(c, () => c.isCurrent);
    expect(c.failure, isNull);
    expect(c.content!.entries.length, 20);
    repository.contentReader = (_, _) async =>
        throw StateError('private-marker');
    c.loadMore();
    await waitForContent(c, () => c.phase == LoadPhase.error);
    expect(c.content!.entries.length, 20);
    expect(c.isCurrent, isFalse);
    expect(c.canLoadMore, isFalse);
    expect(c.failure.toString(), isNot(contains('private-marker')));
    repository.contentReader = (_, page) async =>
        contentWindow(count: 35, limit: page.limit);
    c.refresh();
    await waitForContent(c, () => c.isCurrent);
    expect(c.content!.entries.length, 35);
    expect(c.content!.hasMore, isFalse);
    expect(c.capped, isFalse);
  });

  for (final mode in ['error', 'done', 'throw']) {
    test(
      'invalidation stream $mode produces safe error and explicit retry replaces subscription',
      () async {
        final changes = StreamController<void>.broadcast();
        var cancelCount = 0;
        changes.onCancel = () {
          cancelCount++;
        };
        repository.contentChangesReader = () {
          if (mode == 'throw') throw StateError('private-marker');
          return changes.stream;
        };
        final c = sessions.open('p')..start();
        if (mode != 'throw') {
          await waitForContent(c, () => c.isCurrent);
          if (mode == 'done') {
            await changes.close();
          } else {
            changes.addError(StateError('private-marker'));
          }
        }
        await waitForContent(c, () => c.phase == LoadPhase.error);
        expect(c.failure.toString(), isNot(contains('private-marker')));
        expect(c.isCurrent, isFalse);
        repository.contentChangesReader = null;
        c.refresh();
        await waitForContent(c, () => c.isCurrent);
        expect(repository.contentWatchCount, 2);
        if (mode != 'throw') expect(cancelCount, 1);
        await changes.close();
      },
    );
  }

  test(
    'wrong playlist or requested window responses cannot become visible data',
    () async {
      final c = sessions.open('p');
      for (final response in [
        contentWindow(id: 'other'),
        contentWindow(limit: 19),
        contentWindow(offset: 1),
      ]) {
        repository.contentReader = (_, _) async => response;
        c.refresh();
        await waitForContent(c, () => c.phase == LoadPhase.error);
        expect(c.failure!.code, DomainFailureCode.schemaMismatch);
        expect(c.content, isNull);
      }
    },
  );

  test(
    'read-free unavailable state is an error rather than an empty playlist',
    () async {
      final absent = PlaylistContentSessions();
      final c = absent.open('p')..start();
      await waitForContent(c, () => c.phase == LoadPhase.error);
      expect(c.missing, isFalse);
      expect(c.content, isNull);
      await absent.close();
    },
  );

  test('closing immediately from loading notification never starts unregistered work', () async {
    final c = sessions.open('p');
    Future<void>? close;
    c.addListener(() {
      if (c.loading) close ??= c.close();
    });
    c.start();
    await close;
    expect(repository.contentWatchCount, 0);
    expect(repository.contentReadCalls, isEmpty);
    expect(sessions.retainedSessionCount, 0);
  });

  test('stream getter reentrant close still drains the new subscription cancellation', () async {
    final gate = Completer<void>();
    final entered = Completer<void>();
    final changes = StreamController<void>(
      onCancel: () {
        entered.complete();
        return gate.future;
      },
    );
    final c = sessions.open('p');
    Future<void>? close;
    repository.contentChangesReader = () {
      close = c.close();
      return changes.stream;
    };
    c.start();
    await entered.future;
    expect(sessions.retainedSessionCount, 1);
    expect(repository.contentReadCalls, isEmpty);
    gate.complete();
    await close;
    expect(sessions.retainedSessionCount, 0);
    await changes.close();
  });

  test('refresh cancellation and read futures both drain before root storage closes', () async {
    final readGate = Completer<PlaylistContent?>();
    final cancelGate = Completer<void>();
    final changes = StreamController<void>(onCancel: () => cancelGate.future);
    repository.contentChangesReader = () => changes.stream;
    repository.contentReader = (_, _) => readGate.future;
    final library = FakeLibraryRepository();
    final graph = DependencyGraph(collection: repository, library: library);
    final c = graph.playlistContents.open('p')..start();
    await contentTick();
    c.refresh();
    await contentTick();
    var closed = false;
    final close = graph.close().then((_) => closed = true);
    readGate.complete(contentWindow());
    await contentTick();
    expect(closed, isFalse);
    expect(library.disposeCount, 0);
    expect(graph.playlistContents.retainedSessionCount, 1);
    cancelGate.complete();
    await close;
    expect(library.disposeCount, 1);
    expect(repository.contentWatchCount, 1);
    expect(graph.playlistContents.retainedSessionCount, 0);
    await changes.close();
  });

  test('stream cancellation failures are sanitized while root still releases remaining resources', () async {
    final changes = StreamController<void>(
      onCancel: () async => throw StateError('private-marker'),
    );
    repository.contentChangesReader = () => changes.stream;
    final library = FakeLibraryRepository();
    final graph = DependencyGraph(collection: repository, library: library);
    final c = graph.playlistContents.open('p')..start();
    await waitForContent(c, () => c.isCurrent);
    await expectLater(
      graph.close(),
      throwsA(
        isA<DomainFailure>().having(
          (e) => e.toString(),
          'safe error',
          isNot(contains('private-marker')),
        ),
      ),
    );
    expect(library.disposeCount, 1);
    expect(graph.playlistContents.retainedSessionCount, 0);
    await changes.close();
  });

  test('default fake projection follows entry identity edits, unresolved tracks and deletion', () async {
    repository.contentReader = null;
    final track = detailTrack('same');
    await repository.createPlaylist(contentPlaylist('p'));
    repository.setContentTracks([track]);
    final c = sessions.open('p')..start();
    await waitForContent(c, () => c.isCurrent);
    expect(c.missing, isFalse);
    for (final id in ['first', 'second']) {
      await repository.appendPlaylistEntry(
        'p',
        PlaylistEntryDraft(id: id, track: track.ref, addedAt: contentEpoch),
      );
    }
    await waitForContent(c, () => c.isCurrent && c.content!.totalCount == 2);
    expect(c.content!.entries.every((e) => e.isAvailable), isTrue);
    await repository.movePlaylistEntry('p', 'second', beforeEntryId: 'first');
    await waitForContent(
      c,
      () => c.isCurrent && c.content!.entries.first.entry.id == 'second',
    );
    repository.setContentTracks([]);
    await waitForContent(
      c,
      () => c.isCurrent && c.content!.entries.every((e) => e.track == null),
    );
    expect(c.content!.entries.map((e) => e.entry.track), [
      track.ref,
      track.ref,
    ]);
    await repository.removePlaylistEntry('p', 'first');
    await waitForContent(c, () => c.isCurrent && c.content!.totalCount == 1);
    await repository.deletePlaylist('p');
    await waitForContent(c, () => c.missing);
  });

  test('refresh generation ignores old data and errors before deferred cancellation starts', () async {
    final changes = StreamController<void>.broadcast(sync: true);
    repository.contentChangesReader = () => changes.stream;
    final c = sessions.open('p')..start();
    await waitForContent(c, () => c.isCurrent);
    repository.contentChangesReader = null;
    c.refresh();
    changes.add(null);
    changes.addError(StateError('private-marker'));
    expect(c.loading, isTrue);
    expect(c.failure, isNull);
    await waitForContent(c, () => c.isCurrent);
    expect(repository.contentReadCalls.length, 2);
    expect(repository.contentWatchCount, 2);
    await changes.close();
  });

  test(
    'root may close reentrantly from a data listener and drain that same read',
    () async {
      final library = FakeLibraryRepository();
      final graph = DependencyGraph(collection: repository, library: library);
      final c = graph.playlistContents.open('p');
      final closing = Completer<Future<void>>();
      c.addListener(() {
        if (c.isCurrent) {
          closing.complete(graph.close());
          expect(library.disposeCount, 0);
        }
      });
      c.start();
      await (await closing.future);
      expect(library.disposeCount, 1);
      expect(c.isCurrent, isFalse);
      expect(graph.playlistContents.retainedSessionCount, 0);
    },
  );

  test('a terminal notification can request a new refresh without losing registered work', () async {
    final c = sessions.open('p');
    var refreshed = false;
    c.addListener(() {
      if (c.isCurrent && !refreshed) {
        refreshed = true;
        c.refresh();
      }
    });
    c.start();
    await waitForContent(
      c,
      () => c.isCurrent && repository.contentReadCalls.length == 2,
    );
    expect(repository.contentWatchCount, 2);
    await c.close();
    expect(c.isCurrent, isFalse);
    expect(sessions.retainedSessionCount, 0);
  });
}
