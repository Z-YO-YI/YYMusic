import '../models/library_entities.dart';
import '../models/pagination.dart';
import '../models/track.dart';

/// Catalog contract. Database and remote adapter types stay behind this API.
abstract interface class LibraryRepository {
  Future<void> initialize();

  Stream<List<Track>> watchTracks();
  Future<PageResult<Track>> listTracks(PageRequest request);

  /// First catalog insertion time, inclusive UTC window, newest first.
  /// Migrated rows with unknown insertion time are excluded, not dated today.
  Future<PageResult<Track>> listRecentlyAdded(
    PageRequest request, {
    required DateTime since,
    required DateTime until,
  });
  Future<PageResult<Album>> listAlbums(PageRequest request);
  Future<PageResult<Artist>> listArtists(PageRequest request);
  Future<Track?> getTrack(TrackRef reference);
  Future<void> upsertTracks(Iterable<Track> tracks);
  Future<void> setAvailability(
    TrackRef reference,
    TrackAvailability availability,
  );

  Future<void> dispose();
}
