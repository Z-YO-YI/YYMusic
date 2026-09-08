import 'collection_models.dart';
import 'pagination.dart';
import 'track.dart';

/// Missing catalog rows retain their entry identity and full source reference.
final class PlaylistContentEntry {
  PlaylistContentEntry({required this.entry, this.track}) {
    if (track != null && track!.ref != entry.track) {
      throw ArgumentError('Playlist content track identity mismatch');
    }
  }
  final PlaylistEntry entry;
  final Track? track;
  bool get isAvailable => track?.availability == TrackAvailability.available;
}

/// One consistent, bounded storage window, not an accumulated multi-page cache.
final class PlaylistContent {
  PlaylistContent({
    required this.playlist,
    required this.page,
    required this.totalCount,
    required Iterable<PlaylistContentEntry> entries,
  }) : entries = List.unmodifiable(entries) {
    if (totalCount < 0 || playlist.isSystem) {
      throw ArgumentError(
        'Expected custom playlist content with a valid count',
      );
    }
    final expected = (totalCount - page.offset).clamp(0, page.limit);
    if (this.entries.length != expected) {
      throw ArgumentError('Playlist content window is incomplete');
    }
    final ids = <String>{};
    for (var i = 0; i < this.entries.length; i++) {
      final entry = this.entries[i].entry;
      if (entry.playlistId != playlist.id ||
          entry.position != page.offset + i ||
          !ids.add(entry.id)) {
        throw ArgumentError(
          'Playlist content window identity or order mismatch',
        );
      }
    }
  }
  final Playlist playlist;
  final PageRequest page;
  final int totalCount;
  final List<PlaylistContentEntry> entries;
  bool get hasMore => page.offset + entries.length < totalCount;
}
