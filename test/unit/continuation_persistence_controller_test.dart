import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/domain/models/domain_failure.dart';
import 'package:yymusic/playback/continuation_persistence_controller.dart';
import 'package:yymusic/playback/playback_controller.dart';

import '../support/fake_audio_engine.dart';
import '../support/fake_playback_continuation_repository.dart';

Future<void> flushContinuation() async {
  for (var i = 0; i < 12; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late FakeAudioEngine engine;
  late PlaybackController root;
  late FakePlaybackContinuationRepository repo;
  late ContinuationPersistenceController controller;
  setUp(() {
    engine = FakeAudioEngine();
    root = PlaybackController(engine);
    repo = FakePlaybackContinuationRepository();
    controller = ContinuationPersistenceController(
      playback: root,
      repository: repo,
    );
  });
  tearDown(() async {
    repo.writeError = null;
    if (controller.canRetry) controller.retry(controller.failure!);
    await controller.close();
    await root.close();
    await engine.dispose();
    expect(repo.disposals, 0);
  });

  for (final stored in <bool?>[null, false, true]) {
    test('startup restores $stored without writes or audio', () async {
      repo.stored = stored;
      final future = controller.initialize();
      expect(controller.initialize(), same(future));
      await future;
      expect(root.continueAfterTrack, stored ?? true);
      expect(repo.reads, 1);
      expect(repo.writes, isEmpty);
      expect(engine.calls, isEmpty);
      expect(controller.unsaved, isFalse);
    });
  }

  for (final direct in [false, true]) {
    test('late read loses to unchanged default, direct=$direct', () async {
      final gate = Completer<void>();
      repo.readGate = gate.future;
      repo.stored = false;
      final loading = controller.initialize();
      await flushContinuation();
      if (direct) {
        root.setContinueAfterTrack(true);
      } else {
        controller.setEnabled(true);
      }
      gate.complete();
      await loading;
      expect(root.continueAfterTrack, isTrue);
      expect(repo.stored, isTrue);
      expect(repo.writes, [true]);
    });
  }

  test('corrupt record is retained until explicit unchanged choice', () async {
    repo.readError = DomainFailure(
      code: DomainFailureCode.schemaMismatch,
      diagnosticId: 'private-record',
    );
    await controller.initialize();
    final failure = controller.failure!;
    expect(failure.diagnosticId, 'continuation-persistence.load');
    expect(repo.writes, isEmpty);
    controller.setEnabled(true);
    await flushContinuation();
    expect(repo.writes, [true]);
    expect(controller.failure, isNull);
  });

  test(
    'failed load retries without replacing record or starting audio',
    () async {
      repo.readError = StateError('private-marker');
      await controller.initialize();
      final old = controller.failure!;
      controller.retry(old);
      await flushContinuation();
      final current = controller.failure!;
      expect(current, isNot(same(old)));
      controller.retry(old);
      expect(repo.reads, 2);
      repo.readError = null;
      repo.stored = false;
      controller.retry(current);
      await flushContinuation();
      expect(root.continueAfterTrack, isFalse);
      expect(repo.writes, isEmpty);
      expect(engine.calls, isEmpty);
    },
  );

  test('close after damaged read does not overwrite it', () async {
    repo.readError = StateError('bad record');
    await controller.initialize();
    await controller.close();
    expect(repo.writes, isEmpty);
  });

  test('blocked writes serialize and close drains final choice', () async {
    await controller.initialize();
    final gate = Completer<void>();
    repo.writeGate = gate.future;
    controller.setEnabled(false);
    await flushContinuation();
    controller.setEnabled(true);
    var closed = false;
    final closing = controller.close().then((_) => closed = true);
    controller.setEnabled(false);
    await flushContinuation();
    expect(closed, isFalse);
    expect(repo.writes, [false]);
    gate.complete();
    await closing;
    expect(repo.writes, [false, true]);
    expect(repo.stored, isTrue);
  });

  test('save failure is safe and explicit retry saves latest value', () async {
    await controller.initialize();
    repo.writeError = StateError('private-path');
    controller.setEnabled(false);
    await flushContinuation();
    expect(controller.unsaved, isTrue);
    expect(controller.failure!.diagnosticId, 'continuation-persistence.save');
    repo.writeError = null;
    controller.retry(controller.failure!);
    await flushContinuation();
    expect(repo.stored, isFalse);
    expect(controller.unsaved, isFalse);
  });

  test('direct change before initialize is saved without reading', () async {
    root.setContinueAfterTrack(false);
    await controller.initialize();
    await flushContinuation();
    expect(repo.reads, 0);
    expect(repo.stored, isFalse);
  });

  test('close during pending read does not restore or write default', () async {
    final gate = Completer<void>();
    repo.readGate = gate.future;
    repo.stored = false;
    final loading = controller.initialize();
    final closing = controller.close();
    gate.complete();
    await loading;
    await closing;
    expect(root.continueAfterTrack, isTrue);
    expect(repo.writes, isEmpty);
  });

  for (final close in [false, true]) {
    test(
      'user choice during restore notification wins, close=$close',
      () async {
        repo.stored = false;
        root.addListener(() {
          if (!root.continueAfterTrack) {
            root.setContinueAfterTrack(true);
            if (close) controller.dispose();
          }
        });
        await controller.initialize();
        await controller.close();
        expect(root.continueAfterTrack, isTrue);
        expect(repo.stored, isTrue);
        expect(repo.writes, [true]);
      },
    );
  }

  test(
    'close in restore notification alone does not create a user write',
    () async {
      repo.stored = false;
      root.addListener(controller.dispose);
      await controller.initialize();
      await controller.close();
      expect(repo.writes, isEmpty);
    },
  );

  test(
    'nonpersistent scope remains usable and owns neither dependency',
    () async {
      final otherEngine = FakeAudioEngine();
      final otherRoot = PlaybackController(otherEngine);
      final other = ContinuationPersistenceController(playback: otherRoot);
      await other.initialize();
      other.setEnabled(false);
      expect(otherRoot.continueAfterTrack, isFalse);
      expect(other.unsaved, isFalse);
      await other.close();
      await otherRoot.close();
      await otherEngine.dispose();
    },
  );
  test('close reports an unsaved write and stays idempotent', () async {
    final otherEngine = FakeAudioEngine();
    final otherRoot = PlaybackController(otherEngine);
    final otherRepo = FakePlaybackContinuationRepository()
      ..writeError = StateError('private-write-error');
    final other = ContinuationPersistenceController(
      playback: otherRoot,
      repository: otherRepo,
    );
    other.setEnabled(false);
    await flushContinuation();
    final closing = other.close();
    expect(other.close(), same(closing));
    await expectLater(closing, throwsA(isA<DomainFailure>()));
    other.setEnabled(true);
    expect(otherRepo.writes, [false]);
    await otherRoot.close();
    await otherEngine.dispose();
  });

  test(
    'close during read freezes accepted intent before later root changes',
    () async {
      final gate = Completer<void>();
      repo.readGate = gate.future;
      final loading = controller.initialize();
      controller.setEnabled(false);
      final closing = controller.close();
      root.setContinueAfterTrack(true);
      gate.complete();
      await loading;
      await closing;
      expect(repo.stored, isFalse);
      expect(repo.writes, [false]);
    },
  );

  test(
    'ordinary playback updates do not generate storage notifications',
    () async {
      await controller.initialize();
      var notifications = 0;
      controller.addListener(() => notifications++);
      await root.setVolume(0.4);
      expect(notifications, 0);
      expect(repo.writes, isEmpty);
    },
  );
}
