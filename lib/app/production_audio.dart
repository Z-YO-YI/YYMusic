import '../platform/audio_output/native_audio_output_gateway.dart';
import '../platform/contracts/audio_output_gateway.dart';
import '../playback/audio_engine.dart';
import '../playback/just_audio_engine.dart';
import '../playback/local_playback_source_resolver.dart';
import '../playback/playback_source_resolver.dart';
import 'layout_class.dart';

typedef AudioEngineFactory = Future<AudioEngine> Function(YYPlatform platform);
typedef AudioOutputGatewayFactory = AudioOutputGateway Function(
  YYPlatform platform,
);

AudioOutputGateway createProductionAudioOutputGateway(YYPlatform platform) =>
    NativeAudioOutputGateway();

/// ADR-044: one root-owned engine, with neither an HTTP proxy nor header support.
Future<AudioEngine> createProductionAudioEngine(YYPlatform platform) async =>
    JustAudioEngine.create(
      useProxyForRequestHeaders: false,
      supportsRequestHeaders: false,
    );

Future<AudioEngine> createUnavailableAudioEngine(YYPlatform platform) async =>
    UnavailableAudioEngine();

PlaybackSourceResolver createProductionSourceResolver(YYPlatform platform) =>
    switch (platform) {
      YYPlatform.android => const LocalPlaybackSourceResolver.android(),
      YYPlatform.windows => const LocalPlaybackSourceResolver.windows(),
    };
