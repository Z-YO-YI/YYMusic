import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yymusic/domain/models/track.dart';
import 'package:yymusic/playback/audio_engine_state.dart';
import 'package:yymusic/playback/just_audio_engine.dart';
import 'package:yymusic/playback/playable_source.dart';

import 'support/pinned_https_audio_fixture.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'just_audio plays the identity-verified HTTPS fixture without headers',
    (_) async {
      expect(Platform.isAndroid || Platform.isWindows, isTrue);
      expect(kReleaseMode, isFalse);
      await verifyPinnedHttpsFixture().timeout(const Duration(seconds: 45));

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
            PlayableSource.networkStream(
              track: TrackRef(
                trackId: 'pinned-https-wav',
                sourceId: 'just-audio-native-poc',
                sourceType: MusicSourceType.rest,
              ),
              uri: httpsFixtureUri,
            ),
          )
          .timeout(const Duration(seconds: 30));
      loadWatch.stop();
      expect(observed.last.phase, AudioEnginePhase.ready);
      expect(
        observed.any((state) => state.phase == AudioEnginePhase.playing),
        isFalse,
      );
      await engine.setVolume(0.1).timeout(const Duration(seconds: 10));
      await engine.setPlaybackRate(1.25).timeout(const Duration(seconds: 10));
      final progressed = engine.states
          .firstWhere(
            (state) =>
                state.phase == AudioEnginePhase.playing &&
                state.position >= const Duration(milliseconds: 100) &&
                state.duration != null,
          )
          .timeout(const Duration(seconds: 20));
      final progressWatch = Stopwatch()..start();
      await engine.play().timeout(const Duration(seconds: 10));
      final playing = await progressed;
      progressWatch.stop();
      expect(playing.duration!.inMilliseconds, inInclusiveRange(950, 1050));
      expect(playing.volume, closeTo(0.1, 0.001));
      expect(playing.playbackRate, closeTo(1.25, 0.001));
      // Pause before seeking in the short, independently pinned 1-second asset.
      await engine.pause().timeout(const Duration(seconds: 10));
      expect(observed.last.phase, AudioEnginePhase.paused);
      final seeked = engine.states
          .firstWhere(
            (state) =>
                state.position >= const Duration(milliseconds: 400) &&
                state.position <= const Duration(milliseconds: 650),
          )
          .timeout(const Duration(seconds: 10));
      final seekWatch = Stopwatch()..start();
      await engine
          .seek(const Duration(milliseconds: 500))
          .timeout(const Duration(seconds: 10));
      await seeked;
      seekWatch.stop();
      final completed = engine.states
          .firstWhere((state) => state.phase == AudioEnginePhase.completed)
          .timeout(const Duration(seconds: 20));
      await engine.play().timeout(const Duration(seconds: 10));
      await completed;
      await engine.stop().timeout(const Duration(seconds: 10));
      expect(observed.last.phase, AudioEnginePhase.idle);
      expect(observed.last.position, Duration.zero);
      expect(observed.any((state) => state.failure != null), isFalse);
      await engine.dispose().timeout(const Duration(seconds: 10));
      expect(engine.isAvailable, isFalse);

      final metrics = <String, Object>{
        'platform': Platform.operatingSystem,
        'loadMs': loadWatch.elapsedMilliseconds,
        'firstProgressMs': progressWatch.elapsedMilliseconds,
        'seekMs': seekWatch.elapsedMilliseconds,
        'durationMs': playing.duration!.inMilliseconds,
        'fixtureSha256': httpsFixtureSha256,
        'fixtureVerified': true,
        'rangeVerified': true,
        'completed': true,
        'disposed': true,
        'proxyForHeaders': false,
        'requestHeaders': false,
      };
      binding.reportData = <String, dynamic>{
        ...?binding.reportData,
        'nativeHttps': metrics,
      };
      debugPrint('YYMUSIC_JUST_AUDIO_HTTPS_POC ${jsonEncode(metrics)}');
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
