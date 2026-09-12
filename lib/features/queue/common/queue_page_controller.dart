import '../../../domain/models/collection_models.dart';
import '../../../domain/models/queue_edit.dart';
import '../../../domain/models/system_playlist_content.dart';
import '../../../playback/queue_controller.dart';
import '../../../playback/queue_edit_result.dart';
import '../../playlists/common/system_playlist_controller.dart';
import 'queue_drag_session.dart';

/// Route-owned read binding, not a second queue or playback controller.
final class QueuePageController {
  QueuePageController({
    required this.queue,
    required SystemPlaylistSessions sessions,
  }) : read = sessions.open(SystemPlaylistType.queue),
       _expected = queue.state {
    queue.addListener(_rootChanged);
    read.addListener(_readChanged);
  }

  final QueueController queue;
  final SystemPlaylistController read;
  QueueSnapshot _expected;
  bool _closed = false, _active = true;
  int _intent = 0;
  SystemPlaylistContent? _lastContent;
  bool _lastCurrent = false;
  QueueSnapshot get expected => _expected;
  int get interactionRevision => _intent;

  void start() => read.start();

  void _readChanged() {
    if (!identical(_lastContent, read.content) ||
        _lastCurrent != read.isCurrent) {
      _lastContent = read.content;
      _lastCurrent = read.isCurrent;
      _intent++;
    }
  }

  void _rootChanged() {
    if (_closed || identical(_expected, queue.state)) return;
    _expected = queue.state;
    _intent++;
    read.refreshQueueProjection();
  }

  void setActive(bool active) {
    if (_closed) return;
    if (_active && !active) invalidate();
    _active = active;
    read.setActive(active);
  }

  /// Also called on a size change, even within the same platform layout.
  void invalidate() => _intent++;

  bool matches(SystemPlaylistContent snapshot) {
    if (_closed ||
        !read.isCurrent ||
        !identical(read.content, snapshot) ||
        !identical(queue.state, _expected) ||
        snapshot.totalCount != _expected.entries.length ||
        snapshot.currentQueueEntryId != _expected.currentEntryId) {
      return false;
    }
    for (final row in snapshot.entries) {
      if (row.position >= _expected.entries.length) return false;
      final entry = _expected.entries[row.position];
      if (row.entryId != entry.id ||
          row.reference != entry.track ||
          row.addedAt != entry.addedAt) {
        return false;
      }
    }
    return true;
  }

  bool canEdit(SystemPlaylistContent snapshot) =>
      _active && !queue.editBusy && !read.busy && matches(snapshot);

  QueueDragSession? beginDrag(
    SystemPlaylistContent snapshot,
    int index,
    bool Function() viewPermit,
  ) {
    if (!canEdit(snapshot) ||
        !viewPermit() ||
        index < 0 ||
        index >= snapshot.entries.length) {
      return null;
    }
    final originalPermit = permit();
    return QueueDragSession(
      expected: _expected,
      content: snapshot,
      sourceIndex: index,
      // submitEdit owns the busy gate; its own busy notification must not revoke
      // the permission it checks again just before the accepted database write.
      permit: () => originalPermit() && viewPermit() && matches(snapshot),
    );
  }

  /// Captures an intent once; callers must never recreate it inside a callback.
  bool Function() permit() {
    final intent = _intent, root = _expected;
    return () =>
        !_closed &&
        _active &&
        intent == _intent &&
        identical(queue.state, root);
  }

  Future<QueueEditResult> submit(QueueEdit edit, bool Function() canEdit) =>
      queue.submitEdit(edit, canEdit: canEdit);

  Future<void> close() {
    if (!_closed) {
      _closed = true;
      _intent++;
      queue.removeListener(_rootChanged);
      read.removeListener(_readChanged);
    }
    return read.close();
  }
}
