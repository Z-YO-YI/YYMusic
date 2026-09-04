import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yymusic/domain/models/track.dart';
import 'package:yymusic/playback/audio_engine_state.dart';
import 'package:yymusic/playback/media_kit_audio_engine.dart';
import 'package:yymusic/playback/playable_source.dart';

import 'support/deterministic_pcm_wav.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('native backend decodes and controls a generated local WAV', (
    _,
  ) async {
    expect(Platform.isWindows || Platform.isAndroid, isTrue);
    final directory = await Directory.systemTemp.createTemp(
      'yymusic-native-audio-poc-',
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

    final engine = MediaKitAudioEngine.create();
    addTearDown(engine.dispose);
    final observed = <AudioEngineState>[];
    final subscription = engine.states.listen(observed.add);
    addTearDown(subscription.cancel);

    final ready = engine.states.firstWhere(
      (state) =>
          state.phase == AudioEnginePhase.ready &&
          state.duration != null &&
          state.duration! >= const Duration(milliseconds: 2900),
    );
    final loadWatch = Stopwatch()..start();
    await engine
        .load(
          PlayableSource.localFile(
            track: TrackRef(
              trackId: 'generated-tone',
              sourceId: 'native-audio-poc',
              sourceType: MusicSourceType.local,
            ),
            path: file.path,
          ),
        )
        .timeout(const Duration(seconds: 20));
    final readyState = await ready.timeout(const Duration(seconds: 20));
    loadWatch.stop();
    expect(readyState.phase, AudioEnginePhase.ready);
    expect(
      observed.any((state) => state.phase == AudioEnginePhase.playing),
      isFalse,
    );

    await engine.setVolume(0.2);
    await engine.setPlaybackRate(1.25);
    final progressed = engine.states.firstWhere(
      (state) =>
          state.phase == AudioEnginePhase.playing &&
          state.position >= const Duration(milliseconds: 180),
    );
    final progressWatch = Stopwatch()..start();
    await engine.play().timeout(const Duration(seconds: 10));
    final playingState = await progressed.timeout(const Duration(seconds: 20));
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
    await engine.seek(const Duration(milliseconds: 2500));
    await engine.play();
    await completed.timeout(const Duration(seconds: 15));

    await engine.stop().timeout(const Duration(seconds: 10));
    expect(observed.last.phase, AudioEnginePhase.idle);
    expect(observed.last.position, Duration.zero);
    expect(
      observed.any((state) => state.phase == AudioEnginePhase.error),
      isFalse,
    );

    debugPrint(
      'YYMUSIC_NATIVE_AUDIO_POC ${jsonEncode({'platform': Platform.operatingSystem, 'loadMs': loadWatch.elapsedMilliseconds, 'firstProgressMs': progressWatch.elapsedMilliseconds, 'seekMs': seekWatch.elapsedMilliseconds, 'durationMs': readyState.duration!.inMilliseconds, 'completed': true})}',
    );
  }, timeout: const Timeout(Duration(minutes: 2)));
}
