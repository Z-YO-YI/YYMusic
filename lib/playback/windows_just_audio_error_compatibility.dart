import 'dart:async';

import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';
import 'package:just_audio_platform_interface/method_channel_just_audio.dart';

/// Bridges the pinned Windows plugin's legacy error envelopes (ADR-144).
///
/// Called before creating a player. Other platforms and custom registrations
/// remain untouched; repeated calls do not wrap an already adapted platform.
void configureWindowsJustAudioErrors({required bool isWindows}) {
  if (!isWindows ||
      JustAudioPlatform.instance.runtimeType != MethodChannelJustAudio) {
    return;
  }
  JustAudioPlatform.instance = _WindowsErrorPlatform();
}

final class _WindowsErrorPlatform extends MethodChannelJustAudio {
  @override
  Future<AudioPlayerPlatform> init(InitRequest request) async {
    // The default init sends the native request but subscribes to no streams.
    await super.init(request);
    return _WindowsErrorPlayer(request.id);
  }
}

final class _WindowsErrorPlayer extends MethodChannelAudioPlayer {
  _WindowsErrorPlayer(super.id);

  late final Stream<PlaybackEventMessage> _events = _createEvents();

  @override
  Stream<PlaybackEventMessage> get playbackEventMessageStream => _events;

  Stream<PlaybackEventMessage> _createEvents() {
    PlaybackEventMessage? previous;
    return super.playbackEventMessageStream.transform(
      StreamTransformer<
        PlaybackEventMessage,
        PlaybackEventMessage
      >.fromHandlers(
        handleData: (event, sink) {
          previous = event;
          sink.add(event);
        },
        handleError: (Object _, StackTrace _, sink) {
          // just_audio 0.10 consumes structured error fields, not stream errors.
          // Never forward a native message, details, locator or stack trace.
          sink.add(
            PlaybackEventMessage(
              processingState: ProcessingStateMessage.idle,
              updateTime: DateTime.now(),
              updatePosition: previous?.updatePosition ?? Duration.zero,
              bufferedPosition: previous?.bufferedPosition ?? Duration.zero,
              duration: previous?.duration,
              icyMetadata: null,
              currentIndex: previous?.currentIndex,
              androidAudioSessionId: null,
              errorCode: -1,
              errorMessage: 'Windows audio playback failed',
            ),
          );
        },
      ),
    );
  }
}
