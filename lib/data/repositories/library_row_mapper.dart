import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';

import '../../domain/models/domain_failure.dart';
import '../../domain/models/library_entities.dart';
import '../../domain/models/track.dart';
import '../database/app_database.dart';

final class LibraryRowMapper {
  const LibraryRowMapper();

  TrackRecordsCompanion trackToCompanion(Track track) {
    try {
      return TrackRecordsCompanion.insert(
        trackId: track.id,
        sourceId: track.sourceId,
        sourceType: track.sourceType.name,
        title: track.title,
        albumId: Value(track.albumId),
        albumTitle: Value(track.albumTitle),
        durationMs: track.duration.inMilliseconds,
        artworkUri: Value(track.artworkUri?.toString()),
        localPath: Value(track.localPath),
        contentUri: Value(track.contentUri?.toString()),
        fileFingerprint: Value(track.fileFingerprint),
        modifiedAtMs: Value(track.modifiedAt?.millisecondsSinceEpoch),
        fileSize: Value(track.fileSize),
        availability: track.availability.name,
        metadataJson: Value(jsonEncode(track.metadata)),
      );
    } catch (_) {
      throw _corrupted('track-encode');
    }
  }

  Track trackFromRow(TrackRow row, Iterable<String> artists) {
    try {
      final decoded = jsonDecode(row.metadataJson);
      if (decoded is! Map<String, Object?>) {
        throw const FormatException('Track metadata must be an object');
      }
      return Track(
        id: row.trackId,
        sourceId: row.sourceId,
        sourceType: MusicSourceType.values.byName(row.sourceType),
        title: row.title,
        artists: artists,
        duration: Duration(milliseconds: row.durationMs),
        albumId: row.albumId,
        albumTitle: row.albumTitle,
        artworkUri: _uri(row.artworkUri),
        localPath: row.localPath,
        contentUri: _uri(row.contentUri),
        fileFingerprint: row.fileFingerprint,
        modifiedAt: row.modifiedAtMs == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(
                row.modifiedAtMs!,
                isUtc: true,
              ),
        fileSize: row.fileSize,
        availability: TrackAvailability.values.byName(row.availability),
        metadata: decoded,
      );
    } on DomainFailure {
      rethrow;
    } catch (_) {
      throw _corrupted('track-decode');
    }
  }

  ArtistRecordsCompanion artistToCompanion({
    required String sourceId,
    required String name,
  }) => ArtistRecordsCompanion.insert(
    artistId: artistId(sourceId: sourceId, name: name),
    sourceId: sourceId,
    name: name,
  );

  Artist artistFromRow(ArtistRow row) {
    try {
      return Artist(
        id: row.artistId,
        sourceId: row.sourceId,
        name: row.name,
        artworkUri: _uri(row.artworkUri),
        albumCount: row.albumCount,
        trackCount: row.trackCount,
      );
    } catch (_) {
      throw _corrupted('artist-decode');
    }
  }

  AlbumRecordsCompanion albumToCompanion({
    required String albumId,
    required String sourceId,
    required String title,
    Uri? artworkUri,
  }) => AlbumRecordsCompanion.insert(
    albumId: albumId,
    sourceId: sourceId,
    title: title,
    artworkUri: Value(artworkUri?.toString()),
  );

  Album albumFromRow(AlbumRow row, Iterable<ArtistCredit> artists) {
    try {
      return Album(
        id: row.albumId,
        sourceId: row.sourceId,
        title: row.title,
        artists: artists,
        year: row.year,
        artworkUri: _uri(row.artworkUri),
        trackCount: row.trackCount,
      );
    } catch (_) {
      throw _corrupted('album-decode');
    }
  }

  String artistId({required String sourceId, required String name}) {
    final digest = sha256.convert(utf8.encode('$sourceId\u0000$name'));
    return 'derived:$digest';
  }

  Uri? _uri(String? value) => value == null ? null : Uri.parse(value);

  DomainFailure _corrupted(String diagnosticId) => DomainFailure(
    code: DomainFailureCode.databaseCorrupted,
    diagnosticId: 'library-row.$diagnosticId',
  );
}
