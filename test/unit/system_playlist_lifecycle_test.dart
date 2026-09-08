import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/domain/models/domain_failure.dart';
import 'package:yymusic/domain/models/system_playlist_content.dart';

import '../support/fake_domain_repositories.dart';
import '../support/playlist_content_probe.dart';
import '../support/system_playlist_probe.dart';

void main() {
  late FakeCollectionRepository repository;
  late FakeLibraryRepository library;
  late DependencyGraph graph;
  var closeFailureExpected = false;
  setUp(() {
    closeFailureExpected = false;
    repository = FakeCollectionRepository();
    library = FakeLibraryRepository();
    graph = DependencyGraph(collection: repository, library: library);
  });
  tearDown(() async {
    if (closeFailureExpected) {
      await expectLater(graph.close(), throwsA(isA<DomainFailure>()));
    } else {
      await graph.close();
    }
    await repository.dispose();
  });

  test(
    'close in initial loading notification registers before any I/O starts',
    () async {
      final c = graph.systemPlaylists.open(SystemPlaylistType.queue);
      Future<void>? closing;
      c.addListener(() {
        if (c.loading) closing ??= graph.close();
      });
      c.start();
      await closing;
      expect(repository.systemReadCalls, isEmpty);
      expect(repository.systemWatchCalls, isEmpty);
      expect(library.disposeCount, 1);
      expect(graph.systemPlaylists.retainedSessionCount, 0);
    },
  );

  test('getter reentrant close drains the newly returned subscription cancellation', () async {
    final gate = Completer<void>(), entered = Completer<void>();
    final changes = StreamController<void>(
      onCancel: () {
        entered.complete();
        return gate.future;
      },
    );
    addTearDown(() {
      if (!gate.isCompleted) gate.complete();
    });
    Future<void>? closing;
    repository.systemChangesReader = (_) {
      closing = graph.close();
      return changes.stream;
    };
    final c = graph.systemPlaylists.open(SystemPlaylistType.queue)..start();
    await entered.future;
    expect(library.disposeCount, 0);
    expect(graph.systemPlaylists.retainedSessionCount, 1);
    expect(repository.systemReadCalls, isEmpty);
    gate.complete();
    await closing;
    expect(library.disposeCount, 1);
    expect(graph.systemPlaylists.retainedSessionCount, 0);
    expect(c.isCurrent, isFalse);
    await changes.close();
  });

  test(
    'refresh cancellation and read both drain before shared storage closes',
    () async {
      final read = Completer<SystemPlaylistContent>(),
          cancel = Completer<void>();
      final changes = StreamController<void>(onCancel: () => cancel.future);
      addTearDown(() {
        if (!read.isCompleted) read.complete(systemWindow());
        if (!cancel.isCompleted) cancel.complete();
      });
      repository.systemReader = (_, _) => read.future;
      repository.systemChangesReader = (_) => changes.stream;
      final c = graph.systemPlaylists.open(SystemPlaylistType.queue)..start();
      await contentTick();
      c.refresh();
      await contentTick();
      var finished = false;
      final closing = graph.close().then((_) => finished = true);
      read.complete(systemWindow());
      await contentTick();
      expect(finished, isFalse);
      expect(library.disposeCount, 0);
      cancel.complete();
      await closing;
      expect(library.disposeCount, 1);
      expect(c.content, isNull);
      expect(repository.systemWatchCalls.length, 1);
      expect(graph.systemPlaylists.retainedSessionCount, 0);
      await changes.close();
    },
  );

  test(
    'cancellation failure is safe and remaining root resources still release',
    () async {
      closeFailureExpected = true;
      final changes = StreamController<void>(
        onCancel: () async => throw StateError('private-marker'),
      );
      repository.systemChangesReader = (_) => changes.stream;
      final c = graph.systemPlaylists.open(SystemPlaylistType.queue)..start();
      await waitForSystem(c, () => c.isCurrent);
      await expectLater(
        graph.close(),
        throwsA(
          isA<DomainFailure>().having(
            (e) => e.toString(),
            'safe diagnostic',
            isNot(contains('private-marker')),
          ),
        ),
      );
      expect(library.disposeCount, 1);
      expect(graph.systemPlaylists.retainedSessionCount, 0);
      await changes.close();
    },
  );

  test('old synchronous data and errors after refresh cannot invalidate new generation', () async {
    final changes = StreamController<void>.broadcast(sync: true);
    repository.systemChangesReader = (_) => changes.stream;
    final c = graph.systemPlaylists.open(SystemPlaylistType.queue)..start();
    await waitForSystem(c, () => c.isCurrent);
    repository.systemChangesReader = null;
    c.refresh();
    changes.add(null);
    changes.addError(StateError('private-marker'));
    expect(c.loading, isTrue);
    expect(c.failure, isNull);
    await waitForSystem(c, () => c.isCurrent);
    expect(repository.systemReadCalls.length, 2);
    expect(repository.systemWatchCalls.length, 2);
    await changes.close();
  });

  test('root can close in a terminal data listener without disposing notifier mid-notification', () async {
    final c = graph.systemPlaylists.open(SystemPlaylistType.queue);
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
    expect(graph.systemPlaylists.retainedSessionCount, 0);
  });

  test(
    'terminal listener may refresh without losing the next registered worker',
    () async {
      final c = graph.systemPlaylists.open(SystemPlaylistType.queue);
      var refreshed = false;
      c.addListener(() {
        if (c.isCurrent && !refreshed) {
          refreshed = true;
          c.refresh();
        }
      });
      c.start();
      await waitForSystem(
        c,
        () => c.isCurrent && repository.systemReadCalls.length == 2,
      );
      expect(repository.systemWatchCalls.length, 2);
      final closing = c.close();
      expect(c.close(), same(closing));
      await closing;
      expect(graph.systemPlaylists.retainedSessionCount, 0);
      final reads = repository.systemReadCalls.length;
      repository.setContentTracks([]);
      await contentTick();
      expect(repository.systemReadCalls.length, reads);
      expect(library.disposeCount, 0); // Session does not own storage/playback.
    },
  );

  test(
    'one closed session cannot cancel another view or dispose the root',
    () async {
      final first = graph.systemPlaylists.open(SystemPlaylistType.queue)
        ..start();
      final second = graph.systemPlaylists.open(SystemPlaylistType.favorites)
        ..start();
      await waitForSystem(first, () => first.isCurrent);
      await waitForSystem(second, () => second.isCurrent);
      await first.close();
      final reads = repository.systemReadCalls.length;
      repository.setContentTracks([]);
      await waitForSystem(second, () => second.isCurrent);
      expect(repository.systemReadCalls.length, reads + 1);
      expect(
        repository.systemReadCalls.last.type,
        SystemPlaylistType.favorites,
      );
      expect(graph.systemPlaylists.retainedSessionCount, 1);
      expect(library.disposeCount, 0);
    },
  );
}
