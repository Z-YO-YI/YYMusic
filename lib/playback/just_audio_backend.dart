import 'dart:async';
import 'dart:io';

import 'package:just_audio/just_audio.dart';

import 'playable_source.dart';
import 'windows_just_audio_error_compatibility.dart';

/// Project-owned processing phases exposed by the just_audio candidate seam.
enum JustAudioProcessingPhase { idle, loading, buffering, ready, completed }

/// Safe typed boundary error: never carries a locator, header or native message.
final class JustAudioSourceExpired implements Exception {
  const JustAudioSourceExpired();
  @override
  String toString() => 'Audio source expired';
}

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
    this.currentIndex,
  });

  final bool playing;
  final JustAudioProcessingPhase processing;
  final Duration position;
  final Duration? duration;
  final Duration buffered;
  final double volume;
  final double speed;

  /// Native sequence index, not an application queue entry identifier.
  final int? currentIndex;
}

/// Injectable seam around just_audio. Plugin types stay in playback adapters.
abstract interface class JustAudioPlayerBackend {
  JustAudioPlayerSnapshot get current;
  bool get supportsRequestHeaders;
  Stream<JustAudioPlayerSnapshot> get snapshots;

  /// Raw plugin failures are discarded by the native wrapper.
  Stream<void> get errors;

  Future<void> open(
    Uri resource, {
    required Map<String, String> headers,
    DateTime? expiresAt,
  });
  Future<void> play();
  Future<void> pause();
  Future<void> stop();
  Future<void> seek(Duration position);
  Future<void> setVolume(double value);
  Future<void> setSpeed(double value);
  Future<void> dispose();
}

/// Optional capability for isolated sequence validation. The production root
/// still owns queue policy and uses single-source loading. Callers must serialize
/// operations and must not share this instance with a second playback owner.
abstract interface class JustAudioSequenceBackend
    implements JustAudioPlayerBackend {
  /// Preloads an immutable snapshot without requesting playback. Replacement
  /// requests pause/disposal before loading on a new player; native release
  /// errors hidden by the plugin cannot be acknowledged by this interface.
  /// Locators and headers are ephemeral and must not be persisted or logged.
  Future<void> openSequence(
    List<PlayableSource> sources, {
    int initialIndex = 0,
  });
  Future<bool> retainSequenceThrough(int expectedIndex);
  Future<bool> pruneSequenceBefore(int expectedIndex);
  Future<bool> appendSequence(
    List<PlayableSource> sources, {
    required int expectedLength,
  });
}

/// The only class that talks to package:just_audio.
///
/// [useProxyForRequestHeaders] is explicit because the selected Windows WinRT
/// implementation cannot attach headers directly. Production selection is not
/// made by this factory; the production factory selects it under ADR-044.
final class NativeJustAudioPlayerBackend implements JustAudioSequenceBackend {
  factory NativeJustAudioPlayerBackend.create({
    required bool useProxyForRequestHeaders,
    required bool supportsRequestHeaders,
    DateTime Function()? clock,
  }) {
    configureWindowsJustAudioErrors(isWindows: Platform.isWindows);
    return NativeJustAudioPlayerBackend._(
      AudioPlayer(useProxyForRequestHeaders: useProxyForRequestHeaders),
      useProxyForRequestHeaders,
      clock ?? DateTime.now,
      supportsRequestHeaders: supportsRequestHeaders,
    );
  }

  NativeJustAudioPlayerBackend._(
    this._player,
    this._useProxyForRequestHeaders,
    this._clock, {
    required this.supportsRequestHeaders,
  }) {
    _attachPlayer();
  }

  final DateTime Function() _clock;
  List<DateTime?> _sourceDeadlines = const [];
  bool _sourceExpired = false;

  void _requireFresh(Iterable<DateTime?> deadlines) {
    final now = _clock().toUtc();
    if (deadlines.any((value) => value != null && !now.isBefore(value))) {
      throw const JustAudioSourceExpired();
    }
  }

  Future<T> _withFreshLoadedSource<T>(Future<T> Function() operation) async {
    try {
      if (_disposed) throw StateError('Audio backend is disposed');
      if (_sourceExpired) throw const JustAudioSourceExpired();
      _requireFresh(_sourceDeadlines);
      // No await between the final check and dispatching the native operation.
      final result = await operation();
      if (_disposed) throw StateError('Audio backend is disposed');
      _requireFresh(_sourceDeadlines);
      return result;
    } on JustAudioSourceExpired {
      _sourceExpired = true;
      try {
        await _player.stop();
      } catch (_) {
        /* Preserve safe expiry. */
      }
      rethrow;
    }
  }

  void _attachPlayer() {
    final generation = _generation;
    _observedRawIndex = _player.playbackEvent.currentIndex;
    _watch(
      _player.playbackEventStream,
      onValue: (event) {
        if (_observedRawIndex != event.currentIndex) {
          _observedRawIndex = event.currentIndex;
          _rawIndexRevision++;
        }
      },
    );
    _watch(_player.playingStream);
    _watch(_player.processingStateStream);
    _watch(_player.positionStream);
    _watch(_player.durationStream);
    _watch(_player.bufferedPositionStream);
    _watch(_player.volumeStream);
    _watch(_player.speedStream);
    _watch(_player.currentIndexStream);
    _subscriptions.add(
      _player.errorStream.listen(
        (_) {
          if (!_disposed && generation == _generation) _errors.add(null);
        },
        onError: (Object _, StackTrace _) {
          if (!_disposed && generation == _generation) _errors.add(null);
        },
      ),
    );
  }

  AudioPlayer _player;
  final bool _useProxyForRequestHeaders;
  int _generation = 0;
  bool _hasSource = false;
  bool _replacementFailed = false;
  int? _observedRawIndex;
  int _rawIndexRevision = 0;
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
    // SequenceState clamps indexes after removals; playback events retain the
    // native index needed to detect a transition during a tail edit.
    currentIndex: _player.playbackEvent.currentIndex,
  );

  @override
  Stream<void> get errors => _errors.stream;

  @override
  Stream<JustAudioPlayerSnapshot> get snapshots => _snapshots.stream;

  void _watch<T>(Stream<T> stream, {void Function(T)? onValue}) {
    final generation = _generation;
    _subscriptions.add(
      stream.listen(
        (value) {
          if (_disposed || generation != _generation) return;
          try {
            onValue?.call(value);
            _snapshots.add(current);
          } catch (_) {
            _errors.add(null);
          }
        },
        onError: (Object _, StackTrace _) {
          if (!_disposed && generation == _generation) _errors.add(null);
        },
      ),
    );
  }

  Future<void> _prepareLoad() async {
    if (_disposed || _replacementFailed) {
      throw StateError('Audio backend cannot load media');
    }
    if (!_hasSource) {
      _hasSource = true;
      return;
    }
    final volume = _player.volume;
    final speed = _player.speed;
    _generation++;
    _replacementFailed = true;
    try {
      for (final subscription in _subscriptions) {
        await subscription.cancel();
      }
      _subscriptions.clear();
      // Unlike stop's platform release path, pause propagates native failure.
      // This is a best-effort acknowledged pause, not proof of resource release.
      await _player.pause();
      await _player.dispose();
      if (_disposed) throw StateError('Audio backend is disposed');
      _player = AudioPlayer(
        useProxyForRequestHeaders: _useProxyForRequestHeaders,
      );
      await _player.setVolume(volume);
      await _player.setSpeed(speed);
      if (_disposed) throw StateError('Audio backend is disposed');
      _attachPlayer();
      _replacementFailed = false;
    } catch (_) {
      // Observable preparation failure must not start a second player.
      throw StateError('Audio player could not be replaced');
    }
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
    DateTime? expiresAt,
  }) async {
    if (headers.isNotEmpty && !supportsRequestHeaders) {
      throw UnsupportedError('Request headers are unavailable');
    }
    final ephemeralHeaders = headers.isEmpty
        ? null
        : Map<String, String>.unmodifiable(headers);
    final deadlines = [expiresAt?.toUtc()];
    _requireFresh(deadlines);
    await _prepareLoad();
    if (_disposed) throw StateError('Audio backend is disposed');
    _sourceDeadlines = List.unmodifiable(deadlines);
    _sourceExpired = false;
    await _withFreshLoadedSource(
      () => _player.setAudioSource(
        AudioSource.uri(resource, headers: ephemeralHeaders),
        preload: true,
        initialPosition: Duration.zero,
      ),
    );
  }

  @override
  Future<void> openSequence(
    List<PlayableSource> sources, {
    int initialIndex = 0,
  }) async {
    if (_disposed) throw StateError('Audio backend is disposed');
    final snapshot = List<PlayableSource>.unmodifiable(sources);
    if (snapshot.isEmpty ||
        initialIndex < 0 ||
        initialIndex >= snapshot.length) {
      throw ArgumentError('Invalid audio sequence or initial index');
    }
    if (!supportsRequestHeaders &&
        snapshot.any((source) => source.headers.isNotEmpty)) {
      throw UnsupportedError('Request headers are unavailable');
    }
    final deadlines = snapshot
        .map((source) => source.expiresAt)
        .toList(growable: false);
    _requireFresh(deadlines);
    try {
      final nativeSources = snapshot
          .map((source) {
            final path = source.localPath;
            final resource = path == null
                ? source.uri!
                : Uri.file(
                    path,
                    windows:
                        RegExp(r'^[A-Za-z]:[\\/]').hasMatch(path) ||
                        path.startsWith(r'\\'),
                  );
            return AudioSource.uri(
              resource,
              headers: source.headers.isEmpty ? null : source.headers,
            );
          })
          .toList(growable: false);
      await _prepareLoad();
      if (_disposed) throw StateError('Audio backend is disposed');
      _sourceDeadlines = List.unmodifiable(deadlines);
      _sourceExpired = false;
      await _withFreshLoadedSource(
        () => _player.setAudioSources(
          nativeSources,
          preload: true,
          initialIndex: initialIndex,
          initialPosition: Duration.zero,
        ),
      );
    } on JustAudioSourceExpired {
      rethrow;
    } catch (_) {
      // Plugin failures can contain stream credentials or local paths.
      throw StateError('Audio sequence could not be loaded');
    }
  }

  @override
  Future<bool> appendSequence(
    List<PlayableSource> sources, {
    required int expectedLength,
  }) async {
    if (_disposed || _replacementFailed) {
      throw StateError('Audio backend cannot append media');
    }
    final snapshot = List<PlayableSource>.unmodifiable(sources);
    if (snapshot.isEmpty) throw ArgumentError('Audio append must not be empty');
    if (!supportsRequestHeaders &&
        snapshot.any((source) => source.headers.isNotEmpty)) {
      throw UnsupportedError('Request headers are unavailable');
    }
    if (expectedLength <= 0 ||
        _player.sequence.length != expectedLength ||
        _player.processingState == ProcessingState.completed) {
      return false;
    }
    final generation = _generation;
    final deadlines = [
      ..._sourceDeadlines,
      ...snapshot.map((source) => source.expiresAt),
    ];
    _requireFresh(deadlines);
    try {
      _sourceDeadlines = List.unmodifiable(deadlines);
      await _withFreshLoadedSource(
        () => _player.addAudioSources(
          snapshot.map(_nativeSource).toList(growable: false),
        ),
      );
      return !_disposed && generation == _generation;
    } on JustAudioSourceExpired {
      rethrow;
    } catch (_) {
      throw StateError('Audio sequence could not be extended');
    }
  }

  AudioSource _nativeSource(PlayableSource source) {
    final path = source.localPath;
    final uri = path == null
        ? source.uri!
        : Uri.file(
            path,
            windows:
                RegExp(r'^[A-Za-z]:[\\/]').hasMatch(path) ||
                path.startsWith(r'\\'),
          );
    return AudioSource.uri(
      uri,
      headers: source.headers.isEmpty ? null : source.headers,
    );
  }

  @override
  Future<bool> retainSequenceThrough(int expectedIndex) async {
    if (_disposed || _replacementFailed) {
      throw StateError('Audio backend cannot edit media');
    }
    final length = _player.sequence.length;
    if (expectedIndex < 0 ||
        expectedIndex >= length ||
        _player.playbackEvent.currentIndex != expectedIndex) {
      return false;
    }
    try {
      final revision = _rawIndexRevision;
      if (expectedIndex + 1 < length) {
        await _player.removeAudioSourceRange(expectedIndex + 1, length);
      }
      _sourceDeadlines = List.unmodifiable(
        _sourceDeadlines.take(expectedIndex + 1),
      );
      return !_disposed &&
          revision == _rawIndexRevision &&
          _player.playbackEvent.currentIndex == expectedIndex;
    } catch (_) {
      throw StateError('Audio sequence boundary could not be applied');
    }
  }

  @override
  Future<bool> pruneSequenceBefore(int expectedIndex) async {
    if (_disposed || _replacementFailed) {
      throw StateError('Audio backend cannot edit media');
    }
    if (expectedIndex <= 0 ||
        expectedIndex >= _player.sequence.length ||
        _player.playbackEvent.currentIndex != expectedIndex) {
      return false;
    }
    final generation = _generation;
    final rebased = Completer<void>();
    var invalid = false;
    var lastObserved = expectedIndex;
    final subscription = snapshots.listen(
      (value) {
        final index = value.currentIndex;
        if (index == null || index < 0 || index > lastObserved) invalid = true;
        if (index != null) lastObserved = index;
        if (index == 0 && !rebased.isCompleted) rebased.complete();
      },
      onDone: () {
        if (!rebased.isCompleted) rebased.complete();
      },
    );
    try {
      await _player.removeAudioSourceRange(0, expectedIndex);
      if (_player.playbackEvent.currentIndex != 0) {
        await rebased.future.timeout(const Duration(seconds: 1));
      }
      if (_disposed ||
          generation != _generation ||
          invalid ||
          _player.playbackEvent.currentIndex != 0) {
        return false;
      }
      _sourceDeadlines = List.unmodifiable(
        _sourceDeadlines.skip(expectedIndex),
      );
      return true;
    } catch (_) {
      throw StateError('Audio sequence prefix could not be removed');
    } finally {
      await subscription.cancel();
    }
  }

  @override
  Future<void> play() async {
    if (_disposed || _replacementFailed) {
      throw StateError('Audio backend cannot play media');
    }
    await _withFreshLoadedSource(() async {
      final generation = _generation;
      final request = _player.play();
      unawaited(
        request.then<void>(
          (_) {},
          onError: (Object _, StackTrace _) {
            if (!_disposed && generation == _generation) _errors.add(null);
          },
        ),
      );
      // just_audio's play Future completes on pause/stop/end. AudioEngine.play
      // instead acknowledges the start request so its serialized queue can move.
      await Future<void>.delayed(Duration.zero);
    });
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> seek(Duration position) =>
      _withFreshLoadedSource(() => _player.seek(position));

  @override
  Future<void> setVolume(double value) => _player.setVolume(value);

  @override
  Future<void> setSpeed(double value) => _player.setSpeed(value);

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _generation++;
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
