import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/domain/models/domain_failure.dart';
import 'package:yymusic/playback/audio_engine_state.dart';
import 'package:yymusic/playback/playback_state.dart';

import '../support/playback_history_probe.dart';
import '../support/playlist_content_probe.dart';

void main() {
  late PlaybackHistoryFixture f;
  setUp(() async {
    f = PlaybackHistoryFixture();
    await f.initialize();
  });
  tearDown(() => f.close());

  test(
    'confirmed clear is ordered after old writes and before later listens',
    () async {
      final gate = Completer<void>();
      addTearDown(() {
        if (!gate.isCompleted) gate.complete();
      });
      f.writeGate = gate.future;
      await f.player.play();
      f.tick(100);
      await contentTick();
      var cleared = false;
      final clear = f.player.history.clear().then((_) => cleared = true);
      await f.player.playEntry('q-1');
      f.tick(200);
      await contentTick();
      expect(cleared, isFalse);
      expect(f.player.state.phase, PlaybackPhase.playing);
      gate.complete();
      await clear;
      await waitHistory(f.player.history);
      expect(
        (await f.collection.watchHistory().first).single.track,
        f.tracks[1].ref,
      );
      expect(f.engine.calls.where((e) => e == 'play'), hasLength(2));
    },
  );

  test('successful clear revokes failed retries and does not re-record the current listen', () async {
    f.writeError = StateError('private-marker');
    await f.player.play();
    f.tick(100);
    await waitHistory(f.player.history);
    final failure = f.player.history.failure!;
    await f.player.history.clear();
    f.writeError = null;
    await f.player.history.retry(failure);
    f.tick(200);
    await contentTick();
    expect(f.player.history.failure, isNull);
    expect(await f.collection.watchHistory().first, isEmpty);
    expect(f.writes, hasLength(1));
  });

  test('clear failure is safe and does not poison subsequent saves', () async {
    await f.player.play();
    f.tick(100);
    await waitHistory(f.player.history);
    f.collection.onHistoryClear = () async {
      throw StateError('private-marker');
    };
    await expectLater(
      f.player.history.clear(),
      throwsA(
        isA<DomainFailure>().having(
          (e) => e.diagnosticId,
          'safe diagnostic',
          'playback.history-clear',
        ),
      ),
    );
    expect(
      (await f.collection.watchHistory().first).single.track,
      f.tracks[0].ref,
    );
    await f.player.playEntry('q-1');
    f.tick(100);
    await waitHistory(f.player.history);
    expect(
      (await f.collection.watchHistory().first).first.track,
      f.tracks[1].ref,
    );
    expect(f.player.state.failure, isNull);
  });

  test(
    'root close also drains an accepted clear and rejects later clears',
    () async {
      final gate = Completer<void>(), entered = Completer<void>();
      addTearDown(() {
        if (!gate.isCompleted) gate.complete();
      });
      f.collection.onHistoryClear = () async {
        entered.complete();
        await gate.future;
      };
      final clear = f.player.history.clear();
      await entered.future;
      var closed = false;
      final close = f.player.close().then((_) => closed = true);
      await contentTick();
      expect(closed, isFalse);
      await expectLater(f.player.history.clear(), throwsStateError);
      gate.complete();
      await clear;
      await close;
      expect(f.player.history.busy, isFalse);
    },
  );

  test('cancelled load and source failure never record history', () async {
    final gate = Completer<void>();
    f.engine.loadGate = gate.future;
    var allowed = true;
    final play = f.player.playEntry('q-0', canPlay: () => allowed);
    await contentTick();
    allowed = false;
    gate.complete();
    await play;
    f.tick(100);
    f.tick(200);
    await contentTick();
    expect(f.writes, isEmpty);
    f.engine.loadGate = null;
    f.engine.loadError = StateError('private-marker');
    await expectLater(f.player.play(), throwsA(isA<DomainFailure>()));
    f.tick(100);
    f.tick(200);
    await contentTick();
    expect(f.writes, isEmpty);
  });

  test(
    'engine error before progress rejects late playing until a fresh load',
    () async {
      await f.player.play();
      f.engine.events.add(
        AudioEngineState(
          phase: AudioEnginePhase.error,
          failure: DomainFailure(
            code: DomainFailureCode.playbackInterrupted,
            diagnosticId: 'test.audio',
          ),
        ),
      );
      f.tick(100);
      f.tick(200);
      await contentTick();
      expect(f.writes, isEmpty);
      await f.player.playEntry('q-0');
      f.tick(100);
      await waitHistory(f.player.history);
      expect(f.writes.length, 1);
    },
  );

  test(
    'write failure does not stop audio and exact latest retry is idempotent',
    () async {
      f.writeError = StateError('private-marker');
      await f.player.play();
      f.tick(100);
      await waitHistory(f.player.history);
      final error = f.player.history.failure!;
      expect(error.toString(), isNot(contains('private-marker')));
      expect(f.player.state.phase, PlaybackPhase.playing);
      expect(f.player.state.failure, isNull);
      expect(f.player.history.canRetry, isTrue);
      expect(await f.collection.watchHistory().first, isEmpty);
      f.writeError = null;
      await f.player.history.retry(error);
      expect(f.writes.length, 2);
      expect(f.writes.last.id, f.writes.first.id);
      expect(f.writes.last.startedAt, f.writes.first.startedAt);
      expect(f.player.history.failure, isNull);
      expect((await f.collection.watchHistory().first).length, 1);
      await f.player.history.retry(error);
      expect(f.writes.length, 2);
    },
  );

  test('an older failure cannot reorder newer listens and stale acknowledgement cannot clear a new error', () async {
    f.writeError = StateError('private-marker');
    await f.player.play();
    f.tick(100);
    await waitHistory(f.player.history);
    final old = f.player.history.failure!;
    f.writeError = null;
    await f.player.playEntry('q-1');
    f.tick(100);
    await waitHistory(f.player.history);
    expect(f.player.history.failure, same(old));
    expect(f.player.history.canRetry, isFalse);
    await f.player.history.retry(old);
    expect(f.writes.length, 2);
    f.writeError = StateError('private-marker');
    await f.player.playEntry('q-0');
    f.tick(100);
    await waitHistory(f.player.history);
    final current = f.player.history.failure!;
    f.player.history.dismissFailure(old);
    expect(f.player.history.failure, same(current));
    f.player.history.dismissFailure(current);
    expect(f.player.history.failure, isNull);
  });

  test('slow writes serialize frozen identities without holding the audio command queue', () async {
    final gate = Completer<void>();
    f.writeGate = gate.future;
    addTearDown(() {
      if (!gate.isCompleted) gate.complete();
    });
    await f.player.play();
    f.tick(100);
    await contentTick();
    await f.player.playEntry('q-1');
    f.tick(200);
    await contentTick();
    expect(f.engine.calls.where((e) => e == 'play').length, 2);
    expect(f.writes.length, 1);
    var closed = false;
    final close = f.player.close().then((_) => closed = true);
    await contentTick();
    expect(closed, isFalse);
    f.tick(300);
    gate.complete();
    await close;
    expect(f.writes.map((e) => e.track), [f.tracks[0].ref, f.tracks[1].ref]);
    expect(f.writes.map((e) => e.lastPosition.inMilliseconds), [100, 200]);
    expect(f.player.history.busy, isFalse);
  });

  test(
    'clock rollback keeps newly confirmed track above persisted history',
    () async {
      await f.player.play();
      f.tick(100);
      await waitHistory(f.player.history);
      f.now = contentEpoch.subtract(const Duration(days: 1));
      await f.player.playEntry('q-1');
      f.tick(100);
      await waitHistory(f.player.history);
      final history = await f.collection.watchHistory().first;
      expect(history.first.track, f.tracks[1].ref);
      expect(
        history.first.startedAt,
        contentEpoch.add(const Duration(milliseconds: 1)),
      );
    },
  );
}
