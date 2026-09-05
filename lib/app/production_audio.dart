import '../playback/audio_engine.dart';
import '../playback/just_audio_engine.dart';
import '../playback/local_playback_source_resolver.dart';
import '../playback/playback_source_resolver.dart';
import 'layout_class.dart';

typedef AudioEngineFactory = Future<AudioEngine> Function(YYPlatform platform);

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
