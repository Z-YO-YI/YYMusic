import '../models/library_entities.dart';
import '../models/pagination.dart';
import '../models/track.dart';

/// Catalog contract. Database and remote adapter types stay behind this API.
abstract interface class LibraryRepository {
  Future<void> initialize();

  Stream<List<Track>> watchTracks();
  Future<PageResult<Track>> listTracks(PageRequest request);
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
