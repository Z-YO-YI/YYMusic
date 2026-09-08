import '../models/collection_models.dart';
import '../models/track.dart';

abstract interface class CollectionRepository {
  Stream<List<Playlist>> watchPlaylists();
  Future<Playlist?> getPlaylist(String id);

  /// Create a custom playlist without overwriting an existing ID.
  Future<void> createPlaylist(Playlist playlist);

  /// Rename an existing custom playlist without recreating a removed target.
  Future<void> renamePlaylist(String id, String name);

  /// Bootstrap/import upsert; interactive edits use create/rename above.
  Future<void> savePlaylist(Playlist playlist);
  Future<void> deletePlaylist(String id);
  Future<List<PlaylistEntry>> getPlaylistEntries(String playlistId);

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
