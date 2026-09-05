import 'package:yymusic/domain/models/catalog_browse.dart';
import 'package:yymusic/domain/models/catalog_reference.dart';
import 'package:yymusic/domain/models/catalog_search.dart';
import 'package:yymusic/domain/models/library_entities.dart';
import 'package:yymusic/domain/models/pagination.dart';
import 'package:yymusic/domain/models/track.dart';
import 'package:yymusic/domain/repositories/catalog_browse_repository.dart';

/// Empty data-scope test double, never used by the production bootstrap.
class FakeCatalogBrowseRepository implements CatalogBrowseRepository {
  @override
  Future<PageResult<Track>> browseTracks(
    CatalogTrackQuery query,
    PageRequest page, {
    SearchCancellation? cancellation,
  }) async {
    cancellation?.throwIfCancelled();
    return PageResult(items: const [], hasMore: false);
  }

  @override
  Future<PageResult<Album>> browseAlbums(
    CatalogAlbumQuery query,
    PageRequest page, {
    SearchCancellation? cancellation,
  }) async {
    cancellation?.throwIfCancelled();
    return PageResult(items: const [], hasMore: false);
  }

  @override
  Future<PageResult<Artist>> browseArtists(
    CatalogArtistQuery query,
    PageRequest page, {
    SearchCancellation? cancellation,
  }) async {
    cancellation?.throwIfCancelled();
    return PageResult(items: const [], hasMore: false);
  }

  @override
  Future<Album?> getAlbum(
    AlbumRef reference, {
    SearchCancellation? cancellation,
  }) async {
    cancellation?.throwIfCancelled();
    return null;
  }

  @override
  Future<Artist?> getArtist(
    ArtistRef reference, {
    SearchCancellation? cancellation,
  }) async {
    cancellation?.throwIfCancelled();
    return null;
  }
}
