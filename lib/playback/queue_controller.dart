import 'package:flutter/foundation.dart';

import '../domain/models/collection_models.dart';
import 'playback_controller.dart';
import 'playback_state.dart';

/// A queue command facade. The queue itself lives only in PlaybackState.
final class QueueController extends ChangeNotifier {
  QueueController(this._playback) {
    _playback.addListener(_forwardChange);
  }

  final PlaybackController _playback;
  bool _disposed = false;

  bool get isAvailable => true;
  QueueSnapshot get state => _playback.state.queue;
  bool get shuffleEnabled => _playback.state.shuffleEnabled;
  RepeatMode get repeatMode => _playback.state.repeatMode;

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
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _playback.removeListener(_forwardChange);
    super.dispose();
  }
}
