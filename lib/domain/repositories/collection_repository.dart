import '../models/collection_models.dart';
import '../models/track.dart';

abstract interface class CollectionRepository {
  Stream<List<Playlist>> watchPlaylists();
  Future<Playlist?> getPlaylist(String id);
  Future<void> savePlaylist(Playlist playlist);
  Future<void> deletePlaylist(String id);
  Future<List<PlaylistEntry>> getPlaylistEntries(String playlistId);
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
