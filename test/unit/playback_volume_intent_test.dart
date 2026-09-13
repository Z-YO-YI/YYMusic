import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/domain/models/domain_failure.dart';
import 'package:yymusic/playback/audio_engine.dart';
import 'package:yymusic/playback/audio_engine_state.dart';
import 'package:yymusic/playback/playable_source.dart';
import 'package:yymusic/playback/playback_controller.dart';
import 'package:yymusic/playback/playback_state.dart';

import '../support/fake_audio_engine.dart';
import '../support/fake_domain_repositories.dart';
import '../support/fake_playback_dependencies.dart';

void main() {
  late _VolumeEngine engine;
  late PlaybackController player;
  late FakeLibraryRepository library;

  setUp(() {
    engine = _VolumeEngine();
    library = FakeLibraryRepository(tracks: [playbackFixtureTrack]);
    player = PlaybackController(
      engine,
      library: library,
      sourceResolver: FakePlaybackSourceResolver(),
    );
  });

  tearDown(() async {
    await player.close();
    await engine.dispose();
    await library.dispose();
  });

  Future<void> start() async {
    await player.replaceQueue([playbackFixtureEntry()]);
    await player.play();
  }

  test(
    'successful volume command without a stream event updates intent',
    () async {
      await player.setVolume(0.4);
      expect(player.state.volume, 0.4);
      expect(engine.delegate.volume, 0.4);
    },
  );

  test('late snapshots cannot replace the confirmed user volume', () async {
    await start();
    await player.setVolume(0.4);
    engine.report(0.1, phase: AudioEnginePhase.playing);
    expect(player.state.volume, 0.4);
    expect(player.state.phase, PlaybackPhase.playing);
  });

  test(
    'unloaded late snapshots preserve volume without resurrecting playback',
    () async {
      await player.setVolume(0.4);
      engine.report(0.1, phase: AudioEnginePhase.playing);
      expect(player.state.volume, 0.4);
      expect(player.state.phase, PlaybackPhase.idle);
    },
  );

  test(
    'before first command backend volume remains the initialization source',
    () {
      engine.report(0.6);
      expect(player.state.volume, 0.6);
      engine.report(0.2);
      expect(player.state.volume, 0.2);
      expect(engine.writes, isEmpty);
    },
  );

  for (final value in [0.0, 0.25, 1.0]) {
    test(
      'confirmed intent supports volume $value across ordinary reports',
      () async {
        await player.setVolume(value);
        engine.report(0.9);
        expect(player.state.volume, value);
        expect(engine.writes, [value]);
      },
    );
  }

  test('pending write shields old intent until command succeeds', () async {
    engine.report(0.6);
    final gate = engine.volumeGate = Completer<void>();
    final pending = player.setVolume(0.2);
    await _flush();
    engine.report(0.01);
    expect(player.state.volume, 0.6);
    gate.complete();
    await pending;
    expect(player.state.volume, 0.2);
  });

  test(
    'synchronous callback cannot publish transient backend volume',
    () async {
      final seen = <double>[];
      player.addListener(() => seen.add(player.state.volume));
      engine.onVolume = (_) => engine.report(0.01);
      await player.setVolume(0.4);
      expect(seen, [1, 0.4]);
    },
  );

  test(
    'failed write preserves confirmed intent and reports a safe error',
    () async {
      await player.setVolume(0.6);
      engine.volumeError = StateError('private backend payload');
      engine.onVolume = (_) => engine.report(0.01);
      await expectLater(player.setVolume(0.2), throwsA(isA<DomainFailure>()));
      expect(player.state.volume, 0.6);
      expect(player.state.phase, PlaybackPhase.error);
      expect(player.state.failure!.diagnosticId, 'playback.set-volume');
      expect(
        player.state.failure.toString(),
        isNot(contains('private backend')),
      );
    },
  );

  test('first failed write freezes the pre-command backend seed', () async {
    engine.report(0.6);
    engine.volumeError = StateError('failure');
    await expectLater(player.setVolume(0.2), throwsA(isA<DomainFailure>()));
    engine.report(0.2);
    expect(player.state.volume, 0.6);
  });

  test('retry succeeds after failure without starting playback', () async {
    engine.volumeError = StateError('failure');
    await expectLater(player.setVolume(0.2), throwsA(isA<DomainFailure>()));
    engine.volumeError = null;
    await player.setVolume(0.4);
    expect(player.state.volume, 0.4);
    expect(engine.delegate.calls, isNot(contains('play')));
  });

  for (final invalid in [double.nan, double.infinity, -0.1, 1.1]) {
    test(
      'invalid volume $invalid neither writes nor captures ownership',
      () async {
        await expectLater(player.setVolume(invalid), throwsArgumentError);
        engine.report(0.3);
        expect(player.state.volume, 0.3);
        expect(engine.writes, isEmpty);
      },
    );
  }

  test(
    'queued writes are serialized and newest successful value wins',
    () async {
      final gate = engine.volumeGate = Completer<void>();
      final first = player.setVolume(0.2);
      final second = player.setVolume(0.7);
      await _flush();
      expect(engine.writes, [0.2]);
      gate.complete();
      await Future.wait([first, second]);
      engine.report(0.2);
      expect(engine.writes, [0.2, 0.7]);
      expect(player.state.volume, 0.7);
    },
  );

  test(
    'failed queued write does not discard the next accepted command',
    () async {
      final firstError = expectLater(
        player.setVolume(0.2),
        throwsA(isA<DomainFailure>()),
      );
      engine.onVolume = (value) {
        engine.volumeError = value == 0.2 ? StateError('failure') : null;
      };
      final second = player.setVolume(0.7);
      await firstError;
      await second;
      expect(player.state.volume, 0.7);
      expect(engine.writes, [0.2, 0.7]);
    },
  );

  test(
    'listener-enqueued newer command cannot be overwritten by older completion',
    () async {
      Future<void>? newer;
      player.addListener(() {
        if (player.state.volume == 0.2 && newer == null) {
          newer = player.setVolume(0.7);
        }
      });
      await player.setVolume(0.2);
      await newer;
      engine.report(0.2);
      expect(player.state.volume, 0.7);
    },
  );

  test(
    'stop and reload preserve app intent while other audio facts update',
    () async {
      await start();
      await player.setVolume(0.4);
      await player.stop();
      engine.report(0.05, phase: AudioEnginePhase.playing);
      expect(player.state.phase, PlaybackPhase.idle);
      expect(player.state.volume, 0.4);
      await player.play();
      engine.delegate.events.add(
        AudioEngineState(
          phase: AudioEnginePhase.playing,
          volume: 0.05,
          position: const Duration(seconds: 4),
          playbackRate: 1.25,
        ),
      );
      expect(player.state.volume, 0.4);
      expect(player.state.phase, PlaybackPhase.playing);
      expect(player.state.position, const Duration(seconds: 4));
      expect(player.state.playbackRate, 1.25);
    },
  );

  test(
    'close drains in-flight write without publishing its late success',
    () async {
      final gate = engine.volumeGate = Completer<void>();
      final pending = player.setVolume(0.2);
      await _flush();
      var closed = false;
      final closing = player.close().then((_) => closed = true);
      await _flush();
      expect(closed, isFalse);
      gate.complete();
      await pending;
      await closing;
      expect(player.state.volume, 1);
      expect(closed, isTrue);
      expect(engine.delegate.disposalCount, 0);
    },
  );

  test(
    'closing rejects queued writes and never invokes them on the backend',
    () async {
      final gate = engine.volumeGate = Completer<void>();
      final pending = player.setVolume(0.2);
      final rejected = expectLater(player.setVolume(0.7), throwsStateError);
      await _flush();
      final closing = player.close();
      gate.complete();
      await Future.wait([pending, rejected, closing]);
      expect(engine.writes, [0.2]);
    },
  );

  test(
    'backend reentrant close cannot publish an acknowledged value',
    () async {
      engine.onVolume = (_) => player.dispose();
      await player.setVolume(0.2);
      expect(player.isClosed, isTrue);
      expect(player.state.volume, 1);
      await player.close();
    },
  );
}

Future<void> _flush() async {
  for (var index = 0; index < 8; index++) {
    await Future<void>.delayed(Duration.zero);
  }
}

final class _VolumeEngine implements AudioEngine {
  final delegate = FakeAudioEngine();
  Completer<void>? volumeGate;
  Object? volumeError;
  void Function(double)? onVolume;
  final writes = <double>[];

  void report(double volume, {AudioEnginePhase phase = AudioEnginePhase.idle}) {
    delegate.events.add(AudioEngineState(phase: phase, volume: volume));
  }

  @override
  bool get isAvailable => true;
  @override
  Stream<AudioEngineState> get states => delegate.states;
  @override
  Future<void> setVolume(double value) async {
    writes.add(value);
    onVolume?.call(value);
    await volumeGate?.future;
    final error = volumeError;
    if (error != null) throw error;
    delegate.volume = value;
  }

  @override
  Future<void> load(PlayableSource source) => delegate.load(source);
  @override
  Future<void> play() => delegate.play();
  @override
  Future<void> pause() => delegate.pause();
  @override
  Future<void> stop() => delegate.stop();
  @override
  Future<void> seek(Duration position) => delegate.seek(position);
  @override
  Future<void> setPlaybackRate(double value) => delegate.setPlaybackRate(value);
  @override
  Future<void> dispose() => delegate.dispose();
}
