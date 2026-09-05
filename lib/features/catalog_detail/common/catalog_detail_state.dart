import '../../../domain/models/catalog_reference.dart';
import '../../../domain/models/domain_failure.dart';
import '../../../domain/models/library_entities.dart';
import '../../../domain/models/load_state.dart';

/// A detail destination always retains the source-scoped identity, not a title.
sealed class CatalogDetailTarget {
  const CatalogDetailTarget();
  String get sourceId;
}

final class AlbumDetailTarget extends CatalogDetailTarget {
  const AlbumDetailTarget(this.reference);
  final AlbumRef reference;
  @override
  String get sourceId => reference.sourceId;
}

final class ArtistDetailTarget extends CatalogDetailTarget {
  const ArtistDetailTarget(this.reference);
  final ArtistRef reference;
  @override
  String get sourceId => reference.sourceId;
}

/// Counts are unfiltered catalog totals, never inferred from the loaded page.
sealed class CatalogDetailSummary {
  const CatalogDetailSummary();
  String get title;
  int get trackCount;
}

final class AlbumDetailSummary extends CatalogDetailSummary {
  const AlbumDetailSummary(this.album);
  final Album album;
  @override
  String get title => album.title;
  @override
  int get trackCount => album.trackCount;
}

final class ArtistDetailSummary extends CatalogDetailSummary {
  const ArtistDetailSummary(this.artist);
  final Artist artist;
  @override
  String get title => artist.name;
  @override
  int get trackCount => artist.trackCount;
}

/// Immutable page projection. A failed later request retains earlier rows.
final class CatalogDetailPage<T> {
  CatalogDetailPage({
    Iterable<T> items = const [],
    this.phase = LoadPhase.idle,
    this.loading = false,
    this.hasMore = false,
    this.rawCount = 0,
    this.failure,
  }) : items = List.unmodifiable(items);

  static const pageSize = 20;
  static const maxRawCount = 200;
  final List<T> items;
  final LoadPhase phase;
  final bool loading, hasMore;
  final int rawCount;
  final DomainFailure? failure;
  bool get capped => rawCount >= maxRawCount && hasMore;
}
