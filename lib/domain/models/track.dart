import 'domain_validation.dart';

enum MusicSourceType { local, rest }

enum TrackAvailability {
  available,
  sourceDisabled,
  sourceRemoved,
  localMissing,
  unsupported,
}

final class TrackRef {
  TrackRef({
    required String trackId,
    required String sourceId,
    required this.sourceType,
  }) : trackId = DomainValidation.identifier(trackId, 'trackId'),
       sourceId = DomainValidation.identifier(sourceId, 'sourceId');

  final String trackId;
  final String sourceId;
  final MusicSourceType sourceType;

  @override
  bool operator ==(Object other) =>
      other is TrackRef &&
      other.trackId == trackId &&
      other.sourceId == sourceId &&
      other.sourceType == sourceType;

  @override
  int get hashCode => Object.hash(trackId, sourceId, sourceType);

  @override
  String toString() => 'TrackRef($sourceId/$trackId, ${sourceType.name})';
}

final class Track {
  factory Track({
    required String id,
    required String sourceId,
    required MusicSourceType sourceType,
    required String title,
    required Iterable<String> artists,
    required Duration duration,
    String? albumId,
    String? albumTitle,
    Uri? artworkUri,
    String? localPath,
    Uri? contentUri,
    String? fileFingerprint,
    DateTime? modifiedAt,
    int? fileSize,
    TrackAvailability availability = TrackAvailability.available,
    Map<String, Object?> metadata = const {},
  }) {
    final safeId = DomainValidation.identifier(id, 'id');
    final safeSourceId = DomainValidation.identifier(sourceId, 'sourceId');
    final safeTitle = DomainValidation.text(title, 'title', maxLength: 1024);
    final safeArtists = DomainValidation.textList(artists, 'artists');
    if (duration.isNegative) {
      throw ArgumentError.value(duration, 'duration', 'must not be negative');
    }
    if (fileSize != null && fileSize < 0) {
      throw ArgumentError.value(fileSize, 'fileSize', 'must not be negative');
    }
    final safeAlbumId = albumId == null
        ? null
        : DomainValidation.identifier(albumId, 'albumId');
    final safeAlbumTitle = albumTitle == null
        ? null
        : DomainValidation.text(albumTitle, 'albumTitle', maxLength: 1024);
    if ((safeAlbumId == null) != (safeAlbumTitle == null)) {
      throw ArgumentError('albumId and albumTitle must be provided together');
    }
    final safeLocalPath = localPath == null
        ? null
        : DomainValidation.text(localPath, 'localPath', maxLength: 4096);
    final safeFingerprint = fileFingerprint == null
        ? null
        : DomainValidation.identifier(fileFingerprint, 'fileFingerprint');
    if (sourceType == MusicSourceType.local &&
        safeLocalPath == null &&
        contentUri == null) {
      throw ArgumentError('Local tracks require localPath or contentUri');
    }
    if (contentUri != null && contentUri.scheme != 'content') {
      throw ArgumentError.value(
        contentUri,
        'contentUri',
        'must use the Android content scheme',
      );
    }
    if (sourceType != MusicSourceType.local &&
        (safeLocalPath != null || contentUri != null)) {
      throw ArgumentError(
        'Remote tracks must not contain local media references',
      );
    }
    return Track._(
      id: safeId,
      sourceId: safeSourceId,
      sourceType: sourceType,
      title: safeTitle,
      artists: safeArtists,
      albumId: safeAlbumId,
      albumTitle: safeAlbumTitle,
      duration: duration,
      artworkUri: DomainValidation.httpUri(artworkUri, 'artworkUri'),
      localPath: safeLocalPath,
      contentUri: contentUri,
      fileFingerprint: safeFingerprint,
      modifiedAt: modifiedAt == null
          ? null
          : DomainValidation.utc(modifiedAt, 'modifiedAt'),
      fileSize: fileSize,
      availability: availability,
      metadata: DomainValidation.jsonMap(metadata, 'metadata'),
    );
  }

  const Track._({
    required this.id,
    required this.sourceId,
    required this.sourceType,
    required this.title,
    required this.artists,
    required this.albumId,
    required this.albumTitle,
    required this.duration,
    required this.artworkUri,
    required this.localPath,
    required this.contentUri,
    required this.fileFingerprint,
    required this.modifiedAt,
    required this.fileSize,
    required this.availability,
    required this.metadata,
  });

  final String id;
  final String sourceId;
  final MusicSourceType sourceType;
  final String title;
  final List<String> artists;
  final String? albumId;
  final String? albumTitle;
  final Duration duration;
  final Uri? artworkUri;
  final String? localPath;
  final Uri? contentUri;
  final String? fileFingerprint;
  final DateTime? modifiedAt;
  final int? fileSize;
  final TrackAvailability availability;
  final Map<String, Object?> metadata;

  TrackRef get ref =>
      TrackRef(trackId: id, sourceId: sourceId, sourceType: sourceType);

  Track withAvailability(TrackAvailability value) => Track(
    id: id,
    sourceId: sourceId,
    sourceType: sourceType,
    title: title,
    artists: artists,
    duration: duration,
    albumId: albumId,
    albumTitle: albumTitle,
    artworkUri: artworkUri,
    localPath: localPath,
    contentUri: contentUri,
    fileFingerprint: fileFingerprint,
    modifiedAt: modifiedAt,
    fileSize: fileSize,
    availability: value,
    metadata: metadata,
  );
}
