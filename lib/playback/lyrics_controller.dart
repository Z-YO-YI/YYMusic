import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/models/domain_failure.dart';
import '../domain/models/load_state.dart';
import '../domain/models/lyrics.dart';
import '../domain/models/lyrics_timeline.dart';
import '../domain/models/track.dart';
import '../domain/repositories/lyrics_repository.dart';
import 'playback_controller.dart';
import 'playback_state.dart';

typedef _LyricsIdentity = ({String entryId, TrackRef track});

/// Root-owned, explicitly activated projection of the unique playback clock.
///
/// Borrows the repository and playback controller. Deactivation cancels intent,
/// not an accepted repository read; [close] drains work before storage closes.
final class LyricsController extends ChangeNotifier {
  LyricsController({required this._playback, this._repository});

  final PlaybackController _playback;
  final LyricsRepository? _repository;
  LoadState<LyricsDocument> _state = const LoadState.idle();
  LyricsTimeline? _timeline;
  _LyricsIdentity? _identity;
  int? _activeIndex;
  DomainFailure? _seekFailure;
  int _generation = 0;
  bool _active = false;
  bool _pending = false;
  bool _disposed = false;
  bool _notifierDisposed = false;
  int _notificationDepth = 0;
  Future<void>? _worker;
  Future<void>? _closeFuture;
  final _seeks = <Future<void>>{};

  LoadState<LyricsDocument> get state => _state;
  int? get activeIndex => _activeIndex;
  DomainFailure? get seekFailure => _seekFailure;
  bool get isActive => _active;

  /// The independent lyrics route owns this activity signal, not each Shell.
  void setActive(bool value) {
    if (_disposed || _active == value) return;
    _active = value;
    if (value) {
      _playback.addListener(_onPlayback);
      _reload();
    } else {
      _playback.removeListener(_onPlayback);
      _clear();
      _publish();
    }
  }

  /// Explicit retry/refresh; position ticks never reread the repository.
  void refresh() {
    if (_disposed || !_active) return;
    _reload();
  }

  _LyricsIdentity? _currentIdentity() {
    final playback = _playback.state;
    final entryId = playback.queue.currentEntryId;
    final track = playback.currentTrack?.ref;
    return entryId == null || track == null
        ? null
        : (entryId: entryId, track: track);
  }

  void _onPlayback() {
    if (_disposed || !_active) return;
    if (_identity != _currentIdentity()) {
      _reload();
      return;
    }
    final index = _timeline?.activeIndex(_playback.state.position);
    if (_activeIndex == index) return;
    _activeIndex = index;
    _publish();
  }

  void _clear() {
    _generation++;
    _pending = false;
    _identity = null;
    _timeline = null;
    _activeIndex = null;
    _seekFailure = null;
    _state = const LoadState.idle();
  }

  void _reload() {
    _clear();
    _identity = _currentIdentity();
    if (_identity != null) {
      if (_repository == null) {
        _state = LoadState.error(_failure('lyrics.unavailable'));
      } else {
        _pending = true;
        _state = const LoadState.loading();
      }
    }
    _publish();
    _startWorker();
  }

  void _startWorker() {
    if (_disposed || !_active || !_pending || _worker != null) return;
    // Register before calling any dependency, including synchronous reentrancy.
    _worker = Future<void>.microtask(() async {
      try {
        while (!_disposed && _active && _pending) {
          final identity = _identity!;
          final generation = _generation;
          _pending = false;
          try {
            final document = await _repository!.getLyrics(identity.track);
            if (!_isCurrent(generation, identity)) continue;
            if (document != null && document.track != identity.track) {
              throw _failure(
                'lyrics.load',
                code: DomainFailureCode.schemaMismatch,
              );
            }
            _timeline = document == null ? null : LyricsTimeline(document);
            _activeIndex = _timeline?.activeIndex(_playback.state.position);
            _state = document == null
                ? const LoadState.empty()
                : LoadState.data(document);
          } catch (error) {
            if (!_isCurrent(generation, identity)) continue;
            _state = LoadState.error(_failure('lyrics.load', error: error));
          }
          _publish();
        }
      } finally {
        _worker = null;
      }
    });
  }

  bool _isCurrent(int generation, _LyricsIdentity identity) =>
      !_disposed &&
      _active &&
      generation == _generation &&
      _identity == identity &&
      _currentIdentity() == identity;

  bool _canSeek(int generation, _LyricsIdentity identity) =>
      _isCurrent(generation, identity) &&
      _playback.isAvailable &&
      switch (_playback.state.phase) {
        PlaybackPhase.ready ||
        PlaybackPhase.playing ||
        PlaybackPhase.paused ||
        PlaybackPhase.completed => true,
        _ => false,
      };

  /// Requires the exact visible state snapshot, not just a reused document.
  /// Stale, hidden, plain or invalid line actions are safe no-ops.
  Future<void> seekLine(
    int index, {
    required LoadState<LyricsDocument> expectedState,
  }) {
    final identity = _identity;
    final generation = _generation;
    if (identity == null ||
        !identical(expectedState, _state) ||
        !_canSeek(generation, identity)) {
      return Future<void>.value();
    }
    final target = _timeline?.seekTarget(
      index,
      duration: _playback.state.duration,
    );
    if (target == null) return Future<void>.value();
    final completion = Completer<void>();
    _seeks.add(completion.future);
    unawaited(() async {
      try {
        await _playback.seek(
          target,
          expectedEntryId: identity.entryId,
          canSeek: () =>
              identical(expectedState, _state) &&
              _canSeek(generation, identity) &&
              _timeline?.seekTarget(
                    index,
                    duration: _playback.state.duration,
                  ) ==
                  target,
        );
        if (_isCurrent(generation, identity) && _seekFailure != null) {
          _seekFailure = null;
          _publish();
        }
      } catch (error) {
        if (_isCurrent(generation, identity)) {
          _seekFailure = _failure('lyrics.seek', error: error);
          _publish();
        }
      } finally {
        _seeks.remove(completion.future);
        completion.complete();
      }
    }());
    return completion.future;
  }

  DomainFailure _failure(
    String diagnostic, {
    Object? error,
    DomainFailureCode? code,
  }) => DomainFailure(
    code:
        code ??
        (error is DomainFailure ? error.code : DomainFailureCode.unknown),
    diagnosticId: diagnostic,
  );

  void _publish() {
    if (_disposed) return;
    _notificationDepth++;
    try {
      notifyListeners();
    } finally {
      _notificationDepth--;
      if (_disposed) dispose();
    }
  }

  @override
  void dispose() {
    if (!_disposed) {
      _disposed = true;
      if (_active) _playback.removeListener(_onPlayback);
      _active = false;
      _clear();
      _closeFuture = _drain();
    }
    if (_notifierDisposed || _notificationDepth != 0) return;
    _notifierDisposed = true;
    super.dispose();
  }

  /// Await before releasing the shared audio engine or database.
  Future<void> close() {
    dispose();
    return _closeFuture!;
  }

  Future<void> _drain() async {
    await _worker;
    await Future.wait(_seeks.toList());
  }
}
