import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/domain/models/domain_failure.dart';
import 'package:yymusic/domain/models/load_state.dart';
import 'package:yymusic/domain/models/lyrics.dart';
import 'package:yymusic/playback/audio_engine_state.dart';
import 'package:yymusic/playback/lyrics_controller.dart';

import '../support/lyrics_fixture.dart';

void main() {
  late LyricsFixture fixture;
  late LyricsController controller;
  setUp(() async {
    fixture = LyricsFixture();
    controller = fixture.graph.lyricsController;
    await fixture.initialize();
  });
  tearDown(() => fixture.graph.close());

  Future<void> activate() async {
    controller.setActive(true);
    await flushLyrics();
  }

  void tick(int seconds, {AudioEnginePhase phase = AudioEnginePhase.playing}) {
    fixture.engine.events.add(
      AudioEngineState(
        phase: phase,
        position: Duration(seconds: seconds),
        duration: const Duration(minutes: 3),
      ),
    );
  }

  test(
    'root construction and background playback do not fetch lyrics',
    () async {
      tick(15);
      await fixture.graph.playback.playEntry('entry-1');
      expect(controller.isActive, isFalse);
      expect(controller.state.phase, LoadPhase.idle);
      expect(fixture.repository.reads, isEmpty);
    },
  );

  test(
    'an active route without a current track stays idle without a read',
    () async {
      await fixture.graph.queue.replace([]);
      await activate();
      expect(controller.state.phase, LoadPhase.idle);
      expect(fixture.repository.reads, isEmpty);
      await fixture.graph.queue.replace(
        lyricsEntries(),
        currentEntryId: 'entry-0',
      );
      expect(fixture.repository.reads, isEmpty);
      await fixture.graph.playback.play();
      await flushLyrics();
      expect(controller.state.phase, LoadPhase.data);
      await fixture.graph.queue.replace([]);
      expect(controller.state.phase, LoadPhase.idle);
      expect(controller.activeIndex, isNull);
    },
  );

  test(
    'refresh reentered from a data notification uses the same single worker',
    () async {
      var refreshed = false;
      controller.addListener(() {
        if (!refreshed && controller.state.phase == LoadPhase.data) {
          refreshed = true;
          controller.refresh();
        }
      });
      await activate();
      expect(fixture.repository.reads, hasLength(2));
      expect(fixture.repository.maximumInFlight, 1);
      expect(controller.state.phase, LoadPhase.data);
    },
  );

  test('raw read exceptions produce only a fixed diagnostic', () async {
    fixture.repository.onGet = (_) async => throw StateError('private-marker');
    await activate();
    expect(controller.state.failure!.code, DomainFailureCode.unknown);
    expect(controller.state.failure!.diagnosticId, 'lyrics.load');
    expect(
      controller.state.failure.toString(),
      isNot(contains('private-marker')),
    );
  });

  test(
    'loading is explicit and data uses latest root position, without reread',
    () async {
      final gate = Completer<LyricsDocument?>();
      fixture.repository.onGet = (_) => gate.future;
      controller.setActive(true);
      expect(controller.state.phase, LoadPhase.loading);
      tick(25);
      gate.complete(timedLyrics(lyricsTracks.first.ref));
      await flushLyrics();
      expect(controller.state.phase, LoadPhase.data);
      expect(controller.activeIndex, 1);
      var notifications = 0;
      controller.addListener(() => notifications++);
      tick(26);
      tick(29);
      expect(notifications, 0);
      tick(30);
      expect(controller.activeIndex, 2);
      expect(notifications, 1);
      tick(40);
      expect(controller.activeIndex, isNull);
      tick(15, phase: AudioEnginePhase.paused);
      expect(controller.activeIndex, 0);
      expect(fixture.repository.reads, [lyricsTracks.first.ref]);
    },
  );

  test(
    'same track id and title across sources use the complete reference',
    () async {
      await activate();
      await fixture.graph.playback.playEntry('entry-1');
      await flushLyrics();
      expect(controller.state.data!.track, lyricsTracks[1].ref);
      expect(fixture.repository.reads, [
        lyricsTracks[0].ref,
        lyricsTracks[1].ref,
      ]);
    },
  );

  test(
    'null is empty, not generated title lyrics; explicit retry may recover',
    () async {
      fixture.repository.documents.clear();
      await activate();
      expect(controller.state.phase, LoadPhase.empty);
      expect(controller.activeIndex, isNull);
      tick(15);
      expect(fixture.repository.reads, hasLength(1));
      fixture.repository.documents[lyricsTracks.first.ref] = timedLyrics(
        lyricsTracks.first.ref,
      );
      controller.refresh();
      await flushLyrics();
      expect(controller.state.phase, LoadPhase.data);
      expect(controller.activeIndex, 0);
    },
  );

  test(
    'read failure is sanitized and only explicit retry reads again',
    () async {
      fixture.repository.onGet = (_) async => throw DomainFailure(
        code: DomainFailureCode.databaseCorrupted,
        diagnosticId: 'private-marker',
        sourceId: 'private-source',
      );
      await activate();
      expect(controller.state.phase, LoadPhase.error);
      final failure = controller.state.failure!;
      expect(failure.code, DomainFailureCode.databaseCorrupted);
      expect(failure.diagnosticId, 'lyrics.load');
      expect(failure.sourceId, isNull);
      expect(failure.toString(), isNot(contains('private')));
      tick(15);
      expect(fixture.repository.reads, hasLength(1));
      fixture.repository.onGet = null;
      controller.refresh();
      await flushLyrics();
      expect(controller.state.phase, LoadPhase.data);
    },
  );

  test(
    'a repository returning another source is rejected as schema mismatch',
    () async {
      fixture.repository.onGet = (_) async => timedLyrics(lyricsTracks[1].ref);
      await activate();
      expect(controller.state.phase, LoadPhase.error);
      expect(controller.state.failure!.code, DomainFailureCode.schemaMismatch);
      expect(controller.state.data, isNull);
    },
  );

  test(
    'missing repository is unavailable rather than false empty success',
    () async {
      final missing = LyricsController(playback: fixture.graph.playback);
      addTearDown(missing.close);
      missing.setActive(true);
      expect(missing.state.phase, LoadPhase.error);
      expect(missing.state.failure!.diagnosticId, 'lyrics.unavailable');
    },
  );

  test(
    'deactivation drops a late read and subsequent ticks do not reactivate',
    () async {
      final gate = Completer<LyricsDocument?>();
      fixture.repository.onGet = (_) => gate.future;
      await activate();
      controller.setActive(false);
      gate.complete(timedLyrics(lyricsTracks.first.ref));
      await flushLyrics();
      tick(15);
      controller.refresh();
      expect(controller.state.phase, LoadPhase.idle);
      expect(controller.activeIndex, isNull);
      expect(fixture.repository.reads, hasLength(1));
    },
  );

  test(
    'one read worker coalesces repeated changes to latest complete identity',
    () async {
      final first = Completer<LyricsDocument?>();
      fixture.repository.onGet = (ref) => fixture.repository.reads.length == 1
          ? first.future
          : Future.value(timedLyrics(ref));
      await activate();
      await fixture.graph.playback.playEntry('entry-1');
      controller.refresh();
      await fixture.graph.playback.playEntry('entry-2');
      expect(fixture.repository.reads, hasLength(1));
      first.complete(timedLyrics(lyricsTracks.first.ref));
      await flushLyrics();
      expect(fixture.repository.reads, [
        lyricsTracks[0].ref,
        lyricsTracks[2].ref,
      ]);
      expect(fixture.repository.maximumInFlight, 1);
      expect(controller.state.data!.track, lyricsTracks[2].ref);
    },
  );

  test(
    'late error cannot replace a new track or revived active session',
    () async {
      final first = Completer<LyricsDocument?>();
      fixture.repository.onGet = (ref) => fixture.repository.reads.length == 1
          ? first.future
          : Future.value(timedLyrics(ref));
      await activate();
      controller.setActive(false);
      await fixture.graph.playback.playEntry('entry-1');
      controller.setActive(true);
      first.completeError(StateError('private-marker'));
      await flushLyrics();
      expect(controller.state.phase, LoadPhase.data);
      expect(controller.state.data!.track, lyricsTracks[1].ref);
      expect(fixture.repository.maximumInFlight, 1);
    },
  );

  test('plain and translated text remain data but cannot seek', () async {
    final document = LyricsDocument(
      track: lyricsTracks.first.ref,
      kind: LyricsKind.plain,
      language: 'en',
      translationLanguage: 'zh',
      lines: [LyricsLine(text: 'Actual', translation: '实际')],
    );
    fixture.repository.documents[document.track] = document;
    await activate();
    tick(25);
    expect(controller.state.data, same(document));
    expect(controller.activeIndex, isNull);
    await controller.seekLine(0, expectedState: controller.state);
    expect(
      fixture.engine.calls.where((call) => call.startsWith('seek:')),
      isEmpty,
    );
  });

  test(
    'line seek uses offset and only native position updates highlight',
    () async {
      fixture.repository.documents[lyricsTracks.first.ref] = timedLyrics(
        lyricsTracks.first.ref,
        offset: const Duration(seconds: 2),
      );
      await activate();
      final gate = Completer<void>();
      fixture.engine.seekGate = gate.future;
      final seeking = controller.seekLine(1, expectedState: controller.state);
      await flushLyrics();
      expect(fixture.engine.calls.last, 'seek:22000');
      expect(controller.activeIndex, isNull);
      gate.complete();
      await seeking;
      expect(controller.activeIndex, 1);
      expect(
        fixture.graph.playback.state.position,
        const Duration(seconds: 22),
      );
    },
  );

  test(
    'seek errors stay local and sanitized, without discarding the document',
    () async {
      await activate();
      final snapshot = controller.state;
      fixture.engine.seekError = StateError('private-marker');
      await controller.seekLine(0, expectedState: snapshot);
      expect(controller.state, same(snapshot));
      expect(controller.seekFailure!.diagnosticId, 'lyrics.seek');
      expect(
        controller.seekFailure.toString(),
        isNot(contains('private-marker')),
      );
      fixture.engine.seekError = null;
      tick(0);
      await controller.seekLine(0, expectedState: snapshot);
      expect(controller.seekFailure, isNull);
      expect(controller.activeIndex, 0);
    },
  );

  test(
    'old snapshot is revoked by refresh even when repository reuses document',
    () async {
      await activate();
      final snapshot = controller.state;
      controller.refresh();
      await flushLyrics();
      expect(controller.state.data, same(snapshot.data));
      expect(controller.state, isNot(same(snapshot)));
      await controller.seekLine(0, expectedState: snapshot);
      expect(
        fixture.engine.calls.where((call) => call.startsWith('seek:')),
        isEmpty,
      );
    },
  );

  for (final revoke in ['hide', 'refresh', 'switch-and-back', 'close']) {
    test(
      'queued line seek is revoked by $revoke before native execution',
      () async {
        await activate();
        final snapshot = controller.state;
        final gate = Completer<void>();
        fixture.engine.pauseGate = gate.future;
        final blocking = fixture.graph.playback.pause();
        await flushLyrics();
        Future<void>? away, back;
        if (revoke == 'switch-and-back') {
          away = fixture.graph.playback.playEntry('entry-1');
          back = fixture.graph.playback.playEntry('entry-0');
        }
        final seeking = controller.seekLine(0, expectedState: snapshot);
        Future<void>? closing;
        switch (revoke) {
          case 'hide':
            controller.setActive(false);
            controller.setActive(true);
          case 'refresh':
            controller.refresh();
          case 'close':
            closing = fixture.graph.close();
          case 'switch-and-back':
            break;
        }
        gate.complete();
        await blocking;
        await away;
        await back;
        await seeking;
        await closing;
        expect(
          fixture.engine.calls.where((call) => call.startsWith('seek:')),
          isEmpty,
        );
      },
    );
  }

  test(
    'idle or buffering state and invalid line indices cannot seek',
    () async {
      await activate();
      await controller.seekLine(-1, expectedState: controller.state);
      await controller.seekLine(99, expectedState: controller.state);
      tick(15, phase: AudioEnginePhase.buffering);
      await controller.seekLine(0, expectedState: controller.state);
      await fixture.graph.playback.stop();
      await controller.seekLine(0, expectedState: controller.state);
      expect(
        fixture.engine.calls.where((call) => call.startsWith('seek:')),
        isEmpty,
      );
    },
  );

  test(
    'close drains an accepted native seek and prevents additional work',
    () async {
      await activate();
      final gate = Completer<void>();
      fixture.engine.seekGate = gate.future;
      final snapshot = controller.state;
      final seeking = controller.seekLine(0, expectedState: snapshot);
      await flushLyrics();
      var closed = false;
      final closing = fixture.graph.close().then((_) => closed = true);
      controller.setActive(true);
      controller.refresh();
      await controller.seekLine(1, expectedState: snapshot);
      await flushLyrics();
      expect(closed, isFalse);
      expect(fixture.engine.disposalCount, 0);
      gate.complete();
      await seeking;
      await closing;
      expect(controller.state.phase, LoadPhase.idle);
      expect(fixture.engine.calls.where((call) => call.startsWith('seek:')), [
        'seek:10000',
      ]);
      expect(fixture.engine.disposalCount, 1);
    },
  );

  test(
    'close from nested playback/lyrics notification is reentrancy-safe',
    () async {
      await activate();
      final errors = <FlutterErrorDetails>[];
      final previous = FlutterError.onError;
      FlutterError.onError = errors.add;
      addTearDown(() => FlutterError.onError = previous);
      Future<void>? closing;
      controller.addListener(() => closing = fixture.graph.close());
      tick(15);
      expect(closing, isNotNull);
      await closing;
      expect(errors, isEmpty);
      expect(fixture.engine.disposalCount, 1);
    },
  );

  test('close reentered from repository waits for the already registered read', () async {
    final gate = Completer<LyricsDocument?>();
    Future<void>? closing;
    fixture.repository.onGet = (_) {
      closing = fixture.graph.close();
      return gate.future;
    };
    controller.setActive(true);
    await flushLyrics();
    expect(closing, isNotNull);
    expect(fixture.engine.disposalCount, 0);
    gate.complete(timedLyrics(lyricsTracks.first.ref));
    await closing;
    expect(controller.state.phase, LoadPhase.idle);
    // The borrowed lyrics repository remains usable after controller disposal.
    fixture.repository.onGet = null;
    expect(
      await fixture.repository.getLyrics(lyricsTracks.first.ref),
      isNotNull,
    );
    expect(fixture.engine.disposalCount, 1);
  });
}
