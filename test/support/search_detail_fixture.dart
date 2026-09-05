import 'package:yymusic/domain/models/library_entities.dart';
import 'package:yymusic/domain/models/pagination.dart';
import 'package:yymusic/domain/models/track.dart';

import 'catalog_detail_probe.dart';
import 'search_graph_fixture.dart';

/// The IDs intentionally differ from source types and contain URI separators.
final class SearchDetailFixture {
  SearchDetailFixture() {
    search = SearchGraphFixture(catalogBrowse: catalog);
    for (final source in ['archive/local?完整%#', 'api/rest+音乐']) {
      final artist = Artist(
        id: 'artist/a?%2F#',
        sourceId: source,
        name: '夜航艺人',
        albumCount: 1,
        trackCount: 0,
      );
      final album = Album(
        id: 'album/a?%2F#',
        sourceId: source,
        title: '夜航专辑',
        artists: [ArtistCredit(id: artist.id, name: artist.name)],
        trackCount: 0,
      );
      artists.add(artist);
      albums.add(album);
      catalog.artistData[artist.ref] = artist;
      catalog.albumData[album.ref] = album;
    }
    search.repository.albumQuery = (query, page, token) async => PageResult(
      items: page.offset > 0
          ? const []
          : [albums[query.sourceType == MusicSourceType.local ? 0 : 1]],
      hasMore: false,
    );
    search.repository.artistQuery = (query, page, token) async => PageResult(
      items: page.offset > 0
          ? const []
          : [artists[query.sourceType == MusicSourceType.local ? 0 : 1]],
      hasMore: false,
    );
    catalog.onAlbums = (query, page, token) async => PageResult(
      items: albums
          .where((a) => a.sourceId == query.artist!.sourceId)
          .skip(page.offset)
          .take(page.limit),
      hasMore: false,
    );
  }
  final catalog = CatalogDetailProbe();
  final albums = <Album>[];
  final artists = <Artist>[];
  late final SearchGraphFixture search;
}
