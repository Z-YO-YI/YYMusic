import 'package:drift/drift.dart';

import '../../domain/models/collection_models.dart';
import '../../domain/models/domain_failure.dart';
import '../../domain/models/track.dart';
import '../database/app_database.dart';

final class CollectionRowMapper {
  const CollectionRowMapper();

  PlaylistRecordsCompanion playlistToCompanion(Playlist playlist) {
    try {
      return PlaylistRecordsCompanion.insert(
        playlistId: playlist.id,
        name: playlist.name,
        description: Value(playlist.description),
        createdAtMs: playlist.createdAt.millisecondsSinceEpoch,
        updatedAtMs: playlist.updatedAt.millisecondsSinceEpoch,
        isSystem: Value(playlist.isSystem),
        systemType: Value(playlist.systemType?.name),
      );
    } catch (_) {
      throw _corrupted('playlist-encode');
    }
  }

  Playlist playlistFromRow(PlaylistRow row) {
    try {
      return Playlist(
        id: row.playlistId,
        name: row.name,
        description: row.description,
        createdAt: _utc(row.createdAtMs),
        updatedAt: _utc(row.updatedAtMs),
        isSystem: row.isSystem,
        systemType: row.systemType == null
            ? null
            : SystemPlaylistType.values.byName(row.systemType!),
      );
    } catch (_) {
      throw _corrupted('playlist-decode');
    }
  }

  PlaylistEntryRecordsCompanion playlistEntryToCompanion(PlaylistEntry entry) =>
      PlaylistEntryRecordsCompanion.insert(
        entryId: entry.id,
        playlistId: entry.playlistId,
        trackSourceType: entry.track.sourceType.name,
        trackSourceId: entry.track.sourceId,
        trackId: entry.track.trackId,
        position: entry.position,
        addedAtMs: entry.addedAt.millisecondsSinceEpoch,
      );

  PlaylistEntry playlistEntryFromRow(PlaylistEntryRow row) {
    try {
      return PlaylistEntry(
        id: row.entryId,
        playlistId: row.playlistId,
        track: trackRef(
          sourceType: row.trackSourceType,
          sourceId: row.trackSourceId,
          trackId: row.trackId,
        ),
        position: row.position,
        addedAt: _utc(row.addedAtMs),
      );
    } catch (_) {
      throw _corrupted('playlist-entry-decode');
    }
  }

  QueueEntryRecordsCompanion queueEntryToCompanion(QueueEntry entry) =>
      QueueEntryRecordsCompanion.insert(
        entryId: entry.id,
        trackSourceType: entry.track.sourceType.name,
        trackSourceId: entry.track.sourceId,
        trackId: entry.track.trackId,
        position: entry.position,
        addedAtMs: entry.addedAt.millisecondsSinceEpoch,
      );

  QueueEntry queueEntryFromValues({
    required String id,
    required String sourceType,
    required String sourceId,
    required String trackId,
    required int position,
    required int addedAtMs,
  }) {
    try {
      return QueueEntry(
        id: id,
        track: trackRef(
          sourceType: sourceType,
          sourceId: sourceId,
          trackId: trackId,
        ),
        position: position,
        addedAt: _utc(addedAtMs),
      );
    } catch (_) {
      throw _corrupted('queue-entry-decode');
    }
  }

  FavoriteRecordsCompanion favoriteToCompanion(
    TrackRef track,
    DateTime addedAt,
  ) => FavoriteRecordsCompanion.insert(
    trackSourceType: track.sourceType.name,
    trackSourceId: track.sourceId,
    trackId: track.trackId,
    addedAtMs: addedAt.toUtc().millisecondsSinceEpoch,
  );

  FavoriteEntry favoriteFromRow(FavoriteRow row) {
    try {
      return FavoriteEntry(
        track: trackRef(
          sourceType: row.trackSourceType,
          sourceId: row.trackSourceId,
          trackId: row.trackId,
        ),
        addedAt: _utc(row.addedAtMs),
      );
    } catch (_) {
      throw _corrupted('favorite-decode');
    }
  }

  PlayHistoryRecordsCompanion historyToCompanion(PlayHistoryEntry entry) =>
      PlayHistoryRecordsCompanion.insert(
        historyId: entry.id,
        trackSourceType: entry.track.sourceType.name,
        trackSourceId: entry.track.sourceId,
        trackId: entry.track.trackId,
        startedAtMs: entry.startedAt.millisecondsSinceEpoch,
        lastPositionMs: entry.lastPosition.inMilliseconds,
        completed: Value(entry.completed),
      );

  PlayHistoryEntry historyFromRow(PlayHistoryRow row) {
    try {
      return PlayHistoryEntry(
        id: row.historyId,
        track: trackRef(
          sourceType: row.trackSourceType,
          sourceId: row.trackSourceId,
          trackId: row.trackId,
        ),
        startedAt: _utc(row.startedAtMs),
        lastPosition: Duration(milliseconds: row.lastPositionMs),
        completed: row.completed,
      );
    } catch (_) {
      throw _corrupted('history-decode');
    }
  }

  TrackRef trackRef({
    required String sourceType,
    required String sourceId,
    required String trackId,
  }) => TrackRef(
    trackId: trackId,
    sourceId: sourceId,
    sourceType: MusicSourceType.values.byName(sourceType),
  );

  DateTime _utc(int milliseconds) =>
      DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: true);

  DomainFailure _corrupted(String diagnosticId) => DomainFailure(
    code: DomainFailureCode.databaseCorrupted,
    diagnosticId: 'collection-row.$diagnosticId',
  );
}
