import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/domain/models/load_state.dart';
import 'package:yymusic/domain/models/system_playlist_content.dart';
import 'package:yymusic/features/playlists/common/system_playlist_controller.dart';

import '../support/fake_domain_repositories.dart';
import '../support/playlist_content_probe.dart';
import '../support/system_playlist_probe.dart';

void main() {
  late FakeCollectionRepository repository;
  late SystemPlaylistSessions sessions;
  var count = 1003;
  setUp(() {
    count = 1003;
    repository = FakeCollectionRepository();
    repository.systemReader = (type, page) async => systemWindow(
      type: type,
      count: count,
      limit: page.limit,
      offset: page.offset,
      current: type == SystemPlaylistType.queue && count > 0 ? 'entry-0' : null,
    );
    sessions = SystemPlaylistSessions(repository: repository);
  });
  tearDown(() async {
    await sessions.close();
    await repository.dispose();
  });

  for (final type in [SystemPlaylistType.favorites, SystemPlaylistType.queue]) {
    test(
      '$type traverses all 1003 in bounded replacement windows with stable identities',
      () async {
        final c = sessions.open(type)..start();
        await expandSystemWindow(c);
        final positions = <int>[];
        while (true) {
          final data = c.content!;
          positions.addAll(data.entries.map((e) => e.position));
          expect(data.entries.length, lessThanOrEqualTo(200));
          if (type == SystemPlaylistType.queue) {
            expect(data.currentQueueEntryId, 'entry-0');
          }
          if (!c.canShowNextWindow) break;
          c.showNextWindow(data);
          c.showNextWindow(data);
          await waitForSystem(c, () => c.isCurrent);
        }
        expect(positions, List.generate(1003, (i) => i));
        expect(repository.systemReadCalls.length, 15);
        expect(
          repository.systemReadCalls.every((e) => e.page.limit <= 200),
          isTrue,
        );
        expect(repository.systemWatchCalls, [type]);
        for (var offset = 800; offset >= 0; offset -= 200) {
          c.showPreviousWindow(c.content!);
          await waitForSystem(c, () => c.isCurrent);
          expect(c.content!.page.offset, offset);
          expect(c.content!.entries.length, 200);
        }
        expect(c.canShowPreviousWindow, isFalse);
        expect(repository.playlistMutationCalls, isEmpty);
      },
    );
  }

  test('stale callbacks, inactive view, loading, and disposed sessions do not start reads', () async {
    final c = sessions.open(SystemPlaylistType.queue)..start();
    await waitForSystem(c, () => c.isCurrent);
    final initial = c.content!;
    await expandSystemWindow(c);
    final first = c.content!;
    c.showNextWindow(first);
    await waitForSystem(c, () => c.isCurrent);
    final second = c.content!;
    final reads = repository.systemReadCalls.length;
    c.loadMore(initial);
    c.showNextWindow(first);
    c.showPreviousWindow(first);
    c.setActive(false);
    c.showPreviousWindow(second);
    c.showNextWindow(second);
    expect(c.canShowPreviousWindow, isFalse);
    expect(c.canShowNextWindow, isFalse);
    await contentTick();
    expect(repository.systemReadCalls.length, reads);
    c.setActive(true);
    c.showPreviousWindow(second);
    c.showPreviousWindow(second);
    await waitForSystem(c, () => c.isCurrent);
    expect(repository.systemReadCalls.length, reads + 1);
    expect(c.content!.page.offset, 0);
    await c.close();
    c.loadMore(initial);
    c.showNextWindow(c.content!);
    c.showPreviousWindow(c.content!);
    await contentTick();
    expect(repository.systemReadCalls.length, reads + 1);
  });

  test('shrinking beyond current offset re-reads last group without false empty data', () async {
    count = 405;
    final c = sessions.open(SystemPlaylistType.queue)..start();
    await expandSystemWindow(c);
    for (var i = 0; i < 2; i++) {
      c.showNextWindow(c.content!);
      await waitForSystem(c, () => c.isCurrent);
    }
    final seen = <(int, int)>[];
    c.addListener(() {
      if (c.isCurrent) {
        seen.add((c.content!.page.offset, c.content!.totalCount));
      }
    });
    for (final nextCount in [220, 200, 0]) {
      count = nextCount;
      repository.setContentTracks([]);
      await waitForSystem(
        c,
        () => c.isCurrent && c.content!.totalCount == nextCount,
      );
    }
    expect(seen, [(200, 220), (0, 200), (0, 0)]);
    expect(c.phase, LoadPhase.empty);
    expect(c.content!.currentQueueEntryId, isNull);
    expect(c.canShowPreviousWindow, isFalse);
  });

  test('next-group failure retains disabled old data and retry preserves the target offset', () async {
    final c = sessions.open(SystemPlaylistType.queue)..start();
    await expandSystemWindow(c);
    final old = c.content!, reader = repository.systemReader;
    repository.systemReader = (_, _) async =>
        throw StateError('private-marker');
    c.showNextWindow(old);
    await waitForSystem(c, () => c.phase == LoadPhase.error);
    expect(c.content, same(old));
    expect(c.isCurrent, isFalse);
    expect(c.canShowNextWindow, isFalse);
    expect(c.failure.toString(), isNot(contains('private-marker')));
    repository.systemReader = reader;
    c.refresh();
    await waitForSystem(c, () => c.isCurrent);
    expect(c.content!.page.offset, 200);
    expect(c.content!.page.limit, 200);
  });

  test('late out-of-range result after close neither publishes nor starts fallback', () async {
    final c = sessions.open(SystemPlaylistType.queue)..start();
    await expandSystemWindow(c);
    final old = c.content!;
    final gate = Completer<SystemPlaylistContent>();
    addTearDown(() {
      if (!gate.isCompleted) {
        gate.complete(systemWindow(offset: 200, limit: 200, count: 0));
      }
    });
    repository.systemReader = (_, _) => gate.future;
    c.showNextWindow(old);
    await contentTick();
    var closed = false;
    final closing = sessions.close().then((_) => closed = true);
    await contentTick();
    expect(closed, isFalse);
    expect(sessions.retainedSessionCount, 1);
    final reads = repository.systemReadCalls.length;
    gate.complete(systemWindow(offset: 200, limit: 200, count: 0));
    await closing;
    expect(c.content, same(old));
    expect(repository.systemReadCalls.length, reads);
    expect(sessions.retainedSessionCount, 0);
  });
}
