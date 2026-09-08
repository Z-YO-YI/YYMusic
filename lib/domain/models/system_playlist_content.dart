import 'collection_models.dart';
import 'domain_validation.dart';
import 'pagination.dart';
import 'track.dart';

/// A read-only reference, not a writable custom PlaylistEntry.
final class SystemPlaylistEntry {
  SystemPlaylistEntry({
    required this.reference,
    required this.position,
    required DateTime addedAt,
    String? entryId,
    this.track,
  }) : addedAt = DomainValidation.utc(addedAt, 'addedAt'),
       entryId = entryId == null
           ? null
           : DomainValidation.identifier(entryId, 'entryId') {
    if (position < 0 || (track != null && track!.ref != reference)) {
      throw ArgumentError('Invalid system playlist entry');
    }
  }
  final TrackRef reference;
  final int position;

  /// Favorite/queue addedAt or history startedAt, always UTC.
  final DateTime addedAt;

  /// Null for favorites; actual history/queue ID otherwise.
  final String? entryId;
  final Track? track;
  Object get identity => entryId ?? reference;
  bool get isAvailable => track?.availability == TrackAvailability.available;
}

final class SystemPlaylistContent {
  SystemPlaylistContent({
    required this.type,
    required this.page,
    required this.totalCount,
    required Iterable<SystemPlaylistEntry> entries,
    String? currentQueueEntryId,
  }) : entries = List.unmodifiable(entries),
       currentQueueEntryId = currentQueueEntryId == null
           ? null
           : DomainValidation.identifier(
               currentQueueEntryId,
               'currentQueueEntryId',
             ) {
    if (totalCount < 0 ||
        (type == SystemPlaylistType.recent && totalCount > 20) ||
        (currentQueueEntryId != null &&
            (type != SystemPlaylistType.queue || totalCount == 0)) ||
        this.entries.length !=
            (totalCount - page.offset).clamp(0, page.limit)) {
      throw ArgumentError('Invalid system playlist window');
    }
    final identities = <Object>{};
    for (var i = 0; i < this.entries.length; i++) {
      final entry = this.entries[i];
      if (entry.position != page.offset + i ||
          (entry.entryId == null) != (type == SystemPlaylistType.favorites) ||
          !identities.add(entry.identity)) {
        throw ArgumentError('Ambiguous system playlist entries');
      }
    }
  }
  final SystemPlaylistType type;
  final PageRequest page;
  final int totalCount;
  final List<SystemPlaylistEntry> entries;

  /// May refer to an entry outside this window. It does not select a new track.
  final String? currentQueueEntryId;
  bool get hasMore => page.offset + entries.length < totalCount;
}
