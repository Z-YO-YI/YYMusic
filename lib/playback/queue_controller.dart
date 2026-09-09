import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/models/collection_models.dart';
import '../domain/models/domain_failure.dart';
import '../domain/models/queue_edit.dart';
import 'playback_controller.dart';
import 'playback_state.dart';
import 'queue_edit_result.dart';

part 'queue_edit_feedback.dart';

/// A queue command facade. The queue itself lives only in PlaybackState.
final class QueueController extends ChangeNotifier {
  QueueController(this._playback) {
    _playback.addListener(_forwardChange);
  }

  final PlaybackController _playback;
  bool _disposed = false;
  bool _notifierDisposed = false;
  int _notificationDepth = 0;
  bool _editBusy = false;
  QueueEditFailure? _editFailure;
  Future<void> _editWork = Future<void>.value();
  Future<void>? _editClose;

  bool get isAvailable => true;
  QueueSnapshot get state => _playback.state.queue;
  bool get shuffleEnabled => _playback.state.shuffleEnabled;
  RepeatMode get repeatMode => _playback.state.repeatMode;

  bool get editBusy => _editBusy;
  QueueEditFailure? get editFailure => _editFailure;

  /// Shared UI submission; failures remain available after a page unsubscribes.
  Future<QueueEditResult> submitEdit(
    QueueEdit request, {
    bool Function()? canEdit,
  }) => _submitEdit(request, canEdit: canEdit);

  /// A failed confirmation is never rebound to a newer queue or current item.
  bool canRetryEdit(QueueEditFailure expected) =>
      !_disposed &&
      !_editBusy &&
      identical(_editFailure, expected) &&
      identical(state, expected.edit.expected);

  Future<QueueEditResult> retryEdit(
    QueueEditFailure expected, {
    bool Function()? canEdit,
  }) => canRetryEdit(expected)
      ? _submitEdit(expected.edit, canEdit: canEdit, retrying: expected)
      : Future.value(const QueueEditResult.cancelled());

  /// Only the displayed failure may be acknowledged; newer failures survive.
  void dismissEditFailure(QueueEditFailure expected) {
    if (_disposed || !identical(_editFailure, expected)) return;
    _editFailure = null;
    _forwardChange();
  }

  /// For interactive edits: stale snapshots and disposed/pending views cancel.
  Future<bool> edit(QueueEdit edit, {bool Function()? canEdit}) => _disposed
      ? Future<bool>.value(false)
      : _playback.editQueue(
          edit,
          canEdit: () => !_disposed && (canEdit?.call() ?? true),
        );

  Future<void> replace(
    Iterable<QueueEntry> entries, {
    String? currentEntryId,
  }) => _playback.replaceQueue(entries, currentEntryId: currentEntryId);

  Future<void> play(String entryId) => _playback.playEntry(entryId);
  Future<void> add(QueueEntry entry) => _playback.addToEnd(entry);
  Future<void> playNext(QueueEntry entry) => _playback.insertNext(entry);
  Future<void> move(String entryId, int targetIndex) =>
      _playback.moveQueueEntry(entryId, targetIndex);
  Future<void> remove(String entryId) => _playback.removeQueueEntry(entryId);
  Future<void> clear() => _playback.clearQueue();
  Future<void> skipNext() => _playback.skipNext();
  Future<void> skipPrevious() => _playback.skipPrevious();
  void setShuffleEnabled(bool value) => _playback.setShuffleEnabled(value);
  void setRepeatMode(RepeatMode value) => _playback.setRepeatMode(value);

  void _forwardChange() {
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
    if (_notifierDisposed) return;
    if (!_disposed) {
      _disposed = true;
      _editClose = _editWork;
      _playback.removeListener(_forwardChange);
    }
    if (_notificationDepth > 0) return;
    _notifierDisposed = true;
    super.dispose();
  }

  /// Stops pending intents and waits for accepted result/failure settlement.
  Future<void> close() {
    dispose();
    return _editClose!;
  }
}
