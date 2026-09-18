import 'dart:async';

import '../domain/models/domain_failure.dart';
import 'audio_engine.dart';
import 'audio_engine_state.dart';
import 'audio_sequence.dart';
import 'just_audio_backend.dart';
import 'playable_source.dart';

/// Selected in ADR-044 after native comparison and packaged notice verification.
/// Plugin types remain confined to the backend; app release approval is separate.
final class JustAudioEngine implements AudioSequenceEngine {
  factory JustAudioEngine.create({
    required bool useProxyForRequestHeaders,
    required bool supportsRequestHeaders,
  }) => JustAudioEngine(
    NativeJustAudioPlayerBackend.create(
      useProxyForRequestHeaders: useProxyForRequestHeaders,
      supportsRequestHeaders: supportsRequestHeaders,
    ),
  );

  JustAudioEngine(this._backend, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now {
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
  final DateTime Function() _clock;
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
  List<AudioSequenceCursor>? _sequenceCursors;
  Object? _sequenceFault;
  int? _trimmingIndex;
  bool _trimMoved = false;
  bool _pruning = false;

  @override
  bool get supportsSequences =>
      !_closing && _backend is JustAudioSequenceBackend;

  @override
  bool get isAvailable => !_closing;

  @override
  Stream<AudioEngineState> get states => _states.stream;

  @override
  Future<void> load(PlayableSource source) => _enqueue(() async {
    _requireFreshSources([source]);
    _sequenceFault = null;
    _sequenceCursors = null;
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
        expiresAt: source.expiresAt,
        headers: source.kind == PlayableSourceKind.networkStream
            ? source.headers
            : const {},
      );
      _loading = false;
      _acceptSnapshot(_backend.current);
    } catch (error) {
      _loading = false;
      _loaded = false;
      final failure = _commandFailure(
        error is JustAudioSourceExpired
            ? DomainFailureCode.streamUrlExpired
            : DomainFailureCode.playbackOpenFailed,
        'open',
      );
      _publishFailure(failure);
      throw failure;
    }
  });

  @override
  Future<void> loadSequence(AudioSequence sequence, {int initialIndex = 0}) {
    if (initialIndex < 0 || initialIndex >= sequence.entries.length) {
      return Future.error(
        ArgumentError('Invalid initial audio sequence index'),
      );
    }
    return _enqueue(() async {
      _requireFreshSources(sequence.entries.map((entry) => entry.source));
      final backend = _backend;
      if (backend is! JustAudioSequenceBackend ||
          (!backend.supportsRequestHeaders &&
              sequence.entries.any(
                (entry) => entry.source.headers.isNotEmpty,
              ))) {
        throw _commandFailure(DomainFailureCode.playbackOpenFailed, 'sequence');
      }
      _sequenceCursors = null;
      _sequenceFault = null;
      _failure = null;
      _loaded = true;
      _loading = true;
      _hasPlayed = false;
      _publish(
        AudioEngineState(
          phase: AudioEnginePhase.loading,
          volume: _volume(backend.current.volume),
          playbackRate: _rate(backend.current.speed),
        ),
      );
      try {
        await backend.openSequence(
          sequence.entries.map((entry) => entry.source).toList(growable: false),
          initialIndex: initialIndex,
        );
        if (_failure != null) throw _failure!;
        final cursors = sequence.cursors;
        final index = backend.current.currentIndex;
        if (index == null || index < 0 || index >= cursors.length) {
          throw StateError('Missing audio sequence index');
        }
        _sequenceCursors = cursors;
        _loading = false;
        _acceptSnapshot(backend.current);
      } catch (error) {
        _sequenceCursors = null;
        _loading = false;
        _loaded = false;
        final failure = _commandFailure(
          error is JustAudioSourceExpired
              ? DomainFailureCode.streamUrlExpired
              : DomainFailureCode.playbackOpenFailed,
          'sequence',
        );
        _publishFailure(failure);
        throw failure;
      }
    });
  }

  @override
  Future<bool> appendSequence(AudioSequenceAppend request) async {
    var appended = false;
    await _enqueue(() async {
      final backend = _backend;
      final cursors = _sequenceCursors;
      final expected = request.expectedTail;
      if (backend is! JustAudioSequenceBackend ||
          !_loaded ||
          _loading ||
          _failure != null ||
          cursors == null ||
          cursors.isEmpty ||
          backend.current.processing == JustAudioProcessingPhase.completed) {
        return;
      }
      final tail = cursors.last;
      if (!identical(tail.sequenceIdentity, expected.sequenceIdentity) ||
          tail.index != expected.index ||
          tail.cycle != expected.cycle ||
          tail.entryId != expected.entryId ||
          tail.track != expected.track) {
        return;
      }
      final existing = cursors
          .map((cursor) => (cursor.cycle, cursor.entryId))
          .toSet();
      _requireFreshSources(request.entries.map((entry) => entry.source));
      if (request.entries.any(
        (entry) => existing.contains((entry.cycle, entry.entryId)),
      )) {
        throw ArgumentError('Audio append contains an existing entry');
      }
      if (!backend.supportsRequestHeaders &&
          request.entries.any((entry) => entry.source.headers.isNotEmpty)) {
        throw _commandFailure(
          DomainFailureCode.playbackOpenFailed,
          'sequence-append',
        );
      }
      _sequenceCursors = List.unmodifiable([...cursors, ...request.cursors]);
      try {
        final accepted = await backend.appendSequence(
          request.entries.map((entry) => entry.source).toList(growable: false),
          expectedLength: cursors.length,
        );
        if (_failure != null) throw _failure!;
        if (!accepted) {
          final index = backend.current.currentIndex;
          if (index == null || index < 0 || index >= cursors.length) {
            throw StateError('Rejected append already changed sequence');
          }
          _sequenceCursors = cursors;
          return;
        }
        _acceptSnapshot(backend.current);
        if (_failure != null) throw _failure!;
        appended = true;
      } catch (error) {
        _sequenceCursors = null;
        _loaded = false;
        final failure = _commandFailure(
          error is JustAudioSourceExpired
              ? DomainFailureCode.streamUrlExpired
              : DomainFailureCode.playbackInterrupted,
          'sequence-append',
        );
        _publishFailure(failure);
        try {
          await backend.stop();
        } catch (_) {
          /* Keep the safe failure. */
        }
        throw failure;
      }
    });
    return appended;
  }

  @override
  Future<bool> retainSequenceThrough(AudioSequenceCursor expected) async {
    var retained = false;
    await _enqueue(() async {
      final backend = _backend;
      final cursors = _sequenceCursors;
      if (backend is! JustAudioSequenceBackend ||
          !_loaded ||
          _loading ||
          _failure != null ||
          cursors == null ||
          cursors.isEmpty ||
          expected.index < cursors.first.index ||
          expected.index > cursors.last.index) {
        return;
      }
      final nativeIndex = expected.index - cursors.first.index;
      final current = cursors[nativeIndex];
      if (!identical(current.sequenceIdentity, expected.sequenceIdentity) ||
          current.entryId != expected.entryId ||
          current.cycle != expected.cycle ||
          current.track != expected.track ||
          backend.current.currentIndex != nativeIndex) {
        return;
      }
      _trimmingIndex = nativeIndex;
      _trimMoved = false;
      try {
        final applied = await backend.retainSequenceThrough(nativeIndex);
        if (!applied ||
            _trimMoved ||
            _failure != null ||
            backend.current.currentIndex != nativeIndex) {
          throw StateError('Audio sequence changed during boundary edit');
        }
        _sequenceCursors = List.unmodifiable(cursors.take(nativeIndex + 1));
        _trimmingIndex = null;
        _acceptSnapshot(backend.current);
        retained = true;
      } catch (_) {
        _trimmingIndex = null;
        _sequenceCursors = null;
        _loaded = false;
        final failure = _commandFailure(
          DomainFailureCode.playbackInterrupted,
          'sequence-boundary',
        );
        _publishFailure(failure);
        try {
          await backend.stop();
        } catch (_) {
          // Preserve the safe boundary failure; native stopping is best effort.
        }
        throw failure;
      }
    });
    return retained;
  }

  void _requireFreshSources(Iterable<PlayableSource> sources) {
    final now = _clock();
    if (sources.any((source) => !source.isValidAt(now))) {
      throw _commandFailure(
        DomainFailureCode.streamUrlExpired,
        'source-expired',
      );
    }
  }

  @override
  Future<bool> pruneSequenceBefore(AudioSequenceCursor expected) async {
    var pruned = false;
    await _enqueue(() async {
      final backend = _backend, cursors = _sequenceCursors;
      if (backend is! JustAudioSequenceBackend ||
          !_loaded ||
          _loading ||
          _failure != null ||
          cursors == null ||
          cursors.isEmpty) {
        return;
      }
      final index = expected.index - cursors.first.index;
      if (index <= 0 ||
          index >= cursors.length ||
          backend.current.currentIndex != index) {
        return;
      }
      final cursor = cursors[index];
      if (!identical(cursor.sequenceIdentity, expected.sequenceIdentity) ||
          cursor.entryId != expected.entryId ||
          cursor.cycle != expected.cycle ||
          cursor.track != expected.track) {
        return;
      }
      _pruning = true;
      try {
        if (!await backend.pruneSequenceBefore(index) ||
            _failure != null ||
            backend.current.currentIndex != 0) {
          throw StateError('Sequence changed during prefix removal');
        }
        _sequenceCursors = List.unmodifiable(cursors.skip(index));
        _pruning = false;
        _acceptSnapshot(backend.current);
        if (_failure != null) throw _failure!;
        pruned = true;
      } catch (_) {
        _pruning = false;
        _sequenceCursors = null;
        _loaded = false;
        final failure = _commandFailure(
          DomainFailureCode.playbackInterrupted,
          'sequence-prefix',
        );
        _publishFailure(failure);
        try {
          await backend.stop();
        } catch (_) {
          /* Keep safe failure. */
        }
        throw failure;
      }
    });
    return pruned;
  }

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
    _sequenceFault = null;
    _sequenceCursors = null;
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
        } catch (error) {
          final failure = _commandFailure(
            error is JustAudioSourceExpired
                ? DomainFailureCode.streamUrlExpired
                : DomainFailureCode.playbackInterrupted,
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
    if (_pruning) return;
    final trimming = _trimmingIndex;
    if (trimming != null) {
      if (snapshot.currentIndex != trimming) _trimMoved = true;
      return;
    }
    AudioSequenceCursor? cursor;
    final cursors = _sequenceCursors;
    if (cursors != null && !_loading && _failure == null) {
      final index = snapshot.currentIndex;
      if (index == null || index < 0 || index >= cursors.length) {
        _loaded = false;
        _sequenceCursors = null;
        final fault = _sequenceFault = Object();
        // Stop unidentified media through the same serialized owner. A newer
        // accepted load can supersede this fault; never stop that new media.
        unawaited(
          _enqueue(() async {
            if (!identical(_sequenceFault, fault)) return;
            try {
              await _backend.stop();
            } catch (_) {
              // Keep the safe index failure, never expose a plugin exception.
            }
          }).catchError((Object _, StackTrace _) {}),
        );
        _publishFailure(
          _commandFailure(
            DomainFailureCode.playbackInterrupted,
            'sequence-index',
          ),
        );
        return;
      }
      cursor = cursors[index];
    }
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
        sequenceCursor: cursor,
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
