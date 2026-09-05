import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:yymusic/domain/models/domain_failure.dart';
import 'package:yymusic/domain/models/track.dart';
import 'package:yymusic/playback/audio_engine_state.dart';
import 'package:yymusic/playback/just_audio_engine.dart';
import 'package:yymusic/playback/playable_source.dart';

import 'just_audio_native_local_poc_test.dart' as native_local;
import 'support/deterministic_pcm_wav.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // Keep the original cross-platform baseline, including its teardown checks.
  native_local.main();

  testWidgets(
    'Android content source fails safely and recovers on the same engine',
    (_) async {
      expect(Platform.isAndroid && kDebugMode, isTrue);
      final cache = await getTemporaryDirectory();
      final fixture = File('${cache.path}/native-audio-poc-content.wav');
      // A stale file is a failed precondition, never permission to overwrite it.
      expect(await fixture.exists(), isFalse);
      var createdFixture = false;
      addTearDown(() async {
        if (createdFixture && await fixture.exists()) {
          await fixture.delete();
        }
      });

      final engine = JustAudioEngine.create(
        useProxyForRequestHeaders: false,
        supportsRequestHeaders: false,
      );
      addTearDown(engine.dispose);
      final observed = <AudioEngineState>[];
      final statesClosed = Completer<void>();
      final subscription = engine.states.listen(
        observed.add,
        onDone: statesClosed.complete,
      );
      addTearDown(subscription.cancel);
      final source = PlayableSource.contentUri(
        track: TrackRef(
          trackId: 'generated-content-tone',
          sourceId: 'just-audio-native-poc',
          sourceType: MusicSourceType.local,
        ),
        uri: Uri.parse(
          'content://io.github.z_y_o_y_i.yymusic.native-audio-poc/generated-tone.wav',
        ),
      );

      await expectLater(
        engine.load(source).timeout(const Duration(seconds: 20)),
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
                'audio.just-audio.open',
              ),
        ),
      );
      expect(observed.last.phase, AudioEnginePhase.error);
      expect(observed.last.failure.toString(), isNot(contains('content://')));
      expect(
        observed.any((state) => state.phase == AudioEnginePhase.playing),
        isFalse,
      );

      await fixture.create(exclusive: true);
      createdFixture = true;
      await fixture.writeAsBytes(buildDeterministicPcmWav(), flush: true);
      observed.clear();
      final loadWatch = Stopwatch()..start();
      await engine.load(source).timeout(const Duration(seconds: 20));
      loadWatch.stop();
      expect(observed.last.phase, AudioEnginePhase.ready);
      expect(observed.last.failure, isNull);
      expect(
        observed.any((state) => state.phase == AudioEnginePhase.playing),
        isFalse,
      );

      await engine.setVolume(0.2).timeout(const Duration(seconds: 10));
      await engine.setPlaybackRate(1.25).timeout(const Duration(seconds: 10));
      final progressed = engine.states
          .firstWhere(
            (state) =>
                state.phase == AudioEnginePhase.playing &&
                state.position >= const Duration(milliseconds: 180) &&
                state.duration != null,
          )
          .timeout(const Duration(seconds: 20));
      final progressWatch = Stopwatch()..start();
      await engine.play().timeout(const Duration(seconds: 10));
      final playing = await progressed;
      progressWatch.stop();
      expect(playing.volume, closeTo(0.2, 0.001));
      expect(playing.playbackRate, closeTo(1.25, 0.001));
      expect(playing.duration!.inMilliseconds, inInclusiveRange(2900, 3100));

      final seeked = engine.states
          .firstWhere(
            (state) =>
                state.position >= const Duration(milliseconds: 900) &&
                state.position <= const Duration(milliseconds: 1500),
          )
          .timeout(const Duration(seconds: 10));
      final seekWatch = Stopwatch()..start();
      await engine
          .seek(const Duration(seconds: 1))
          .timeout(const Duration(seconds: 10));
      await seeked;
      seekWatch.stop();
      final paused = engine.states
          .firstWhere((state) => state.phase == AudioEnginePhase.paused)
          .timeout(const Duration(seconds: 10));
      await engine.pause().timeout(const Duration(seconds: 10));
      await paused;

      final completed = engine.states
          .firstWhere((state) => state.phase == AudioEnginePhase.completed)
          .timeout(const Duration(seconds: 15));
      await engine
          .seek(const Duration(milliseconds: 2500))
          .timeout(const Duration(seconds: 10));
      await engine.play().timeout(const Duration(seconds: 10));
      await completed;
      await engine.stop().timeout(const Duration(seconds: 10));
      expect(observed.last.phase, AudioEnginePhase.idle);
      expect(observed.last.position, Duration.zero);
      expect(observed.any((state) => state.failure != null), isFalse);
      await engine.dispose().timeout(const Duration(seconds: 10));
      await statesClosed.future.timeout(const Duration(seconds: 10));
      expect(engine.isAvailable, isFalse);

      // Only synthetic timing/state evidence; no URI, path or plugin error text.
      final metrics = <String, Object>{
        'platform': Platform.operatingSystem,
        'loadMs': loadWatch.elapsedMilliseconds,
        'firstProgressMs': progressWatch.elapsedMilliseconds,
        'seekMs': seekWatch.elapsedMilliseconds,
        'durationMs': playing.duration!.inMilliseconds,
        'missingSourceRejected': true,
        'sameEngineRecovered': true,
        'completed': true,
        'disposed': true,
        'proxyForHeaders': false,
        'requestHeaders': false,
      };
      binding.reportData = <String, dynamic>{
        ...?binding.reportData,
        'nativeContent': metrics,
      };
      debugPrint(
        'YYMUSIC_JUST_AUDIO_ANDROID_CONTENT_POC ${jsonEncode(metrics)}',
      );
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
