import 'domain_validation.dart';

final class ArtistCredit {
  ArtistCredit({required String id, required String name})
    : id = DomainValidation.identifier(id, 'artistId'),
      name = DomainValidation.text(name, 'artistName', maxLength: 512);

  final String id;
  final String name;
}

final class Album {
  factory Album({
    required String id,
    required String sourceId,
    required String title,
    required Iterable<ArtistCredit> artists,
    int? year,
    Uri? artworkUri,
    required int trackCount,
  }) {
    if (artists.isEmpty) {
      throw ArgumentError.value(artists, 'artists', 'must not be empty');
    }
    if (year != null && (year < 1 || year > 9999)) {
      throw ArgumentError.value(year, 'year', 'must be between 1 and 9999');
    }
    if (trackCount < 0) {
      throw ArgumentError.value(
        trackCount,
        'trackCount',
        'must not be negative',
      );
    }
    return Album._(
      id: DomainValidation.identifier(id, 'id'),
      sourceId: DomainValidation.identifier(sourceId, 'sourceId'),
      title: DomainValidation.text(title, 'title', maxLength: 1024),
      artists: List<ArtistCredit>.unmodifiable(artists),
      year: year,
      artworkUri: DomainValidation.httpUri(artworkUri, 'artworkUri'),
      trackCount: trackCount,
    );
  }

  const Album._({
    required this.id,
    required this.sourceId,
    required this.title,
    required this.artists,
    required this.year,
    required this.artworkUri,
    required this.trackCount,
  });

  final String id;
  final String sourceId;
  final String title;
  final List<ArtistCredit> artists;
  final int? year;
  final Uri? artworkUri;
  final int trackCount;
}

final class Artist {
  Artist({
    required String id,
    required String sourceId,
    required String name,
    Uri? artworkUri,
    required this.albumCount,
    required this.trackCount,
  }) : id = DomainValidation.identifier(id, 'id'),
       sourceId = DomainValidation.identifier(sourceId, 'sourceId'),
       name = DomainValidation.text(name, 'name', maxLength: 512),
       artworkUri = DomainValidation.httpUri(artworkUri, 'artworkUri') {
    if (albumCount < 0 || trackCount < 0) {
      throw ArgumentError('Artist counts must not be negative');
    }
  }

  final String id;
  final String sourceId;
  final String name;
  final Uri? artworkUri;
  final int albumCount;
  final int trackCount;
}
