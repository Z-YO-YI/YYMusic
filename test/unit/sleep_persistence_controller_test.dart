import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/domain/models/domain_failure.dart';
import 'package:yymusic/domain/models/sleep_timer_snapshot.dart';
import 'package:yymusic/playback/playback_controller.dart';
import 'package:yymusic/playback/playback_sleep_timer_state.dart';
import 'package:yymusic/playback/sleep_persistence_controller.dart';

import '../support/fake_audio_engine.dart';
import '../support/fake_domain_repositories.dart';
import '../support/fake_playback_dependencies.dart';
import '../support/fake_sleep_timer_repository.dart';

Future<void> flushSleepPersistence() async {
  for (var i = 0; i < 16; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late DateTime now;
  late PlaybackController root;
  late FakeAudioEngine engine;
  late FakeLibraryRepository library;
  late FakeSleepTimerRepository repo;
  late SleepPersistenceController persistence;
  late List<void Function()> wakes;
  var expectedCloseFailure = false;
  setUp(() {
    now = DateTime.utc(2026, 9, 13);
    expectedCloseFailure = false;
    wakes = [];
    engine = FakeAudioEngine();
    library = FakeLibraryRepository(tracks: [playbackFixtureTrack]);
    repo = FakeSleepTimerRepository();
    root = PlaybackController(
      engine,
      library: library,
      sourceResolver: FakePlaybackSourceResolver(),
      clock: () => now,
      sleepScheduler: (_, callback) {
        wakes.add(callback);
        return _SleepWake();
      },
    );
    persistence = SleepPersistenceController(playback: root, repository: repo);
  });
  tearDown(() async {
    repo.readError = null;
    repo.writeError = null;
    repo.onWrite = null;
    if (persistence.canRetry) {
      persistence.retry(persistence.failure!);
      await flushSleepPersistence();
    }
    if (expectedCloseFailure) {
      await expectLater(persistence.close(), throwsA(isA<DomainFailure>()));
    } else {
      await persistence.close();
    }
    await root.close();
    await engine.dispose();
    await library.dispose();
    await repo.dispose();
  });
  SleepTimerSnapshot stored() => SleepTimerSnapshot(
    durationMinutes: 30,
    deadline: now.add(const Duration(minutes: 12)),
  );

  test(
    'restore keeps original deadline and selection without writes or autoplay',
    () async {
      repo.stored = stored();
      final value = repo.stored!;
      await persistence.initialize();
      expect(root.sleepTimer.deadline, value.deadline);
      expect(root.sleepTimer.duration, PlaybackSleepDuration.thirty);
      expect(root.sleepRemaining, const Duration(minutes: 12));
      expect(repo.writes, isEmpty);
      expect(engine.calls, isEmpty);
      expect(persistence.unsaved, isFalse);
    },
  );
  test(
    'initialization is idempotent and missing read does not clear',
    () async {
      final first = persistence.initialize();
      expect(persistence.initialize(), same(first));
      await first;
      expect(repo.reads, 1);
      expect(repo.writes, isEmpty);
    },
  );
  test(
    'ordinary playback notifications do not overwrite pending restore',
    () async {
      repo.stored = stored();
      final gate = Completer<void>();
      repo.readGate = gate.future;
      final loading = persistence.initialize();
      try {
        await flushSleepPersistence();
        await root.replaceQueue([playbackFixtureEntry()]);
        await root.play();
        expect(repo.writes, isEmpty);
        gate.complete();
        await loading;
        expect(root.sleepTimer.duration, PlaybackSleepDuration.thirty);
        expect(repo.writes, isEmpty);
      } finally {
        if (!gate.isCompleted) gate.complete();
      }
    },
  );
  for (final change in ['cancel', 'new', 'new-cancel']) {
    test('user $change beats delayed stored read', () async {
      repo.stored = stored();
      final gate = Completer<void>();
      repo.readGate = gate.future;
      final loading = persistence.initialize();
      try {
        await flushSleepPersistence();
        if (change != 'cancel') root.setSleepTimer(PlaybackSleepDuration.sixty);
        if (change != 'new') root.setSleepTimer(null);
        final latest = root.sleepTimer;
        gate.complete();
        await loading;
        expect(root.sleepTimer, same(latest));
        expect(repo.stored?.durationMinutes, change == 'new' ? 60 : null);
        expect(engine.calls, isEmpty);
      } finally {
        if (!gate.isCompleted) gate.complete();
      }
    });
  }
  test('user change before initialize skips obsolete load', () async {
    repo.stored = stored();
    root.setSleepTimer(PlaybackSleepDuration.fifteen);
    await persistence.initialize();
    await flushSleepPersistence();
    expect(repo.reads, 0);
    expect(repo.stored!.durationMinutes, 15);
  });
  test('expired record is cleared without pause or a new deadline', () async {
    repo.stored = SleepTimerSnapshot(durationMinutes: 15, deadline: now);
    await persistence.initialize();
    expect(root.sleepTimer.phase, PlaybackSleepPhase.off);
    expect(repo.stored, isNull);
    expect(repo.writes, [null]);
    expect(engine.calls, isEmpty);
  });
  test('invalid schema is explicitly cleared but I/O failure is not', () async {
    repo.stored = stored();
    repo.readError = DomainFailure(
      code: DomainFailureCode.schemaMismatch,
      diagnosticId: 'test.invalid',
    );
    await persistence.initialize();
    expect(repo.stored, isNull);
    expect(repo.writes, [null]);
  });
  test(
    'load failure retains record and retry restores without autoplay',
    () async {
      repo.stored = stored();
      repo.readError = StateError('private-marker');
      await persistence.initialize();
      final failure = persistence.failure!;
      expect(failure.toString(), isNot(contains('private-marker')));
      expect(repo.writes, isEmpty);
      repo.readError = null;
      persistence.retry(failure);
      await flushSleepPersistence();
      expect(persistence.failure, isNull);
      expect(root.sleepTimer.duration, PlaybackSleepDuration.thirty);
      expect(engine.calls, isEmpty);
      persistence.retry(failure);
      await flushSleepPersistence();
      expect(repo.reads, 2);
    },
  );
  test(
    'read failure after user cancel still attempts explicit clear',
    () async {
      repo.stored = stored();
      repo.readError = StateError('private-marker');
      final gate = Completer<void>();
      repo.readGate = gate.future;
      final loading = persistence.initialize();
      try {
        await flushSleepPersistence();
        root.setSleepTimer(null);
        gate.complete();
        await loading;
        expect(repo.stored, isNull);
        expect(persistence.failure, isNull);
      } finally {
        if (!gate.isCompleted) gate.complete();
      }
    },
  );
  test(
    'save failure retains live intent and retry writes latest snapshot',
    () async {
      await persistence.initialize();
      repo.writeError = StateError('private-marker');
      root.setSleepTimer(PlaybackSleepDuration.fifteen);
      await flushSleepPersistence();
      final error = persistence.failure!;
      expect(root.sleepTimer.phase, PlaybackSleepPhase.armed);
      expect(persistence.unsaved, isTrue);
      repo.writeError = null;
      persistence.retry(error);
      await flushSleepPersistence();
      expect(repo.stored!.durationMinutes, 15);
      expect(persistence.unsaved, isFalse);
    },
  );
  test(
    'latest accepted clear follows delayed save even during close',
    () async {
      await persistence.initialize();
      final gate = Completer<void>();
      repo.writeGate = gate.future;
      try {
        root.setSleepTimer(PlaybackSleepDuration.fifteen);
        await flushSleepPersistence();
        root.setSleepTimer(null);
        var closed = false;
        final closing = persistence.close().then((_) => closed = true);
        await flushSleepPersistence();
        expect(closed, isFalse);
        gate.complete();
        await closing;
        expect(repo.stored, isNull);
        expect(repo.writes.map((v) => v?.durationMinutes), [15, null]);
      } finally {
        if (!gate.isCompleted) gate.complete();
      }
    },
  );
  test('older write failure cannot hide newer accepted intent', () async {
    await persistence.initialize();
    final gate = Completer<void>();
    var first = true;
    repo.onWrite = (_) async {
      if (first) {
        first = false;
        await gate.future;
        throw StateError('private-marker');
      }
    };
    try {
      root.setSleepTimer(PlaybackSleepDuration.fifteen);
      await flushSleepPersistence();
      root.setSleepTimer(PlaybackSleepDuration.sixty);
      gate.complete();
      await flushSleepPersistence();
      expect(repo.stored!.durationMinutes, 60);
      expect(persistence.failure, isNull);
    } finally {
      if (!gate.isCompleted) gate.complete();
    }
  });
  test('off cancellation retries a previously failed clear', () async {
    repo.stored = stored();
    await persistence.initialize();
    repo.writeError = StateError('private-marker');
    root.setSleepTimer(null);
    await flushSleepPersistence();
    expect(persistence.failure, isNotNull);
    repo.writeError = null;
    root.setSleepTimer(null);
    await flushSleepPersistence();
    expect(repo.stored, isNull);
    expect(persistence.failure, isNull);
  });
  test(
    'close during unchanged load preserves storage and never arms root',
    () async {
      repo.stored = stored();
      final original = repo.stored;
      final gate = Completer<void>();
      repo.readGate = gate.future;
      final loading = persistence.initialize();
      try {
        await flushSleepPersistence();
        final closing = persistence.close();
        await root.close();
        gate.complete();
        await loading;
        await closing;
        expect(repo.stored, original);
        expect(repo.writes, isEmpty);
      } finally {
        if (!gate.isCompleted) gate.complete();
      }
    },
  );
  test(
    'freezing persistence before root shutdown retains live minute timer',
    () async {
      await persistence.initialize();
      root.setSleepTimer(PlaybackSleepDuration.thirty);
      final original = root.sleepTimer.deadline;
      persistence.dispose();
      await root.close();
      await persistence.close();
      expect(repo.stored!.deadline, original);
      expect(repo.writes, hasLength(1));
    },
  );
  test('failed final save is observable on close', () async {
    await persistence.initialize();
    repo.writeError = StateError('private-marker');
    root.setSleepTimer(PlaybackSleepDuration.fifteen);
    await flushSleepPersistence();
    expectedCloseFailure = true;
    await expectLater(persistence.close(), throwsA(isA<DomainFailure>()));
  });
  test('actual restored deadline clears storage after pausing once', () async {
    await root.replaceQueue([playbackFixtureEntry()]);
    await root.play();
    engine.calls.clear();
    repo.stored = stored();
    await persistence.initialize();
    now = root.sleepTimer.deadline!;
    wakes.single();
    await flushSleepPersistence();
    expect(root.sleepTimer.phase, PlaybackSleepPhase.expired);
    expect(repo.stored, isNull);
    expect(engine.calls, ['pause']);
  });
  for (final cancel in [false, true]) {
    test(
      'close reentered during restore preserves ${cancel ? 'cancel' : 'stored intent'}',
      () async {
        repo.stored = stored();
        final original = repo.stored;
        var once = true;
        root.addListener(() {
          if (!once || root.sleepTimer.phase != PlaybackSleepPhase.armed) {
            return;
          }
          once = false;
          if (cancel) root.setSleepTimer(null);
          persistence.dispose();
          root.dispose();
        });
        await persistence.initialize();
        await persistence.close();
        expect(repo.stored, cancel ? isNull : original);
        expect(repo.writes, cancel ? [null] : isEmpty);
      },
    );
  }
  test('entry-end intent removes obsolete minute record', () async {
    await root.replaceQueue([playbackFixtureEntry()]);
    await root.play();
    repo.stored = stored();
    await persistence.initialize();
    expect(root.setSleepAtCurrentEntryEnd(), isTrue);
    await flushSleepPersistence();
    expect(repo.stored, isNull);
    expect(root.sleepTimer.entryId, isNotNull);
  });
}

final class _SleepWake implements Timer {
  @override
  bool isActive = true;
  @override
  int get tick => 0;
  @override
  void cancel() => isActive = false;
}
