import 'dart:async';

import 'package:yymusic/playback/audio_engine.dart';
import 'package:yymusic/playback/playback_state.dart';

final class FakeAudioEngine implements AudioEngine {
  final events = StreamController<PlaybackState>.broadcast(sync: true);
  int disposalCount = 0;
  @override
  bool get isAvailable => true;
  @override
  Stream<PlaybackState> get states => events.stream;
  @override
  Future<void> play() async =>
      events.add(const PlaybackState(phase: PlaybackPhase.playing));
  @override
  Future<void> pause() async =>
      events.add(const PlaybackState(phase: PlaybackPhase.paused));
  @override
  Future<void> dispose() async {
    disposalCount++;
    await events.close();
  }
}
