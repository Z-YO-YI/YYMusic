import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/domain/models/domain_failure.dart';
import 'package:yymusic/domain/models/queue_edit.dart';
import 'package:yymusic/playback/playback_controller.dart';
import 'package:yymusic/playback/playback_state.dart';
import 'package:yymusic/playback/queue_controller.dart';

import '../support/fake_audio_engine.dart';
import '../support/fake_domain_repositories.dart';
import '../support/fake_playback_dependencies.dart';
import 'queue_edit_test.dart' show queueEditEpoch;

void main() {
  late FakeAudioEngine engine;
  late FakeCollectionRepository collection;
  late FakeLibraryRepository library;
  late PlaybackController player;
  late QueueController queue;
  setUp(() async {
    engine = FakeAudioEngine();
    collection = FakeCollectionRepository();
    library = FakeLibraryRepository(tracks: [playbackFixtureTrack]);
    player = PlaybackController(
      engine,
      collection: collection,
      library: library,
      sourceResolver: FakePlaybackSourceResolver(),
      clock: () => queueEditEpoch,
      randomIndex: (_) => 0,
    );
    queue = QueueController(player);
    await player.initialize();
    await queue.replace([
      for (var i = 0; i < 3; i++)
        QueueEntry(
          id: ['a', 'b', 'c'][i],
          track: playbackFixtureTrack.ref,
          position: i,
          addedAt: queueEditEpoch,
        ),
    ], currentEntryId: 'b');
    await queue.play('b');
    collection.queueWrites.clear();
    engine.calls.clear();
  });
  tearDown(() async {
    queue.dispose();
    await player.close();
    await engine.dispose();
    await collection.dispose();
    await library.dispose();
  });
  test(
    'reorder saves once without stopping loading or resetting current playback',
    () async {
      player.setShuffleEnabled(true);
      player.setRepeatMode(RepeatMode.all);
      final current = player.state.currentTrack;
      expect(await queue.edit(QueueEdit.move(queue.state, 'a')), isTrue);
      expect(queue.state.entries.map((e) => e.id), ['b', 'c', 'a']);
      expect(queue.state, same(player.state.queue));
      expect(collection.queueWrites.single, same(queue.state));
      expect(player.state.currentTrack, same(current));
      expect(player.state.phase, PlaybackPhase.playing);
      expect(player.state.shuffleEnabled, isTrue);
      expect(player.state.repeatMode, RepeatMode.all);
      expect(engine.calls, isEmpty);
      await player.skipNext();
      expect(queue.state.currentEntryId, isNot('b'));
    },
  );
  test(
    'remove exact duplicate does not remove other instances or stop audio',
    () async {
      expect(await queue.edit(QueueEdit.remove(queue.state, 'a')), isTrue);
      expect(queue.state.entries.map((e) => e.id), ['b', 'c']);
      expect(queue.state.currentEntryId, 'b');
      expect(engine.calls, isEmpty);
    },
  );
  for (final clear in [false, true]) {
    test(
      'current removal clear=$clear stops once without autoplaying neighbor',
      () async {
        final request = clear
            ? QueueEdit.clear(queue.state)
            : QueueEdit.remove(queue.state, 'b');
        expect(await queue.edit(request), isTrue);
        expect(engine.calls, ['stop']);
        expect(queue.state.currentEntryId, clear ? null : 'c');
        expect(player.state.currentTrack, isNull);
        expect(player.state.phase, PlaybackPhase.idle);
      },
    );
  }
  test(
    'same timestamp and value replacement still invalidates an old request',
    () async {
      final stale = QueueEdit.clear(queue.state);
      await queue.replace(queue.state.entries, currentEntryId: 'b');
      collection.queueWrites.clear();
      expect(await queue.edit(stale), isFalse);
      expect(queue.state.entries.length, 3);
      expect(collection.queueWrites, isEmpty);
      expect(engine.calls, isEmpty);
    },
  );
  test('a different current entry also invalidates confirmation', () async {
    final stale = QueueEdit.clear(queue.state);
    await queue.play('a');
    collection.queueWrites.clear();
    engine.calls.clear();
    expect(await queue.edit(stale), isFalse);
    expect(queue.state.currentEntryId, 'a');
    expect(collection.queueWrites, isEmpty);
    expect(engine.calls, isEmpty);
  });
  test('queued competing edits accept only one captured snapshot', () async {
    final snapshot = queue.state;
    final moved = queue.edit(QueueEdit.move(snapshot, 'a'));
    final removed = queue.edit(QueueEdit.remove(snapshot, 'c'));
    expect(await moved, isTrue);
    expect(await removed, isFalse);
    expect(collection.queueWrites, hasLength(1));
    expect(queue.state.entries.length, 3);
  });
  for (final action in ['leave', 'facade', 'root']) {
    test('queued edit revoked by $action has no durable mutation', () async {
      final paused = Completer<void>();
      addTearDown(() {
        if (!paused.isCompleted) paused.complete();
      });
      engine.pauseGate = paused.future;
      final pause = player.pause();
      final request = QueueEdit.clear(queue.state);
      var allowed = true;
      final editing = queue.edit(request, canEdit: () => allowed);
      await Future<void>.delayed(Duration.zero);
      Future<void>? closing;
      switch (action) {
        case 'leave':
          allowed = false;
        case 'facade':
          queue.dispose();
        case 'root':
          closing = player.close();
      }
      paused.complete();
      await pause;
      expect(await editing, isFalse);
      await closing;
      expect(collection.queueWrites, isEmpty);
      expect(engine.calls, ['pause']);
    });
  }
  test(
    'revocation after accepted stop prevents SQL but does not restart music',
    () async {
      var allowed = true;
      player.addListener(() {
        if (player.state.phase == PlaybackPhase.idle) allowed = false;
      });
      final snapshot = queue.state;
      expect(
        await queue.edit(QueueEdit.clear(snapshot), canEdit: () => allowed),
        isFalse,
      );
      expect(queue.state, same(snapshot));
      expect(collection.queueWrites, isEmpty);
      expect(engine.calls, ['stop']);
    },
  );
  test(
    'SQL accepted before leaving is applied rather than rolled back',
    () async {
      final entered = Completer<void>();
      final gate = Completer<void>();
      addTearDown(() {
        if (!gate.isCompleted) gate.complete();
      });
      collection.beforeQueueWrite = (_) async {
        entered.complete();
        await gate.future;
      };
      var allowed = true;
      final snapshot = queue.state;
      final editing = queue.edit(
        QueueEdit.remove(snapshot, 'a'),
        canEdit: () => allowed,
      );
      await entered.future;
      allowed = false;
      expect(queue.state, same(snapshot));
      gate.complete();
      expect(await editing, isTrue);
      expect(queue.state.entries.map((e) => e.id), ['b', 'c']);
      expect(collection.queueWrites.single, same(queue.state));
    },
  );
  test(
    'write error is safe and retryable without corrupting active audio state',
    () async {
      collection.beforeQueueWrite = (_) async =>
          throw StateError('private diagnostic');
      final snapshot = queue.state;
      final request = QueueEdit.remove(snapshot, 'a');
      await expectLater(
        queue.edit(request),
        throwsA(
          isA<DomainFailure>()
              .having((e) => e.diagnosticId, 'safe ID', 'queue.edit-failed')
              .having((e) => e.retryable, 'retryable', isTrue)
              .having(
                (e) => e.toString(),
                'no raw error',
                isNot(contains('private')),
              ),
        ),
      );
      expect(queue.state, same(snapshot));
      expect(player.state.phase, PlaybackPhase.playing);
      expect(player.state.failure, isNull);
      expect(engine.calls, isEmpty);
      collection.beforeQueueWrite = null;
      expect(await queue.edit(request), isTrue);
    },
  );
  test(
    'save failure after stop retains old queue and does not autoplay',
    () async {
      collection.beforeQueueWrite = (_) async =>
          throw StateError('private diagnostic');
      final snapshot = queue.state;
      await expectLater(
        queue.edit(QueueEdit.clear(snapshot)),
        throwsA(isA<DomainFailure>()),
      );
      expect(queue.state, same(snapshot));
      expect(engine.calls, ['stop']);
      expect(player.state.phase, PlaybackPhase.idle);
      expect(collection.queueWrites, isEmpty);
    },
  );
  test('stop failure prevents saving and returns safe edit failure', () async {
    engine.stopError = StateError('private diagnostic');
    final snapshot = queue.state;
    await expectLater(
      queue.edit(QueueEdit.clear(snapshot)),
      throwsA(isA<DomainFailure>()),
    );
    expect(queue.state, same(snapshot));
    expect(collection.queueWrites, isEmpty);
    expect(engine.calls, ['stop']);
  });
  test('no-op and already-disposed facade make no writes', () async {
    expect(
      await queue.edit(QueueEdit.move(queue.state, 'a', beforeEntryId: 'b')),
      isFalse,
    );
    queue.dispose();
    expect(await queue.edit(QueueEdit.clear(queue.state)), isFalse);
    expect(engine.calls, isEmpty);
    expect(collection.queueWrites, isEmpty);
  });
  test(
    'queue listener can close root and facade during commit notification',
    () async {
      Future<void>? closing;
      queue.addListener(() {
        queue.dispose();
        closing = player.close();
      });
      expect(await queue.edit(QueueEdit.remove(queue.state, 'a')), isTrue);
      await closing;
      expect(collection.queueWrites.single.entries.map((e) => e.id), [
        'b',
        'c',
      ]);
      expect(await queue.edit(QueueEdit.clear(queue.state)), isFalse);
    },
  );
  test(
    'closing from an authorization callback cancels before any mutation',
    () async {
      Future<void>? closing;
      expect(
        await queue.edit(
          QueueEdit.clear(queue.state),
          canEdit: () {
            closing = player.close();
            return true;
          },
        ),
        isFalse,
      );
      await closing;
      expect(collection.queueWrites, isEmpty);
      expect(engine.calls, isEmpty);
    },
  );
  test('root close waits for accepted persistence and is idempotent', () async {
    final entered = Completer<void>();
    final gate = Completer<void>();
    addTearDown(() {
      if (!gate.isCompleted) gate.complete();
    });
    collection.beforeQueueWrite = (_) async {
      entered.complete();
      await gate.future;
    };
    final editing = queue.edit(QueueEdit.remove(queue.state, 'a'));
    await entered.future;
    var closed = false;
    final closing = player.close().then((_) => closed = true);
    await Future<void>.delayed(Duration.zero);
    expect(closed, isFalse);
    gate.complete();
    expect(await editing, isTrue);
    await closing;
    expect(closed, isTrue);
    expect((await collection.loadQueue()).entries.map((e) => e.id), ['b', 'c']);
    await player.close();
  });
}
