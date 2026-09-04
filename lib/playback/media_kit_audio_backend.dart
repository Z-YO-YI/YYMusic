import 'dart:async';

import 'package:media_kit/media_kit.dart';

/// Minimal view of media_kit facts used by the project-owned audio adapter.
/// Plugin objects never cross this playback-layer boundary.
final class MediaKitPlayerSnapshot {
  const MediaKitPlayerSnapshot({
    this.playing = false,
    this.completed = false,
    this.buffering = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.buffer = Duration.zero,
    this.volume = 100,
    this.rate = 1,
  });

  final bool playing;
  final bool completed;
  final bool buffering;
  final Duration position;
  final Duration duration;
  final Duration buffer;
  final double volume;
  final double rate;
}

/// Injectable seam around Player. Tests use a project fake without loading
/// native libraries; production POC code uses [NativeMediaKitPlayerBackend].
abstract interface class MediaKitPlayerBackend {
  MediaKitPlayerSnapshot get current;
  Stream<MediaKitPlayerSnapshot> get snapshots;

  /// Raw plugin messages are discarded inside the native wrapper.
  Stream<void> get errors;

  Future<void> open(
    String resource, {
    required Map<String, String> headers,
    required bool play,
  });
  Future<void> play();
  Future<void> pause();
  Future<void> stop();
  Future<void> seek(Duration position);
  Future<void> setVolume(double value);
  Future<void> setRate(double value);
  Future<void> dispose();
}

/// The only class that talks to package:media_kit's Player.
final class NativeMediaKitPlayerBackend implements MediaKitPlayerBackend {
  factory NativeMediaKitPlayerBackend.create() {
    MediaKit.ensureInitialized();
    return NativeMediaKitPlayerBackend._(Player());
  }

  /// Creates the native backend with libmpv's clock-only audio sink.
  ///
  /// This is restricted to the headless Windows CI POC, whose hosted runner
  /// has no audio endpoint. The normal factory keeps automatic device output.
  static Future<NativeMediaKitPlayerBackend>
  createWithHeadlessAudioSinkForPoc() async {
    MediaKit.ensureInitialized();
    final player = Player();
    final platform = player.platform;
    if (platform is! NativePlayer) {
      await player.dispose();
      throw UnsupportedError('Native media_kit player is unavailable');
    }
    try {
      await platform.setProperty('ao', 'null');
      return NativeMediaKitPlayerBackend._(player);
    } catch (_) {
      await player.dispose();
      rethrow;
    }
  }

  NativeMediaKitPlayerBackend._(this._player) {
    _watch(_player.stream.playing);
    _watch(_player.stream.completed);
    _watch(_player.stream.buffering);
    _watch(_player.stream.position);
    _watch(_player.stream.duration);
    _watch(_player.stream.buffer);
    _watch(_player.stream.volume);
    _watch(_player.stream.rate);
    _subscriptions.add(
      _player.stream.error.listen((_) {
        if (!_disposed) _errors.add(null);
      }),
    );
  }

  final Player _player;
  final _snapshots = StreamController<MediaKitPlayerSnapshot>.broadcast(
    sync: true,
  );
  final _errors = StreamController<void>.broadcast(sync: true);
  final List<StreamSubscription<Object?>> _subscriptions = [];
  bool _disposed = false;

  @override
  MediaKitPlayerSnapshot get current {
    final state = _player.state;
    return MediaKitPlayerSnapshot(
      playing: state.playing,
      completed: state.completed,
      buffering: state.buffering,
      position: state.position,
      duration: state.duration,
      buffer: state.buffer,
      volume: state.volume,
      rate: state.rate,
    );
  }

  @override
  Stream<void> get errors => _errors.stream;

  @override
  Stream<MediaKitPlayerSnapshot> get snapshots => _snapshots.stream;

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

  @override
  Future<void> open(
    String resource, {
    required Map<String, String> headers,
    required bool play,
  }) => _player.open(
    Media(
      resource,
      httpHeaders: headers.isEmpty
          ? null
          : Map<String, String>.unmodifiable(headers),
    ),
    play: play,
  );

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setRate(double value) => _player.setRate(value);

  @override
  Future<void> setVolume(double value) => _player.setVolume(value);

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    for (final subscription in _subscriptions) {
      try {
        await subscription.cancel();
      } catch (_) {
        // Continue releasing the remaining native resources.
      }
    }
    try {
      await _player.dispose();
    } catch (_) {
      // The adapter owns no durable state; shutdown is fail-closed.
    }
    await _snapshots.close();
    await _errors.close();
  }
}
