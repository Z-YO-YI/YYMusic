import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/domain/models/domain_failure.dart';
import 'package:yymusic/domain/models/load_state.dart';
import 'package:yymusic/domain/models/system_playlist_content.dart';
import 'package:yymusic/features/playlists/common/system_playlist_controller.dart';

import '../support/catalog_detail_probe.dart';
import '../support/fake_domain_repositories.dart';
import '../support/playlist_content_probe.dart';
import '../support/system_playlist_probe.dart';
import 'system_playlist_repository_test.dart' show systemHistory, systemQueue;

void main() {
  late FakeCollectionRepository repository;
  late SystemPlaylistSessions sessions;
  setUp(() {
    repository = FakeCollectionRepository(clock: () => contentEpoch);
    sessions = SystemPlaylistSessions(repository: repository);
  });
  tearDown(() async {
    await sessions.close();
    await repository.dispose();
  });

  test('root opens independent idle typed sessions without any I/O', () async {
    final graph = DependencyGraph(collection: repository);
    final one = graph.systemPlaylists.open(SystemPlaylistType.queue);
    final two = graph.systemPlaylists.open(SystemPlaylistType.queue);
    final favorites = graph.systemPlaylists.open(SystemPlaylistType.favorites);
    expect(one, isNot(same(two)));
    expect(favorites.type, SystemPlaylistType.favorites);
    expect(one.phase, LoadPhase.idle);
    expect(one.content, isNull);
    expect(repository.systemReadCalls, isEmpty);
    expect(repository.systemWatchCalls, isEmpty);
    await graph.close();
    one.start();
    one.refresh();
    one.setActive(true);
    one.loadMore(systemWindow());
    expect(one.isCurrent, isFalse);
    expect(repository.systemReadCalls, isEmpty);
    expect(graph.systemPlaylists.retainedSessionCount, 0);
    expect(
      () => graph.systemPlaylists.open(SystemPlaylistType.recent),
      throwsStateError,
    );
  });

  for (final type in SystemPlaylistType.values) {
    test(
      '$type subscribes before its only initial read and exists empty',
      () async {
        repository.systemReader = (actual, page) async {
          expect(repository.systemWatchCalls, [type]);
          return systemWindow(type: actual, count: 0, limit: page.limit);
        };
        final c = sessions.open(type)..start();
        c.start();
        await waitForSystem(c, () => c.phase == LoadPhase.empty);
        expect(c.content!.type, type);
        expect(c.content!.totalCount, 0);
        expect(c.isCurrent, isTrue);
        expect(c.canLoadMore, isFalse);
        expect(repository.systemReadCalls.length, 1);
        expect(repository.playlistReadCount, 0);
        expect(repository.playlistMutationCalls, isEmpty);
      },
    );
  }

  test('three sessions react only to their collection and all react to catalog changes', () async {
    final cs = [
      for (final type in SystemPlaylistType.values)
        sessions.open(type)..start(),
    ];
    for (final c in cs) {
      await waitForSystem(c, () => c.isCurrent);
    }
    final track = detailTrack('same');
    await repository.setFavorite(track.ref, favorite: true);
    await waitForSystem(
      cs[0],
      () => cs[0].isCurrent && cs[0].content!.totalCount == 1,
    );
    expect(repository.systemReadCalls.map((e) => e.type), [
      ...SystemPlaylistType.values,
      SystemPlaylistType.favorites,
    ]);
    expect(cs[0].content!.entries.single.track, isNull);
    await repository.recordHistory(systemHistory('h', track.ref, contentEpoch));
    await waitForSystem(
      cs[1],
      () => cs[1].isCurrent && cs[1].content!.totalCount == 1,
    );
    await repository.saveQueue(
      systemQueue([track.ref, track.ref], current: 'q-1'),
    );
    await waitForSystem(
      cs[2],
      () => cs[2].isCurrent && cs[2].content!.totalCount == 2,
    );
    repository.setContentTracks([track]);
    for (final c in cs) {
      await waitForSystem(
        c,
        () => c.isCurrent && c.content!.entries.every((e) => e.isAvailable),
      );
    }
    expect(cs[0].content!.entries.single.identity, track.ref);
    expect(cs[1].content!.entries.single.identity, 'h');
    expect(cs[2].content!.entries.map((e) => e.identity), ['q-0', 'q-1']);
    expect(cs[2].content!.entries.map((e) => e.reference), [
      track.ref,
      track.ref,
    ]);
    expect(cs[2].content!.currentQueueEntryId, 'q-1');
    final reads = repository.systemReadCalls.length;
    await repository.createPlaylist(contentPlaylist('custom'));
    await contentTick();
    expect(repository.systemReadCalls.length, reads);
    await repository.clearHistory();
    await waitForSystem(cs[1], () => cs[1].phase == LoadPhase.empty);
    expect(cs[0].content!.totalCount, 1);
    expect(cs[2].content!.totalCount, 2);
  });

  test(
    'invalidation storm coalesces while obsolete success never becomes data',
    () async {
      final gate = Completer<SystemPlaylistContent>();
      var calls = 0;
      repository.systemReader = (_, _) =>
          calls++ == 0 ? gate.future : Future.value(systemWindow(count: 4));
      addTearDown(() {
        if (!gate.isCompleted) gate.complete(systemWindow());
      });
      final c = sessions.open(SystemPlaylistType.queue)..start();
      await contentTick();
      for (var i = 0; i < 100; i++) {
        repository.setContentTracks([]);
      }
      final seen = <int>[];
      c.addListener(() {
        if (c.isCurrent) seen.add(c.content!.totalCount);
      });
      expect(repository.systemReadCalls.length, 1);
      gate.complete(systemWindow(count: 1));
      await waitForSystem(c, () => c.isCurrent);
      expect(seen, [4]);
      expect(repository.systemReadCalls.length, 2);
    },
  );

  test('refresh ignores old failed read and page retry retains disabled old content', () async {
    final gate = Completer<SystemPlaylistContent>();
    var calls = 0;
    repository.systemReader = (_, page) => calls++ == 0
        ? gate.future
        : Future.value(systemWindow(count: 35, limit: page.limit));
    addTearDown(() {
      if (!gate.isCompleted) gate.complete(systemWindow());
    });
    final c = sessions.open(SystemPlaylistType.queue)..start();
    await contentTick();
    c.refresh();
    gate.completeError(StateError('private-marker'));
    await waitForSystem(c, () => c.isCurrent);
    final old = c.content!;
    repository.systemReader = (_, _) async => throw DomainFailure(
      code: DomainFailureCode.databaseCorrupted,
      diagnosticId: 'private-marker',
    );
    c.loadMore(old);
    await waitForSystem(c, () => c.phase == LoadPhase.error);
    expect(c.content, same(old));
    expect(c.isCurrent, isFalse);
    expect(c.canLoadMore, isFalse);
    expect(c.failure!.code, DomainFailureCode.databaseCorrupted);
    expect(c.failure.toString(), isNot(contains('private-marker')));
    repository.systemReader = (_, page) async =>
        systemWindow(count: 35, limit: page.limit);
    c.refresh();
    await waitForSystem(c, () => c.isCurrent);
    expect(c.content!.entries.length, 35);
    expect(c.content!.page.limit, 40);
    expect(c.failure, isNull);
  });

  for (final mode in ['error', 'done', 'throw']) {
    test(
      'stream $mode fails closed; explicit retry restores one live watch',
      () async {
        final changes = StreamController<void>.broadcast();
        var canceled = 0;
        changes.onCancel = () {
          canceled++;
        };
        repository.systemChangesReader = (_) {
          if (mode == 'throw') throw StateError('private-marker');
          return changes.stream;
        };
        final c = sessions.open(SystemPlaylistType.queue)..start();
        if (mode != 'throw') {
          await waitForSystem(c, () => c.isCurrent);
          if (mode == 'done') {
            await changes.close();
          } else {
            changes.addError(StateError('private-marker'));
          }
        }
        await waitForSystem(c, () => c.phase == LoadPhase.error);
        expect(c.failure.toString(), isNot(contains('private-marker')));
        expect(c.isCurrent, isFalse);
        repository.systemChangesReader = null;
        c.refresh();
        await waitForSystem(c, () => c.isCurrent);
        expect(repository.systemWatchCalls.length, 2);
        if (mode != 'throw') expect(canceled, 1);
        await changes.close();
      },
    );
  }

  test(
    'wrong type, offset, or limit never publishes a mismatched window',
    () async {
      final c = sessions.open(SystemPlaylistType.queue);
      for (final result in [
        systemWindow(type: SystemPlaylistType.favorites),
        systemWindow(limit: 19),
        systemWindow(offset: 1),
      ]) {
        repository.systemReader = (_, _) async => result;
        c.refresh();
        await waitForSystem(c, () => c.phase == LoadPhase.error);
        expect(c.failure!.code, DomainFailureCode.schemaMismatch);
        expect(c.content, isNull);
      }
    },
  );

  test('missing repository is retryable error, never empty data', () async {
    final absent = SystemPlaylistSessions();
    final c = absent.open(SystemPlaylistType.favorites)..start();
    await waitForSystem(c, () => c.phase == LoadPhase.error);
    expect(c.content, isNull);
    expect(c.failure!.retryable, isTrue);
    await absent.close();
  });
}
