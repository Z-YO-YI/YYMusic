import '../models/catalog_search.dart';
import '../models/library_entities.dart';
import '../models/pagination.dart';
import '../models/track.dart';

/// Searches only persisted metadata, with independent pages per entity kind.
/// Calling these methods must never record history or populate the catalog.
abstract interface class CatalogSearchRepository {
  Future<PageResult<Track>> searchTracks(
    CatalogQuery query,
    PageRequest page, {
    SearchCancellation? cancellation,
  });
  Future<PageResult<Album>> searchAlbums(
    CatalogQuery query,
    PageRequest page, {
    SearchCancellation? cancellation,
  });
  Future<PageResult<Artist>> searchArtists(
    CatalogQuery query,
    PageRequest page, {
    SearchCancellation? cancellation,
  });
}
