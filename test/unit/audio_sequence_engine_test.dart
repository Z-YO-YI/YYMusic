import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/domain/models/domain_failure.dart';
import 'package:yymusic/domain/models/track.dart';
import 'package:yymusic/playback/audio_engine_state.dart';
import 'package:yymusic/playback/audio_sequence.dart';
import 'package:yymusic/playback/just_audio_backend.dart';
import 'package:yymusic/playback/just_audio_engine.dart';
import 'package:yymusic/playback/playable_source.dart';

void main() {
  final track = TrackRef(
    trackId: 'same',
    sourceId: 'local',
    sourceType: MusicSourceType.local,
  );
  final source = PlayableSource.localFile(
    track: track,
    path: '/private/song.wav',
  );
  AudioSequence sequence() => AudioSequence([
    AudioSequenceEntry(entryId: 'first', source: source),
    AudioSequenceEntry(entryId: 'repeated', source: source),
  ]);
  late _SequenceBackend backend;
  late JustAudioEngine engine;
  late List<AudioEngineState> states;
  late DateTime now;
  setUp(() {
    now = DateTime.utc(2026, 9, 13);
    backend = _SequenceBackend();
    engine = JustAudioEngine(backend, clock: () => now);
    states = [];
    engine.states.listen(states.add);
  });
  tearDown(() => engine.dispose());

  AudioSequenceAppend append(AudioSequence batch, {String id = 'third'}) =>
      AudioSequenceAppend(
        expectedTail: batch.cursors.last,
        entries: [AudioSequenceEntry(entryId: id, source: source)],
      );

  PlayableSource timed(DateTime? deadline) => PlayableSource.networkStream(
    track: track,
    uri: Uri.parse('https://fixture.invalid/a?private=value'),
    expiresAt: deadline,
  );

  test(
    'expiry is UTC and exact deadline is invalid without leaking locator',
    () {
      final deadline = DateTime.parse('2026-09-13T07:00:00+07:00');
      final value = timed(deadline);
      expect(value.expiresAt!.isUtc, isTrue);
      expect(
        value.isValidAt(now.subtract(const Duration(microseconds: 1))),
        isTrue,
      );
      expect(value.isValidAt(now), isFalse);
      expect(value.toString(), isNot(contains('private')));
      expect(timed(null).isValidAt(now), isTrue);
      expect(source.expiresAt, isNull);
    },
  );

  test(
    'expired single and batch inputs preserve existing native state',
    () async {
      final batch = sequence();
      await engine.loadSequence(batch);
      await engine.play();
      final before = states.length;
      final expired = timed(now);
      await expectLater(
        engine.load(expired),
        throwsA(
          isA<DomainFailure>().having(
            (e) => e.code,
            'code',
            DomainFailureCode.streamUrlExpired,
          ),
        ),
      );
      await expectLater(
        engine.loadSequence(
          AudioSequence([
            AudioSequenceEntry(entryId: 'expired', source: expired),
          ]),
        ),
        throwsA(isA<DomainFailure>()),
      );
      expect(backend.calls, ['sequence:0', 'play']);
      expect(states.length, before);
      expect(
        states.last.sequenceCursor!.sequenceIdentity,
        same(batch.identity),
      );
    },
  );

  test('expired append is rejected before changing batch mapping', () async {
    final batch = sequence();
    await engine.loadSequence(batch);
    await expectLater(
      engine.appendSequence(
        AudioSequenceAppend(
          expectedTail: batch.cursors.last,
          entries: [AudioSequenceEntry(entryId: 'later', source: timed(now))],
        ),
      ),
      throwsA(isA<DomainFailure>()),
    );
    expect(backend.calls, ['sequence:0']);
    expect(await engine.appendSequence(append(batch)), isTrue);
  });

  test('queued load rechecks time when command actually executes', () async {
    final gate = backend.gate = Completer<void>();
    final loading = engine.loadSequence(sequence());
    final queued = engine.load(timed(now.add(const Duration(seconds: 1))));
    final expectation = expectLater(queued, throwsA(isA<DomainFailure>()));
    now = now.add(const Duration(seconds: 2));
    gate.complete();
    await loading;
    await expectation;
    expect(backend.calls, ['sequence:0']);
  });

  test('append maps early native index without reload or play', () async {
    final batch = sequence();
    await engine.loadSequence(batch);
    backend.appendIndex = 2;
    expect(await engine.appendSequence(append(batch)), isTrue);
    expect(states.last.sequenceCursor!.entryId, 'third');
    expect(states.last.sequenceCursor!.sequenceIdentity, same(batch.identity));
    expect(backend.calls, ['sequence:0', 'append:1']);
    expect(await engine.appendSequence(append(batch)), isFalse);
    expect(backend.calls, ['sequence:0', 'append:1']);
  });

  test('foreign tail and duplicate entry cannot mutate native list', () async {
    final batch = sequence();
    await engine.loadSequence(batch);
    expect(await engine.appendSequence(append(sequence())), isFalse);
    await expectLater(
      engine.appendSequence(append(batch, id: 'first')),
      throwsArgumentError,
    );
    expect(backend.calls, ['sequence:0']);
  });

  test('failed append clears identity and stops with safe failure', () async {
    final batch = sequence();
    await engine.loadSequence(batch);
    backend.appendFails = true;
    await expectLater(
      engine.appendSequence(append(batch)),
      throwsA(isA<DomainFailure>()),
    );
    expect(states.last.sequenceCursor, isNull);
    expect(states.last.phase, AudioEnginePhase.error);
    expect(backend.calls.last, 'stop');
  });

  test(
    'invalid index after append cannot be acknowledged as success',
    () async {
      final batch = sequence();
      await engine.loadSequence(batch);
      backend.appendIndex = 20;
      await expectLater(
        engine.appendSequence(append(batch)),
        throwsA(isA<DomainFailure>()),
      );
      expect(states.last.phase, AudioEnginePhase.error);
    },
  );

  test('completed sequence cannot be restarted through append', () async {
    final batch = sequence();
    await engine.loadSequence(batch);
    backend.current = const JustAudioPlayerSnapshot(
      currentIndex: 1,
      processing: JustAudioProcessingPhase.completed,
    );
    expect(await engine.appendSequence(append(batch)), isFalse);
    expect(backend.calls, ['sequence:0']);
  });

  test(
    'immutable request preserves repeated tracks with distinct entry IDs',
    () {
      final entries = [AudioSequenceEntry(entryId: 'first', source: source)];
      final batch = AudioSequence(entries);
      entries.clear();
      expect(batch.entries, hasLength(1));
      expect(() => batch.entries.clear(), throwsUnsupportedError);
      expect(() => batch.cursors.clear(), throwsUnsupportedError);
      expect(() => AudioSequence([]), throwsArgumentError);
      expect(
        () => AudioSequence([batch.entries.single, batch.entries.single]),
        throwsArgumentError,
      );
      final repeated = sequence();
      expect(repeated.cursors.map((e) => e.entryId), ['first', 'repeated']);
      expect(repeated.cursors.map((e) => e.track), [track, track]);
      expect(identical(repeated.identity, sequence().identity), isFalse);
      expect(repeated.toString(), isNot(contains('/private/')));
      expect(repeated.cursors.first.toString(), isNot(contains('/private/')));
    },
  );

  test(
    'loads once without play and atomically maps index and entry identity',
    () async {
      final batch = sequence();
      expect(engine.supportsSequences, isTrue);
      await engine.loadSequence(batch, initialIndex: 1);
      expect(backend.calls, ['sequence:1']);
      expect(states.first.phase, AudioEnginePhase.loading);
      expect(states.first.sequenceCursor, isNull);
      expect(states.last.phase, AudioEnginePhase.ready);
      expect(states.last.sequenceCursor!.entryId, 'repeated');
      expect(
        identical(states.last.sequenceCursor!.sequenceIdentity, batch.identity),
        isTrue,
      );
      await engine.play();
      backend.emit(
        index: 0,
        playing: true,
        position: const Duration(seconds: 2),
      );
      expect(states.last.phase, AudioEnginePhase.playing);
      expect(states.last.position, const Duration(seconds: 2));
      expect(states.last.sequenceCursor!.entryId, 'first');
      expect(backend.calls, ['sequence:1', 'play']);
    },
  );

  test(
    'replacement suppresses old cursors while native loading is pending',
    () async {
      final old = sequence();
      await engine.loadSequence(old);
      final next = sequence();
      backend.gate = Completer<void>();
      final offset = states.length;
      final loading = engine.loadSequence(next, initialIndex: 1);
      await Future<void>.delayed(Duration.zero);
      backend.emit(index: 0);
      expect(
        states.skip(offset).every((state) => state.sequenceCursor == null),
        isTrue,
      );
      backend.gate!.complete();
      await loading;
      expect(
        identical(states.last.sequenceCursor!.sequenceIdentity, next.identity),
        isTrue,
      );
      expect(
        identical(states.last.sequenceCursor!.sequenceIdentity, old.identity),
        isFalse,
      );
    },
  );

  test('invalid initial index preserves existing state and backend', () async {
    await engine.loadSequence(sequence());
    final before = states.last;
    for (final index in [-1, 2]) {
      await expectLater(
        engine.loadSequence(sequence(), initialIndex: index),
        throwsArgumentError,
      );
    }
    expect(identical(states.last, before), isTrue);
    expect(backend.calls, ['sequence:0']);
  });

  test('unsupported backend rejects before replacing single media', () async {
    final single = _SingleBackend();
    final adapter = JustAudioEngine(single);
    addTearDown(adapter.dispose);
    final observed = <AudioEngineState>[];
    adapter.states.listen(observed.add);
    await adapter.load(source);
    final previous = observed.last;
    expect(adapter.supportsSequences, isFalse);
    await expectLater(
      adapter.loadSequence(sequence()),
      throwsA(isA<DomainFailure>()),
    );
    expect(single.calls, ['open']);
    expect(identical(observed.last, previous), isTrue);
  });

  test('whole-batch unsupported headers preserve previous identity', () async {
    await engine.loadSequence(sequence());
    final before = states.last;
    backend.supportsRequestHeaders = false;
    final request = AudioSequence([
      AudioSequenceEntry(entryId: 'ok', source: source),
      AudioSequenceEntry(
        entryId: 'headers',
        source: PlayableSource.networkStream(
          track: track,
          uri: Uri.parse('https://example.invalid/song'),
          headers: {'X-Fixture': 'private-value'},
        ),
      ),
    ]);
    await expectLater(
      engine.loadSequence(request),
      throwsA(isA<DomainFailure>()),
    );
    expect(identical(states.last, before), isTrue);
    expect(backend.calls, ['sequence:0']);
  });

  test(
    'safe load failure clears identity and does not poison later requests',
    () async {
      await engine.loadSequence(sequence());
      backend.fail = true;
      await expectLater(
        engine.loadSequence(sequence()),
        throwsA(
          isA<DomainFailure>().having(
            (failure) => failure.diagnosticId,
            'safe diagnostic',
            'audio.just-audio.sequence',
          ),
        ),
      );
      expect(states.last.sequenceCursor, isNull);
      expect(states.last.phase, AudioEnginePhase.error);
      backend.fail = false;
      await engine.loadSequence(sequence());
      expect(states.last.phase, AudioEnginePhase.ready);
      expect(states.last.sequenceCursor, isNotNull);
    },
  );

  test(
    'async error during load cannot become a successful identified ready state',
    () async {
      backend.gate = Completer<void>();
      final loading = engine.loadSequence(sequence());
      final rejected = expectLater(loading, throwsA(isA<DomainFailure>()));
      await Future<void>.delayed(Duration.zero);
      backend.errorsController.add(null);
      backend.gate!.complete();
      await rejected;
      expect(states.last.phase, AudioEnginePhase.error);
      expect(states.every((state) => state.sequenceCursor == null), isTrue);
    },
  );

  for (final invalid in [null, -1, 2]) {
    test(
      'invalid native index $invalid fails closed without guessing a track',
      () async {
        await engine.loadSequence(sequence());
        backend.emit(index: invalid);
        expect(states.last.phase, AudioEnginePhase.error);
        expect(states.last.sequenceCursor, isNull);
        expect(
          states.last.failure!.diagnosticId,
          'audio.just-audio.sequence-index',
        );
        await expectLater(engine.play(), throwsA(isA<DomainFailure>()));
        expect(backend.calls, ['sequence:0', 'stop']);
      },
    );
  }

  test(
    'an already accepted replacement supersedes the old index fault stop',
    () async {
      await engine.loadSequence(sequence());
      final replacement = sequence();
      final loading = engine.loadSequence(replacement);
      backend.emit(index: null);
      await loading;
      await engine.setVolume(0.5);
      expect(backend.calls, ['sequence:0', 'sequence:0', 'volume']);
      expect(
        identical(
          states.last.sequenceCursor!.sequenceIdentity,
          replacement.identity,
        ),
        isTrue,
      );
    },
  );

  test('index fault stop failure stays safe and close still drains', () async {
    await engine.loadSequence(sequence());
    backend.stopFails = true;
    backend.emit(index: null);
    await engine.dispose();
    expect(backend.calls, ['sequence:0', 'stop']);
    expect(backend.disposals, 1);
    expect(
      states.last.failure!.diagnosticId,
      'audio.just-audio.sequence-index',
    );
  });

  test(
    'missing initial native index fails load rather than reporting ready',
    () async {
      backend.omitIndex = true;
      await expectLater(
        engine.loadSequence(sequence()),
        throwsA(isA<DomainFailure>()),
      );
      expect(states.last.phase, AudioEnginePhase.error);
      expect(states.last.sequenceCursor, isNull);
    },
  );

  test(
    'single load and stop clear sequence identity, including late snapshots',
    () async {
      await engine.loadSequence(sequence());
      await engine.load(source);
      expect(states.last.sequenceCursor, isNull);
      await engine.loadSequence(sequence());
      await engine.stop();
      backend.emit(index: 1);
      expect(states.last.phase, AudioEnginePhase.idle);
      expect(states.last.sequenceCursor, isNull);
    },
  );

  test(
    'boundary keeps current identity and clock without play/seek/reload',
    () async {
      final batch = sequence();
      await engine.loadSequence(batch);
      backend.emit(
        index: 0,
        playing: true,
        position: const Duration(seconds: 9),
      );
      expect(
        await engine.retainSequenceThrough(states.last.sequenceCursor!),
        isTrue,
      );
      expect(states.last.sequenceCursor!.entryId, 'first');
      expect(states.last.phase, AudioEnginePhase.playing);
      expect(states.last.position, const Duration(seconds: 9));
      expect(backend.calls, ['sequence:0', 'retain:0']);
      expect(await engine.retainSequenceThrough(batch.cursors[1]), isFalse);
      expect(backend.calls, ['sequence:0', 'retain:0']);
    },
  );

  test(
    'old batch or noncurrent entry never dispatches a boundary edit',
    () async {
      final old = sequence();
      await engine.loadSequence(old);
      final next = sequence();
      await engine.loadSequence(next);
      expect(await engine.retainSequenceThrough(old.cursors.first), isFalse);
      expect(await engine.retainSequenceThrough(next.cursors.last), isFalse);
      expect(backend.calls, ['sequence:0', 'sequence:0']);
    },
  );

  test('queued replacement revokes an older boundary request', () async {
    final old = sequence();
    await engine.loadSequence(old);
    final loading = engine.loadSequence(sequence());
    final boundary = engine.retainSequenceThrough(old.cursors.first);
    await loading;
    expect(await boundary, isFalse);
    expect(backend.calls, ['sequence:0', 'sequence:0']);
  });

  for (final returnsToOriginal in [false, true]) {
    test(
      'index movement during trim fails even if it returns=$returnsToOriginal',
      () async {
        await engine.loadSequence(sequence());
        final expected = states.last.sequenceCursor!;
        backend.trimGate = Completer<void>();
        final editing = engine.retainSequenceThrough(expected);
        final rejected = expectLater(editing, throwsA(isA<DomainFailure>()));
        await Future<void>.delayed(Duration.zero);
        final count = states.length;
        backend.emit(index: 1);
        if (returnsToOriginal) backend.emit(index: 0);
        expect(states.length, count);
        backend.trimGate!.complete();
        await rejected;
        expect(states.last.phase, AudioEnginePhase.error);
        expect(states.last.sequenceCursor, isNull);
        expect(
          states.last.failure!.diagnosticId,
          'audio.just-audio.sequence-boundary',
        );
        expect(backend.calls, ['sequence:0', 'retain:0', 'stop']);
      },
    );
  }

  test(
    'native edit and stop errors remain safe and require a new load',
    () async {
      await engine.loadSequence(sequence());
      backend.trimFails = true;
      backend.stopFails = true;
      await expectLater(
        engine.retainSequenceThrough(states.last.sequenceCursor!),
        throwsA(
          isA<DomainFailure>().having(
            (e) => e.diagnosticId,
            'safe diagnostic',
            'audio.just-audio.sequence-boundary',
          ),
        ),
      );
      expect(states.last.sequenceCursor, isNull);
      await expectLater(engine.play(), throwsA(isA<DomainFailure>()));
      backend.trimFails = false;
      backend.stopFails = false;
      await engine.loadSequence(sequence());
      expect(states.last.sequenceCursor, isNotNull);
    },
  );

  test(
    'async error while trimming cannot report successful retention',
    () async {
      await engine.loadSequence(sequence());
      backend.trimGate = Completer<void>();
      final editing = engine.retainSequenceThrough(states.last.sequenceCursor!);
      final rejected = expectLater(editing, throwsA(isA<DomainFailure>()));
      await Future<void>.delayed(Duration.zero);
      backend.errorsController.add(null);
      backend.trimGate!.complete();
      await rejected;
      expect(states.last.sequenceCursor, isNull);
      expect(backend.calls.last, 'stop');
    },
  );

  test(
    'close drains accepted trim without late notifications or new edits',
    () async {
      await engine.loadSequence(sequence());
      final expected = states.last.sequenceCursor!;
      backend.trimGate = Completer<void>();
      final editing = engine.retainSequenceThrough(expected);
      await Future<void>.delayed(Duration.zero);
      final closing = engine.dispose();
      final count = states.length;
      await expectLater(
        engine.retainSequenceThrough(expected),
        throwsStateError,
      );
      backend.trimGate!.complete();
      expect(await editing, isTrue);
      await closing;
      expect(states.length, count);
      expect(backend.disposals, 1);
    },
  );

  test('play waits behind accepted sequence load', () async {
    backend.gate = Completer<void>();
    final loading = engine.loadSequence(sequence());
    final playing = engine.play();
    await Future<void>.delayed(Duration.zero);
    expect(backend.calls, ['sequence:0']);
    backend.gate!.complete();
    await loading;
    await playing;
    expect(backend.calls, ['sequence:0', 'play']);
    expect(states.last.sequenceCursor, isNotNull);
  });

  test(
    'close drains accepted load, suppresses notifications and rejects new work',
    () async {
      backend.gate = Completer<void>();
      final loading = engine.loadSequence(sequence());
      await Future<void>.delayed(Duration.zero);
      final close = engine.dispose();
      final count = states.length;
      expect(engine.supportsSequences, isFalse);
      await expectLater(engine.loadSequence(sequence()), throwsStateError);
      expect(backend.disposals, 0);
      backend.gate!.complete();
      await loading;
      await close;
      expect(states.length, count);
      expect(backend.disposals, 1);
      await engine.dispose();
      expect(backend.disposals, 1);
    },
  );
}

class _SingleBackend implements JustAudioPlayerBackend {
  final snapshotsController =
      StreamController<JustAudioPlayerSnapshot>.broadcast(sync: true);
  final errorsController = StreamController<void>.broadcast(sync: true);
  final calls = <String>[];
  int disposals = 0;
  bool stopFails = false;
  @override
  bool supportsRequestHeaders = true;
  @override
  JustAudioPlayerSnapshot current = const JustAudioPlayerSnapshot();
  @override
  Stream<JustAudioPlayerSnapshot> get snapshots => snapshotsController.stream;
  @override
  Stream<void> get errors => errorsController.stream;
  void emit({
    int? index,
    bool playing = false,
    Duration position = Duration.zero,
  }) {
    current = JustAudioPlayerSnapshot(
      currentIndex: index,
      playing: playing,
      processing: JustAudioProcessingPhase.ready,
      position: position,
    );
    snapshotsController.add(current);
  }

  @override
  Future<void> open(
    Uri resource, {
    required Map<String, String> headers,
    DateTime? expiresAt,
  }) async {
    calls.add('open');
    emit();
  }

  @override
  Future<void> play() async {
    calls.add('play');
    emit(index: current.currentIndex, playing: true);
  }

  @override
  Future<void> pause() async {
    calls.add('pause');
    emit(index: current.currentIndex);
  }

  @override
  Future<void> stop() async {
    calls.add('stop');
    if (stopFails) throw StateError('private-stop-detail');
    emit();
  }

  @override
  Future<void> seek(Duration position) async {
    calls.add('seek');
  }

  @override
  Future<void> setVolume(double value) async {
    calls.add('volume');
  }

  @override
  Future<void> setSpeed(double value) async {
    calls.add('speed');
  }

  @override
  Future<void> dispose() async {
    disposals++;
    await snapshotsController.close();
    await errorsController.close();
  }
}

final class _SequenceBackend extends _SingleBackend
    implements JustAudioSequenceBackend {
  Completer<void>? gate;
  bool fail = false;
  bool omitIndex = false;
  Completer<void>? trimGate;
  bool trimFails = false;
  bool appendFails = false;
  int? appendIndex;
  @override
  Future<bool> appendSequence(
    List<PlayableSource> sources, {
    required int expectedLength,
  }) async {
    calls.add('append:${sources.length}');
    if (appendFails) throw StateError('private-append-detail');
    if (appendIndex != null) emit(index: appendIndex, playing: true);
    return true;
  }

  @override
  Future<bool> retainSequenceThrough(int expectedIndex) async {
    calls.add('retain:$expectedIndex');
    if (trimGate != null) await trimGate!.future;
    if (trimFails) throw StateError('private-boundary-failure');
    return current.currentIndex == expectedIndex;
  }

  @override
  Future<void> openSequence(
    List<PlayableSource> sources, {
    int initialIndex = 0,
  }) async {
    calls.add('sequence:$initialIndex');
    if (gate != null) await gate!.future;
    if (fail) throw StateError('private-native-detail');
    emit(index: omitIndex ? null : initialIndex);
  }
}
