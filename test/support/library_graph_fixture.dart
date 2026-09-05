import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/domain/models/catalog_browse.dart';
import 'package:yymusic/domain/models/catalog_search.dart';
import 'package:yymusic/domain/models/library_entities.dart';
import 'package:yymusic/domain/models/pagination.dart';
import 'package:yymusic/domain/models/track.dart';

import 'fake_audio_engine.dart';
import 'fake_catalog_browse_repository.dart';
import 'fake_domain_repositories.dart';
import 'fake_playback_dependencies.dart';

typedef BrowseCall = ({
  Object query,
  PageRequest page,
  SearchCancellation? cancellation,
});

/// Deterministic test adapter. SQL sort/association semantics have separate tests.
class BrowseStub extends FakeCatalogBrowseRepository {
  BrowseStub(this.tracks);
  final List<Track> tracks;
  final calls = <BrowseCall>[];
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
  Future<PageResult<Artist>> Function(
    CatalogArtistQuery,
    PageRequest,
    SearchCancellation?,
  )?
  onArtists;
  bool fail = false;
  Iterable<Track> _filtered(CatalogFilter filter) => tracks.where(
    (t) =>
        (filter.sourceType == null || t.sourceType == filter.sourceType) &&
        (filter.sourceId == null || t.sourceId == filter.sourceId) &&
        (filter.availability.isEmpty ||
            filter.availability.contains(t.availability)),
  );
  PageResult<T> _page<T>(Iterable<T> items, PageRequest page) {
    if (fail) throw StateError('private-test-error');
    final remaining = items.skip(page.offset).toList();
    return PageResult(
      items: remaining.take(page.limit),
      hasMore: remaining.length > page.limit,
    );
  }

  @override
  Future<PageResult<Track>> browseTracks(
    CatalogTrackQuery query,
    PageRequest page, {
    SearchCancellation? cancellation,
  }) async {
    calls.add((query: query, page: page, cancellation: cancellation));
    if (onTracks != null) return onTracks!(query, page, cancellation);
    cancellation?.throwIfCancelled();
    return _page(_filtered(query.filter), page);
  }

  @override
  Future<PageResult<Album>> browseAlbums(
    CatalogAlbumQuery query,
    PageRequest page, {
    SearchCancellation? cancellation,
  }) async {
    calls.add((query: query, page: page, cancellation: cancellation));
    if (onAlbums != null) return onAlbums!(query, page, cancellation);
    cancellation?.throwIfCancelled();
    return _page(
      _filtered(query.filter).map(
        (t) => Album(
          id: t.albumId!,
          sourceId: t.sourceId,
          title: t.albumTitle!,
          artists: [ArtistCredit(id: t.id, name: t.artists.first)],
          year: 2026,
          trackCount: 1,
        ),
      ),
      page,
    );
  }

  @override
  Future<PageResult<Artist>> browseArtists(
    CatalogArtistQuery query,
    PageRequest page, {
    SearchCancellation? cancellation,
  }) async {
    calls.add((query: query, page: page, cancellation: cancellation));
    if (onArtists != null) return onArtists!(query, page, cancellation);
    cancellation?.throwIfCancelled();
    return _page(
      _filtered(query.filter).map(
        (t) => Artist(
          id: t.id,
          sourceId: t.sourceId,
          name: t.artists.first,
          albumCount: 1,
          trackCount: 1,
        ),
      ),
      page,
    );
  }
}

class LibraryGraphFixture {
  LibraryGraphFixture({int count = 24, FakeCollectionRepository? collections}) {
    tracks = [
      for (var i = 0; i < count; i++)
        Track(
          id: 'library-${i.toString().padLeft(3, '0')}',
          sourceId: i.isEven ? 'local-test' : 'rest-test',
          sourceType: i.isEven ? MusicSourceType.local : MusicSourceType.rest,
          title: '音乐库歌曲 ${i + 1}',
          artists: ['测试艺人 ${i + 1}'],
          albumId: 'album-$i',
          albumTitle: '音乐库专辑 ${i + 1}',
          localPath: i.isEven ? '/fixture-only/$i.wav' : null,
          duration: const Duration(seconds: 185),
          availability: i == 2
              ? TrackAvailability.localMissing
              : TrackAvailability.available,
        ),
    ];
    repository = BrowseStub(tracks);
    collection = collections ?? FakeCollectionRepository();
    graph = DependencyGraph(
      catalogBrowse: repository,
      library: FakeLibraryRepository(tracks: tracks),
      collection: collection,
      musicSources: sources,
      audioEngine: engine,
      playbackSourceResolver: FakePlaybackSourceResolver(),
    );
  }
  late final List<Track> tracks;
  late final BrowseStub repository;
  late final FakeCollectionRepository collection;
  final sources = FakeMusicSourceRepository();
  final engine = FakeAudioEngine();
  late final DependencyGraph graph;
  Future<void> disposeFakes() async {
    await collection.dispose();
    await sources.dispose();
  }

  Future<void> close() async {
    await graph.close();
    await disposeFakes();
  }
}
