part of 'playback_controller.dart';

extension on PlaybackController {
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
          committed = await _commitQueue(next, canCommit: allowed);
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
