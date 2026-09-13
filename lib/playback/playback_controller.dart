import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../domain/models/collection_models.dart';
import '../domain/models/domain_failure.dart';
import '../domain/models/queue_edit.dart';
import '../domain/models/sleep_timer_snapshot.dart';
import '../domain/models/track.dart';
import '../domain/repositories/collection_repository.dart';
import '../domain/repositories/library_repository.dart';
import '../platform/contracts/media_session_gateway.dart';
import 'audio_engine.dart';
import 'audio_engine_state.dart';
import 'playback_continuation_restore.dart';
import 'playback_history_recorder.dart';
import 'playback_sleep_restore.dart';
import 'playback_sleep_timer_state.dart';
import 'playback_source_resolver.dart';
import 'playback_state.dart';
import 'sleep_fade_runner.dart';

part 'catalog_selection_playback.dart';
part 'queue_editing.dart';
part 'sleep_deadline_actions.dart';
part 'sleep_restore_actions.dart';
part 'sleep_fade_actions.dart';

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
    String Function()? historyIdFactory,
    PlaybackSleepTimerScheduler? sleepScheduler,
    Duration Function()? sleepFadeElapsed,
    PlaybackSleepTimerScheduler? sleepFadeScheduler,
  }) : _libraryRepository = library,
       _collectionRepository = collection,
       _resolver = sourceResolver,
       _mediaSession = mediaSession ?? const UnavailableMediaSessionGateway(),
       _clock = clock ?? _utcNow,
       _sleepScheduler = sleepScheduler ?? Timer.new,
       _sleepFadeTiming = (
         elapsed: sleepFadeElapsed,
         scheduler: sleepFadeScheduler,
       ),
       _randomIndex = randomIndex ?? Random().nextInt,
       history = PlaybackHistoryRecorder(
         collection: collection,
         clock: clock,
         idFactory: historyIdFactory,
       ) {
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
  final PlaybackSleepTimerScheduler _sleepScheduler;
  final ({Duration Function()? elapsed, PlaybackSleepTimerScheduler? scheduler})
  _sleepFadeTiming;
  SleepFadeRunner? _sleepFade;
  final Set<Future<void>> _sleepFadeJobs = {};
  bool _fadeVolumeDirty = false;
  DomainFailure? _fadeRestoreFailure;
  Timer? _sleepWake;
  int _sleepGeneration = 0;
  PlaybackSleepTimerState _sleepState = const PlaybackSleepTimerState.off();
  final PlaybackRandomIndex _randomIndex;
  final PlaybackHistoryRecorder history;
  late final StreamSubscription<AudioEngineState> _subscription;

  PlaybackState _state = PlaybackState();
  // App volume intent is distinct from backend amplitude (e.g. a sleep fade).
  // Before the first valid command, backend reports seed the initial value.
  double? _userVolume;
  bool _continueAfterTrack = true;
  int _continuationRevision = 0;
  int _continuationIntentRevision = 0;
  bool _continuationRestoreCaptured = false;
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
  bool _notifierDisposed = false;
  int _notificationDepth = 0;
  int _catalogSequence = 0;
  Future<void>? _closeFuture;

  PlaybackState get state => _state;
  bool get isClosed => _disposed;
  bool get continueAfterTrack => _continueAfterTrack;

  /// Applies to natural completion only, including automatic repeat-one.
  /// Changing this never starts/stops the current track or resumes an ended one.
  void setContinueAfterTrack(bool enabled) {
    if (_disposed) return;
    // An explicit choice of the current value must still defeat a late restore.
    _continuationIntentRevision++;
    if (enabled == _continueAfterTrack) return;
    _continueAfterTrack = enabled;
    _continuationRevision++;
    _publish(_state);
  }

  /// Issues one startup permit before storage I/O and any explicit choice.
  PlaybackContinuationRestoreAction? captureContinuationRestore() {
    if (_disposed ||
        _continuationRestoreCaptured ||
        _continuationIntentRevision != 0) {
      return null;
    }
    _continuationRestoreCaptured = true;
    final revision = _continuationIntentRevision;
    var used = false;
    bool current() =>
        !_disposed && !used && revision == _continuationIntentRevision;
    return PlaybackContinuationRestoreAction(
      isCurrent: current,
      apply: (enabled) {
        if (!current()) return PlaybackContinuationRestoreResult.superseded;
        used = true;
        setContinueAfterTrack(enabled);
        return !_disposed && _continuationIntentRevision == revision + 1
            ? PlaybackContinuationRestoreResult.restored
            : PlaybackContinuationRestoreResult.superseded;
      },
    );
  }

  PlaybackSleepTimerState get sleepTimer => _sleepState;

  /// Read-only wall-clock projection. Reading never consumes the deadline.
  Duration? get sleepRemaining {
    final deadline = _sleepState.deadline;
    if (_disposed ||
        _sleepState.phase != PlaybackSleepPhase.armed ||
        deadline == null) {
      return null;
    }
    final remaining = deadline.difference(_clock().toUtc());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Null cancels. Never starts playback; persistence observes accepted intent.
  void setSleepTimer(PlaybackSleepDuration? duration) =>
      _setSleepTimer(duration);

  /// Capture before loading storage. User sleep changes revoke late restores.
  PlaybackSleepRestoreAction? captureSleepRestore() => _captureSleepRestore();

  /// False leaves the prior intent intact when no loaded current entry exists.
  bool setSleepAtCurrentEntryEnd() => _setSleepAtCurrentEntryEnd();
  bool get canSleepAtCurrentEntryEnd => _canSleepAtCurrentEntryEnd;
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
          history.begin(_state.currentTrack!.ref);
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
    _interruptSleepFade();
    history.suspend();
    _sessionRevision++;
    try {
      await _guarded('pause', _engine.pause);
    } finally {
      await _restoreFadeVolume();
    }
  });

  Future<void> stop() => _schedule(() async {
    _requireEngine();
    await _guarded('stop', _stopEngine);
  });

  /// Seeks through the shared command queue, optionally revoking a UI intent.
  Future<void> seek(
    Duration position, {
    String? expectedEntryId,
    bool Function()? canSeek,
  }) => _schedule(() async {
    if (canSeek?.call() == false) return;
    if (expectedEntryId != null &&
        expectedEntryId != _state.queue.currentEntryId) {
      return;
    }
    _requireEngine();
    if (position.isNegative) {
      throw ArgumentError.value(position, 'position', 'must not be negative');
    }
    _interruptSleepFade();
    await _restoreFadeVolume();
    final duration = _state.duration;
    final target = duration != null && position > duration
        ? duration
        : position;
    _sessionRevision++;
    final replay =
        _state.phase == PlaybackPhase.completed &&
        _state.currentTrack != null &&
        (duration == null || target < duration);
    if (replay) history.begin(_state.currentTrack!.ref);
    history.suspend();
    await _guarded('seek', () => _engine.seek(target));
    history.activate();
  });

  Future<void> setVolume(double value) => _schedule(() async {
    _requireEngine();
    _validateVolume(value);
    _interruptSleepFade();
    // Shield the last confirmed intent before invoking a reentrant backend.
    // On failure keep it; never present a rejected command as successful.
    _userVolume ??= _state.volume;
    await _guarded('set-volume', () async {
      await _engine.setVolume(value);
      if (_disposed) return;
      _userVolume = value;
      _fadeVolumeDirty = false;
      _fadeRestoreFailure = null;
      _publish(_state.copyWith(volume: value));
    });
  });

  Future<void> setPlaybackRate(double value) => _schedule(() async {
    _requireEngine();
    _validatePlaybackRate(value);
    await _guarded('set-playback-rate', () => _engine.setPlaybackRate(value));
  });

  /// Plays this exact queue entry, optionally canceling a pending UI intent.
  Future<void> playEntry(String entryId, {bool Function()? canPlay}) =>
      _schedule(() => _playEntryInternal(entryId, canPlay: canPlay));

  /// One serialized command, preserving the queue and full source identity.
  /// A revoked UI intent never starts audio after a queued/read/load boundary.
  Future<void> playCatalogTrack(TrackRef track, {bool Function()? canPlay}) =>
      _schedule(
        () => _guarded('catalog-play', () async {
          if (canPlay?.call() == false) return;
          _requireEngine();
          var id = _state.queue.entries
              .where((entry) => entry.track == track)
              .firstOrNull
              ?.id;
          if (id == null) {
            final now = _clock().toUtc();
            String candidate;
            do {
              candidate =
                  'catalog-${now.microsecondsSinceEpoch}-${_catalogSequence++}';
            } while (_state.queue.entries.any(
              (entry) => entry.id == candidate,
            ));
            await _commitQueue(
              _snapshot(
                _normalize([
                  ..._state.queue.entries,
                  QueueEntry(
                    id: candidate,
                    track: track,
                    position: _state.queue.entries.length,
                    addedAt: now,
                  ),
                ]),
                currentEntryId: _state.queue.currentEntryId,
              ),
            );
            id = candidate;
          }
          if (canPlay?.call() == false) return;
          await _playEntryInternal(id, canPlay: canPlay);
        }),
      );

  Future<void> skipNext() => _schedule(
    () => _guarded('skip-next', () => _advanceInternal(isAutomatic: false)),
  );

  /// Replaces the queue and begins a complete reference selection in one command.
  /// Returns false for empty/revoked work. Committed queues are never rolled back
  /// when a route leaves; a revoked pending load must not start audio.
  Future<bool> playCatalogSelection(
    Iterable<TrackRef> tracks, {
    required bool shuffle,
    bool Function()? canPlay,
  }) => _playSelection(tracks, shuffle: shuffle, canPlay: canPlay);

  Future<void> skipPrevious() => _schedule(() async {
    _requireEngine();
    _interruptSleepFade();
    await _restoreFadeVolume();
    if (_state.position > const Duration(seconds: 3)) {
      _sessionRevision++;
      await _guarded('skip-previous-seek', () => _engine.seek(Duration.zero));
      return;
    }
    final entry = _previousEntry();
    if (entry != null) await _playEntryInternal(entry.id);
  });

  /// Edits only the captured root snapshot; false means stale, revoked or no-op.
  /// Accepted persistence drains even if its page leaves while SQL is running.
  Future<bool> editQueue(QueueEdit edit, {bool Function()? canEdit}) =>
      _editQueue(edit, canEdit: canEdit);

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
        preserveShuffle: true,
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
        preserveShuffle: true,
        nextEntryId: entry.id,
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

  Future<void> _playEntryInternal(
    String entryId, {
    bool Function()? canPlay,
  }) async {
    if (canPlay?.call() == false) return;
    _requireEngine();
    try {
      final entry = _entry(entryId);
      _interruptSleepFade();
      await _restoreFadeVolume();
      if (canPlay == null) {
        _sessionRevision++;
        _completionHandled = true;
      }
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
      if (canPlay?.call() == false) return;
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
      if (canPlay?.call() == false) return;
      if (source.track != track.ref) {
        throw DomainFailure(
          code: DomainFailureCode.schemaMismatch,
          diagnosticId: 'playback.source-track-mismatch',
          sourceId: track.sourceId,
        );
      }
      if (canPlay != null) {
        _sessionRevision++;
        _completionHandled = true;
      }
      if (_state.queue.currentEntryId != entryId) {
        await _commitQueue(
          _snapshot(_state.queue.entries, currentEntryId: entryId),
          rebuildShuffle: false,
        );
      }
      // Explicit replay and error recovery must not retain a previous source.
      if (canPlay?.call() == false) return;
      if (_loadedEntryId != null) await _stopEngine();
      _checkNotDisposed();
      if (canPlay?.call() == false) return;
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
      history.end();
      await _engine.load(source);
      _loadingSource = false;
      _checkNotDisposed();
      _loadedEntryId = entryId;
      history.begin(track.ref);
      if (canPlay?.call() == false) {
        await _stopEngine();
        return;
      }
      await _startPlayback(canPlay: canPlay);
    } catch (error, stack) {
      _loadingSource = false;
      history.end();
      final failure = _safeFailure(error, 'load-entry');
      _publish(_state.copyWith(phase: PlaybackPhase.error, failure: failure));
      Error.throwWithStackTrace(failure, stack);
    }
  }

  Future<void> _advanceInternal({
    required bool isAutomatic,
    bool Function()? canAdvance,
  }) async {
    _requireEngine();
    if (canAdvance?.call() == false) return;
    if (!isAutomatic) {
      _interruptSleepFade();
      await _restoreFadeVolume();
    }
    if (isAutomatic && _state.repeatMode == RepeatMode.one) {
      if (_state.currentTrack != null) {
        history.begin(_state.currentTrack!.ref);
        await _engine.seek(Duration.zero);
        await _startPlayback(canPlay: canAdvance);
      }
      return;
    }
    final next = _nextEntry();
    if (next != null) await _playEntryInternal(next.id, canPlay: canAdvance);
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
      return _entry(_shuffleOrder[_shuffleCursor + 1]);
    }
    if (_state.repeatMode != RepeatMode.all) return null;
    _rebuildShuffleOrder();
    if (_shuffleCursor + 1 < _shuffleOrder.length) {
      return _entry(_shuffleOrder[_shuffleCursor + 1]);
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
        _state.copyWith(
          volume: _userVolume ?? value.volume,
          playbackRate: value.playbackRate,
        ),
      );
      return;
    }
    if (value.phase == AudioEnginePhase.idle && !_loadingSource) {
      history.end();
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
    final continuationRevision = _continuationRevision;
    if (!_loadingSource &&
        _loadedEntryId != null &&
        _loadedEntryId == _state.queue.currentEntryId &&
        _state.currentTrack != null) {
      history.observe(value);
    }
    final completedEntryId = _loadedEntryId;
    final sleepConsumed =
        value.phase == AudioEnginePhase.completed &&
        !_completionHandled &&
        _consumeEntrySleep(completedEntryId);
    final shouldAdvance =
        _continueAfterTrack &&
        value.phase == AudioEnginePhase.completed &&
        !_completionHandled &&
        !sleepConsumed &&
        _sleepState.phase != PlaybackSleepPhase.pausing;
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
        volume: _userVolume ?? value.volume,
        playbackRate: value.playbackRate,
        failure: value.failure,
      ),
    );
    if (shouldAdvance) {
      unawaited(
        _schedule(
          () => _guarded('auto-advance', () async {
            bool canContinue() =>
                !_disposed &&
                _continueAfterTrack &&
                continuationRevision == _continuationRevision;
            if (!canContinue() ||
                _sessionRevision != revision ||
                _loadedEntryId != completedEntryId ||
                _state.phase != PlaybackPhase.completed) {
              return;
            }
            await _advanceInternal(isAutomatic: true, canAdvance: canContinue);
          }),
        ).catchError((Object _) {}),
      );
    }
  }

  Future<bool> _commitQueue(
    QueueSnapshot snapshot, {
    bool rebuildShuffle = true,
    _SelectionMode? selectionMode,
    bool Function()? canCommit,
    bool preserveShuffle = false,
    String? nextEntryId,
  }) async {
    if (canCommit?.call() == false) return false;
    if (!_retainsCurrentTrack(snapshot) &&
        _state.currentTrack != null &&
        _engine.isAvailable) {
      await _stopEngine();
    }
    if (canCommit?.call() == false) return false;
    _checkNotDisposed();
    final collection = _collectionRepository;
    if (collection != null) await collection.saveQueue(snapshot);
    _applyQueue(
      snapshot,
      rebuildShuffle: rebuildShuffle,
      selectionMode: selectionMode,
      preserveShuffle: preserveShuffle,
      nextEntryId: nextEntryId,
    );
    return true;
  }

  void _applyQueue(
    QueueSnapshot queue, {
    bool rebuildShuffle = true,
    _SelectionMode? selectionMode,
    bool preserveShuffle = false,
    String? nextEntryId,
  }) {
    final currentTrack = _retainsCurrentTrack(queue)
        ? _state.currentTrack
        : null;
    final currentId = queue.currentEntryId;
    if (selectionMode != null) {
      _shuffleOrder = selectionMode.order;
      _shuffleCursor = selectionMode.enabled ? 0 : -1;
    }
    _publish(
      _state.copyWith(
        phase: currentTrack == null ? PlaybackPhase.idle : _state.phase,
        currentTrack: currentTrack,
        position: currentTrack == null ? Duration.zero : _state.position,
        buffered: currentTrack == null ? Duration.zero : _state.buffered,
        duration: currentTrack == null ? null : _state.duration,
        queue: queue,
        shuffleEnabled: selectionMode?.enabled,
        failure: currentTrack == null ? null : _state.failure,
      ),
    );
    if (selectionMode == null && _state.shuffleEnabled) {
      if (preserveShuffle) {
        _extendShuffleOrder(queue, nextEntryId);
      } else if (rebuildShuffle) {
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

  Future<void> _startPlayback({bool Function()? canPlay}) async {
    _checkNotDisposed();
    if (canPlay?.call() == false) return;
    _interruptSleepFade();
    await _restoreFadeVolume();
    _checkNotDisposed();
    if (canPlay?.call() == false) return;
    if (history.ended && _state.currentTrack != null) {
      history.begin(_state.currentTrack!.ref);
    }
    history.activate();
    _sessionRevision++;
    _completionHandled = false;
    await _engine.play();
  }

  Future<void> _stopEngine() async {
    _interruptSleepFade();
    history.end();
    _sessionRevision++;
    _completionHandled = true;
    try {
      await _engine.stop();
    } finally {
      await _restoreFadeVolume();
    }
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
      history.end();
      final failure = _safeFailure(error, operation);
      _publish(_state.copyWith(phase: PlaybackPhase.error, failure: failure));
      Error.throwWithStackTrace(failure, stack);
    }
  }

  Future<void> _schedule(
    Future<void> Function() operation, {
    bool allowClosed = false,
  }) {
    final completer = Completer<void>();
    final previous = _operationTail;
    _operationTail = () async {
      await previous;
      if (_disposed && !allowClosed) {
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
    _reconcileEntrySleep(value);
    _state = value;
    _notificationDepth++;
    try {
      notifyListeners();
    } finally {
      _notificationDepth--;
      if (_disposed) dispose();
    }
    if (!_disposed && _mediaInitialized) {
      unawaited(_queueMediaSynchronization(value));
    }
  }

  void _publishFailure(Object error, String operation) {
    if (_disposed) return;
    history.end();
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
    if (!_disposed) {
      _cancelSleepTimer();
      _disposed = true;
      history.dispose();
      _closeFuture = _drain();
      unawaited(_closeFuture!.catchError((Object _) {}));
    }
    if (_notifierDisposed || _notificationDepth != 0) return;
    _notifierDisposed = true;
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
      try {
        await Future.wait(_sleepFadeJobs.toList());
        await _operationTail;
        final failure = _fadeRestoreFailure;
        if (failure != null) throw failure;
      } finally {
        await _mediaSyncTail;
        await history.close();
      }
    }
  }
}

DateTime _utcNow() => DateTime.now().toUtc();
