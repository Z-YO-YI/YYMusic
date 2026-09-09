import 'collection_models.dart';

enum _QueueEditKind { move, remove, clear }

/// An immutable edit of one exact root snapshot, never a stale row index.
final class QueueEdit {
  QueueEdit.move(this.expected, String entryId, {String? beforeEntryId})
    : _kind = _QueueEditKind.move,
      _entryId = entryId,
      _beforeEntryId = beforeEntryId {
    _requireEntry(entryId);
    if (beforeEntryId != null) _requireEntry(beforeEntryId);
  }

  QueueEdit.remove(this.expected, String entryId)
    : _kind = _QueueEditKind.remove,
      _entryId = entryId,
      _beforeEntryId = null {
    _requireEntry(entryId);
  }

  const QueueEdit.clear(this.expected)
    : _kind = _QueueEditKind.clear,
      _entryId = null,
      _beforeEntryId = null;

  final QueueSnapshot expected;
  final _QueueEditKind _kind;
  final String? _entryId, _beforeEntryId;

  void _requireEntry(String id) {
    if (!expected.entries.any((entry) => entry.id == id)) {
      throw ArgumentError('Queue edit target must belong to its snapshot');
    }
  }

  /// Pure preview; null means no change. The root must authorize [expected].
  QueueSnapshot? apply({required DateTime updatedAt}) {
    final entries = [...expected.entries];
    var current = expected.currentEntryId;
    switch (_kind) {
      case _QueueEditKind.move:
        if (_entryId == _beforeEntryId) return null;
        final source = entries.indexWhere((entry) => entry.id == _entryId);
        final entry = entries.removeAt(source);
        final target = _beforeEntryId == null
            ? entries.length
            : entries.indexWhere((entry) => entry.id == _beforeEntryId);
        entries.insert(target, entry);
        if (target == source) return null;
      case _QueueEditKind.remove:
        final index = entries.indexWhere((entry) => entry.id == _entryId);
        entries.removeAt(index);
        if (current == _entryId) {
          current = entries.isEmpty
              ? null
              : entries[index < entries.length ? index : entries.length - 1].id;
        }
      case _QueueEditKind.clear:
        if (entries.isEmpty) return null;
        entries.clear();
        current = null;
    }
    return QueueSnapshot(
      entries: [
        for (var i = 0; i < entries.length; i++)
          QueueEntry(
            id: entries[i].id,
            track: entries[i].track,
            position: i,
            addedAt: entries[i].addedAt,
          ),
      ],
      currentEntryId: current,
      updatedAt: updatedAt,
    );
  }
}
