import 'package:yymusic/domain/models/catalog_search.dart';
import 'package:yymusic/domain/models/library_entities.dart';
import 'package:yymusic/domain/models/pagination.dart';
import 'package:yymusic/domain/models/track.dart';
import 'package:yymusic/domain/repositories/catalog_search_repository.dart';
import 'package:yymusic/domain/repositories/search_history_repository.dart';

class FakeSearchRepository implements CatalogSearchRepository {
  FakeSearchRepository({this.tracks = const []});
  List<Track> tracks;
  final requests = <(String, CatalogQuery, PageRequest, SearchCancellation?)>[];
  Future<PageResult<Track>> Function(
    CatalogQuery,
    PageRequest,
    SearchCancellation?,
  )?
  trackQuery;
  bool remoteFailure = false;
  @override
  Future<PageResult<Track>> searchTracks(
    CatalogQuery query,
    PageRequest page, {
    SearchCancellation? cancellation,
  }) async {
    requests.add(('tracks', query, page, cancellation));
    if (trackQuery != null) return trackQuery!(query, page, cancellation);
    _check(query, cancellation);
    final matching = tracks
        .where(
          (t) =>
              t.sourceType == query.sourceType &&
              t.title.toLowerCase().contains(query.text.toLowerCase()),
        )
        .toList();
    return PageResult(
      items: matching.skip(page.offset).take(page.limit),
      hasMore: matching.length > page.offset + page.limit,
    );
  }

  @override
  Future<PageResult<Album>> searchAlbums(
    CatalogQuery query,
    PageRequest page, {
    SearchCancellation? cancellation,
  }) async {
    requests.add(('albums', query, page, cancellation));
    _check(query, cancellation);
    return PageResult(
      items: tracks.isEmpty
          ? const []
          : [
              Album(
                id: 'album',
                sourceId: query.sourceType!.name,
                title: '夜航专辑',
                artists: [ArtistCredit(id: 'artist', name: '测试艺术家')],
                trackCount: 3,
              ),
            ],
      hasMore: false,
    );
  }

  @override
  Future<PageResult<Artist>> searchArtists(
    CatalogQuery query,
    PageRequest page, {
    SearchCancellation? cancellation,
  }) async {
    requests.add(('artists', query, page, cancellation));
    _check(query, cancellation);
    return PageResult(
      items: tracks.isEmpty
          ? const []
          : [
              Artist(
                id: 'artist',
                sourceId: query.sourceType!.name,
                name: '夜航艺术家',
                albumCount: 1,
                trackCount: 3,
              ),
            ],
      hasMore: false,
    );
  }

  void _check(CatalogQuery query, SearchCancellation? cancellation) {
    cancellation?.throwIfCancelled();
    if (remoteFailure && query.sourceType == MusicSourceType.rest) {
      throw StateError('Authorization private-search-marker');
    }
  }
}

class FakeSearchHistoryRepository implements SearchHistoryRepository {
  List<SearchHistoryEntry> items = [];
  final calls = <String>[];
  Future<void>? recordGate;
  bool fail = false, disposed = false;
  @override
  Future<List<SearchHistoryEntry>> listHistory() async {
    calls.add('list');
    if (fail) throw StateError('private-search-marker');
    return List.unmodifiable(items);
  }

  @override
  Future<void> record(String query, {String? sourceId}) async {
    calls.add('record');
    await recordGate;
    if (fail) throw StateError('private-search-marker');
    items = [
      SearchHistoryEntry(
        id: 'history-${calls.length}',
        query: query,
        searchedAt: DateTime.utc(2026, 9, 5),
      ),
      ...items.where((e) => e.query != query),
    ].take(20).toList();
  }

  @override
  Future<void> clear() async {
    calls.add('clear');
    if (fail) throw StateError('private-search-marker');
    items = [];
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}
