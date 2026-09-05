import 'dart:async';

import 'package:yymusic/playback/audio_engine.dart';
import 'package:yymusic/playback/audio_engine_state.dart';
import 'package:yymusic/playback/playable_source.dart';

final class FakeAudioEngine implements AudioEngine {
  FakeAudioEngine({this.duration = const Duration(minutes: 3)});

  final events = StreamController<AudioEngineState>.broadcast(sync: true);
  final List<String> calls = [];
  final Duration? duration;
  PlayableSource? loadedSource;
  Object? loadError;
  Object? stopError;
  Object? stateStreamError;
  Object? disposeError;
  Future<void>? loadGate;
  Duration position = Duration.zero;
  Duration buffered = Duration.zero;
  double volume = 1;
  double playbackRate = 1;
  int disposalCount = 0;

  @override
  bool get isAvailable => true;
  @override
  Stream<AudioEngineState> get states {
    final error = stateStreamError;
    if (error != null) throw error;
    return events.stream;
  }

  @override
  Future<void> load(PlayableSource source) async {
    calls.add('load');
    await loadGate;
    final error = loadError;
    if (error != null) throw error;
    loadedSource = source;
    position = Duration.zero;
    buffered = Duration.zero;
    _emit(AudioEnginePhase.loading);
    _emit(AudioEnginePhase.ready);
  }

  @override
  Future<void> play() async {
    calls.add('play');
    if (loadedSource == null) throw StateError('No audio source is loaded');
    _emit(AudioEnginePhase.playing);
  }

  @override
  Future<void> pause() async {
    calls.add('pause');
    _emit(AudioEnginePhase.paused);
  }

  @override
  Future<void> stop() async {
    calls.add('stop');
    final error = stopError;
    if (error != null) throw error;
    loadedSource = null;
    position = Duration.zero;
    buffered = Duration.zero;
    _emit(AudioEnginePhase.idle);
  }

  @override
  Future<void> seek(Duration value) async {
    calls.add('seek:${value.inMilliseconds}');
    position = value;
    _emit(AudioEnginePhase.paused);
  }

  @override
  Future<void> setVolume(double value) async {
    calls.add('volume:$value');
    volume = value;
    _emit(AudioEnginePhase.paused);
  }

  @override
  Future<void> setPlaybackRate(double value) async {
    calls.add('rate:$value');
    playbackRate = value;
    _emit(AudioEnginePhase.paused);
  }

  @override
  Future<void> dispose() async {
    disposalCount++;
    await events.close();
    final error = disposeError;
    if (error != null) throw error;
  }

  void complete() => _emit(AudioEnginePhase.completed);

  void _emit(AudioEnginePhase phase) => events.add(
    AudioEngineState(
      phase: phase,
      position: position,
      buffered: buffered,
      duration: duration,
      volume: volume,
      playbackRate: playbackRate,
    ),
  );
}
