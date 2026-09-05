import '../models/catalog_browse.dart';
import '../models/catalog_reference.dart';
import '../models/catalog_search.dart';
import '../models/library_entities.dart';
import '../models/pagination.dart';
import '../models/track.dart';

/// Read-only, source-scoped catalog browsing. Counts belong to the full entity,
/// not its filtered tracks. Pages are individually consistent, not a long-lived
/// snapshot across user actions. Cancellation discards results, not native SQL.
abstract interface class CatalogBrowseRepository {
  Future<PageResult<Track>> browseTracks(
    CatalogTrackQuery query,
    PageRequest page, {
    SearchCancellation? cancellation,
  });
  Future<PageResult<Album>> browseAlbums(
    CatalogAlbumQuery query,
    PageRequest page, {
    SearchCancellation? cancellation,
  });
  Future<PageResult<Artist>> browseArtists(
    CatalogArtistQuery query,
    PageRequest page, {
    SearchCancellation? cancellation,
  });
  Future<Album?> getAlbum(
    AlbumRef reference, {
    SearchCancellation? cancellation,
  });
  Future<Artist?> getArtist(
    ArtistRef reference, {
    SearchCancellation? cancellation,
  });
}
