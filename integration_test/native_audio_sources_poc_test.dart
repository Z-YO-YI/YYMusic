import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:yymusic/domain/models/domain_failure.dart';
import 'package:yymusic/domain/models/track.dart';
import 'package:yymusic/playback/audio_engine_state.dart';
import 'package:yymusic/playback/media_kit_audio_engine.dart';
import 'package:yymusic/playback/network_playable_source_probe.dart';
import 'package:yymusic/playback/playable_source.dart';

import 'support/controlled_https_audio_server.dart';
import 'support/deterministic_pcm_wav.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('validates native content and controlled HTTPS sources', (
    _,
  ) async {
    expect(Platform.isWindows || Platform.isAndroid, isTrue);
    final server = await ControlledHttpsAudioServer.start();
    addTearDown(server.close);
    final networkSource = _networkSource(server.uri('/audio.wav'));
    final probe = NetworkPlayableSourceProbe(
      DartIoNetworkHeadTransport(clientFactory: server.trustedClient),
    );

    await probe.validate(networkSource);
    expect(server.expectedHeaderCount, 1);
    await _verifyFailureMatrix(server);

    server.resetAudioRequestCounters();
    final networkEngine = await MediaKitAudioEngine.createForControlledHttpsPoc(
      headlessAudio: Platform.isWindows,
    );
    final networkMetrics = await _exerciseNativeSource(
      networkEngine,
      networkSource,
    );
    await networkEngine.dispose();
    expect(server.audioGetCount, greaterThan(0));
    expect(server.expectedHeaderCount, greaterThan(0));

    _NativeMetrics? contentMetrics;
    if (Platform.isAndroid) {
      final temporaryDirectory = await getTemporaryDirectory();
      final contentFixture = File(
        '${temporaryDirectory.path}${Platform.pathSeparator}'
        'native-audio-poc-content.wav',
      );
      await contentFixture.writeAsBytes(
        buildDeterministicPcmWav(),
        flush: true,
      );
      addTearDown(() async {
        if (await contentFixture.exists()) await contentFixture.delete();
      });
      final contentEngine = MediaKitAudioEngine.create();
      contentMetrics = await _exerciseNativeSource(
        contentEngine,
        PlayableSource.contentUri(
          track: _contentTrack,
          uri: Uri.parse(
            'content://io.github.z_y_o_y_i.yymusic.native-audio-poc/'
            'generated-tone.wav',
          ),
        ),
      );
      await contentEngine.dispose();
    }

    debugPrint(
      'YYMUSIC_NATIVE_AUDIO_SOURCES_POC ${jsonEncode({'platform': Platform.operatingSystem, 'httpsLoadMs': networkMetrics.loadMs, 'httpsFirstProgressMs': networkMetrics.firstProgressMs, 'httpsSeekMs': networkMetrics.seekMs, 'httpsCompleted': true, 'contentApplicable': Platform.isAndroid, 'contentLoadMs': contentMetrics?.loadMs, 'contentFirstProgressMs': contentMetrics?.firstProgressMs, 'contentSeekMs': contentMetrics?.seekMs, 'contentCompleted': contentMetrics != null, 'failureMatrix': true})}',
    );
  }, timeout: const Timeout(Duration(minutes: 5)));
}

Future<void> _verifyFailureMatrix(ControlledHttpsAudioServer server) async {
  final probe = NetworkPlayableSourceProbe(
    DartIoNetworkHeadTransport(clientFactory: server.trustedClient),
  );
  final statuses = <String, DomainFailureCode>{
    '/status/401': DomainFailureCode.unauthorized,
    '/status/403': DomainFailureCode.forbidden,
    '/status/404': DomainFailureCode.notFound,
    '/status/429': DomainFailureCode.rateLimited,
    '/status/503': DomainFailureCode.serverError,
  };
  for (final entry in statuses.entries) {
    await _expectFailure(
      NetworkPlayableSourceProbe(
        DartIoNetworkHeadTransport(clientFactory: server.trustedClient),
      ),
      _networkSource(server.uri(entry.key)),
      entry.value,
    );
  }
  await _expectFailure(
    NetworkPlayableSourceProbe(
      DartIoNetworkHeadTransport(clientFactory: server.trustedClient),
      timeout: const Duration(milliseconds: 150),
    ),
    _networkSource(server.uri('/timeout')),
    DomainFailureCode.networkTimeout,
  );
  await _expectFailure(
    NetworkPlayableSourceProbe(DartIoNetworkHeadTransport()),
    _networkSource(server.uri('/audio.wav')),
    DomainFailureCode.tlsFailed,
  );

  final closedSocket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final closedPort = closedSocket.port;
  await closedSocket.close();
  await _expectFailure(
    probe,
    _networkSource(
      Uri(
        scheme: 'https',
        host: InternetAddress.loopbackIPv4.address,
        port: closedPort,
        path: '/offline',
      ),
    ),
    DomainFailureCode.networkOffline,
  );
}

Future<void> _expectFailure(
  NetworkPlayableSourceProbe probe,
  PlayableSource source,
  DomainFailureCode expected,
) async {
  try {
    await probe.validate(source);
  } on DomainFailure catch (failure) {
    expect(failure.code, expected);
    expect(failure.toString(), isNot(contains('127.0.0.1')));
    expect(failure.toString(), isNot(contains(pocRequestHeaderValue)));
    return;
  }
  throw TestFailure('Expected ${expected.name}');
}

Future<_NativeMetrics> _exerciseNativeSource(
  MediaKitAudioEngine engine,
  PlayableSource source,
) async {
  final observed = <AudioEngineState>[];
  final subscription = engine.states.listen(observed.add);
  try {
    final ready = engine.states.firstWhere(
      (state) =>
          state.phase == AudioEnginePhase.ready &&
          state.duration != null &&
          state.duration! >= const Duration(milliseconds: 2900),
    );
    final loadWatch = Stopwatch()..start();
    await engine.load(source).timeout(const Duration(seconds: 30));
    final readyState = await ready.timeout(const Duration(seconds: 30));
    loadWatch.stop();
    expect(readyState.duration, const Duration(seconds: 3));
    expect(
      observed.any((state) => state.phase == AudioEnginePhase.playing),
      isFalse,
    );

    await engine.setVolume(0);
    final progressed = engine.states.firstWhere(
      (state) =>
          state.phase == AudioEnginePhase.playing &&
          state.position >= const Duration(milliseconds: 180),
    );
    final progressWatch = Stopwatch()..start();
    await engine.play().timeout(const Duration(seconds: 10));
    await progressed.timeout(const Duration(seconds: 20));
    progressWatch.stop();

    final seeked = engine.states.firstWhere(
      (state) =>
          state.position >= const Duration(milliseconds: 900) &&
          state.position <= const Duration(milliseconds: 1500),
    );
    final seekWatch = Stopwatch()..start();
    await engine.seek(const Duration(seconds: 1));
    await seeked.timeout(const Duration(seconds: 10));
    seekWatch.stop();

    final completed = engine.states.firstWhere(
      (state) => state.phase == AudioEnginePhase.completed,
    );
    await engine.seek(const Duration(milliseconds: 2500));
    await engine.play();
    await completed.timeout(const Duration(seconds: 15));
    await engine.stop();
    expect(observed.last.phase, AudioEnginePhase.idle);
    expect(
      observed.any((state) => state.phase == AudioEnginePhase.error),
      isFalse,
    );
    return (
      loadMs: loadWatch.elapsedMilliseconds,
      firstProgressMs: progressWatch.elapsedMilliseconds,
      seekMs: seekWatch.elapsedMilliseconds,
    );
  } finally {
    await subscription.cancel();
  }
}

PlayableSource _networkSource(Uri uri) => PlayableSource.networkStream(
  track: _networkTrack,
  uri: uri,
  headers: const {pocRequestHeaderName: pocRequestHeaderValue},
);

final _networkTrack = TrackRef(
  trackId: 'controlled-network-tone',
  sourceId: 'native-audio-source-poc',
  sourceType: MusicSourceType.rest,
);

final _contentTrack = TrackRef(
  trackId: 'controlled-content-tone',
  sourceId: 'native-audio-content-poc',
  sourceType: MusicSourceType.local,
);

typedef _NativeMetrics = ({int loadMs, int firstProgressMs, int seekMs});
