part of 'playback_controller.dart';

extension NativeSequencePlayback on PlaybackController {
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

  Future<({AudioSequence sequence, List<Track> tracks})> _resolveNativeSequence(
    String entryId,
    Track track,
    PlayableSource source,
    bool Function()? canPlay,
  ) async {
    final revision = _nativePolicyRevision;
    if (_state.shuffleEnabled) _ensureShuffleOrder();
    final order = _state.shuffleEnabled
        ? List<String>.of(_shuffleOrder)
        : _state.queue.entries.map((entry) => entry.id).toList();
    final start = order.indexOf(entryId);
    final entries = [AudioSequenceEntry(entryId: entryId, source: source)];
    final tracks = [track];
    for (final id in order.skip(start + 1).take(2)) {
      if (!_continueAfterTrack ||
          _state.repeatMode == RepeatMode.one ||
          revision != _nativePolicyRevision ||
          canPlay?.call() == false) {
        break;
      }
      try {
        final entry = _entry(id);
        final next = await _libraryRepository!.getTrack(entry.track);
        _checkNotDisposed();
        if (next == null || _availabilityFailure(next) != null) break;
        final resolved = await _resolver!.resolve(next);
        _checkNotDisposed();
        if (resolved.track != next.ref || resolved.expiresAt != null) break;
        entries.add(AudioSequenceEntry(entryId: id, source: resolved));
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
    );
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
    if (index < 0 ||
        index >= binding.cursors.length ||
        binding.cursors[index].entryId != cursor.entryId ||
        binding.cursors[index].track != cursor.track) {
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
          binding.currentIndex = index;
          history.end();
          history.begin(cursor.track);
          history.activate();
          _loadedEntryId = entry.id;
          _sessionRevision++;
          _completionHandled = false;
          _syncShuffleCursor(entry.id);
          // Replay only bounded, actually observed evidence after persistence.
          // Metadata and each corresponding native clock publish atomically.
          for (final evidence in pending.evidence) {
            if (_disposed || !identical(_nativeSequence, binding)) return;
            _acceptEngineState(
              evidence,
              adoptedQueue: snapshot,
              adoptedTrack: binding.tracks[index],
            );
          }
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

  void _ensureNativeLookahead(_NativeSequenceBinding binding) {
    if (!_canRefill(binding) ||
        binding.refilling ||
        binding.cursors.length - binding.highestObserved - 1 >= 2) {
      return;
    }
    final order = _state.shuffleEnabled
        ? List<String>.of(_shuffleOrder)
        : _state.queue.entries.map((entry) => entry.id).toList();
    final tail = binding.cursors.last;
    final nextIndex = order.indexOf(tail.entryId) + 1;
    if (nextIndex <= 0 || nextIndex >= order.length) return;
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
            entries: [AudioSequenceEntry(entryId: entry.id, source: source)],
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
              if (binding.highestObserved >= oldCursors.length) {
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
      binding.cursors[binding.highestObserved],
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
  _NativeSequenceBinding(this.cursors, this.tracks);
  List<AudioSequenceCursor> cursors;
  List<Track> tracks;
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
