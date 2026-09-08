import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../domain/models/domain_failure.dart';
import '../../../domain/models/track.dart';
import '../../../domain/repositories/collection_repository.dart';
import '../../../playback/playback_history_recorder.dart';

enum SystemPlaylistWriteKind { removeFavorite, clearHistory }

/// Safe, root-retained failure identity. No plugin or database text is retained.
final class SystemPlaylistWriteFailure {
  SystemPlaylistWriteFailure._(this.kind, this.reference)
    : failure = DomainFailure(
        code: DomainFailureCode.unknown,
        diagnosticId: 'system-playlist.write',
        retryable: true,
      );
  final SystemPlaylistWriteKind kind;
  final TrackRef? reference;
  final DomainFailure failure;
  String get message => switch (kind) {
    SystemPlaylistWriteKind.removeFavorite => '取消喜欢未完成，请重新打开对应歌曲菜单重试。',
    SystemPlaylistWriteKind.clearHistory => '历史未能清除，请重新确认后重试。',
  };
}

/// Shared by root system sessions; does not own the database or audio engine.
final class SystemPlaylistWriter extends ChangeNotifier {
  SystemPlaylistWriter({this.repository, this.history});
  final CollectionRepository? repository;
  final PlaybackHistoryRecorder? history;
  bool _disposed = false, _notifierDisposed = false, _busy = false;
  int _notificationDepth = 0;
  SystemPlaylistWriteFailure? _failure;
  Future<void> _work = Future<void>.value();
  Future<void>? _closeFuture;

  bool get busy => _busy;
  SystemPlaylistWriteFailure? get failure => _failure;
  bool get canRemoveFavorite => !_disposed && !busy && repository != null;
  bool get canClearHistory =>
      canRemoveFavorite &&
      history != null &&
      identical(history!.collection, repository);

  /// Removes only the exact favorite reference, including unavailable tracks.
  Future<void> removeFavorite(TrackRef reference) {
    if (!canRemoveFavorite) return Future.value();
    return _run(
      SystemPlaylistWriteKind.removeFavorite,
      reference,
      () => repository!.setFavorite(reference, favorite: false),
    );
  }

  /// Caller must already have obtained explicit confirmation on current data.
  Future<void> clearHistory() {
    if (!canClearHistory) return Future.value();
    return _run(SystemPlaylistWriteKind.clearHistory, null, history!.clear);
  }

  void dismissFailure(SystemPlaylistWriteFailure expected) {
    if (_disposed || !identical(expected, _failure)) return;
    _failure = null;
    _notify();
  }

  Future<void> _run(
    SystemPlaylistWriteKind kind,
    TrackRef? reference,
    Future<void> Function() action,
  ) {
    final done = Completer<void>();
    // Register before invoking dependencies or notifying reentrant listeners.
    _work = done.future;
    _busy = true;
    unawaited(() async {
      try {
        await action();
        if (_failure?.kind == kind && _failure?.reference == reference) {
          _failure = null;
        }
      } catch (_) {
        _failure = SystemPlaylistWriteFailure._(kind, reference);
      } finally {
        _busy = false;
        done.complete();
        _notify();
      }
    }());
    _notify();
    return done.future;
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
      _closeFuture = _work;
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
