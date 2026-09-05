import '../domain/models/catalog_reference.dart';
import '../features/catalog_detail/common/catalog_detail_state.dart';

/// URLs carry only the stable entity/source identity; no media URL or credentials.
Uri catalogDetailLocation(CatalogDetailTarget target) => Uri(
  pathSegments: switch (target) {
    AlbumDetailTarget(:final reference) => ['', 'album', reference.albumId],
    ArtistDetailTarget(:final reference) => ['', 'artist', reference.artistId],
  },
  queryParameters: {'source': target.sourceId},
);

/// Invalid/ambiguous links fail closed without surfacing their raw values.
CatalogDetailTarget? parseCatalogDetailLocation(Uri uri) {
  try {
    final segments = uri.pathSegments;
    final sources = uri.queryParametersAll['source'];
    if (uri.hasScheme ||
        uri.hasAuthority ||
        uri.hasFragment ||
        segments.length != 2 ||
        uri.queryParametersAll.length != 1 ||
        sources == null ||
        sources.length != 1) {
      return null;
    }
    return switch (segments.first) {
      'album' => AlbumDetailTarget(
        AlbumRef(sourceId: sources.single, albumId: segments.last),
      ),
      'artist' => ArtistDetailTarget(
        ArtistRef(sourceId: sources.single, artistId: segments.last),
      ),
      _ => null,
    };
  } catch (_) {
    return null;
  }
}
