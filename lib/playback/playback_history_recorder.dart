import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../domain/models/collection_models.dart';
import '../domain/models/domain_failure.dart';
import '../domain/models/track.dart';
import '../domain/repositories/collection_repository.dart';
import 'audio_engine_state.dart';

/// Root-owned history writer. A play acknowledgement alone never records.
final class PlaybackHistoryRecorder extends ChangeNotifier {
  PlaybackHistoryRecorder({
    this.collection,
    DateTime Function()? clock,
    String Function()? idFactory,
  }) : _clock = clock ?? DateTime.now,
       _idFactory = idFactory ?? _newHistoryId;

  final CollectionRepository? collection;
  final DateTime Function() _clock;
  final String Function() _idFactory;
  TrackRef? _track;
  Duration? _position;
  bool _enabled = false, _ended = true, _confirmed = false;
  bool _disposed = false, _notifierDisposed = false;
  int _notificationDepth = 0, _pending = 0, _sequence = 0;
  int _failureSequence = 0;
  int _lastAssignedMs = -8640000000000000;
  Future<void> _tail = Future<void>.value();
  Future<void>? _closeFuture;
  DomainFailure? _failure;
  _HistoryDraft? _retryDraft;

  DomainFailure? get failure => _failure;
  bool get busy => _pending > 0;
  bool get ended => _ended;
  bool get canRetry =>
      !_disposed &&
      !busy &&
      _retryDraft != null &&
      _retryDraft!.sequence == _sequence;

  /// New source or explicit replay, never an ordinary pause/resume.
  void begin(TrackRef track) {
    if (_disposed) return;
    _track = track;
    _position = null;
    _ended = _confirmed = _enabled = false;
  }

  void activate() {
    if (_disposed || _ended) return;
    _enabled = true;
    _position = null;
  }

  /// A seek discontinuity must not look like elapsed playback time.
  void suspend() {
    _enabled = false;
    _position = null;
  }

  void end() {
    suspend();
    _ended = true;
    _track = null;
  }

  /// Called only for the root's current, fully loaded source.
  void observe(AudioEngineState value) {
    if (_disposed || !_enabled || _ended) return;
    if (value.phase == AudioEnginePhase.playing ||
        value.phase == AudioEnginePhase.completed) {
      final previous = _position;
      _position = value.position;
      if (!_confirmed && previous != null && value.position > previous) {
        _confirmed = true;
        if (collection != null) _confirm(_track!, value.position);
      }
      if (value.phase == AudioEnginePhase.completed) end();
    } else {
      _position = null;
      if (value.phase == AudioEnginePhase.error ||
          value.phase == AudioEnginePhase.idle) {
        end();
      }
    }
  }

  void _confirm(TrackRef track, Duration position) {
    final sequence = ++_sequence;
    _queue(
      () => _HistoryDraft(
        sequence: sequence,
        track: track,
        position: position,
        observedAt: _clock().toUtc(),
        id: _idFactory(),
      ),
    );
  }

  Future<void> retry(DomainFailure expected) {
    if (!canRetry || !identical(expected, failure)) return Future.value();
    final draft = _retryDraft!;
    return _queue(() => draft);
  }

  void dismissFailure(DomainFailure expected) {
    if (_disposed || !identical(expected, failure)) return;
    _failure = null;
    _retryDraft = null;
    _notify();
  }

  /// The existing confirmed clear action shares ordering with accepted writes.
  /// New listening cycles may record afterwards; the current cycle stays heard.
  Future<void> clear() {
    if (_disposed) {
      return Future.error(StateError('History recorder is closed'));
    }
    final cutoff = _sequence, previous = _tail, done = Completer<void>();
    _tail = done.future.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    _pending++;
    unawaited(
      Future<void>(() async {
        try {
          await previous;
          if (collection == null) {
            throw StateError('History storage unavailable');
          }
          await collection!.clearHistory();
          if (_failureSequence <= cutoff) {
            _failure = null;
            _retryDraft = null;
          }
          done.complete();
        } catch (_) {
          done.completeError(
            DomainFailure(
              code: DomainFailureCode.unknown,
              diagnosticId: 'playback.history-clear',
              retryable: true,
            ),
          );
        } finally {
          _pending--;
          _notify();
        }
      }),
    );
    _notify();
    return done.future;
  }

  Future<void> _queue(_HistoryDraft Function() capture) {
    final previous = _tail, done = Completer<void>();
    // Register before clock/idFactory, either of which can reenter root close.
    _tail = done.future;
    _pending++;
    _HistoryDraft? draft;
    try {
      draft = capture();
    } catch (_) {
      _setFailure(null);
    }
    unawaited(
      Future<void>(() async {
        try {
          await previous;
          if (draft != null) {
            try {
              await _store(draft);
              if (identical(_retryDraft, draft)) {
                _retryDraft = null;
                _failure = null;
              }
            } catch (_) {
              _setFailure(draft);
            }
          }
        } finally {
          _pending--;
          done.complete();
          _notify();
        }
      }),
    );
    _notify();
    return done.future;
  }

  Future<void> _store(_HistoryDraft draft) async {
    final entries = await collection!.watchHistory().first;
    if (draft.savedAt == null) {
      // Stable ordering across same-ms starts, restarts and a backward clock.
      var milliseconds = max(
        draft.observedAt.millisecondsSinceEpoch,
        _lastAssignedMs + 1,
      );
      for (final entry in entries) {
        milliseconds = max(
          milliseconds,
          entry.startedAt.millisecondsSinceEpoch + 1,
        );
      }
      draft.savedAt = DateTime.fromMillisecondsSinceEpoch(
        milliseconds,
        isUtc: true,
      );
      _lastAssignedMs = milliseconds;
    }
    await collection!.recordHistory(
      PlayHistoryEntry(
        id: draft.id,
        track: draft.track,
        startedAt: draft.savedAt!,
        lastPosition: draft.position,
      ),
    );
  }

  void _setFailure(_HistoryDraft? draft) {
    _retryDraft = draft;
    _failureSequence = draft?.sequence ?? _sequence;
    _failure = DomainFailure(
      code: DomainFailureCode.unknown,
      diagnosticId: 'playback.history-save',
      retryable: true,
    );
    _notify();
  }

  void _notify() {
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
      end();
      _closeFuture = _tail;
    }
    if (_notifierDisposed || _notificationDepth != 0) return;
    _notifierDisposed = true;
    super.dispose();
  }

  Future<void> close() {
    dispose();
    return _closeFuture!;
  }
}

final class _HistoryDraft {
  _HistoryDraft({
    required this.sequence,
    required this.track,
    required this.position,
    required this.observedAt,
    required this.id,
  });
  final int sequence;
  final TrackRef track;
  final Duration position;
  final DateTime observedAt;
  final String id;
  DateTime? savedAt;
}

String _newHistoryId() {
  final random = Random.secure();
  return 'history-${List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';
}
