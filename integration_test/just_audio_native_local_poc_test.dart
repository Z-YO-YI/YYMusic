import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yymusic/domain/models/track.dart';
import 'package:yymusic/playback/audio_engine_state.dart';
import 'package:yymusic/playback/just_audio_engine.dart';
import 'package:yymusic/playback/playable_source.dart';

import 'support/deterministic_pcm_wav.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('just_audio decodes and controls a generated local WAV', (
    _,
  ) async {
    expect(Platform.isWindows || Platform.isAndroid, isTrue);
    final directory = await Directory.systemTemp.createTemp(
      'yymusic-just-audio-poc-',
    );
    addTearDown(() async {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });
    final file = File(
      '${directory.path}${Platform.pathSeparator}generated-tone.wav',
    );
    await file.writeAsBytes(buildDeterministicPcmWav(), flush: true);

    final engine = JustAudioEngine.create(
      useProxyForRequestHeaders: false,
      supportsRequestHeaders: false,
    );
    addTearDown(engine.dispose);
    final observed = <AudioEngineState>[];
    final subscription = engine.states.listen(observed.add);
    addTearDown(subscription.cancel);

    final loadWatch = Stopwatch()..start();
    await engine
        .load(
          PlayableSource.localFile(
            track: TrackRef(
              trackId: 'generated-tone',
              sourceId: 'just-audio-native-poc',
              sourceType: MusicSourceType.local,
            ),
            path: file.path,
          ),
        )
        .timeout(const Duration(seconds: 20));
    loadWatch.stop();
    expect(observed.last.phase, AudioEnginePhase.ready);
    expect(
      observed.any((state) => state.phase == AudioEnginePhase.playing),
      isFalse,
    );

    await engine.setVolume(0.2).timeout(const Duration(seconds: 10));
    await engine.setPlaybackRate(1.25).timeout(const Duration(seconds: 10));
    final progressed = engine.states.firstWhere(
      (state) =>
          state.phase == AudioEnginePhase.playing &&
          state.position >= const Duration(milliseconds: 180),
    );
    final durationKnown = engine.states.firstWhere(
      (state) =>
          state.duration != null &&
          state.duration! >= const Duration(milliseconds: 2900),
    );
    final progressWatch = Stopwatch()..start();
    await engine.play().timeout(const Duration(seconds: 10));
    final playbackEvidence = await Future.wait([
      progressed.timeout(const Duration(seconds: 20)),
      durationKnown.timeout(const Duration(seconds: 20)),
    ]);
    final playingState = playbackEvidence[0];
    final durationState = playbackEvidence[1];
    progressWatch.stop();
    expect(playingState.volume, closeTo(0.2, 0.001));
    expect(playingState.playbackRate, closeTo(1.25, 0.001));

    final seeked = engine.states.firstWhere(
      (state) =>
          state.position >= const Duration(milliseconds: 900) &&
          state.position <= const Duration(milliseconds: 1500),
    );
    final seekWatch = Stopwatch()..start();
    await engine
        .seek(const Duration(seconds: 1))
        .timeout(const Duration(seconds: 10));
    await seeked.timeout(const Duration(seconds: 10));
    seekWatch.stop();

    final paused = engine.states.firstWhere(
      (state) => state.phase == AudioEnginePhase.paused,
    );
    await engine.pause().timeout(const Duration(seconds: 10));
    await paused.timeout(const Duration(seconds: 10));

    final completed = engine.states.firstWhere(
      (state) => state.phase == AudioEnginePhase.completed,
    );
    await engine
        .seek(const Duration(milliseconds: 2500))
        .timeout(const Duration(seconds: 10));
    await engine.play().timeout(const Duration(seconds: 10));
    await completed.timeout(const Duration(seconds: 15));

    await engine.stop().timeout(const Duration(seconds: 10));
    expect(observed.last.phase, AudioEnginePhase.idle);
    expect(observed.last.position, Duration.zero);
    expect(
      observed.any((state) => state.phase == AudioEnginePhase.error),
      isFalse,
    );

    final metrics = <String, Object>{
      'platform': Platform.operatingSystem,
      'loadMs': loadWatch.elapsedMilliseconds,
      'firstProgressMs': progressWatch.elapsedMilliseconds,
      'seekMs': seekWatch.elapsedMilliseconds,
      'durationMs': durationState.duration!.inMilliseconds,
      'completed': true,
      'proxyForHeaders': false,
      'requestHeaders': false,
    };
    binding.reportData = <String, Object>{'nativeAudio': metrics};
    debugPrint('YYMUSIC_JUST_AUDIO_NATIVE_POC ${jsonEncode(metrics)}');
  }, timeout: const Timeout(Duration(minutes: 2)));
}
