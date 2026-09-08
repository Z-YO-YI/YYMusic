import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/domain/models/domain_failure.dart';
import 'package:yymusic/domain/models/load_state.dart';
import 'package:yymusic/domain/models/pagination.dart';
import 'package:yymusic/features/local_music/common/local_music_controller.dart';

import '../support/local_music_probe.dart';

Future<void> flushLocal() => pumpEventQueue(times: 30);

void main() {
  late LocalMusicProbe probe;
  late LocalMusicController controller;
  setUp(() {
    probe = LocalMusicProbe();
    controller = LocalMusicController(repository: probe);
  });
  tearDown(() async {
    await controller.close();
    await probe.close();
  });
  Future<void> activate() async {
    controller.start();
    controller.setActive(true);
    await flushLocal();
  }

  test('idle construction and hidden start perform no work; active empty is real data', () async {
    controller.start();
    await flushLocal();
    expect(probe.calls, isEmpty);
    expect(controller.phase, LoadPhase.idle);
    controller.setActive(true);
    await flushLocal();
    expect(probe.watchCount, 1);
    expect(probe.calls.single.page.limit, 20);
    expect(controller.phase, LoadPhase.empty);
    expect(controller.content!.folderCount, 0);
    controller.start();
    controller.setActive(true);
    await flushLocal();
    expect(probe.calls, hasLength(1));
  });

  test('same snapshot paging rejects duplicate and stale callbacks and preserves root data', () async {
    probe.data.folders.addAll(List.generate(45, localFolder));
    await activate();
    final first = controller.content!;
    controller.next(first);
    controller.next(first);
    await flushLocal();
    expect(controller.content!.page.offset, 20);
    controller.next(first);
    expect(probe.calls, hasLength(2));
    controller.next(controller.content!);
    await flushLocal();
    expect(controller.content!.folders, hasLength(5));
    expect(controller.canNext, isFalse);
    controller.previous(controller.content!);
    await flushLocal();
    expect(controller.content!.page.offset, 20);
  });

  test('last-page deletion returns to a valid page and zero folders returns to zero', () async {
    probe.data.folders.addAll(List.generate(21, localFolder));
    await activate();
    controller.next(controller.content!);
    await flushLocal();
    probe.data.folders.removeLast();
    probe.changes.add(null);
    await flushLocal();
    expect(controller.content!.page.offset, 0);
    expect(controller.content!.folders, hasLength(20));
    probe.data.folders.clear();
    probe.changes.add(null);
    await flushLocal();
    expect(controller.phase, LoadPhase.empty);
  });

  test('hidden state cancels pending read, rejects actions and refreshes on return', () async {
    final gate = Completer<void>();
    probe.onRead = (page, token) async {
      await gate.future;
      return probe.data.readLocalOverview(page);
    };
    await activate();
    expect(controller.phase, LoadPhase.loading);
    controller.setActive(false);
    expect(probe.calls.single.token!.isCancelled, isTrue);
    controller.refresh();
    probe.changes.add(null);
    gate.complete();
    await flushLocal();
    expect(probe.calls, hasLength(1));
    expect(controller.content, isNull);
    controller.setActive(true);
    await flushLocal();
    expect(probe.calls, hasLength(2));
    expect(controller.phase, LoadPhase.empty);
  });

  test('rapid invalidations coalesce behind one read and discard obsolete response', () async {
    final gate = Completer<void>();
    var concurrent = 0, maximum = 0;
    probe.onRead = (page, token) async {
      concurrent++;
      if (concurrent > maximum) maximum = concurrent;
      if (probe.calls.length == 1) await gate.future;
      concurrent--;
      return probe.data.readLocalOverview(page);
    };
    await activate();
    for (var i = 0; i < 30; i++) {
      probe.changes.add(null);
    }
    await flushLocal();
    expect(probe.calls, hasLength(1));
    gate.complete();
    await flushLocal();
    expect(probe.calls, hasLength(2));
    expect(maximum, 1);
    expect(controller.isCurrent, isTrue);
  });

  test(
    'read failure retains old content as stale and retry clears safe failure',
    () async {
      probe.data.folders.add(localFolder(1));
      await activate();
      final old = controller.content;
      probe.onRead = (_, _) async => throw StateError('private-marker');
      controller.refresh();
      await flushLocal();
      expect(controller.phase, LoadPhase.error);
      expect(controller.content, same(old));
      expect(controller.isCurrent, isFalse);
      expect(controller.failure.toString(), isNot(contains('private-marker')));
      probe.onRead = null;
      controller.refresh();
      await flushLocal();
      expect(controller.failure, isNull);
      expect(controller.isCurrent, isTrue);
    },
  );

  for (final done in [false, true]) {
    test(
      'watch ${done ? 'completion' : 'error'} blocks stale results until reconnect',
      () async {
        final failed = StreamController<void>();
        probe.onWatch = () => failed.stream;
        await activate();
        if (done) {
          await failed.close();
        } else {
          failed.addError(StateError('private-marker'));
        }
        await flushLocal();
        expect(controller.phase, LoadPhase.error);
        expect(controller.isCurrent, isFalse);
        probe.onWatch = null;
        controller.refresh();
        await flushLocal();
        expect(controller.phase, LoadPhase.empty);
        if (!done) await failed.close();
      },
    );
  }

  test('missing repository shows failure not zero statistics', () async {
    final unavailable = LocalMusicController();
    addTearDown(unavailable.close);
    unavailable.start();
    unavailable.setActive(true);
    await flushLocal();
    expect(unavailable.phase, LoadPhase.error);
    expect(unavailable.content, isNull);
  });

  test(
    'mismatched pagination is a schema error and never replaces data',
    () async {
      probe.onRead = (_, _) =>
          probe.data.readLocalOverview(PageRequest(limit: 1));
      await activate();
      expect(controller.phase, LoadPhase.error);
      expect(controller.failure!.code, DomainFailureCode.schemaMismatch);
      expect(controller.content, isNull);
    },
  );

  test('root close drains a delayed read and is idempotent', () async {
    final gate = Completer<void>();
    probe.onRead = (page, _) async {
      await gate.future;
      return probe.data.readLocalOverview(page);
    };
    await activate();
    var closed = false;
    final closing = controller.close().then((_) => closed = true);
    expect(controller.close(), same(controller.close()));
    await flushLocal();
    expect(closed, isFalse);
    gate.complete();
    await closing;
    expect(controller.content, isNull);
    controller.refresh();
    controller.setActive(true);
    expect(probe.calls, hasLength(1));
  });

  test(
    'close inside watch getter drains subsequently returned subscription',
    () async {
      final gate = Completer<void>();
      var cancelled = false;
      final stream = StreamController<void>(
        onCancel: () async {
          await gate.future;
          cancelled = true;
        },
      );
      Future<void>? closing;
      probe.onWatch = () {
        closing = controller.close();
        return stream.stream;
      };
      controller.start();
      controller.setActive(true);
      await flushLocal();
      expect(closing, isNotNull);
      expect(cancelled, isFalse);
      expect(probe.calls, isEmpty);
      gate.complete();
      await closing;
      expect(cancelled, isTrue);
      await stream.close();
    },
  );

  test(
    'close during listener notification is safe and prevents new work',
    () async {
      Future<void>? closing;
      controller.addListener(() {
        if (controller.isCurrent) closing = controller.close();
      });
      await activate();
      await closing;
      expect(controller.canRefresh, isFalse);
      expect(probe.calls, hasLength(1));
    },
  );
}
