part of 'playback_controller.dart';

extension on PlaybackController {
  // Called only after persistence succeeds. Keep prior pending choices stable;
  // an explicit next choice takes precedence over ordinary shuffled entries.
  void _extendShuffleOrder(QueueSnapshot queue, String? nextEntryId) {
    final ids = queue.entries.map((entry) => entry.id).toSet();
    final order = _shuffleOrder.where(ids.contains).toList();
    final existing = order.toSet();
    order.addAll(ids.where((id) => !existing.contains(id)));
    if (nextEntryId != null && order.remove(nextEntryId)) {
      final current = order.indexOf(queue.currentEntryId ?? '');
      order.insert(current + 1, nextEntryId);
    }
    _shuffleOrder = order;
    _shuffleCursor = queue.currentEntryId == null
        ? -1
        : order.indexOf(queue.currentEntryId!);
  }

  Future<bool> _editQueue(QueueEdit edit, {bool Function()? canEdit}) async {
    var committed = false;
    var accepted = false;
    try {
      await _schedule(() async {
        accepted = true;
        try {
          bool allowed() =>
              !_disposed &&
              identical(_state.queue, edit.expected) &&
              (canEdit?.call() ?? true);
          if (!allowed()) return;
          final next = edit.apply(updatedAt: _clock().toUtc());
          if (next == null) return;
          committed = await _commitQueue(
            next,
            canCommit: allowed,
            preserveShuffle: edit.insertsEntry,
            nextEntryId: edit.nextEntryId,
          );
        } catch (error, stack) {
          // Editing is not an audio-engine failure. Never expose raw errors.
          final failure = DomainFailure(
            code: error is DomainFailure
                ? error.code
                : DomainFailureCode.unknown,
            diagnosticId: 'queue.edit-failed',
            retryable: true,
          );
          Error.throwWithStackTrace(failure, stack);
        }
      });
    } catch (_) {
      if (!accepted && _disposed) return false;
      rethrow;
    }
    return committed;
  }
}
