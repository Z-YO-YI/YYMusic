import 'dart:async';

import 'package:just_audio/just_audio.dart';

/// Project-owned processing phases exposed by the just_audio candidate seam.
enum JustAudioProcessingPhase { idle, loading, buffering, ready, completed }

/// Minimal immutable view of player facts used by [JustAudioEngine].
final class JustAudioPlayerSnapshot {
  const JustAudioPlayerSnapshot({
    this.playing = false,
    this.processing = JustAudioProcessingPhase.idle,
    this.position = Duration.zero,
    this.duration,
    this.buffered = Duration.zero,
    this.volume = 1,
    this.speed = 1,
  });

  final bool playing;
  final JustAudioProcessingPhase processing;
  final Duration position;
  final Duration? duration;
  final Duration buffered;
  final double volume;
  final double speed;
}

/// Injectable seam around just_audio. Plugin types stay inside this file.
abstract interface class JustAudioPlayerBackend {
  JustAudioPlayerSnapshot get current;
  bool get supportsRequestHeaders;
  Stream<JustAudioPlayerSnapshot> get snapshots;

  /// Raw plugin failures are discarded by the native wrapper.
  Stream<void> get errors;

  Future<void> open(Uri resource, {required Map<String, String> headers});
  Future<void> play();
  Future<void> pause();
  Future<void> stop();
  Future<void> seek(Duration position);
  Future<void> setVolume(double value);
  Future<void> setSpeed(double value);
  Future<void> dispose();
}

/// The only class that talks to package:just_audio.
///
/// [useProxyForRequestHeaders] is explicit because the selected Windows WinRT
/// implementation cannot attach headers directly. Production selection is not
/// made by this factory; Phase 4E uses it only from an isolated POC.
final class NativeJustAudioPlayerBackend implements JustAudioPlayerBackend {
  factory NativeJustAudioPlayerBackend.create({
    required bool useProxyForRequestHeaders,
    required bool supportsRequestHeaders,
  }) => NativeJustAudioPlayerBackend._(
    AudioPlayer(useProxyForRequestHeaders: useProxyForRequestHeaders),
    supportsRequestHeaders: supportsRequestHeaders,
  );

  NativeJustAudioPlayerBackend._(
    this._player, {
    required this.supportsRequestHeaders,
  }) {
    _watch(_player.playingStream);
    _watch(_player.processingStateStream);
    _watch(_player.positionStream);
    _watch(_player.durationStream);
    _watch(_player.bufferedPositionStream);
    _watch(_player.volumeStream);
    _watch(_player.speedStream);
    _subscriptions.add(
      _player.errorStream.listen(
        (_) {
          if (!_disposed) _errors.add(null);
        },
        onError: (Object _, StackTrace _) {
          if (!_disposed) _errors.add(null);
        },
      ),
    );
  }

  final AudioPlayer _player;
  @override
  final bool supportsRequestHeaders;
  final _snapshots = StreamController<JustAudioPlayerSnapshot>.broadcast(
    sync: true,
  );
  final _errors = StreamController<void>.broadcast(sync: true);
  final List<StreamSubscription<Object?>> _subscriptions = [];
  bool _disposed = false;

  @override
  JustAudioPlayerSnapshot get current => JustAudioPlayerSnapshot(
    playing: _player.playing,
    processing: _processing(_player.processingState),
    position: _player.position,
    duration: _player.duration,
    buffered: _player.bufferedPosition,
    volume: _player.volume,
    speed: _player.speed,
  );

  @override
  Stream<void> get errors => _errors.stream;

  @override
  Stream<JustAudioPlayerSnapshot> get snapshots => _snapshots.stream;

  void _watch<T>(Stream<T> stream) {
    _subscriptions.add(
      stream.listen(
        (_) {
          if (_disposed) return;
          try {
            _snapshots.add(current);
          } catch (_) {
            _errors.add(null);
          }
        },
        onError: (Object _, StackTrace _) {
          if (!_disposed) _errors.add(null);
        },
      ),
    );
  }

  JustAudioProcessingPhase _processing(ProcessingState value) =>
      switch (value) {
        ProcessingState.idle => JustAudioProcessingPhase.idle,
        ProcessingState.loading => JustAudioProcessingPhase.loading,
        ProcessingState.buffering => JustAudioProcessingPhase.buffering,
        ProcessingState.ready => JustAudioProcessingPhase.ready,
        ProcessingState.completed => JustAudioProcessingPhase.completed,
      };

  @override
  Future<void> open(
    Uri resource, {
    required Map<String, String> headers,
  }) async {
    if (headers.isNotEmpty && !supportsRequestHeaders) {
      throw UnsupportedError('Request headers are unavailable');
    }
    final ephemeralHeaders = headers.isEmpty
        ? null
        : Map<String, String>.unmodifiable(headers);
    await _player.setAudioSource(
      AudioSource.uri(resource, headers: ephemeralHeaders),
      preload: true,
      initialPosition: Duration.zero,
    );
  }

  @override
  Future<void> play() async {
    final request = _player.play();
    unawaited(
      request.then<void>(
        (_) {},
        onError: (Object _, StackTrace _) {
          if (!_disposed) _errors.add(null);
        },
      ),
    );
    // just_audio's play Future completes on pause/stop/end. AudioEngine.play
    // instead acknowledges the start request so its serialized queue can move.
    await Future<void>.delayed(Duration.zero);
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setVolume(double value) => _player.setVolume(value);

  @override
  Future<void> setSpeed(double value) => _player.setSpeed(value);

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    for (final subscription in _subscriptions) {
      try {
        await subscription.cancel();
      } catch (_) {
        // Continue releasing the remaining candidate resources.
      }
    }
    try {
      await _player.dispose();
    } catch (_) {
      // Candidate shutdown must not expose raw plugin errors.
    }
    await _snapshots.close();
    await _errors.close();
  }
}
