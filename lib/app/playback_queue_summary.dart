import '../domain/models/collection_models.dart';

/// Read-only list position, never a prediction of shuffled playback order.
final class PlaybackQueueSummary {
  factory PlaybackQueueSummary.fromQueue(QueueSnapshot queue) {
    final currentId = queue.currentEntryId;
    final index = currentId == null
        ? -1
        : queue.entries.indexWhere((entry) => entry.id == currentId);
    return PlaybackQueueSummary._(
      totalCount: queue.entries.length,
      currentEntry: index < 0 ? null : queue.entries[index],
      currentOrdinal: index < 0 ? null : index + 1,
    );
  }

  const PlaybackQueueSummary._({
    required this.totalCount,
    required this.currentEntry,
    required this.currentOrdinal,
  });

  final int totalCount;
  final QueueEntry? currentEntry;

  /// One-based position in the stored list; null means no selected entry.
  final int? currentOrdinal;
}
