import 'domain_validation.dart';
import 'track.dart';

enum SystemPlaylistType { favorites, recent, queue }

final class Playlist {
  Playlist({
    required String id,
    required String name,
    String description = '',
    required DateTime createdAt,
    required DateTime updatedAt,
    this.isSystem = false,
    this.systemType,
  }) : id = DomainValidation.identifier(id, 'id'),
       name = DomainValidation.text(name, 'name', maxLength: 512),
       description = description.isEmpty
           ? ''
           : DomainValidation.text(description, 'description', maxLength: 4096),
       createdAt = DomainValidation.utc(createdAt, 'createdAt'),
       updatedAt = DomainValidation.utc(updatedAt, 'updatedAt') {
    if (updatedAt.isBefore(createdAt)) {
      throw ArgumentError('updatedAt must not precede createdAt');
    }
    if (isSystem != (systemType != null)) {
      throw ArgumentError(
        'systemType must be present exactly when isSystem is true',
      );
    }
  }

  final String id;
  final String name;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSystem;
  final SystemPlaylistType? systemType;
}

final class PlaylistEntry {
  PlaylistEntry({
    required String id,
    required String playlistId,
    required this.track,
    required this.position,
    required DateTime addedAt,
  }) : id = DomainValidation.identifier(id, 'id'),
       playlistId = DomainValidation.identifier(playlistId, 'playlistId'),
       addedAt = DomainValidation.utc(addedAt, 'addedAt') {
    if (position < 0) {
      throw ArgumentError.value(position, 'position', 'must not be negative');
    }
  }

  final String id;
  final String playlistId;
  final TrackRef track;
  final int position;
  final DateTime addedAt;
}

/// Queue entry identity is independent from TrackRef so duplicate tracks work.
final class QueueEntry {
  QueueEntry({
    required String id,
    required this.track,
    required this.position,
    required DateTime addedAt,
  }) : id = DomainValidation.identifier(id, 'id'),
       addedAt = DomainValidation.utc(addedAt, 'addedAt') {
    if (position < 0) {
      throw ArgumentError.value(position, 'position', 'must not be negative');
    }
  }

  final String id;
  final TrackRef track;
  final int position;
  final DateTime addedAt;
}

final class QueueSnapshot {
  factory QueueSnapshot({
    required Iterable<QueueEntry> entries,
    String? currentEntryId,
    required DateTime updatedAt,
  }) {
    final copy = List<QueueEntry>.unmodifiable(entries);
    final ids = copy.map((entry) => entry.id).toSet();
    final positions = copy.map((entry) => entry.position).toSet();
    if (ids.length != copy.length) {
      throw ArgumentError('Queue entry IDs must be unique');
    }
    if (positions.length != copy.length) {
      throw ArgumentError('Queue positions must be unique');
    }
    for (var index = 0; index < copy.length; index++) {
      if (copy[index].position != index) {
        throw ArgumentError(
          'Queue entries must be sorted with contiguous positions',
        );
      }
    }
    if (currentEntryId != null && !ids.contains(currentEntryId)) {
      throw ArgumentError.value(
        currentEntryId,
        'currentEntryId',
        'must identify an entry',
      );
    }
    return QueueSnapshot._(
      entries: copy,
      currentEntryId: currentEntryId,
      updatedAt: DomainValidation.utc(updatedAt, 'updatedAt'),
    );
  }

  const QueueSnapshot._({
    required this.entries,
    required this.currentEntryId,
    required this.updatedAt,
  });

  final List<QueueEntry> entries;
  final String? currentEntryId;
  final DateTime updatedAt;
}

final class FavoriteEntry {
  FavoriteEntry({required this.track, required DateTime addedAt})
    : addedAt = DomainValidation.utc(addedAt, 'addedAt');

  final TrackRef track;
  final DateTime addedAt;
}

final class PlayHistoryEntry {
  PlayHistoryEntry({
    required String id,
    required this.track,
    required DateTime startedAt,
    required this.lastPosition,
    this.completed = false,
  }) : id = DomainValidation.identifier(id, 'id'),
       startedAt = DomainValidation.utc(startedAt, 'startedAt') {
    if (lastPosition.isNegative) {
      throw ArgumentError.value(
        lastPosition,
        'lastPosition',
        'must not be negative',
      );
    }
  }

  final String id;
  final TrackRef track;
  final DateTime startedAt;
  final Duration lastPosition;
  final bool completed;
}
