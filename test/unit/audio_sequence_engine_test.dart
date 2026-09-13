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
  setUp(() {
    backend = _SequenceBackend();
    engine = JustAudioEngine(backend);
    states = [];
    engine.states.listen(states.add);
  });
  tearDown(() => engine.dispose());

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
