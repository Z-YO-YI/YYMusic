part of 'playback_controller.dart';

extension NativeSequencePlayback on PlaybackController {
  Future<bool> _refreshLoadedSourceIfExpired(
    Duration position, {
    bool Function()? canPlay,
  }) async {
    final deadline = _loadedSourceExpiresAt;
    final entryId = _loadedEntryId;
    if (deadline == null ||
        entryId == null ||
        _clock().toUtc().isBefore(deadline)) {
      return false;
    }
    final entry = _entry(entryId);
    final wasNative = _nativeSequence != null;
    _nativeSequence = null;
    history.suspend();
    try {
      await _engine.pause();
      _checkNotDisposed();
      if (canPlay?.call() == false) return false;
      final track = await _libraryRepository!.getTrack(entry.track);
      _checkNotDisposed();
      if (canPlay?.call() == false) return false;
      if (track == null) throw _queueTrackMissing(entry.track);
      if (track.ref != entry.track) {
        throw DomainFailure(
          code: DomainFailureCode.schemaMismatch,
          diagnosticId: 'playback.refresh-track-mismatch',
          sourceId: entry.track.sourceId,
        );
      }
      final failure = _availabilityFailure(track);
      if (failure != null) throw failure;
      final source = await _resolveFreshSource(track, canPlay: canPlay);
      if (canPlay?.call() == false) return false;
      final plan = wasNative
          ? await _resolveNativeSequence(entryId, track, source, canPlay)
          : null;
      _checkNotDisposed();
      if (canPlay?.call() == false) return false;
      final revision = _nativePolicyRevision;
      _loadingSource = true;
      if (plan == null) {
        await _engine.load(source);
      } else {
        final binding = _NativeSequenceBinding(
          plan.sequence.cursors,
          plan.tracks,
          plan.orders,
          _shuffleOrder,
        );
        _nativeSequence = binding;
        await (_engine as AudioSequenceEngine).loadSequence(plan.sequence);
        if (!identical(_nativeSequence, binding)) {
          throw StateError('Refreshed sequence revoked');
        }
        if (binding.boundaryRequested || revision != _nativePolicyRevision) {
          await _retainNativeCurrent(binding);
        }
      }
      _checkNotDisposed();
      if (canPlay?.call() == false) {
        await _stopEngine();
        return false;
      }
      _loadedEntryId = entryId;
      _loadedSourceExpiresAt = source.expiresAt;
      await _engine.seek(position);
      _checkNotDisposed();
      if (canPlay?.call() == false) {
        await _stopEngine();
        return false;
      }
      return true;
    } catch (_) {
      _nativeSequence = null;
      _loadedEntryId = null;
      _loadedSourceExpiresAt = null;
      try {
        await _engine.stop();
      } catch (_) {
        /* Keep the original failure. */
      }
      rethrow;
    } finally {
      _loadingSource = false;
    }
  }

  Future<PlayableSource> _resolveFreshSource(
    Track track, {
    PlayableSource? previous,
    bool Function()? canPlay,
  }) async {
    var source = previous ?? await _resolver!.resolve(track);
    for (var attempt = 0; attempt < 2; attempt++) {
      _checkNotDisposed();
      if (canPlay?.call() == false) return source;
      if (source.track != track.ref) {
        throw DomainFailure(
          code: DomainFailureCode.schemaMismatch,
          diagnosticId: 'playback.source-track-mismatch',
          sourceId: track.sourceId,
        );
      }
      if (source.isValidAt(_clock())) return source;
      if (attempt == 0) source = await _resolver!.resolve(track);
    }
    throw DomainFailure(
      code: DomainFailureCode.streamUrlExpired,
      diagnosticId: 'playback.source-expired',
      sourceId: track.sourceId,
    );
  }

  /// Explicit integration entry point. The production UI does not enable
  /// gapless until policy, native lifecycle and acoustic acceptance are complete.
  Future<void> playNativeSequence(String entryId, {bool Function()? canPlay}) {
    final expected = _state.queue;
    return _schedule(() async {
      if (!identical(expected, _state.queue) || canPlay?.call() == false) {
        return;
      }
      final engine = _engine;
      if (engine is! AudioSequenceEngine || !engine.supportsSequences) {
        throw DomainFailure(
          code: DomainFailureCode.playbackOpenFailed,
          diagnosticId: 'playback.native-sequence-unavailable',
        );
      }
      await _playEntryInternal(entryId, canPlay: canPlay, nativeSequence: true);
    });
  }

  Future<
    ({
      AudioSequence sequence,
      List<Track> tracks,
      Map<int, List<String>> orders,
    })
  >
  _resolveNativeSequence(
    String entryId,
    Track track,
    PlayableSource source,
    bool Function()? canPlay,
  ) async {
    final revision = _nativePolicyRevision;
    if (_state.shuffleEnabled) _ensureShuffleOrder();
    var order = _state.shuffleEnabled
        ? List<String>.of(_shuffleOrder)
        : _state.queue.entries.map((entry) => entry.id).toList();
    var at = order.indexOf(entryId), cycle = 0;
    final orders = <int, List<String>>{0: List.unmodifiable(order)};
    final entries = [AudioSequenceEntry(entryId: entryId, source: source)];
    final tracks = [track];
    for (var ahead = 0; ahead < 2; ahead++) {
      if (!_continueAfterTrack ||
          _state.repeatMode == RepeatMode.one ||
          revision != _nativePolicyRevision ||
          canPlay?.call() == false) {
        break;
      }
      try {
        at++;
        if (at >= order.length) {
          if (_state.repeatMode != RepeatMode.all) break;
          order = _newNativeCycleOrder(entries.last.entryId);
          at = _state.shuffleEnabled && order.length > 1 ? 1 : 0;
          orders[++cycle] = order;
        }
        final id = order[at];
        final entry = _entry(id);
        final next = await _libraryRepository!.getTrack(entry.track);
        _checkNotDisposed();
        if (next == null || _availabilityFailure(next) != null) break;
        final resolved = await _resolver!.resolve(next);
        _checkNotDisposed();
        if (resolved.track != next.ref || resolved.expiresAt != null) break;
        entries.add(
          AudioSequenceEntry(entryId: id, source: resolved, cycle: cycle),
        );
        tracks.add(next);
      } catch (_) {
        if (_disposed) rethrow;
        // Defer an unavailable tail to the existing per-entry advancement path,
        // which classifies/records errors when that entry is actually requested.
        break;
      }
    }
    if (revision != _nativePolicyRevision ||
        !_continueAfterTrack ||
        _state.repeatMode == RepeatMode.one) {
      entries.removeRange(1, entries.length);
      tracks.removeRange(1, tracks.length);
    }
    return (
      sequence: AudioSequence(entries),
      tracks: List<Track>.unmodifiable(tracks),
      orders: orders,
    );
  }

  List<String> _newNativeCycleOrder(String preceding) {
    final ids = _state.queue.entries.map((entry) => entry.id).toList();
    if (!_state.shuffleEnabled) return List.unmodifiable(ids);
    ids.remove(preceding);
    for (var i = ids.length - 1; i > 0; i--) {
      final picked = _randomIndex(i + 1);
      if (picked < 0 || picked > i) throw StateError('Invalid shuffle index');
      final value = ids[i];
      ids[i] = ids[picked];
      ids[picked] = value;
    }
    return List.unmodifiable([preceding, ...ids]);
  }

  bool _receiveNativeState(AudioEngineState value) {
    final binding = _nativeSequence;
    final cursor = value.sequenceCursor;
    if (cursor == null) {
      if (!_loadingSource &&
          (value.phase == AudioEnginePhase.idle ||
              value.phase == AudioEnginePhase.error)) {
        _nativeSequence = null;
      }
      return false;
    }
    if (binding == null ||
        !identical(binding.identity, cursor.sequenceIdentity)) {
      return true;
    }
    final index = cursor.index;
    if (index < binding.firstIndex ||
        index > binding.cursors.last.index ||
        binding.cursorAt(index).entryId != cursor.entryId ||
        binding.cursorAt(index).cycle != cursor.cycle ||
        binding.cursorAt(index).track != cursor.track) {
      _rejectNativeSequence(binding);
      return true;
    }
    if (index < binding.highestObserved) return true;
    if (index == binding.currentIndex) return false;
    if (binding.pending.containsKey(index)) {
      binding.pending[index]!.accept(value);
      return true;
    }
    if (_loadingSource ||
        binding.boundaryRequested ||
        !_continueAfterTrack ||
        _state.repeatMode == RepeatMode.one ||
        _sleepState.phase == PlaybackSleepPhase.pausing ||
        _consumeEntrySleep(_loadedEntryId) ||
        index != binding.highestObserved + 1) {
      _rejectNativeSequence(binding);
      return true;
    }
    binding.highestObserved = index;
    // Revoke completion work for the preceding index before storage can wait.
    _sessionRevision++;
    binding.pending[index] = _NativePendingTransition(value);
    unawaited(
      _schedule(() async {
        if (!identical(_nativeSequence, binding)) return;
        try {
          if (index != binding.currentIndex + 1) {
            throw StateError('Sequence order changed');
          }
          final entry = _entry(cursor.entryId);
          if (entry.track != cursor.track) {
            throw StateError('Sequence entry changed');
          }
          final snapshot = _snapshot(
            _state.queue.entries,
            currentEntryId: entry.id,
          );
          final collection = _collectionRepository;
          if (collection != null) await collection.saveQueue(snapshot);
          if (_disposed || !identical(_nativeSequence, binding)) return;
          final pending = binding.pending.remove(index)!;
          final previousCycle = binding.cursorAt(binding.currentIndex).cycle;
          binding.currentIndex = index;
          history.end();
          history.begin(cursor.track);
          history.activate();
          _loadedEntryId = entry.id;
          // Future expiring sources are not preloaded (ADR-138).
          _loadedSourceExpiresAt = null;
          _sessionRevision++;
          _completionHandled = false;
          if (_state.shuffleEnabled &&
              cursor.cycle != previousCycle &&
              identical(_shuffleOrder, binding.appliedShuffleOrder)) {
            _shuffleOrder = List.of(binding.orders[cursor.cycle]!);
            binding.appliedShuffleOrder = _shuffleOrder;
          }
          _syncShuffleCursor(entry.id);
          // Replay only bounded, actually observed evidence after persistence.
          // Metadata and each corresponding native clock publish atomically.
          for (final evidence in pending.evidence) {
            if (_disposed || !identical(_nativeSequence, binding)) return;
            _acceptEngineState(
              evidence,
              adoptedQueue: snapshot,
              adoptedTrack: binding.tracks[index - binding.firstIndex],
            );
          }
          await _pruneNativeHistory(binding);
          _ensureNativeLookahead(binding);
        } catch (_) {
          _rejectNativeSequence(binding);
        }
      }).catchError((Object _) {}),
    );
    return true;
  }

  void _requestNativeBoundary() {
    final binding = _nativeSequence;
    if (binding == null || binding.boundaryRequested) return;
    binding.boundaryRequested = true;
    unawaited(
      _schedule(() async {
        if (!identical(_nativeSequence, binding)) return;
        try {
          await _retainNativeCurrent(binding);
        } catch (_) {
          _rejectNativeSequence(binding);
        }
      }).catchError((Object _) {}),
    );
  }

  bool _canRefill(_NativeSequenceBinding binding) =>
      !_disposed &&
      identical(_nativeSequence, binding) &&
      !binding.boundaryRequested &&
      !binding.refillBlocked &&
      _continueAfterTrack &&
      _state.repeatMode != RepeatMode.one &&
      _state.phase != PlaybackPhase.completed &&
      _state.phase != PlaybackPhase.error &&
      _sleepState.phase != PlaybackSleepPhase.pausing;

  Future<void> _pruneNativeHistory(_NativeSequenceBinding binding) async {
    final count = binding.currentIndex - binding.firstIndex;
    if (!identical(_nativeSequence, binding) ||
        count < 8 ||
        binding.pending.isNotEmpty ||
        binding.currentIndex != binding.highestObserved) {
      return;
    }
    if (await (_engine as AudioSequenceEngine).pruneSequenceBefore(
      binding.cursorAt(binding.currentIndex),
    )) {
      binding.cursors = List.unmodifiable(binding.cursors.skip(count));
      binding.tracks = List.unmodifiable(binding.tracks.skip(count));
      binding.orders.removeWhere(
        (cycle, _) => cycle < binding.cursors.first.cycle,
      );
    }
  }

  void _ensureNativeLookahead(_NativeSequenceBinding binding) {
    if (!_canRefill(binding) ||
        binding.refilling ||
        binding.cursors.length >= 11 ||
        binding.cursors.last.index - binding.highestObserved >= 2) {
      return;
    }
    final tail = binding.cursors.last;
    var cycle = tail.cycle;
    var order = binding.orders[cycle]!;
    var nextIndex = order.indexOf(tail.entryId) + 1;
    if (nextIndex <= 0) return;
    if (nextIndex >= order.length) {
      if (_state.repeatMode != RepeatMode.all) return;
      order = binding.orders[++cycle] ??= _newNativeCycleOrder(tail.entryId);
      nextIndex = _state.shuffleEnabled && order.length > 1 ? 1 : 0;
    }
    final entry = _entry(order[nextIndex]);
    final revision = _nativePolicyRevision;
    binding.refilling = true;
    // Register synchronously; resolution must never occupy the command queue.
    final done = Completer<void>();
    _nativeRefillJobs.add(done.future);
    unawaited(() async {
      try {
        final track = await _libraryRepository!.getTrack(entry.track);
        if (!_canRefill(binding) || revision != _nativePolicyRevision) return;
        if (track == null || _availabilityFailure(track) != null) {
          binding.refillBlocked = true;
          return;
        }
        final source = await _resolver!.resolve(track);
        if (!_canRefill(binding) || revision != _nativePolicyRevision) return;
        if (source.track != entry.track || source.expiresAt != null) {
          binding.refillBlocked = true;
          return;
        }
        await _schedule(() async {
          if (!_canRefill(binding) ||
              revision != _nativePolicyRevision ||
              !identical(binding.cursors.last, tail) ||
              _entry(entry.id).track != entry.track) {
            return;
          }
          final request = AudioSequenceAppend(
            expectedTail: tail,
            entries: [
              AudioSequenceEntry(
                entryId: entry.id,
                source: source,
                cycle: cycle,
              ),
            ],
          );
          final oldCursors = binding.cursors, oldTracks = binding.tracks;
          binding.cursors = List.unmodifiable([
            ...oldCursors,
            ...request.cursors,
          ]);
          binding.tracks = List.unmodifiable([...oldTracks, track]);
          try {
            final accepted = await (_engine as AudioSequenceEngine)
                .appendSequence(request);
            if (!accepted && identical(_nativeSequence, binding)) {
              if (binding.highestObserved > oldCursors.last.index) {
                _rejectNativeSequence(binding);
              } else {
                binding.cursors = oldCursors;
                binding.tracks = oldTracks;
                binding.refillBlocked = true;
              }
            }
          } catch (_) {
            _rejectNativeSequence(binding);
          }
        });
      } catch (_) {
        // Leave classification to normal advancement when the entry is due.
        binding.refillBlocked = true;
      } finally {
        binding.refilling = false;
        _nativeRefillJobs.remove(done.future);
        done.complete();
        _ensureNativeLookahead(binding);
      }
    }());
  }

  Future<void> _retainNativeCurrent(_NativeSequenceBinding binding) async {
    binding.boundaryRequested = true;
    final engine = _engine as AudioSequenceEngine;
    if (!await engine.retainSequenceThrough(
      binding.cursorAt(binding.highestObserved),
    )) {
      _rejectNativeSequence(binding);
      throw DomainFailure(
        code: DomainFailureCode.playbackInterrupted,
        diagnosticId: 'playback.native-sequence-boundary',
      );
    }
  }

  void _rejectNativeSequence(_NativeSequenceBinding binding) {
    if (_disposed || !identical(_nativeSequence, binding)) return;
    _nativeSequence = null;
    history.end();
    final revision = ++_sessionRevision;
    final failure = DomainFailure(
      code: DomainFailureCode.playbackInterrupted,
      diagnosticId: 'playback.native-sequence-transition',
    );
    _publish(_state.copyWith(phase: PlaybackPhase.error, failure: failure));
    unawaited(
      _schedule(() async {
        if (_disposed || _sessionRevision != revision) return;
        try {
          await _stopEngine();
        } catch (_) {
          /* Keep the safe failure. */
        }
        _publish(_state.copyWith(phase: PlaybackPhase.error, failure: failure));
      }).catchError((Object _) {}),
    );
  }
}

final class _NativeSequenceBinding {
  _NativeSequenceBinding(
    this.cursors,
    this.tracks,
    Map<int, List<String>> orders,
    this.appliedShuffleOrder,
  ) : orders = Map.of(orders);
  final Map<int, List<String>> orders;
  List<String> appliedShuffleOrder;
  List<AudioSequenceCursor> cursors;
  List<Track> tracks;
  int get firstIndex => cursors.first.index;
  AudioSequenceCursor cursorAt(int index) => cursors[index - firstIndex];
  Object get identity => cursors.first.sequenceIdentity;
  int currentIndex = 0;
  int highestObserved = 0;
  bool boundaryRequested = false;
  bool refilling = false;
  bool refillBlocked = false;
  final pending = <int, _NativePendingTransition>{};
}

final class _NativePendingTransition {
  _NativePendingTransition(AudioEngineState value) : latest = value {
    accept(value);
  }
  AudioEngineState latest;
  AudioEngineState? firstPlaying;
  AudioEngineState? lastPlaying;
  void accept(AudioEngineState value) {
    latest = value;
    if (value.phase == AudioEnginePhase.playing) {
      firstPlaying ??= value;
      lastPlaying = value;
    }
  }

  Iterable<AudioEngineState> get evidence sync* {
    final first = firstPlaying, last = lastPlaying;
    if (first != null && !identical(first, latest)) yield first;
    if (last != null && !identical(last, first) && !identical(last, latest)) {
      yield last;
    }
    yield latest;
  }
}
