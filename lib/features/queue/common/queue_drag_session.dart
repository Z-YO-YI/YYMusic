import '../../../domain/models/collection_models.dart';
import '../../../domain/models/queue_edit.dart';
import '../../../domain/models/system_playlist_content.dart';

/// One gesture/semantic move against a fixed root and a bounded read window.
final class QueueDragSession {
  const QueueDragSession({
    required this.expected,
    required this.content,
    required this.sourceIndex,
    required this.permit,
  });
  final QueueSnapshot expected;
  final SystemPlaylistContent content;
  final int sourceIndex;
  final bool Function() permit;

  /// Flutter onReorderItem already adjusts the target for removal of the source.
  QueueEdit? moveTo(int targetIndex) {
    if (!permit() ||
        sourceIndex < 0 ||
        sourceIndex >= content.entries.length ||
        targetIndex < 0 ||
        targetIndex >= content.entries.length ||
        sourceIndex == targetIndex) {
      return null;
    }
    final source = content.entries[sourceIndex];
    if (source.position >= expected.entries.length ||
        expected.entries[source.position].id != source.entryId) {
      return null;
    }
    final anchorIndex =
        content.page.offset + targetIndex + (targetIndex > sourceIndex ? 1 : 0);
    if (anchorIndex > expected.entries.length) return null;
    return QueueEdit.move(
      expected,
      source.entryId!,
      beforeEntryId: anchorIndex == expected.entries.length
          ? null
          : expected.entries[anchorIndex].id,
    );
  }
}
