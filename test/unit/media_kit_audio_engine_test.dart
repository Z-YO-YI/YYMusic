import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/domain/models/domain_failure.dart';
import 'package:yymusic/domain/models/track.dart';
import 'package:yymusic/playback/audio_engine_state.dart';
import 'package:yymusic/playback/media_kit_audio_backend.dart';
import 'package:yymusic/playback/media_kit_audio_engine.dart';
import 'package:yymusic/playback/playable_source.dart';

void main() {
  final localTrack = TrackRef(
    trackId: 'local-track',
    sourceId: 'local-source',
    sourceType: MusicSourceType.local,
  );
  final remoteTrack = TrackRef(
    trackId: 'remote-track',
    sourceId: 'remote-source',
    sourceType: MusicSourceType.rest,
  );

  test(
    'maps three ephemeral source kinds without automatic playback',
    () async {
      final backend = _FakeMediaKitBackend();
      final engine = MediaKitAudioEngine(backend);
      addTearDown(engine.dispose);

      await engine.load(
        PlayableSource.localFile(
          track: localTrack,
          path: r'C:\Music\POC tone.wav',
        ),
      );
      expect(backend.lastResource, 'file:///C:/Music/POC%20tone.wav');
      expect(backend.lastHeaders, isEmpty);
      expect(backend.lastPlay, isFalse);

      await engine.load(
        PlayableSource.contentUri(
          track: localTrack,
          uri: Uri.parse('content://media/external/audio/media/42'),
        ),
      );
      expect(backend.lastResource, 'content://media/external/audio/media/42');
      expect(backend.lastHeaders, isEmpty);
      expect(backend.lastPlay, isFalse);

      await engine.load(
        PlayableSource.networkStream(
          track: remoteTrack,
          uri: Uri.parse('https://audio.example.test/stream?id=42'),
          headers: const {'Authorization': 'Bearer runtime-only'},
        ),
      );
      expect(backend.lastResource, 'https://audio.example.test/stream?id=42');
      expect(backend.lastHeaders, const {
        'Authorization': 'Bearer runtime-only',
      });
      expect(backend.lastPlay, isFalse);
      expect(backend.calls.where((call) => call == 'open'), hasLength(3));
    },
  );

  test('maps backend facts and normalized transport commands', () async {
    final backend = _FakeMediaKitBackend();
    final engine = MediaKitAudioEngine(backend);
    final states = <AudioEngineState>[];
    final subscription = engine.states.listen(states.add);
    addTearDown(() async {
      await subscription.cancel();
      await engine.dispose();
    });

    await engine.load(
      PlayableSource.localFile(track: localTrack, path: r'C:\Music\tone.wav'),
    );
    expect(
      states.map((state) => state.phase),
      containsAllInOrder([AudioEnginePhase.loading, AudioEnginePhase.ready]),
    );

    backend.emit(
      buffering: true,
      duration: const Duration(seconds: 90),
      buffer: const Duration(seconds: 12),
    );
    expect(states.last.phase, AudioEnginePhase.buffering);
    expect(states.last.duration, const Duration(seconds: 90));
    expect(states.last.buffered, const Duration(seconds: 12));

    await engine.play();
    expect(states.last.phase, AudioEnginePhase.playing);
    await engine.seek(const Duration(seconds: 23));
    expect(states.last.position, const Duration(seconds: 23));
    await engine.setVolume(0.42);
    expect(backend.current.volume, 42);
    expect(states.last.volume, 0.42);
    await engine.setPlaybackRate(1.5);
    expect(backend.current.rate, 1.5);
    expect(states.last.playbackRate, 1.5);
    await engine.pause();
    expect(states.last.phase, AudioEnginePhase.paused);

    backend.emit(completed: true, position: const Duration(seconds: 90));
    expect(states.last.phase, AudioEnginePhase.completed);
    await engine.stop();
    expect(states.last.phase, AudioEnginePhase.idle);
    expect(states.last.position, Duration.zero);
    expect(
      backend.calls,
      containsAllInOrder([
        'open',
        'play',
        'seek:23000',
        'volume:42.0',
        'rate:1.5',
        'pause',
        'stop',
      ]),
    );
  });

  test(
    'maps command and async failures without retaining raw plugin text',
    () async {
      final backend = _FakeMediaKitBackend()
        ..openError = Exception(
          'https://secret.example/audio Authorization: Bearer leaked-value',
        );
      final engine = MediaKitAudioEngine(backend);
      final states = <AudioEngineState>[];
      final subscription = engine.states.listen(states.add);
      addTearDown(() async {
        await subscription.cancel();
        await engine.dispose();
      });

      await expectLater(
        engine.load(
          PlayableSource.networkStream(
            track: remoteTrack,
            uri: Uri.parse('https://secret.example/audio'),
            headers: const {'Authorization': 'Bearer leaked-value'},
          ),
        ),
        throwsA(
          isA<DomainFailure>()
              .having(
                (failure) => failure.code,
                'code',
                DomainFailureCode.playbackOpenFailed,
              )
              .having(
                (failure) => failure.diagnosticId,
                'diagnosticId',
                'audio.media-kit.open',
              ),
        ),
      );
      expect(states.last.phase, AudioEnginePhase.error);
      expect(states.last.failure.toString(), isNot(contains('secret.example')));
      expect(states.last.failure.toString(), isNot(contains('leaked-value')));

      backend.emitError();
      expect(states.last.failure?.diagnosticId, 'audio.media-kit.stream');
      expect(states.join(' '), isNot(contains('Authorization')));
    },
  );

  test(
    'dispose waits for accepted work, rejects new work and is idempotent',
    () async {
      final backend = _FakeMediaKitBackend()
        ..openGate = Completer<void>()
        ..disposeError = Exception('native dispose detail must stay private');
      final engine = MediaKitAudioEngine(backend);
      final done = Completer<void>();
      engine.states.listen((_) {}, onDone: done.complete);

      final load = engine.load(
        PlayableSource.localFile(track: localTrack, path: r'C:\Music\tone.wav'),
      );
      await Future<void>.delayed(Duration.zero);
      final disposal = engine.dispose();
      expect(engine.isAvailable, isFalse);
      await expectLater(engine.play(), throwsStateError);
      expect(backend.disposalCount, 0);

      backend.openGate!.complete();
      await load;
      await disposal;
      await done.future;
      await engine.dispose();
      expect(backend.disposalCount, 1);
    },
  );

  test('rejects invalid engine values before invoking the backend', () async {
    final backend = _FakeMediaKitBackend();
    final engine = MediaKitAudioEngine(backend);
    addTearDown(engine.dispose);

    await expectLater(
      engine.seek(const Duration(milliseconds: -1)),
      throwsArgumentError,
    );
    await expectLater(engine.setVolume(1.1), throwsArgumentError);
    await expectLater(engine.setPlaybackRate(2.1), throwsArgumentError);
    expect(backend.calls, isEmpty);
  });
}

final class _FakeMediaKitBackend implements MediaKitPlayerBackend {
  final _snapshots = StreamController<MediaKitPlayerSnapshot>.broadcast(
    sync: true,
  );
  final _errors = StreamController<void>.broadcast(sync: true);
  final List<String> calls = [];

  @override
  MediaKitPlayerSnapshot current = const MediaKitPlayerSnapshot();
  String? lastResource;
  Map<String, String> lastHeaders = const {};
  bool? lastPlay;
  Object? openError;
  Completer<void>? openGate;
  Object? disposeError;
  int disposalCount = 0;

  @override
  Stream<void> get errors => _errors.stream;

  @override
  Stream<MediaKitPlayerSnapshot> get snapshots => _snapshots.stream;

  @override
  Future<void> open(
    String resource, {
    required Map<String, String> headers,
    required bool play,
  }) async {
    calls.add('open');
    lastResource = resource;
    lastHeaders = Map.unmodifiable(headers);
    lastPlay = play;
    final error = openError;
    if (error != null) throw error;
    final gate = openGate;
    if (gate != null) await gate.future;
    current = const MediaKitPlayerSnapshot();
  }

  @override
  Future<void> play() async {
    calls.add('play');
    emit(playing: true, buffering: false);
  }

  @override
  Future<void> pause() async {
    calls.add('pause');
    emit(playing: false);
  }

  @override
  Future<void> stop() async {
    calls.add('stop');
    current = MediaKitPlayerSnapshot(
      volume: current.volume,
      rate: current.rate,
    );
    _snapshots.add(current);
  }

  @override
  Future<void> seek(Duration position) async {
    calls.add('seek:${position.inMilliseconds}');
    emit(position: position, completed: false);
  }

  @override
  Future<void> setVolume(double value) async {
    calls.add('volume:$value');
    emit(volume: value);
  }

  @override
  Future<void> setRate(double value) async {
    calls.add('rate:$value');
    emit(rate: value);
  }

  void emit({
    bool? playing,
    bool? completed,
    bool? buffering,
    Duration? position,
    Duration? duration,
    Duration? buffer,
    double? volume,
    double? rate,
  }) {
    current = MediaKitPlayerSnapshot(
      playing: playing ?? current.playing,
      completed: completed ?? current.completed,
      buffering: buffering ?? current.buffering,
      position: position ?? current.position,
      duration: duration ?? current.duration,
      buffer: buffer ?? current.buffer,
      volume: volume ?? current.volume,
      rate: rate ?? current.rate,
    );
    _snapshots.add(current);
  }

  void emitError() => _errors.add(null);

  @override
  Future<void> dispose() async {
    disposalCount++;
    await _snapshots.close();
    await _errors.close();
    final error = disposeError;
    if (error != null) throw error;
  }
}
