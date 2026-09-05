import 'catalog_reference.dart';
import 'track.dart';

enum CatalogDirection { ascending, descending }

enum CatalogTrackSort { title, artist, album, duration, addedAt }

enum CatalogAlbumSort { title, artist, year, trackCount }

enum CatalogArtistSort { name, albumCount, trackCount }

/// Empty availability means all states; supplied sets are defensively copied.
final class CatalogFilter {
  factory CatalogFilter({
    MusicSourceType? sourceType,
    String? sourceId,
    Iterable<TrackAvailability> availability = const [],
  }) => CatalogFilter._(
    sourceType,
    sourceId == null ? null : catalogIdentifier(sourceId),
    Set.unmodifiable(availability),
  );
  const CatalogFilter.all() : this._(null, null, const {});
  const CatalogFilter._(this.sourceType, this.sourceId, this.availability);
  final MusicSourceType? sourceType;
  final String? sourceId;
  final Set<TrackAvailability> availability;
  bool get isAll =>
      sourceType == null && sourceId == null && availability.isEmpty;
  @override
  String toString() => 'CatalogFilter(<redacted>)';
}

final class CatalogTrackQuery {
  const CatalogTrackQuery({
    this.filter = const CatalogFilter.all(),
    this.sort = CatalogTrackSort.title,
    this.direction = CatalogDirection.ascending,
    this.album,
    this.artist,
  });
  final CatalogFilter filter;
  final CatalogTrackSort sort;
  final CatalogDirection direction;
  final AlbumRef? album;
  final ArtistRef? artist;
}

final class CatalogAlbumQuery {
  const CatalogAlbumQuery({
    this.filter = const CatalogFilter.all(),
    this.sort = CatalogAlbumSort.title,
    this.direction = CatalogDirection.ascending,
    this.artist,
  });
  final CatalogFilter filter;
  final CatalogAlbumSort sort;
  final CatalogDirection direction;
  final ArtistRef? artist;
}

final class CatalogArtistQuery {
  const CatalogArtistQuery({
    this.filter = const CatalogFilter.all(),
    this.sort = CatalogArtistSort.name,
    this.direction = CatalogDirection.ascending,
  });
  final CatalogFilter filter;
  final CatalogArtistSort sort;
  final CatalogDirection direction;
}
