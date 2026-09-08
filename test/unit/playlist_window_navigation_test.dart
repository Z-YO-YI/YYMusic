import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/domain/models/domain_failure.dart';
import 'package:yymusic/domain/models/load_state.dart';
import 'package:yymusic/domain/models/playlist_content.dart';
import 'package:yymusic/features/playlists/common/playlist_content_controller.dart';

import '../support/fake_domain_repositories.dart';
import '../support/playlist_content_fixture.dart';
import '../support/playlist_content_probe.dart';
import 'playlist_content_actions_test.dart' show startContent;

Future<void> expandWindow(PlaylistContentController c) async {
  await waitForContent(c, () => c.isCurrent);
  while (c.canLoadMore) {
    c.loadMore(c.content!);
    await waitForContent(c, () => c.isCurrent);
  }
}

void main() {
  late FakeCollectionRepository repository;
  late PlaylistContentSessions sessions;
  var count = 1003;
  setUp(() {
    count = 1003;
    repository = FakeCollectionRepository();
    repository.contentReader = (id, page) async => contentWindow(
      id: id,
      count: count,
      limit: page.limit,
      offset: page.offset,
    );
    sessions = PlaylistContentSessions(repository: repository);
  });
  tearDown(() async {
    await sessions.close();
    await repository.dispose();
  });

  test('all 1003 entries are reachable exactly once with at most 200 retained and bound per query', () async {
    final c = sessions.open('p')..start();
    await expandWindow(c);
    final ids = <String>[];
    while (true) {
      final data = c.content!;
      ids.addAll(data.entries.map((e) => e.entry.id));
      expect(data.entries.length, lessThanOrEqualTo(200));
      if (!c.canShowNextWindow) break;
      c.showNextWindow(data);
      c.showNextWindow(data);
      await waitForContent(c, () => c.isCurrent);
    }
    expect(ids, List.generate(1003, (i) => 'entry-$i'));
    expect(c.content!.page.offset, 1000);
    expect(c.canShowPreviousWindow, isTrue);
    expect(repository.contentReadCalls.length, 15);
    expect(
      repository.contentReadCalls.every((r) => r.page.limit <= 200),
      isTrue,
    );
    expect(repository.contentWatchCount, 1);
    for (var offset = 800; offset >= 0; offset -= 200) {
      c.showPreviousWindow(c.content!);
      await waitForContent(c, () => c.isCurrent);
      expect(c.content!.page.offset, offset);
      expect(c.content!.entries.length, 200);
      expect(c.content!.entries.first.entry.id, 'entry-$offset');
    }
    expect(c.canShowPreviousWindow, isFalse);
    expect(repository.playlistMutationCalls, isEmpty);
  });

  test('stale next, previous and more callbacks, inactive sessions and busy root writer are read-free', () async {
    final f = PlaylistContentFixture(count: 401);
    addTearDown(f.close);
    final c = await startContent(f);
    final initial = c.content!;
    await expandWindow(c);
    final first = c.content!;
    c.showNextWindow(first);
    await waitForContent(c, () => c.isCurrent);
    final second = c.content!;
    var reads = f.collection.contentReadCalls.length;
    c.showNextWindow(first);
    c.showPreviousWindow(first);
    c.loadMore(initial);
    c.setActive(false);
    c.showPreviousWindow(second);
    c.showNextWindow(second);
    await contentTick();
    expect(f.collection.contentReadCalls.length, reads);
    c.setActive(true);
    final gate = Completer<void>();
    addTearDown(() {
      if (!gate.isCompleted) gate.complete();
    });
    f.collection.onPlaylistMutation = (_, _) => gate.future;
    final write = f.graph.playlists.renamePlaylist('custom', '更新名称');
    expect(c.busy, isTrue);
    c.showPreviousWindow(second);
    c.showNextWindow(second);
    await contentTick();
    expect(f.collection.contentReadCalls.length, reads);
    gate.complete();
    await write;
    await waitForContent(
      c,
      () => c.isCurrent && c.content!.playlist.name == '更新名称',
    );
    reads = f.collection.contentReadCalls.length;
    await c.close();
    c.showNextWindow(c.content!);
    c.showPreviousWindow(c.content!);
    c.loadMore();
    expect(f.collection.contentReadCalls.length, reads);
  });

  test('refresh and invalidation preserve offset and replace the snapshot after reorder', () async {
    final f = PlaylistContentFixture(count: 405);
    addTearDown(f.close);
    final c = await startContent(f);
    await expandWindow(c);
    c.showNextWindow(c.content!);
    await waitForContent(c, () => c.isCurrent);
    await f.collection.movePlaylistEntry(f.id, 'e-400', beforeEntryId: 'e-200');
    await waitForContent(
      c,
      () => c.isCurrent && c.content!.entries.first.entry.id == 'e-400',
    );
    expect(c.content!.entries.map((e) => e.entry.id).toSet().length, 200);
    expect(c.canMoveEntry('e-400', up: true), isFalse);
    expect(
      c.canMoveEntry(c.content!.entries.last.entry.id, up: false),
      isFalse,
    );
    c.refresh();
    await waitForContent(c, () => c.isCurrent);
    expect(c.content!.page.offset, 200);
    expect(c.content!.page.limit, 200);
    expect(c.content!.entries.first.entry.id, 'e-400');
    expect(f.engine.calls, isEmpty);
  });

  test('deletion moves an out-of-range group to the last valid group without publishing false emptiness', () async {
    count = 405;
    final c = sessions.open('p')..start();
    await expandWindow(c);
    for (var i = 0; i < 2; i++) {
      c.showNextWindow(c.content!);
      await waitForContent(c, () => c.isCurrent);
    }
    final seen = <(int, int)>[];
    c.addListener(() {
      if (c.isCurrent) {
        seen.add((c.content!.page.offset, c.content!.entries.length));
      }
    });
    count = 220;
    repository.setContentTracks([]);
    await waitForContent(c, () => c.isCurrent && c.content!.totalCount == 220);
    expect(seen, [(200, 20)]);
    count = 200;
    repository.setContentTracks([]);
    await waitForContent(c, () => c.isCurrent && c.content!.totalCount == 200);
    expect(seen.last, (0, 200));
    count = 0;
    repository.setContentTracks([]);
    await waitForContent(c, () => c.phase == LoadPhase.empty);
    expect(c.missing, isFalse);
    expect(c.content!.page.offset, 0);
  });

  test('empty or missing playlist while on a later group is distinguished without endless retries', () async {
    final c = sessions.open('p')..start();
    await expandWindow(c);
    c.showNextWindow(c.content!);
    await waitForContent(c, () => c.isCurrent);
    count = 0;
    final reads = repository.contentReadCalls.length;
    c.refresh();
    await waitForContent(c, () => c.phase == LoadPhase.empty);
    expect(repository.contentReadCalls.length, reads + 2);
    expect(c.missing, isFalse);
    repository.contentReader = (_, _) async => null;
    c.refresh();
    await waitForContent(c, () => c.missing);
    expect(c.canShowPreviousWindow, isFalse);
    expect(c.canShowNextWindow, isFalse);
  });

  test('failed next-group read keeps disabled old rows and explicit retry still targets the requested offset', () async {
    final c = sessions.open('p')..start();
    await expandWindow(c);
    final first = c.content!;
    final reader = repository.contentReader;
    repository.contentReader = (_, _) async =>
        throw StateError('private-marker');
    c.showNextWindow(first);
    await waitForContent(c, () => c.phase == LoadPhase.error);
    expect(c.content, same(first));
    expect(c.canOpenEntry('entry-0'), isFalse);
    expect(c.canShowNextWindow, isFalse);
    expect(c.canShowPreviousWindow, isFalse);
    expect(c.failure.toString(), isNot(contains('private-marker')));
    repository.contentReader = reader;
    c.refresh();
    await waitForContent(c, () => c.isCurrent);
    expect(c.content!.page.offset, 200);
  });

  test('wrong nonzero offset response fails closed, while stale in-flight success is never published', () async {
    final c = sessions.open('p')..start();
    await expandWindow(c);
    final reader = repository.contentReader;
    repository.contentReader = (_, page) async =>
        contentWindow(count: count, limit: page.limit);
    c.showNextWindow(c.content!);
    await waitForContent(c, () => c.phase == LoadPhase.error);
    expect(c.failure!.code, DomainFailureCode.schemaMismatch);
    expect(c.content!.page.offset, 0);
    final gate = Completer<PlaylistContent?>();
    addTearDown(() {
      if (!gate.isCompleted) gate.complete(null);
    });
    repository.contentReader = (_, _) => gate.future;
    c.refresh();
    await contentTick();
    repository.contentReader = reader;
    count = 207;
    repository.setContentTracks([]);
    await contentTick();
    gate.complete(contentWindow(count: 1003, offset: 200, limit: 200));
    await waitForContent(c, () => c.isCurrent);
    expect(c.content!.totalCount, 207);
    expect(c.content!.entries.length, 7);
  });

  test('closing during a later group read drains it and does not start fallback or publish late data', () async {
    final c = sessions.open('p')..start();
    await expandWindow(c);
    final first = c.content!;
    final gate = Completer<PlaylistContent?>();
    repository.contentReader = (_, _) => gate.future;
    c.showNextWindow(first);
    await contentTick();
    var closed = false;
    final closing = sessions.close().then((_) => closed = true);
    await contentTick();
    expect(closed, isFalse);
    expect(sessions.retainedSessionCount, 1);
    final reads = repository.contentReadCalls.length;
    gate.complete(contentWindow(count: 0, offset: 200, limit: 200));
    await closing;
    expect(c.content, same(first));
    expect(repository.contentReadCalls.length, reads);
    expect(sessions.retainedSessionCount, 0);
  });
}
