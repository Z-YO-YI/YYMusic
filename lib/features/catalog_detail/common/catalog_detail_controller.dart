import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../domain/models/catalog_browse.dart';
import '../../../domain/models/catalog_search.dart';
import '../../../domain/models/collection_models.dart';
import '../../../domain/models/domain_failure.dart';
import '../../../domain/models/library_entities.dart';
import '../../../domain/models/load_state.dart';
import '../../../domain/models/pagination.dart';
import '../../../domain/models/track.dart';
import '../../../domain/repositories/catalog_browse_repository.dart';
import '../../../domain/repositories/collection_repository.dart';
import '../../../domain/repositories/music_source_repository.dart';
import '../../../playback/playback_controller.dart';
import 'catalog_detail_state.dart';

part 'catalog_detail_favorites.dart';
part 'catalog_detail_sessions.dart';

final class _DetailBuffer<T> {
  var state = CatalogDetailPage<T>();
  var token = SearchCancellation();
  void reset() {
    token.cancel();
    token = SearchCancellation();
    state = CatalogDetailPage<T>();
  }
}

/// One detail projection, owned by the root registry until reads/actions drain.
/// No query is started by construction; views call start outside their build.
final class CatalogDetailController extends ChangeNotifier {
  CatalogDetailController._(
    this.target,
    this._repository,
    this._onClosed,
    this._playback,
    this._sources,
    this._collection,
  );
  final CatalogDetailTarget target;
  final CatalogBrowseRepository? _repository;
  final VoidCallback _onClosed;
  final PlaybackController? _playback;
  final MusicSourceRepository? _sources;
  final CollectionRepository? _collection;
  late final _favorites = _DetailFavorites(_collection, _notify, _track);
  final _tracks = _DetailBuffer<Track>();
  final _albums = _DetailBuffer<Album>();
  final _pending = <Future<void>>{};
  var _headerToken = SearchCancellation();
  LoadState<CatalogDetailSummary> _summary = const LoadState.idle();
  LoadState<CatalogDetailSummary> get summary => _summary;
  CatalogDetailPage<Track> get tracks => _tracks.state;
  CatalogDetailPage<Album> get albums => _albums.state;
  bool _disposed = false, _started = false;
  bool _active = true, _busy = false;
  int _intent = 0, _revision = 0;
  String _sourceLabel = '来源未配置';
  String? _actionError;
  String get sourceLabel => _sourceLabel;
  String? get actionError => _actionError;
  bool get busy => _busy;
  bool get favoritesReady => _favorites.ready;
  String? get favoriteError => _favorites.error;
  bool isFavorite(TrackRef reference) => _favorites.contains(reference);
  int get revision => _revision;
  Future<void>? _initialLoad, _closeFuture;

  /// Starts once. Retained routes and layout changes reuse their existing state.
  Future<void> start() {
    if (_disposed) return Future.value();
    if (_started) return _initialLoad ?? Future.value();
    _started = true;
    return _initialLoad = refresh();
  }

  /// Reloads the summary and both sections; old work may finish but cannot win.
  Future<void> refresh() {
    if (_disposed) return Future.value();
    _started = true;
    _intent++;
    _revision++;
    _actionError = null;
    _headerToken.cancel();
    final token = _headerToken = SearchCancellation();
    _tracks.reset();
    _albums.reset();
    _summary = const LoadState.loading();
    final operation = _track(() async {
      try {
        if (!_valid(token)) return;
        final repository = _repository;
        if (repository == null) throw StateError('Catalog unavailable');
        final CatalogDetailSummary? result;
        switch (target) {
          case AlbumDetailTarget(:final reference):
            final album = await repository.getAlbum(
              reference,
              cancellation: token,
            );
            if (!_valid(token)) return;
            if (album != null && album.ref != reference) throw _mismatch();
            result = album == null ? null : AlbumDetailSummary(album);
          case ArtistDetailTarget(:final reference):
            final artist = await repository.getArtist(
              reference,
              cancellation: token,
            );
            if (!_valid(token)) return;
            if (artist != null && artist.ref != reference) throw _mismatch();
            result = artist == null ? null : ArtistDetailSummary(artist);
        }
        _summary = result == null
            ? const LoadState.empty()
            : LoadState.data(result);
        _notify();
        // A listener may close or refresh this session when the summary arrives.
        if (result == null || !_valid(token)) return;
        await Future.wait([
          loadMoreTracks(),
          if (target is ArtistDetailTarget) loadMoreAlbums(),
        ]);
      } catch (error) {
        if (!_valid(token)) return;
        _summary = LoadState.error(
          _safeFailure(error, 'catalog-detail.summary'),
        );
        _notify();
      }
    });
    _sourceLabel = _sources == null ? '来源未配置' : '来源读取中';
    final sourceRead = _track(() async {
      if (!_valid(token)) return;
      try {
        final source = await _sources?.getSource(target.sourceId);
        if (!_valid(token)) return;
        _sourceLabel = source?.id == target.sourceId ? source!.name : '来源未配置';
      } catch (_) {
        if (!_valid(token)) return;
        _sourceLabel = '来源未配置';
      }
      _notify();
    });
    _notify();
    return Future.wait([operation, sourceRead]).then((_) {});
  }

  /// Route visibility revokes unexecuted playback intent, not already playing audio.
  void setActive(bool active) {
    if (_disposed || active == _active) return;
    _active = active;
    if (!active) _intent++;
  }

  bool canPlay(TrackRef reference) =>
      !_disposed &&
      _active &&
      !_busy &&
      (_playback?.isAvailable ?? false) &&
      tracks.items.any(
        (track) =>
            track.ref == reference &&
            track.availability == TrackAvailability.available,
      );

  /// Reuses/appends a root queue entry; never constructs a player or replaces a queue.
  Future<void> play(TrackRef reference) {
    if (!canPlay(reference)) return Future.value();
    final intent = _intent;
    _busy = true;
    _actionError = null;
    final operation = _track(() async {
      try {
        await _playback!.playCatalogTrack(
          reference,
          canPlay: () => !_disposed && _active && intent == _intent,
        );
      } catch (_) {
        if (!_disposed && intent == _intent) _actionError = '播放未完成，请重试。';
      } finally {
        _busy = false;
        _notify();
      }
    });
    _notify();
    return operation;
  }

  bool canOpenActions(TrackRef reference) =>
      !_disposed &&
      _active &&
      tracks.items.any((track) => track.ref == reference);
  bool canFavorite(TrackRef reference) =>
      canOpenActions(reference) && !_busy && _favorites.ready;
  void prepareTrackActions() {
    if (!_disposed && _active) _favorites.start();
  }

  void retryFavorites() {
    if (!_disposed && _active) _favorites.retry();
  }

  /// Accepted writes drain even if this route is refreshed, covered or closed.
  Future<void> toggleFavorite(TrackRef reference) {
    if (!canFavorite(reference)) return Future.value();
    final next = !isFavorite(reference);
    _busy = true;
    _actionError = null;
    final operation = _track(() async {
      try {
        await _collection!.setFavorite(reference, favorite: next);
        _favorites.retry();
      } catch (_) {
        if (!_disposed) _actionError = '收藏未完成，请重试。';
      } finally {
        _busy = false;
        _notify();
      }
    });
    _notify();
    return operation;
  }

  /// Retries only the failed track page, leaving the summary/albums untouched.
  Future<void> loadMoreTracks() => _loadPage(
    _tracks,
    diagnostic: 'catalog-detail.tracks',
    query: (repository, page, token) => repository.browseTracks(
      CatalogTrackQuery(
        album: switch (target) {
          AlbumDetailTarget(:final reference) => reference,
          ArtistDetailTarget() => null,
        },
        artist: switch (target) {
          ArtistDetailTarget(:final reference) => reference,
          AlbumDetailTarget() => null,
        },
      ),
      page,
      cancellation: token,
    ),
    identity: (track) => track.ref,
    matches: (track) =>
        track.sourceId == target.sourceId &&
        switch (target) {
          AlbumDetailTarget(:final reference) =>
            track.albumId == reference.albumId,
          // Track exposes artist names, not credit IDs. The repository must
          // enforce this join; name-based matching would corrupt its semantics.
          ArtistDetailTarget() => true,
        },
  );

  /// Artist albums have an independent page/error state. Albums have no child albums.
  Future<void> loadMoreAlbums() {
    final target = this.target;
    if (target is! ArtistDetailTarget) return Future.value();
    return _loadPage(
      _albums,
      diagnostic: 'catalog-detail.albums',
      query: (repository, page, token) => repository.browseAlbums(
        CatalogAlbumQuery(artist: target.reference),
        page,
        cancellation: token,
      ),
      identity: (album) => album.ref,
      // The artist can be credited on a track in a compilation without being
      // an album artist. Association is the repository's track-credit join.
      matches: (album) => album.sourceId == target.sourceId,
    );
  }

  Future<void> _loadPage<T>(
    _DetailBuffer<T> buffer, {
    required String diagnostic,
    required Future<PageResult<T>> Function(
      CatalogBrowseRepository,
      PageRequest,
      SearchCancellation,
    )
    query,
    required Object Function(T) identity,
    required bool Function(T) matches,
  }) {
    final previous = buffer.state;
    if (_disposed ||
        summary.phase != LoadPhase.data ||
        previous.loading ||
        previous.capped ||
        previous.phase == LoadPhase.empty ||
        (previous.phase == LoadPhase.data && !previous.hasMore)) {
      return Future.value();
    }
    final token = buffer.token;
    final limit = (CatalogDetailPage.maxRawCount - previous.rawCount).clamp(
      1,
      CatalogDetailPage.pageSize,
    );
    buffer.state = CatalogDetailPage(
      items: previous.items,
      phase: previous.items.isEmpty ? LoadPhase.loading : LoadPhase.data,
      loading: true,
      hasMore: previous.hasMore,
      rawCount: previous.rawCount,
    );
    final operation = _track(() async {
      try {
        if (!_valid(token)) return;
        final result = await query(
          _repository!,
          PageRequest(offset: previous.rawCount, limit: limit),
          token,
        );
        if (!_valid(token)) return;
        final raw = result.items.take(limit).toList();
        if (!raw.every(matches)) throw _mismatch();
        final seen = previous.items.map(identity).toSet();
        final items = [
          ...previous.items,
          ...raw.where((item) => seen.add(identity(item))),
        ];
        buffer.state = CatalogDetailPage(
          items: items,
          phase: items.isEmpty ? LoadPhase.empty : LoadPhase.data,
          hasMore: raw.isNotEmpty && result.hasMore,
          rawCount: previous.rawCount + raw.length,
        );
      } catch (error) {
        if (!_valid(token)) return;
        buffer.state = CatalogDetailPage(
          items: previous.items,
          phase: LoadPhase.error,
          hasMore: previous.hasMore,
          rawCount: previous.rawCount,
          failure: _safeFailure(error, diagnostic),
        );
      }
      if (_valid(token)) _notify();
    });
    _notify();
    return operation;
  }

  bool _valid(SearchCancellation token) => !_disposed && !token.isCancelled;
  static DomainFailure _mismatch() => DomainFailure(
    code: DomainFailureCode.schemaMismatch,
    diagnosticId: 'catalog-detail.identity-mismatch',
  );
  static DomainFailure _safeFailure(Object error, String diagnostic) =>
      DomainFailure(
        code: error is DomainFailure ? error.code : DomainFailureCode.unknown,
        diagnosticId: diagnostic,
        retryable: true,
      );

  Future<void> _track(Future<void> Function() action) {
    late final Future<void> future;
    // Defer execution until the future is registered. Even a synchronous fake
    // or reentrant notification cannot close storage ahead of this operation.
    future = Future<void>(action).whenComplete(() => _pending.remove(future));
    _pending.add(future);
    return future;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _intent++;
    _headerToken.cancel();
    _tracks.token.cancel();
    _albums.token.cancel();
    _favorites.close();
    super.dispose();
    _closeFuture = Future.wait<void>(_pending).then((_) {
      _onClosed();
    });
    unawaited(_closeFuture!.catchError((Object _) {}));
  }

  /// Waits for actual in-flight reads, even if the adapter ignores cancellation.
  Future<void> close() {
    dispose();
    return _closeFuture!;
  }
}
