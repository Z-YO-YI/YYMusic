import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/domain/models/queue_edit.dart';
import 'package:yymusic/playback/playback_state.dart';
import 'package:yymusic/playback/queue_edit_result.dart';

import '../support/queue_insert_fixture.dart';

void main() {
  late QueueInsertFixture f;
  setUp(() async {
    f = QueueInsertFixture();
    await f.initialize();
  });
  tearDown(() => f.close());
  for (final shuffle in [false, true]) {
    for (final legacy in [false, true]) {
      test(
        'next then append retain explicit priority shuffle=$shuffle legacy=$legacy',
        () async {
          f.player.setShuffleEnabled(shuffle);
          final current = f.player.state.currentTrack;
          for (final id in ['first', 'second']) {
            if (legacy) {
              await f.queue.playNext(f.entry(id));
            } else {
              expect(
                (await f.queue.submitEdit(
                  QueueEdit.playNext(f.queue.state, f.entry(id)),
                )).status,
                QueueEditStatus.applied,
              );
            }
          }
          if (legacy) {
            await f.queue.add(f.entry('tail'));
          } else {
            await f.queue.submitEdit(
              QueueEdit.addToEnd(f.queue.state, f.entry('tail')),
            );
          }
          expect(f.queue.state.entries.map((e) => e.id), [
            'a',
            'b',
            'second',
            'first',
            'c',
            'tail',
          ]);
          expect(f.queue.state.currentEntryId, 'b');
          expect(f.player.state.currentTrack, same(current));
          expect(f.player.state.phase, PlaybackPhase.playing);
          expect(f.engine.calls, isEmpty);
          await f.player.skipNext();
          expect(f.queue.state.currentEntryId, 'second');
          await f.player.skipNext();
          expect(f.queue.state.currentEntryId, 'first');
        },
      );
    }
  }
  test('append keeps existing shuffled successor and visited cursor', () async {
    f.player.setShuffleEnabled(true); // b, c, a with the deterministic random.
    await f.player.skipNext();
    expect(f.queue.state.currentEntryId, 'c');
    await f.queue.submitEdit(
      QueueEdit.addToEnd(f.queue.state, f.entry('tail')),
    );
    await f.player.skipNext();
    expect(f.queue.state.currentEntryId, 'a');
    await f.player.skipNext();
    expect(f.queue.state.currentEntryId, 'tail');
  });
  test(
    'failed next does not replace an earlier explicit shuffled successor',
    () async {
      f.player.setShuffleEnabled(true);
      await f.queue.submitEdit(
        QueueEdit.playNext(f.queue.state, f.entry('first')),
      );
      f.collection.beforeQueueWrite = (_) async =>
          throw StateError('private-marker');
      expect(
        (await f.queue.submitEdit(
          QueueEdit.playNext(f.queue.state, f.entry('failed')),
        )).status,
        QueueEditStatus.failed,
      );
      f.collection.beforeQueueWrite = null;
      await f.player.skipNext();
      expect(f.queue.state.currentEntryId, 'first');
      expect(
        f.queue.state.entries.any((entry) => entry.id == 'failed'),
        isFalse,
      );
    },
  );
  test(
    'turning shuffle on during accepted SQL still prioritizes inserted next',
    () async {
      final entered = Completer<void>(), gate = Completer<void>();
      addTearDown(() {
        if (!gate.isCompleted) gate.complete();
      });
      f.collection.beforeQueueWrite = (_) async {
        entered.complete();
        await gate.future;
      };
      final writing = f.queue.submitEdit(
        QueueEdit.playNext(f.queue.state, f.entry('next')),
      );
      await entered.future;
      f.player.setShuffleEnabled(true);
      gate.complete();
      expect((await writing).status, QueueEditStatus.applied);
      f.collection.beforeQueueWrite = null;
      await f.player.skipNext();
      expect(f.queue.state.currentEntryId, 'next');
    },
  );
  test(
    'no current item uses head insertion and first shuffled successor',
    () async {
      await f.queue.replace(f.queue.state.entries);
      f.player.setShuffleEnabled(true);
      f.engine.calls.clear();
      await f.queue.submitEdit(
        QueueEdit.playNext(f.queue.state, f.entry('next')),
      );
      expect(f.queue.state.currentEntryId, isNull);
      expect(f.queue.state.entries.first.id, 'next');
      expect(f.engine.calls, isEmpty);
      await f.player.skipNext();
      expect(f.queue.state.currentEntryId, 'next');
    },
  );
  for (final repeat in [RepeatMode.off, RepeatMode.all, RepeatMode.one]) {
    test(
      'automatic advance respects repeat=$repeat and explicit shuffled next',
      () async {
        f.player.setShuffleEnabled(true);
        f.player.setRepeatMode(repeat);
        await f.queue.submitEdit(
          QueueEdit.playNext(f.queue.state, f.entry('next')),
        );
        f.engine.complete();
        await f.player
            .pause(); // Drain the earlier automatic advance on the same worker.
        expect(
          f.queue.state.currentEntryId,
          repeat == RepeatMode.one ? 'b' : 'next',
        );
      },
    );
  }
  test('failed insertion keeps queue, playback and random priority; same-ID retry is explicit', () async {
    f.player.setShuffleEnabled(true);
    final old = f.queue.state;
    final request = QueueEdit.playNext(old, f.entry('next'));
    f.collection.beforeQueueWrite = (_) async =>
        throw StateError('private-marker');
    final failed = await f.queue.submitEdit(request);
    expect(failed.status, QueueEditStatus.failed);
    expect(f.queue.state, same(old));
    expect(f.player.state.phase, PlaybackPhase.playing);
    expect(failed.failure!.message, isNot(contains('private-marker')));
    expect(f.engine.calls, isEmpty);
    f.collection.beforeQueueWrite = null;
    expect(
      (await f.queue.retryEdit(failed.failure!)).status,
      QueueEditStatus.applied,
    );
    expect(f.queue.state.entries.where((e) => e.id == 'next'), hasLength(1));
    expect(f.queue.editFailure, isNull);
    await f.player.skipNext();
    expect(f.queue.state.currentEntryId, 'next');
  });
  for (final reason in ['refresh', 'current', 'leave', 'close']) {
    test('insert cancels without write on $reason', () async {
      final request = QueueEdit.playNext(f.queue.state, f.entry('next'));
      switch (reason) {
        case 'refresh':
          await f.queue.replace(f.queue.state.entries, currentEntryId: 'b');
        case 'current':
          await f.queue.play('a');
        case 'leave':
          break;
        case 'close':
          await f.queue.close();
      }
      f.collection.queueWrites.clear();
      f.engine.calls.clear();
      final result = await f.queue.submitEdit(
        request,
        canEdit: () => reason != 'leave',
      );
      expect(result.status, QueueEditStatus.cancelled);
      expect(f.collection.queueWrites, isEmpty);
      expect(f.engine.calls, isEmpty);
    });
  }
  test('duplicate pending insert is busy and accepted storage drains through close', () async {
    final entered = Completer<void>(), gate = Completer<void>();
    addTearDown(() {
      if (!gate.isCompleted) gate.complete();
    });
    f.collection.beforeQueueWrite = (_) async {
      entered.complete();
      await gate.future;
    };
    var allowed = true;
    final request = QueueEdit.addToEnd(f.queue.state, f.entry('tail'));
    final first = f.queue.submitEdit(request, canEdit: () => allowed);
    expect(f.queue.editBusy, isTrue);
    expect((await f.queue.submitEdit(request)).status, QueueEditStatus.busy);
    await entered.future;
    allowed = false;
    var closed = false;
    final closing = f.queue.close().then((_) => closed = true);
    await Future<void>.delayed(Duration.zero);
    expect(closed, isFalse);
    gate.complete();
    expect((await first).status, QueueEditStatus.applied);
    await closing;
    expect(f.collection.queueWrites.single.entries.last.id, 'tail');
  });
  test(
    'empty queue insertion is durable without selecting or starting audio',
    () async {
      await f.queue.clear();
      f.engine.calls.clear();
      await f.queue.submitEdit(
        QueueEdit.playNext(f.queue.state, f.entry('only')),
      );
      expect(f.queue.state.currentEntryId, isNull);
      expect(f.queue.state.entries.single.id, 'only');
      expect(f.engine.calls, isEmpty);
      await f.player.play();
      expect(f.queue.state.currentEntryId, 'only');
    },
  );
}
