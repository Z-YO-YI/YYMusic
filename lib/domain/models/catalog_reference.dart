import 'domain_validation.dart';

/// Album/artist keys are source-scoped in the existing catalog schema.
final class AlbumRef {
  AlbumRef({required String sourceId, required String albumId})
    : sourceId = catalogIdentifier(sourceId),
      albumId = catalogIdentifier(albumId);
  final String sourceId, albumId;
  @override
  bool operator ==(Object other) =>
      other is AlbumRef &&
      other.sourceId == sourceId &&
      other.albumId == albumId;
  @override
  int get hashCode => Object.hash(sourceId, albumId);
  @override
  String toString() => 'AlbumRef(<redacted>)';
}

final class ArtistRef {
  ArtistRef({required String sourceId, required String artistId})
    : sourceId = catalogIdentifier(sourceId),
      artistId = catalogIdentifier(artistId);
  final String sourceId, artistId;
  @override
  bool operator ==(Object other) =>
      other is ArtistRef &&
      other.sourceId == sourceId &&
      other.artistId == artistId;
  @override
  int get hashCode => Object.hash(sourceId, artistId);
  @override
  String toString() => 'ArtistRef(<redacted>)';
}

/// Reject identifiers without echoing input into an ArgumentError.
String catalogIdentifier(String value) {
  try {
    return DomainValidation.identifier(value, 'catalogIdentifier');
  } catch (_) {
    throw ArgumentError('Invalid catalog identifier');
  }
}
