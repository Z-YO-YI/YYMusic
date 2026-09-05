import 'package:yymusic/domain/models/catalog_browse.dart';
import 'package:yymusic/domain/models/catalog_reference.dart';
import 'package:yymusic/domain/models/catalog_search.dart';
import 'package:yymusic/domain/models/library_entities.dart';
import 'package:yymusic/domain/models/pagination.dart';
import 'package:yymusic/domain/models/track.dart';

import 'fake_catalog_browse_repository.dart';

typedef DetailReadCall = ({
  String kind,
  Object query,
  PageRequest? page,
  SearchCancellation? token,
});

/// Controlled async adapter. Real SQL credit/sort semantics are tested separately.
final class CatalogDetailProbe extends FakeCatalogBrowseRepository {
  final calls = <DetailReadCall>[];
  final albumData = <AlbumRef, Album>{};
  final artistData = <ArtistRef, Artist>{};
  final trackData = <Track>[];
  Future<Album?> Function(AlbumRef, SearchCancellation?)? onAlbum;
  Future<Artist?> Function(ArtistRef, SearchCancellation?)? onArtist;
  Future<PageResult<Track>> Function(
    CatalogTrackQuery,
    PageRequest,
    SearchCancellation?,
  )?
  onTracks;
  Future<PageResult<Album>> Function(
    CatalogAlbumQuery,
    PageRequest,
    SearchCancellation?,
  )?
  onAlbums;

  @override
  Future<PageResult<Artist>> browseArtists(
    CatalogArtistQuery query,
    PageRequest page, {
    SearchCancellation? cancellation,
  }) async {
    calls.add((kind: 'artists', query: query, page: page, token: cancellation));
    cancellation?.throwIfCancelled();
    return detailPage(artistData.values, page);
  }

  @override
  Future<Album?> getAlbum(
    AlbumRef reference, {
    SearchCancellation? cancellation,
  }) async {
    calls.add((
      kind: 'album',
      query: reference,
      page: null,
      token: cancellation,
    ));
    if (onAlbum != null) return onAlbum!(reference, cancellation);
    cancellation?.throwIfCancelled();
    return albumData[reference];
  }

  @override
  Future<Artist?> getArtist(
    ArtistRef reference, {
    SearchCancellation? cancellation,
  }) async {
    calls.add((
      kind: 'artist',
      query: reference,
      page: null,
      token: cancellation,
    ));
    if (onArtist != null) return onArtist!(reference, cancellation);
    cancellation?.throwIfCancelled();
    return artistData[reference];
  }

  @override
  Future<PageResult<Track>> browseTracks(
    CatalogTrackQuery query,
    PageRequest page, {
    SearchCancellation? cancellation,
  }) async {
    calls.add((kind: 'tracks', query: query, page: page, token: cancellation));
    if (onTracks != null) return onTracks!(query, page, cancellation);
    cancellation?.throwIfCancelled();
    return detailPage(
      trackData.where(
        (track) =>
            (query.album == null ||
                (track.sourceId == query.album!.sourceId &&
                    track.albumId == query.album!.albumId)) &&
            (query.artist == null || track.sourceId == query.artist!.sourceId),
      ),
      page,
    );
  }

  @override
  Future<PageResult<Album>> browseAlbums(
    CatalogAlbumQuery query,
    PageRequest page, {
    SearchCancellation? cancellation,
  }) async {
    calls.add((kind: 'albums', query: query, page: page, token: cancellation));
    if (onAlbums != null) return onAlbums!(query, page, cancellation);
    cancellation?.throwIfCancelled();
    return detailPage(
      albumData.values.where(
        (album) =>
            query.artist == null || album.sourceId == query.artist!.sourceId,
      ),
      page,
    );
  }
}

PageResult<T> detailPage<T>(Iterable<T> items, PageRequest page) => PageResult(
  items: items.skip(page.offset).take(page.limit),
  hasMore: items.length > page.offset + page.limit,
);

Album detailAlbum({
  String source = 'source-a',
  String id = 'album-a',
  int count = 240,
}) => Album(
  id: id,
  sourceId: source,
  title: '测试专辑',
  artists: [ArtistCredit(id: 'album-artist', name: '合辑署名')],
  year: 2026,
  trackCount: count,
);

Artist detailArtist({String source = 'source-a', String id = 'artist-a'}) =>
    Artist(
      id: id,
      sourceId: source,
      name: '测试曲目艺人',
      albumCount: 240,
      trackCount: 480,
    );

Track detailTrack(
  String id, {
  String source = 'source-a',
  String album = 'album-a',
  MusicSourceType type = MusicSourceType.local,
  TrackAvailability availability = TrackAvailability.available,
}) => Track(
  id: id,
  sourceId: source,
  sourceType: type,
  title: '测试曲目 $id',
  artists: ['测试曲目艺人'],
  albumId: album,
  albumTitle: '测试专辑',
  duration: const Duration(seconds: 120),
  localPath: type == MusicSourceType.local ? '/test-only/$id.wav' : null,
  availability: availability,
);
