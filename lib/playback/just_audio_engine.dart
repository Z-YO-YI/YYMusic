import 'dart:async';

import '../domain/models/domain_failure.dart';
import 'audio_engine.dart';
import 'audio_engine_state.dart';
import 'just_audio_backend.dart';
import 'playable_source.dart';

/// Isolated Phase 4E candidate. Production bootstrap must not create it until
/// native comparison and redistribution review are complete.
final class JustAudioEngine implements AudioEngine {
  factory JustAudioEngine.create({
    required bool useProxyForRequestHeaders,
    required bool supportsRequestHeaders,
  }) => JustAudioEngine(
    NativeJustAudioPlayerBackend.create(
      useProxyForRequestHeaders: useProxyForRequestHeaders,
      supportsRequestHeaders: supportsRequestHeaders,
    ),
  );

  JustAudioEngine(this._backend) {
    _snapshotSubscription = _backend.snapshots.listen(
      _acceptSnapshot,
      onError: (Object _, StackTrace _) => _publishAsyncFailure(),
    );
    _errorSubscription = _backend.errors.listen(
      (_) => _publishAsyncFailure(),
      onError: (Object _, StackTrace _) => _publishAsyncFailure(),
    );
  }

  final JustAudioPlayerBackend _backend;
  final _states = StreamController<AudioEngineState>.broadcast(sync: true);
  late final StreamSubscription<JustAudioPlayerSnapshot> _snapshotSubscription;
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
        playbackRate: _rate(_backend.current.speed),
      ),
    );
    try {
      if (source.headers.isNotEmpty && !_backend.supportsRequestHeaders) {
        throw UnsupportedError('Request headers are unavailable');
      }
      await _backend.open(
        _resource(source),
        headers: source.kind == PlayableSourceKind.networkStream
            ? source.headers
            : const {},
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
        playbackRate: _rate(_backend.current.speed),
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
      await _backend.setVolume(value);
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
      await _backend.setSpeed(value);
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

  Uri _resource(PlayableSource source) => switch (source.kind) {
    PlayableSourceKind.localFile => _fileUri(source.localPath!),
    PlayableSourceKind.contentUri ||
    PlayableSourceKind.networkStream => source.uri!,
  };

  Uri _fileUri(String path) {
    final windowsPath =
        RegExp(r'^[A-Za-z]:[\\/]').hasMatch(path) || path.startsWith(r'\\');
    return Uri.file(path, windows: windowsPath);
  }

  void _acceptSnapshot(JustAudioPlayerSnapshot snapshot) {
    if (_closing) return;
    if (snapshot.playing) _hasPlayed = true;
    final failure = _failure;
    final phase = failure != null ? AudioEnginePhase.error : _phase(snapshot);
    _publish(
      AudioEngineState(
        phase: phase,
        position: _duration(snapshot.position),
        buffered: _duration(snapshot.buffered),
        duration: snapshot.duration == null
            ? null
            : _duration(snapshot.duration!),
        volume: _volume(snapshot.volume),
        playbackRate: _rate(snapshot.speed),
        failure: failure,
      ),
    );
  }

  AudioEnginePhase _phase(JustAudioPlayerSnapshot snapshot) {
    if (!_loaded) return AudioEnginePhase.idle;
    if (_loading || snapshot.processing == JustAudioProcessingPhase.loading) {
      return AudioEnginePhase.loading;
    }
    if (snapshot.processing == JustAudioProcessingPhase.completed &&
        _hasPlayed) {
      return AudioEnginePhase.completed;
    }
    if (snapshot.processing == JustAudioProcessingPhase.buffering) {
      return AudioEnginePhase.buffering;
    }
    if (snapshot.playing) return AudioEnginePhase.playing;
    return _hasPlayed ? AudioEnginePhase.paused : AudioEnginePhase.ready;
  }

  Duration _duration(Duration value) =>
      value.isNegative ? Duration.zero : value;

  double _volume(double value) => value.isFinite ? value.clamp(0, 1) : 1;

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
        diagnosticId: 'audio.just-audio.$operation',
        retryable: code == DomainFailureCode.playbackInterrupted,
      );

  void _publishFailure(DomainFailure failure) {
    _failure = failure;
    _publish(
      AudioEngineState(
        phase: AudioEnginePhase.error,
        position: _duration(_backend.current.position),
        buffered: _duration(_backend.current.buffered),
        duration: _backend.current.duration == null
            ? null
            : _duration(_backend.current.duration!),
        volume: _volume(_backend.current.volume),
        playbackRate: _rate(_backend.current.speed),
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
      // Continue releasing the remaining candidate resources.
    }
    try {
      await _errorSubscription.cancel();
    } catch (_) {
      // Continue releasing the remaining candidate resources.
    }
    try {
      await _backend.dispose();
    } catch (_) {
      // Candidate shutdown must not expose raw plugin errors.
    }
    await _states.close();
  }
}
