import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/domain/models/domain_failure.dart';
import 'package:yymusic/domain/models/queue_edit.dart';
import 'package:yymusic/playback/playback_controller.dart';
import 'package:yymusic/playback/queue_controller.dart';
import 'package:yymusic/playback/queue_edit_result.dart';

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
    engine.calls.clear();
    collection.queueWrites.clear();
  });
  tearDown(() async {
    await queue.close();
    await player.close();
    await engine.dispose();
    await collection.dispose();
    await library.dispose();
  });
  Future<QueueEditFailure> fail([QueueEdit? request]) async {
    collection.beforeQueueWrite = (_) async =>
        throw StateError('private-marker');
    final result = await queue.submitEdit(
      request ?? QueueEdit.remove(queue.state, 'a'),
    );
    collection.beforeQueueWrite = null;
    expect(result.status, QueueEditStatus.failed);
    expect(result.failure, same(queue.editFailure));
    return result.failure!;
  }

  Completer<void> gate() {
    final result = Completer<void>();
    addTearDown(() {
      if (!result.isCompleted) result.complete();
    });
    return result;
  }

  test(
    'result constructors distinguish all statuses with no ambiguous failure',
    () {
      expect(const QueueEditResult.applied().status, QueueEditStatus.applied);
      expect(const QueueEditResult.cancelled().failure, isNull);
      expect(const QueueEditResult.busy().failure, isNull);
    },
  );
  test('busy is synchronous and duplicate submission does not perform a second write', () async {
    final request = QueueEdit.remove(queue.state, 'a');
    final first = queue.submitEdit(request);
    expect(queue.editBusy, isTrue);
    expect((await queue.submitEdit(request)).status, QueueEditStatus.busy);
    expect((await first).status, QueueEditStatus.applied);
    expect(queue.editBusy, isFalse);
    expect(queue.editFailure, isNull);
    expect(collection.queueWrites, hasLength(1));
    expect(engine.calls, isEmpty);
  });
  test('stale submission makes no notification or persistence', () async {
    final request = QueueEdit.clear(queue.state);
    await queue.replace(queue.state.entries, currentEntryId: 'b');
    collection.queueWrites.clear();
    var notifications = 0;
    queue.addListener(() => notifications++);
    expect((await queue.submitEdit(request)).status, QueueEditStatus.cancelled);
    expect(notifications, 0);
    expect(collection.queueWrites, isEmpty);
  });
  test('no-op resolves cancelled and is never retained as failure', () async {
    final result = await queue.submitEdit(
      QueueEdit.move(queue.state, 'a', beforeEntryId: 'b'),
    );
    expect(result.status, QueueEditStatus.cancelled);
    expect(result.failure, isNull);
    expect(queue.editBusy, isFalse);
    expect(queue.editFailure, isNull);
    expect(collection.queueWrites, isEmpty);
  });
  test('revoked route returns a normal cancelled result', () async {
    final result = await queue.submitEdit(
      QueueEdit.clear(queue.state),
      canEdit: () => false,
    );
    expect(result.status, QueueEditStatus.cancelled);
    expect(engine.calls, isEmpty);
    expect(collection.queueWrites, isEmpty);
  });
  test(
    'safe retained failure is exactly associated with its result and intent',
    () async {
      final request = QueueEdit.remove(queue.state, 'a');
      final failure = await fail(request);
      expect(failure.edit, same(request));
      expect(failure.failure.code, DomainFailureCode.unknown);
      expect(failure.failure.diagnosticId, 'queue.edit-failed');
      expect(failure.message, isNot(contains('private-marker')));
      expect(failure.failure.toString(), isNot(contains('private-marker')));
      expect(queue.canRetryEdit(failure), isTrue);
      expect(player.state.failure, isNull);
      expect(engine.calls, isEmpty);
    },
  );
  test(
    'failure survives unsubscribing during accepted write and resubscribing',
    () async {
      final entered = Completer<void>(), blocked = gate();
      collection.beforeQueueWrite = (_) async {
        entered.complete();
        await blocked.future;
        throw StateError('private-marker');
      };
      var oldNotifies = 0;
      void oldPage() {
        oldNotifies++;
      }

      queue.addListener(oldPage);
      var active = true;
      final work = queue.submitEdit(
        QueueEdit.remove(queue.state, 'a'),
        canEdit: () => active,
      );
      await entered.future;
      queue.removeListener(oldPage);
      active = false;
      final before = oldNotifies;
      blocked.complete();
      final result = await work;
      expect(oldNotifies, before);
      expect(result.status, QueueEditStatus.failed);
      expect(queue.editFailure, same(result.failure));
      var newNotifies = 0;
      queue.addListener(() => newNotifies++);
      queue.dismissEditFailure(result.failure!);
      expect(newNotifies, 1);
    },
  );
  test(
    'explicit same-snapshot retry clears only its successful failure',
    () async {
      final failure = await fail();
      expect((await queue.retryEdit(failure)).status, QueueEditStatus.applied);
      expect(queue.editFailure, isNull);
      expect(queue.state.entries.map((e) => e.id), ['b', 'c']);
    },
  );
  test(
    'retry failing again has new identity and rejects old callbacks',
    () async {
      final old = await fail();
      collection.beforeQueueWrite = (_) async =>
          throw StateError('private-marker');
      final retry = await queue.retryEdit(old);
      expect(retry.status, QueueEditStatus.failed);
      expect(retry.failure, isNot(same(old)));
      queue.dismissEditFailure(old);
      expect(queue.editFailure, same(retry.failure));
      expect((await queue.retryEdit(old)).status, QueueEditStatus.cancelled);
      expect(queue.canRetryEdit(retry.failure!), isTrue);
    },
  );
  test(
    'unrelated success preserves old failure but makes old retry unavailable',
    () async {
      final failure = await fail();
      expect(
        (await queue.submitEdit(
          QueueEdit.move(queue.state, 'c', beforeEntryId: 'b'),
        )).status,
        QueueEditStatus.applied,
      );
      expect(queue.editFailure, same(failure));
      expect(queue.canRetryEdit(failure), isFalse);
      expect(
        (await queue.retryEdit(failure)).status,
        QueueEditStatus.cancelled,
      );
      queue.dismissEditFailure(failure);
      expect(queue.editFailure, isNull);
    },
  );
  for (final change in ['replacement', 'current']) {
    test(
      '$change invalidates failed confirmation without silently dropping it',
      () async {
        final failure = await fail();
        if (change == 'replacement') {
          await queue.replace(queue.state.entries, currentEntryId: 'b');
        } else {
          await queue.play('a');
        }
        final writes = collection.queueWrites.length;
        expect(queue.canRetryEdit(failure), isFalse);
        expect(
          (await queue.retryEdit(failure)).status,
          QueueEditStatus.cancelled,
        );
        expect(collection.queueWrites.length, writes);
        expect(queue.editFailure, same(failure));
      },
    );
  }
  test(
    'lookalike failure cannot authorize retry or dismiss the retained object',
    () async {
      final original = await fail();
      final lookalike = QueueEditFailure(original.edit, original.failure.code);
      expect(queue.canRetryEdit(lookalike), isFalse);
      queue.dismissEditFailure(lookalike);
      expect(queue.editFailure, same(original));
    },
  );
  test(
    'cancelled retry preserves failure for a future explicit decision',
    () async {
      final failure = await fail();
      expect(
        (await queue.retryEdit(failure, canEdit: () => false)).status,
        QueueEditStatus.cancelled,
      );
      expect(queue.editFailure, same(failure));
      expect(queue.canRetryEdit(failure), isTrue);
    },
  );
  test(
    'dismissing an in-flight retry does not erase its later new failure',
    () async {
      final failure = await fail();
      final entered = Completer<void>(), blocked = gate();
      collection.beforeQueueWrite = (_) async {
        entered.complete();
        await blocked.future;
        throw StateError('private-marker');
      };
      final work = queue.retryEdit(failure);
      await entered.future;
      queue.dismissEditFailure(failure);
      expect(queue.editFailure, isNull);
      blocked.complete();
      final result = await work;
      expect(queue.editFailure, same(result.failure));
      expect(result.failure, isNot(same(failure)));
    },
  );
  test('owner close before worker runs cancels and drains normally', () async {
    final work = queue.submitEdit(QueueEdit.clear(queue.state));
    final close = queue.close();
    expect((await work).status, QueueEditStatus.cancelled);
    await close;
    expect(queue.editBusy, isFalse);
    expect(
      (await queue.submitEdit(QueueEdit.clear(queue.state))).status,
      QueueEditStatus.cancelled,
    );
    expect(engine.calls, isEmpty);
  });
  test('busy notification can synchronously close the owner without abandoning its future', () async {
    Future<void>? closing;
    queue.addListener(() {
      if (queue.editBusy) closing = queue.close();
    });
    expect(
      (await queue.submitEdit(QueueEdit.clear(queue.state))).status,
      QueueEditStatus.cancelled,
    );
    await closing;
    expect(collection.queueWrites, isEmpty);
  });
  test(
    'terminal listener may immediately submit the next independent edit',
    () async {
      Future<QueueEditResult>? next;
      var started = false;
      queue.addListener(() {
        if (!queue.editBusy && !started && queue.state.entries.length == 2) {
          started = true;
          next = queue.submitEdit(QueueEdit.remove(queue.state, 'c'));
        }
      });
      expect(
        (await queue.submitEdit(QueueEdit.remove(queue.state, 'a'))).status,
        QueueEditStatus.applied,
      );
      expect((await next!).status, QueueEditStatus.applied);
      expect(queue.state.entries.single.id, 'b');
      expect(collection.queueWrites, hasLength(2));
    },
  );
  test(
    'terminal failure notification can close without losing the result',
    () async {
      Future<void>? closing;
      queue.addListener(() {
        if (!queue.editBusy && queue.editFailure != null) {
          closing = queue.close();
        }
      });
      final failure = await fail();
      await closing;
      expect(queue.editFailure, same(failure));
      expect(queue.canRetryEdit(failure), isFalse);
    },
  );
  for (final fails in [false, true]) {
    test('accepted write drains through owner close, fails=$fails', () async {
      final entered = Completer<void>(), blocked = gate();
      collection.beforeQueueWrite = (_) async {
        entered.complete();
        await blocked.future;
        if (fails) throw StateError('private-marker');
      };
      final work = queue.submitEdit(QueueEdit.remove(queue.state, 'a'));
      await entered.future;
      var closed = false;
      final closing = queue.close().then((_) => closed = true);
      await Future<void>.delayed(Duration.zero);
      expect(closed, isFalse);
      blocked.complete();
      final result = await work;
      await closing;
      expect(
        result.status,
        fails ? QueueEditStatus.failed : QueueEditStatus.applied,
      );
      expect(queue.editBusy, isFalse);
      expect(collection.queueWrites.length, fails ? 0 : 1);
      await queue.close();
    });
  }
  test('throwing route authorization is captured as safe result not an unobserved future error', () async {
    final result = await queue.submitEdit(
      QueueEdit.clear(queue.state),
      canEdit: () => throw StateError('private-marker'),
    );
    expect(result.status, QueueEditStatus.failed);
    expect(result.failure!.message, isNot(contains('private-marker')));
    expect(engine.calls, isEmpty);
    expect(collection.queueWrites, isEmpty);
  });
}
