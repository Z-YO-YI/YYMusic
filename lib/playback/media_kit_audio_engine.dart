import 'dart:async';

import '../domain/models/domain_failure.dart';
import 'audio_engine.dart';
import 'audio_engine_state.dart';
import 'media_kit_audio_backend.dart';
import 'playable_source.dart';

/// Candidate Phase 4 backend. It is not wired into production bootstrap until
/// the Android and Windows native POC and redistribution review both pass.
final class MediaKitAudioEngine implements AudioEngine {
  factory MediaKitAudioEngine.create() =>
      MediaKitAudioEngine(NativeMediaKitPlayerBackend.create());

  /// Headless Windows POC only; production keeps automatic device output.
  static Future<MediaKitAudioEngine>
  createWithHeadlessAudioSinkForPoc() async => MediaKitAudioEngine(
    await NativeMediaKitPlayerBackend.createWithHeadlessAudioSinkForPoc(),
  );

  /// Controlled self-signed loopback HTTPS only; production verifies TLS.
  static Future<MediaKitAudioEngine> createForControlledHttpsPoc({
    required bool headlessAudio,
  }) async => MediaKitAudioEngine(
    await NativeMediaKitPlayerBackend.createForControlledHttpsPoc(
      headlessAudio: headlessAudio,
    ),
  );

  MediaKitAudioEngine(this._backend) {
    _snapshotSubscription = _backend.snapshots.listen(
      _acceptSnapshot,
      onError: (Object _, StackTrace _) => _publishAsyncFailure(),
    );
    _errorSubscription = _backend.errors.listen(
      (_) => _publishAsyncFailure(),
      onError: (Object _, StackTrace _) => _publishAsyncFailure(),
    );
  }

  final MediaKitPlayerBackend _backend;
  final _states = StreamController<AudioEngineState>.broadcast(sync: true);
  late final StreamSubscription<MediaKitPlayerSnapshot> _snapshotSubscription;
  late final StreamSubscription<void> _errorSubscription;
  Future<void> _operationTail = Future<void>.value();
  Future<void>? _disposeFuture;
  bool _closing = false;
  bool _loaded = false;
  bool _loading = false;
  bool _hasPlayed = false;
  DomainFailure? _failure;

  @override
  bool get isAvailable => !_closing;

  @override
  Stream<AudioEngineState> get states => _states.stream;

  @override
  Future<void> load(PlayableSource source) => _enqueue(() async {
    _failure = null;
    _loaded = true;
    _loading = true;
    _hasPlayed = false;
    _publish(
      AudioEngineState(
        phase: AudioEnginePhase.loading,
        volume: _volume(_backend.current.volume),
        playbackRate: _rate(_backend.current.rate),
      ),
    );
    try {
      await _backend.open(
        _resource(source),
        headers: source.kind == PlayableSourceKind.networkStream
            ? source.headers
            : const {},
        play: false,
      );
      _loading = false;
      _acceptSnapshot(_backend.current);
    } catch (_) {
      _loading = false;
      _loaded = false;
      final failure = _commandFailure(
        DomainFailureCode.playbackOpenFailed,
        'open',
      );
      _publishFailure(failure);
      throw failure;
    }
  });

  @override
  Future<void> play() => _command('play', () async {
    _requireLoaded();
    await _backend.play();
    _hasPlayed = true;
    _acceptSnapshot(_backend.current);
  });

  @override
  Future<void> pause() => _command('pause', () async {
    _requireLoaded();
    await _backend.pause();
    _hasPlayed = true;
    _acceptSnapshot(_backend.current);
  });

  @override
  Future<void> stop() => _command('stop', () async {
    _loaded = false;
    _loading = false;
    _hasPlayed = false;
    await _backend.stop();
    _failure = null;
    _publish(
      AudioEngineState(
        volume: _volume(_backend.current.volume),
        playbackRate: _rate(_backend.current.rate),
      ),
    );
  });

  @override
  Future<void> seek(Duration position) {
    if (position.isNegative) {
      return Future.error(
        ArgumentError.value(position, 'position', 'must not be negative'),
      );
    }
    return _command('seek', () async {
      _requireLoaded();
      await _backend.seek(position);
      _acceptSnapshot(_backend.current);
    });
  }

  @override
  Future<void> setVolume(double value) {
    if (!value.isFinite || value < 0 || value > 1) {
      return Future.error(
        ArgumentError.value(value, 'value', 'must be between 0 and 1'),
      );
    }
    return _command('volume', () async {
      await _backend.setVolume(value * 100);
      _acceptSnapshot(_backend.current);
    });
  }

  @override
  Future<void> setPlaybackRate(double value) {
    if (!value.isFinite || value < 0.5 || value > 2) {
      return Future.error(
        ArgumentError.value(value, 'value', 'must be between 0.5 and 2'),
      );
    }
    return _command('rate', () async {
      await _backend.setRate(value);
      _acceptSnapshot(_backend.current);
    });
  }

  Future<void> _command(String operation, Future<void> Function() callback) =>
      _enqueue(() async {
        _failure = null;
        try {
          await callback();
        } catch (_) {
          final failure = _commandFailure(
            DomainFailureCode.playbackInterrupted,
            operation,
          );
          _publishFailure(failure);
          throw failure;
        }
      });

  Future<void> _enqueue(Future<void> Function() callback) {
    if (_closing) {
      return Future.error(StateError('AudioEngine is disposed'));
    }
    final operation = _operationTail.then((_) => callback());
    _operationTail = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }

  String _resource(PlayableSource source) => switch (source.kind) {
    PlayableSourceKind.localFile => _fileUri(source.localPath!),
    PlayableSourceKind.contentUri ||
    PlayableSourceKind.networkStream => source.uri!.toString(),
  };

  String _fileUri(String path) {
    final windowsPath =
        RegExp(r'^[A-Za-z]:[\\/]').hasMatch(path) || path.startsWith(r'\\');
    return Uri.file(path, windows: windowsPath).toString();
  }

  void _acceptSnapshot(MediaKitPlayerSnapshot snapshot) {
    if (_closing) return;
    if (snapshot.playing) _hasPlayed = true;
    final failure = _failure;
    final phase = failure != null ? AudioEnginePhase.error : _phase(snapshot);
    _publish(
      AudioEngineState(
        phase: phase,
        position: _duration(snapshot.position),
        buffered: _duration(snapshot.buffer),
        duration: snapshot.duration > Duration.zero
            ? _duration(snapshot.duration)
            : null,
        volume: _volume(snapshot.volume),
        playbackRate: _rate(snapshot.rate),
        failure: failure,
      ),
    );
  }

  AudioEnginePhase _phase(MediaKitPlayerSnapshot snapshot) {
    if (!_loaded) return AudioEnginePhase.idle;
    if (_loading) return AudioEnginePhase.loading;
    if (snapshot.completed) return AudioEnginePhase.completed;
    if (snapshot.buffering) return AudioEnginePhase.buffering;
    if (snapshot.playing) return AudioEnginePhase.playing;
    return _hasPlayed ? AudioEnginePhase.paused : AudioEnginePhase.ready;
  }

  Duration _duration(Duration value) =>
      value.isNegative ? Duration.zero : value;

  double _volume(double value) =>
      value.isFinite ? (value / 100).clamp(0, 1) : 1;

  double _rate(double value) => value.isFinite ? value.clamp(0.5, 2) : 1;

  void _publishAsyncFailure() {
    if (_closing) return;
    _publishFailure(
      _commandFailure(DomainFailureCode.playbackInterrupted, 'stream'),
    );
  }

  DomainFailure _commandFailure(DomainFailureCode code, String operation) =>
      DomainFailure(
        code: code,
        diagnosticId: 'audio.media-kit.$operation',
        retryable: code == DomainFailureCode.playbackInterrupted,
      );

  void _publishFailure(DomainFailure failure) {
    _failure = failure;
    _publish(
      AudioEngineState(
        phase: AudioEnginePhase.error,
        position: _duration(_backend.current.position),
        buffered: _duration(_backend.current.buffer),
        duration: _backend.current.duration > Duration.zero
            ? _duration(_backend.current.duration)
            : null,
        volume: _volume(_backend.current.volume),
        playbackRate: _rate(_backend.current.rate),
        failure: failure,
      ),
    );
  }

  void _publish(AudioEngineState state) {
    if (!_closing && !_states.isClosed) _states.add(state);
  }

  void _requireLoaded() {
    if (!_loaded) throw StateError('No audio source is loaded');
  }

  @override
  Future<void> dispose() {
    final existing = _disposeFuture;
    if (existing != null) return existing;
    _closing = true;
    final disposal = _dispose();
    _disposeFuture = disposal;
    return disposal;
  }

  Future<void> _dispose() async {
    await _operationTail;
    try {
      await _snapshotSubscription.cancel();
    } catch (_) {
      // Disposal must not surface raw plugin errors or leave the app hanging.
    }
    try {
      await _errorSubscription.cancel();
    } catch (_) {
      // Disposal must not surface raw plugin errors or leave the app hanging.
    }
    try {
      await _backend.dispose();
    } catch (_) {
      // The candidate backend owns no durable state; fail closed on shutdown.
    }
    await _states.close();
  }
}
