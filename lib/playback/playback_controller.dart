import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../domain/models/collection_models.dart';
import '../domain/models/domain_failure.dart';
import '../domain/models/track.dart';
import '../domain/repositories/collection_repository.dart';
import '../domain/repositories/library_repository.dart';
import '../platform/contracts/media_session_gateway.dart';
import 'audio_engine.dart';
import 'audio_engine_state.dart';
import 'playback_source_resolver.dart';
import 'playback_state.dart';

typedef PlaybackRandomIndex = int Function(int upperBound);

final class PlaybackController extends ChangeNotifier {
  PlaybackController(
    this._engine, {
    LibraryRepository? library,
    CollectionRepository? collection,
    PlaybackSourceResolver? sourceResolver,
    MediaSessionGateway? mediaSession,
    DateTime Function()? clock,
    PlaybackRandomIndex? randomIndex,
  }) : _libraryRepository = library,
       _collectionRepository = collection,
       _resolver = sourceResolver,
       _mediaSession = mediaSession ?? const UnavailableMediaSessionGateway(),
       _clock = clock ?? _utcNow,
       _randomIndex = randomIndex ?? Random().nextInt {
    _subscription = _engine.states.listen(
      _acceptEngineState,
      onError: (Object error, StackTrace stack) {
        _publishFailure(error, 'engine-stream');
      },
    );
  }

  final AudioEngine _engine;
  final LibraryRepository? _libraryRepository;
  final CollectionRepository? _collectionRepository;
  final PlaybackSourceResolver? _resolver;
  final MediaSessionGateway _mediaSession;
  final DateTime Function() _clock;
  final PlaybackRandomIndex _randomIndex;
  late final StreamSubscription<AudioEngineState> _subscription;

  PlaybackState _state = PlaybackState();
  Future<void> _operationTail = Future<void>.value();
  Future<void> _mediaSyncTail = Future<void>.value();
  Future<void>? _initialization;
  List<String> _shuffleOrder = const [];
  int _shuffleCursor = -1;
  TrackRef? _mediaTrack;
  bool _mediaInitialized = false;
  String? _loadedEntryId;
  int _sessionRevision = 0;
  bool _completionHandled = true;
  bool _loadingSource = false;
  bool _disposed = false;
  Future<void>? _closeFuture;

  PlaybackState get state => _state;
  bool get isAvailable => _engine.isAvailable;
  bool get isMediaSessionAvailable => _mediaSession.isAvailable;

  Future<void> initialize() => _initialization ??= _schedule(() async {
    final collection = _collectionRepository;
    if (collection != null) {
      try {
        _applyQueue(await collection.loadQueue());
      } catch (error) {
        _publishFailure(error, 'restore-queue');
      }
    }
    _checkNotDisposed();
    try {
      await _mediaSession.initialize(
        MediaSessionCallbacks(
          play: play,
          pause: pause,
          stop: stop,
          skipNext: skipNext,
          skipPrevious: skipPrevious,
          seek: seek,
        ),
      );
      _checkNotDisposed();
      _mediaInitialized = true;
      await _queueMediaSynchronization(_state);
    } catch (_) {
      _mediaInitialized = false;
    }
  });

  Future<void> play() => _schedule(() async {
    _requireEngine();
    if (_loadedEntryId != null &&
        _loadedEntryId == _state.queue.currentEntryId &&
        _state.phase != PlaybackPhase.error) {
      await _guarded('play', () async {
        if (_state.phase == PlaybackPhase.completed) {
          await _engine.seek(Duration.zero);
        }
        await _startPlayback();
      });
      return;
    }
    final entryId =
        _state.queue.currentEntryId ??
        (_state.queue.entries.isEmpty ? null : _state.queue.entries.first.id);
    if (entryId == null) {
      final failure = DomainFailure(
        code: DomainFailureCode.notFound,
        diagnosticId: 'playback.queue-empty',
      );
      _publish(_state.copyWith(phase: PlaybackPhase.error, failure: failure));
      throw failure;
    }
    await _playEntryInternal(entryId);
  });

  Future<void> pause() => _schedule(() async {
    _requireEngine();
    _sessionRevision++;
    await _guarded('pause', _engine.pause);
  });

  Future<void> stop() => _schedule(() async {
    _requireEngine();
    await _guarded('stop', _stopEngine);
  });

  Future<void> seek(Duration position) => _schedule(() async {
    _requireEngine();
    if (position.isNegative) {
      throw ArgumentError.value(position, 'position', 'must not be negative');
    }
    final duration = _state.duration;
    final target = duration != null && position > duration
        ? duration
        : position;
    _sessionRevision++;
    await _guarded('seek', () => _engine.seek(target));
  });

  Future<void> setVolume(double value) => _schedule(() async {
    _requireEngine();
    _validateVolume(value);
    await _guarded('set-volume', () => _engine.setVolume(value));
  });

  Future<void> setPlaybackRate(double value) => _schedule(() async {
    _requireEngine();
    _validatePlaybackRate(value);
    await _guarded('set-playback-rate', () => _engine.setPlaybackRate(value));
  });

  Future<void> playEntry(String entryId) =>
      _schedule(() => _playEntryInternal(entryId));

  Future<void> skipNext() => _schedule(
    () => _guarded('skip-next', () => _advanceInternal(isAutomatic: false)),
  );

  Future<void> skipPrevious() => _schedule(() async {
    _requireEngine();
    if (_state.position > const Duration(seconds: 3)) {
      _sessionRevision++;
      await _guarded('skip-previous-seek', () => _engine.seek(Duration.zero));
      return;
    }
    final entry = _previousEntry();
    if (entry != null) await _playEntryInternal(entry.id);
  });

  Future<void> replaceQueue(
    Iterable<QueueEntry> entries, {
    String? currentEntryId,
  }) => _schedule(
    () => _guarded('replace-queue', () async {
      final snapshot = _snapshot(
        _normalize(entries),
        currentEntryId: currentEntryId,
      );
      await _commitQueue(snapshot);
    }),
  );

  Future<void> addToEnd(QueueEntry entry) => _schedule(
    () => _guarded('queue-add', () async {
      final entries = [..._state.queue.entries, entry];
      await _commitQueue(
        _snapshot(
          _normalize(entries),
          currentEntryId: _state.queue.currentEntryId,
        ),
      );
    }),
  );

  Future<void> insertNext(QueueEntry entry) => _schedule(
    () => _guarded('queue-insert-next', () async {
      final entries = [..._state.queue.entries];
      final currentIndex = entries.indexWhere(
        (candidate) => candidate.id == _state.queue.currentEntryId,
      );
      entries.insert(currentIndex < 0 ? 0 : currentIndex + 1, entry);
      await _commitQueue(
        _snapshot(
          _normalize(entries),
          currentEntryId: _state.queue.currentEntryId,
        ),
      );
    }),
  );

  Future<void> moveQueueEntry(String entryId, int targetIndex) => _schedule(
    () => _guarded('queue-move', () async {
      final entries = [..._state.queue.entries];
      final sourceIndex = entries.indexWhere((entry) => entry.id == entryId);
      if (sourceIndex < 0) throw _queueEntryMissing(entryId);
      if (targetIndex < 0 || targetIndex >= entries.length) {
        throw RangeError.range(targetIndex, 0, entries.length - 1);
      }
      final entry = entries.removeAt(sourceIndex);
      entries.insert(targetIndex, entry);
      await _commitQueue(
        _snapshot(
          _normalize(entries),
          currentEntryId: _state.queue.currentEntryId,
        ),
      );
    }),
  );

  Future<void> removeQueueEntry(String entryId) => _schedule(
    () => _guarded('queue-remove', () async {
      final entries = [..._state.queue.entries];
      final index = entries.indexWhere((entry) => entry.id == entryId);
      if (index < 0) throw _queueEntryMissing(entryId);
      final removedCurrent = entryId == _state.queue.currentEntryId;
      entries.removeAt(index);
      String? nextCurrent = _state.queue.currentEntryId;
      if (removedCurrent) {
        nextCurrent = entries.isEmpty
            ? null
            : entries[min(index, entries.length - 1)].id;
      }
      await _commitQueue(
        _snapshot(_normalize(entries), currentEntryId: nextCurrent),
      );
    }),
  );

  Future<void> clearQueue() => _schedule(
    () => _guarded('queue-clear', () async {
      await _commitQueue(_snapshot(const []));
    }),
  );

  void setShuffleEnabled(bool value) {
    if (_disposed || value == _state.shuffleEnabled) return;
    _publish(_state.copyWith(shuffleEnabled: value));
    if (value) {
      _rebuildShuffleOrder();
    } else {
      _shuffleOrder = const [];
      _shuffleCursor = -1;
    }
  }

  void setRepeatMode(RepeatMode value) {
    if (_disposed || value == _state.repeatMode) return;
    _publish(_state.copyWith(repeatMode: value));
  }

  Future<void> _playEntryInternal(String entryId) async {
    _requireEngine();
    try {
      final entry = _entry(entryId);
      _sessionRevision++;
      _completionHandled = true;
      final library = _libraryRepository;
      if (library == null) {
        throw DomainFailure(
          code: DomainFailureCode.playbackOpenFailed,
          diagnosticId: 'playback.library-unavailable',
          sourceId: entry.track.sourceId,
        );
      }
      final track = await library.getTrack(entry.track);
      _checkNotDisposed();
      if (track == null) throw _queueTrackMissing(entry.track);
      final availabilityFailure = _availabilityFailure(track);
      if (availabilityFailure != null) throw availabilityFailure;
      final resolver = _resolver;
      if (resolver == null) {
        throw DomainFailure(
          code: DomainFailureCode.playbackOpenFailed,
          diagnosticId: 'playback.source-resolver-unavailable',
          sourceId: track.sourceId,
        );
      }
      final source = await resolver.resolve(track);
      _checkNotDisposed();
      if (source.track != track.ref) {
        throw DomainFailure(
          code: DomainFailureCode.schemaMismatch,
          diagnosticId: 'playback.source-track-mismatch',
          sourceId: track.sourceId,
        );
      }
      if (_state.queue.currentEntryId != entryId) {
        await _commitQueue(
          _snapshot(_state.queue.entries, currentEntryId: entryId),
          rebuildShuffle: false,
        );
      }
      // Explicit replay and error recovery must not retain a previous source.
      if (_loadedEntryId != null) await _stopEngine();
      _checkNotDisposed();
      _publish(
        _state.copyWith(
          phase: PlaybackPhase.loading,
          currentTrack: track,
          position: Duration.zero,
          buffered: Duration.zero,
          duration: track.duration == Duration.zero ? null : track.duration,
          failure: null,
        ),
      );
      _syncShuffleCursor(entryId);
      _loadingSource = true;
      await _engine.load(source);
      _loadingSource = false;
      _checkNotDisposed();
      _loadedEntryId = entryId;
      await _startPlayback();
    } catch (error, stack) {
      _loadingSource = false;
      final failure = _safeFailure(error, 'load-entry');
      _publish(_state.copyWith(phase: PlaybackPhase.error, failure: failure));
      Error.throwWithStackTrace(failure, stack);
    }
  }

  Future<void> _advanceInternal({required bool isAutomatic}) async {
    _requireEngine();
    if (isAutomatic && _state.repeatMode == RepeatMode.one) {
      if (_state.currentTrack != null) {
        await _engine.seek(Duration.zero);
        await _startPlayback();
      }
      return;
    }
    final next = _nextEntry();
    if (next != null) await _playEntryInternal(next.id);
  }

  QueueEntry? _nextEntry() {
    final entries = _state.queue.entries;
    if (entries.isEmpty) return null;
    if (!_state.shuffleEnabled) {
      final index = entries.indexWhere(
        (entry) => entry.id == _state.queue.currentEntryId,
      );
      if (index < 0) return entries.first;
      if (index + 1 < entries.length) return entries[index + 1];
      return _state.repeatMode == RepeatMode.all ? entries.first : null;
    }
    _ensureShuffleOrder();
    if (_shuffleCursor + 1 < _shuffleOrder.length) {
      return _entry(_shuffleOrder[++_shuffleCursor]);
    }
    if (_state.repeatMode != RepeatMode.all) return null;
    _rebuildShuffleOrder();
    if (_shuffleCursor + 1 < _shuffleOrder.length) {
      return _entry(_shuffleOrder[++_shuffleCursor]);
    }
    return entries.length == 1 ? entries.single : null;
  }

  QueueEntry? _previousEntry() {
    final entries = _state.queue.entries;
    if (entries.isEmpty) return null;
    if (!_state.shuffleEnabled) {
      final index = entries.indexWhere(
        (entry) => entry.id == _state.queue.currentEntryId,
      );
      if (index > 0) return entries[index - 1];
      return _state.repeatMode == RepeatMode.all ? entries.last : null;
    }
    _ensureShuffleOrder();
    if (_shuffleCursor > 0) return _entry(_shuffleOrder[--_shuffleCursor]);
    if (_state.repeatMode == RepeatMode.all && _shuffleOrder.isNotEmpty) {
      _shuffleCursor = _shuffleOrder.length - 1;
      return _entry(_shuffleOrder[_shuffleCursor]);
    }
    return null;
  }

  void _acceptEngineState(AudioEngineState value) {
    if (_disposed) return;
    if (value.phase == AudioEnginePhase.completed && _loadedEntryId == null) {
      return;
    }
    if (!_loadingSource &&
        _loadedEntryId == null &&
        value.phase != AudioEnginePhase.idle &&
        value.phase != AudioEnginePhase.error) {
      // Late media snapshots after stop cannot resurrect an unloaded session.
      _publish(
        _state.copyWith(volume: value.volume, playbackRate: value.playbackRate),
      );
      return;
    }
    if (value.phase == AudioEnginePhase.idle && !_loadingSource) {
      _loadedEntryId = null;
      _sessionRevision++;
      _completionHandled = true;
    }
    if (value.phase == AudioEnginePhase.playing &&
        _loadedEntryId != null &&
        _completionHandled) {
      // A seek may resume the native clock without another play command.
      _sessionRevision++;
      _completionHandled = false;
    }
    final revision = _sessionRevision;
    final completedEntryId = _loadedEntryId;
    final shouldAdvance =
        value.phase == AudioEnginePhase.completed && !_completionHandled;
    if (value.phase == AudioEnginePhase.completed) _completionHandled = true;
    final phase = switch (value.phase) {
      AudioEnginePhase.idle => PlaybackPhase.idle,
      AudioEnginePhase.loading => PlaybackPhase.loading,
      AudioEnginePhase.buffering => PlaybackPhase.buffering,
      AudioEnginePhase.ready => PlaybackPhase.ready,
      AudioEnginePhase.playing => PlaybackPhase.playing,
      AudioEnginePhase.paused => PlaybackPhase.paused,
      AudioEnginePhase.completed => PlaybackPhase.completed,
      AudioEnginePhase.error => PlaybackPhase.error,
    };
    _publish(
      _state.copyWith(
        phase: phase,
        position: value.position,
        buffered: value.buffered,
        duration: value.duration,
        volume: value.volume,
        playbackRate: value.playbackRate,
        failure: value.failure,
      ),
    );
    if (shouldAdvance) {
      unawaited(
        _schedule(
          () => _guarded('auto-advance', () async {
            if (_sessionRevision != revision ||
                _loadedEntryId != completedEntryId ||
                _state.phase != PlaybackPhase.completed) {
              return;
            }
            await _advanceInternal(isAutomatic: true);
          }),
        ).catchError((Object _) {}),
      );
    }
  }

  Future<void> _commitQueue(
    QueueSnapshot snapshot, {
    bool rebuildShuffle = true,
  }) async {
    if (!_retainsCurrentTrack(snapshot) &&
        _state.currentTrack != null &&
        _engine.isAvailable) {
      await _stopEngine();
    }
    _checkNotDisposed();
    final collection = _collectionRepository;
    if (collection != null) await collection.saveQueue(snapshot);
    _applyQueue(snapshot, rebuildShuffle: rebuildShuffle);
  }

  void _applyQueue(QueueSnapshot queue, {bool rebuildShuffle = true}) {
    final currentTrack = _retainsCurrentTrack(queue)
        ? _state.currentTrack
        : null;
    final currentId = queue.currentEntryId;
    _publish(
      _state.copyWith(
        phase: currentTrack == null ? PlaybackPhase.idle : _state.phase,
        currentTrack: currentTrack,
        position: currentTrack == null ? Duration.zero : _state.position,
        buffered: currentTrack == null ? Duration.zero : _state.buffered,
        duration: currentTrack == null ? null : _state.duration,
        queue: queue,
        failure: currentTrack == null ? null : _state.failure,
      ),
    );
    if (_state.shuffleEnabled) {
      if (rebuildShuffle) {
        _rebuildShuffleOrder();
      } else if (currentId != null) {
        _syncShuffleCursor(currentId);
      }
    }
  }

  bool _retainsCurrentTrack(QueueSnapshot queue) {
    final currentTrack = _state.currentTrack;
    final currentId = queue.currentEntryId;
    return currentTrack != null &&
        currentId == _state.queue.currentEntryId &&
        queue.entries.any(
          (entry) => entry.id == currentId && entry.track == currentTrack.ref,
        );
  }

  Future<void> _startPlayback() async {
    _checkNotDisposed();
    _sessionRevision++;
    _completionHandled = false;
    await _engine.play();
  }

  Future<void> _stopEngine() async {
    _sessionRevision++;
    _completionHandled = true;
    await _engine.stop();
    _loadedEntryId = null;
  }

  void _checkNotDisposed() {
    if (_disposed) throw StateError('PlaybackController is disposed');
  }

  void _rebuildShuffleOrder() {
    final currentId = _state.queue.currentEntryId;
    final remaining = _state.queue.entries
        .map((entry) => entry.id)
        .where((id) => id != currentId)
        .toList();
    for (var index = remaining.length - 1; index > 0; index--) {
      final selected = _randomIndex(index + 1);
      if (selected < 0 || selected > index) {
        throw StateError('PlaybackRandomIndex returned an out-of-range value');
      }
      final value = remaining[index];
      remaining[index] = remaining[selected];
      remaining[selected] = value;
    }
    _shuffleOrder = [?currentId, ...remaining];
    _shuffleCursor = currentId == null ? -1 : 0;
  }

  void _ensureShuffleOrder() {
    final queueIds = _state.queue.entries.map((entry) => entry.id).toSet();
    if (_shuffleOrder.length != queueIds.length ||
        !_shuffleOrder.every(queueIds.contains)) {
      _rebuildShuffleOrder();
      return;
    }
    final currentId = _state.queue.currentEntryId;
    if (currentId != null) _syncShuffleCursor(currentId);
  }

  void _syncShuffleCursor(String entryId) {
    final index = _shuffleOrder.indexOf(entryId);
    if (index >= 0) _shuffleCursor = index;
  }

  Future<void> _guarded(
    String operation,
    Future<void> Function() callback,
  ) async {
    try {
      await callback();
    } catch (error, stack) {
      if (error is UnsupportedError || error is ArgumentError) rethrow;
      final failure = _safeFailure(error, operation);
      _publish(_state.copyWith(phase: PlaybackPhase.error, failure: failure));
      Error.throwWithStackTrace(failure, stack);
    }
  }

  Future<void> _schedule(Future<void> Function() operation) {
    final completer = Completer<void>();
    final previous = _operationTail;
    _operationTail = () async {
      await previous;
      if (_disposed) {
        completer.completeError(StateError('PlaybackController is disposed'));
        return;
      }
      try {
        await operation();
        completer.complete();
      } catch (error, stack) {
        completer.completeError(error, stack);
      }
    }();
    return completer.future;
  }

  void _publish(PlaybackState value) {
    if (_disposed) return;
    _state = value;
    notifyListeners();
    if (_mediaInitialized) {
      unawaited(_queueMediaSynchronization(value));
    }
  }

  void _publishFailure(Object error, String operation) {
    if (_disposed) return;
    final failure = _safeFailure(error, operation);
    _publish(_state.copyWith(phase: PlaybackPhase.error, failure: failure));
  }

  Future<void> _synchronizeMediaSession(PlaybackState value) async {
    final track = value.currentTrack;
    if (track == null) {
      _mediaTrack = null;
      await _mediaSession.clear();
      return;
    }
    if (_mediaTrack != track.ref) {
      await _mediaSession.updateMetadata(track);
      _mediaTrack = track.ref;
    }
    if (_disposed) return;
    await _mediaSession.updatePlaybackState(value);
  }

  Future<void> _queueMediaSynchronization(PlaybackState value) {
    final previous = _mediaSyncTail;
    _mediaSyncTail = () async {
      await previous;
      if (_disposed) return;
      try {
        await _synchronizeMediaSession(value);
      } catch (_) {
        // Media controls are auxiliary and must never stop audio playback.
      }
    }();
    return _mediaSyncTail;
  }

  QueueEntry _entry(String id) {
    for (final entry in _state.queue.entries) {
      if (entry.id == id) return entry;
    }
    throw _queueEntryMissing(id);
  }

  DomainFailure _queueEntryMissing(String id) => DomainFailure(
    code: DomainFailureCode.notFound,
    diagnosticId: 'playback.queue-entry-not-found',
  );

  DomainFailure _queueTrackMissing(TrackRef track) => DomainFailure(
    code: DomainFailureCode.notFound,
    diagnosticId: 'playback.track-not-found',
    sourceId: track.sourceId,
  );

  DomainFailure? _availabilityFailure(Track track) =>
      switch (track.availability) {
        TrackAvailability.available => null,
        TrackAvailability.sourceDisabled => DomainFailure(
          code: DomainFailureCode.sourceDisabled,
          diagnosticId: 'playback.source-disabled',
          sourceId: track.sourceId,
        ),
        TrackAvailability.sourceRemoved => DomainFailure(
          code: DomainFailureCode.sourceRemoved,
          diagnosticId: 'playback.source-removed',
          sourceId: track.sourceId,
        ),
        TrackAvailability.localMissing => DomainFailure(
          code: DomainFailureCode.localFileMissing,
          diagnosticId: 'playback.local-file-missing',
          sourceId: track.sourceId,
        ),
        TrackAvailability.unsupported => DomainFailure(
          code: DomainFailureCode.unsupportedAudioFormat,
          diagnosticId: 'playback.audio-format-unsupported',
          sourceId: track.sourceId,
        ),
      };

  DomainFailure _safeFailure(Object error, String operation) =>
      error is DomainFailure
      ? error
      : DomainFailure(
          code: DomainFailureCode.unknown,
          diagnosticId: 'playback.$operation',
        );

  QueueSnapshot _snapshot(
    Iterable<QueueEntry> entries, {
    String? currentEntryId,
  }) => QueueSnapshot(
    entries: entries,
    currentEntryId: currentEntryId,
    updatedAt: _clock(),
  );

  List<QueueEntry> _normalize(Iterable<QueueEntry> entries) =>
      List<QueueEntry>.unmodifiable(
        entries.indexed.map(
          (indexed) => QueueEntry(
            id: indexed.$2.id,
            track: indexed.$2.track,
            position: indexed.$1,
            addedAt: indexed.$2.addedAt,
          ),
        ),
      );

  void _requireEngine() {
    if (!_engine.isAvailable) {
      throw UnsupportedError(
        'Windows and Android audio POC has not selected a production backend',
      );
    }
  }

  void _validateVolume(double value) {
    if (!value.isFinite || value < 0 || value > 1) {
      throw ArgumentError.value(value, 'value', 'must be between 0 and 1');
    }
  }

  void _validatePlaybackRate(double value) {
    if (!value.isFinite || value < 0.5 || value > 2) {
      throw ArgumentError.value(value, 'value', 'must be between 0.5 and 2');
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _closeFuture = _drain();
    unawaited(_closeFuture!.catchError((Object _) {}));
    super.dispose();
  }

  /// The owner must await this before releasing the engine, session or data.
  Future<void> close() {
    dispose();
    return _closeFuture!;
  }

  Future<void> _drain() async {
    try {
      await _subscription.cancel();
    } finally {
      await _operationTail;
      await _mediaSyncTail;
    }
  }
}

DateTime _utcNow() => DateTime.now().toUtc();
