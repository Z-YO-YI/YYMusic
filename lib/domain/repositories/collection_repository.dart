import '../models/collection_models.dart';
import '../models/pagination.dart';
import '../models/playlist_content.dart';
import '../models/playlist_name_query.dart';
import '../models/playlist_playback_plan.dart';
import '../models/system_playlist_content.dart';
import '../models/track.dart';

abstract interface class CollectionRepository {
  /// Consistent read-only system view; does not create a persisted Playlist.
  Future<SystemPlaylistContent> readSystemPlaylistContent(
    SystemPlaylistType type,
    PageRequest page,
  );

  /// No initial event or content read; subscribe before reading a fresh window.
  /// May conservatively invalidate after rollback; not a mutation/commit log.
  Stream<void> watchSystemPlaylistChanges(SystemPlaylistType type);

  Stream<List<Playlist>> watchPlaylists();

  /// Bounded custom metadata only, updatedAt DESC / ID ASC; literal name filter.
  Future<PageResult<Playlist>> readCustomPlaylists(
    PlaylistNameQuery query,
    PageRequest page,
  );
  Future<Playlist?> getPlaylist(String id);

  /// Create a custom playlist without overwriting an existing ID.
  Future<void> createPlaylist(Playlist playlist);

  /// Atomically create a custom playlist with its first complete track reference.
  /// Neither identity may collide; failure must leave no new parent or entry.
  Future<void> createPlaylistWithEntry(
    Playlist playlist,
    PlaylistEntryDraft entry,
  );

  /// Rename an existing custom playlist without recreating a removed target.
  Future<void> renamePlaylist(String id, String name);

  /// Bootstrap/import upsert; interactive edits use create/rename above.
  Future<void> savePlaylist(Playlist playlist);
  Future<void> deletePlaylist(String id);
  Future<List<PlaylistEntry>> getPlaylistEntries(String playlistId);

  /// One consistent custom-playlist window; null means its parent is missing.
  /// System views use favorites/history/queue, not persisted playlist entries.
  Future<PlaylistContent?> readPlaylistContent(
    String playlistId,
    PageRequest page,
  );

  /// Complete custom-playlist references and availability from one snapshot.
  /// Null means a missing parent; no full track metadata or media is loaded.
  Future<PlaylistPlaybackPlan?> readPlaylistPlaybackPlan(String playlistId);

  /// Invalidation only, no initial event or content queries. May conservatively
  /// include other playlists or rolled-back transactions; this is not a commit
  /// log. Subscribe before the first read and query the current stored content.
  Stream<void> watchPlaylistContentChanges();

  /// Append to a current custom playlist, rejecting a globally collided entry ID.
  Future<void> appendPlaylistEntry(String playlistId, PlaylistEntryDraft entry);

  /// Remove only this entry. An absent entry is a no-op, a wrong scope is notFound.
  Future<void> removePlaylistEntry(String playlistId, String entryId);

  /// Move before a current same-playlist anchor, or to the end when null.
  Future<void> movePlaylistEntry(
    String playlistId,
    String entryId, {
    String? beforeEntryId,
  });

  /// Bootstrap/import replacement; interactive edits use atomic commands above.
  Future<void> replacePlaylistEntries(
    String playlistId,
    Iterable<PlaylistEntry> entries,
  );

  Stream<QueueSnapshot> watchQueue();
  Future<QueueSnapshot> loadQueue();
  Future<void> saveQueue(QueueSnapshot snapshot);

  Stream<List<FavoriteEntry>> watchFavorites();
  Future<void> setFavorite(TrackRef track, {required bool favorite});

  Stream<List<PlayHistoryEntry>> watchHistory();
  Future<void> recordHistory(PlayHistoryEntry entry);
  Future<void> clearHistory();
}
