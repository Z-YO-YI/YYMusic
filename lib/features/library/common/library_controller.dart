import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../domain/models/catalog_browse.dart';
import '../../../domain/models/catalog_search.dart';
import '../../../domain/models/collection_models.dart';
import '../../../domain/models/library_entities.dart';
import '../../../domain/models/load_state.dart';
import '../../../domain/models/music_source.dart';
import '../../../domain/models/pagination.dart';
import '../../../domain/models/track.dart';
import '../../../domain/repositories/catalog_browse_repository.dart';
import '../../../domain/repositories/collection_repository.dart';
import '../../../domain/repositories/music_source_repository.dart';
import '../../../playback/playback_controller.dart';

enum LibraryCategory {
  albums('专辑'),
  tracks('歌曲'),
  artists('艺人'),
  playlists('歌单'),
  local('本地');

  const LibraryCategory(this.label);
  final String label;
}

enum LibrarySource { all, local, online }

enum LibraryAvailability { all, available, unavailable }

/// One bounded, read-only view per category; only its controller mutates it.
final class LibraryPage {
  LibraryPage(this.category);
  final LibraryCategory category;
  List<Object> _items = const [];
  List<Object> get items => _items;
  LoadPhase _phase = LoadPhase.idle;
  LoadPhase get phase => _phase;
  bool _loading = false, _hasMore = false;
  bool get loading => _loading;
  bool get hasMore => _hasMore;
  int _offset = 0, _sort = 0;
  int get sort => _sort;
  CatalogDirection _direction = CatalogDirection.ascending;
  CatalogDirection get direction => _direction;
  bool get capped => _offset >= 200 && _hasMore;
  SearchCancellation _token = SearchCancellation();
  void _reset() {
    _token.cancel();
    _token = SearchCancellation();
    _items = const [];
    _phase = LoadPhase.idle;
    _loading = _hasMore = false;
    _offset = 0;
  }
}

/// Root-owned catalog projection. Storage and playback are borrowed contracts.
final class LibraryController extends ChangeNotifier {
  LibraryController({
    required this.playback,
    this.repository,
    this.collection,
    this.sources,
  });
  final PlaybackController playback;
  final CatalogBrowseRepository? repository;
  final CollectionRepository? collection;
  final MusicSourceRepository? sources;
  final _pages = {
    for (final category in LibraryCategory.values)
      category: LibraryPage(category),
  };
  final _pending = <Future<void>>{};
  StreamSubscription<List<MusicSourceConfig>>? _sourceSubscription;
  StreamSubscription<List<FavoriteEntry>>? _favoriteSubscription;
  StreamSubscription<List<Playlist>>? _playlistSubscription;
  Map<String, String> _sourceNames = const {};
  Set<TrackRef> _favorites = const {};
  LibraryCategory _category = LibraryCategory.albums;
  LibrarySource _source = LibrarySource.all;
  LibraryAvailability _availability = LibraryAvailability.all;
  bool _started = false, _disposed = false, _active = true, _busy = false;
  bool _favoritesReady = false;
  int _intent = 0,
      _playlistGeneration = 0,
      _favoriteGeneration = 0,
      _viewRevision = 0;
  String? _actionError, _favoriteError;
  Future<void>? _closeFuture;
  LibraryCategory get category => _category;
  LibrarySource get source => _source;
  LibraryAvailability get availability => _availability;
  LibraryPage get page => _pages[_category]!;
  int get viewRevision => _viewRevision;
  bool get busy => _busy;
  String? get actionError => _actionError;
  String? get favoriteError => _favoriteError;
  bool isFavorite(Track track) => _favorites.contains(track.ref);
  String sourceLabel(String id) => _sourceNames[id] ?? '来源未配置';
  List<String> get sortLabels => switch (_category) {
    LibraryCategory.albums => const ['名称', '首位艺人', '年份', '曲目数'],
    LibraryCategory.artists => const ['名称', '专辑数', '曲目数'],
    LibraryCategory.tracks ||
    LibraryCategory.local => const ['名称', '首位艺人', '专辑', '时长', '入库时间'],
    LibraryCategory.playlists => const [],
  };

  void start() {
    if (_disposed || _started) return;
    _started = true;
    try {
      _sourceSubscription = sources?.watchSources().listen(
        (items) {
          if (_disposed) return;
          _sourceNames = Map.unmodifiable({
            for (final item in items) item.id: item.name,
          });
          _notify();
        },
        onError: (Object _) {
          if (_disposed) return;
          _sourceNames = const {};
          _notify();
        },
      );
    } catch (_) {
      _sourceNames = const {};
    }
    retryFavorites();
    _watchPlaylists();
    unawaited(loadMore());
  }

  void selectCategory(LibraryCategory value) {
    if (_disposed || value == _category) return;
    _category = value;
    _changedView();
    if (page.phase == LoadPhase.idle) unawaited(loadMore());
  }

  void setSource(LibrarySource value) {
    if (_disposed ||
        value == _source ||
        _category == LibraryCategory.playlists ||
        _category == LibraryCategory.local) {
      return;
    }
    _source = value;
    _resetCatalog();
  }

  void setAvailability(LibraryAvailability value) {
    if (_disposed ||
        value == _availability ||
        _category == LibraryCategory.playlists) {
      return;
    }
    _availability = value;
    _resetCatalog();
  }

  void setSort(int value) {
    if (_disposed ||
        _category == LibraryCategory.playlists ||
        page.sort == value) {
      return;
    }
    if (value < 0 || value >= sortLabels.length) {
      throw ArgumentError('Invalid library sort');
    }
    page._sort = value;
    _refreshPage();
  }

  void toggleDirection() {
    if (_disposed || _category == LibraryCategory.playlists) return;
    page._direction = page.direction == CatalogDirection.ascending
        ? CatalogDirection.descending
        : CatalogDirection.ascending;
    _refreshPage();
  }

  void refresh() {
    if (_disposed) return;
    if (_category == LibraryCategory.playlists) {
      _watchPlaylists();
    } else {
      _refreshPage();
    }
  }

  void _resetCatalog() {
    for (final entry in _pages.values) {
      if (entry.category != LibraryCategory.playlists) entry._reset();
    }
    _changedView();
    unawaited(loadMore());
  }

  void _refreshPage() {
    page._reset();
    _changedView();
    unawaited(loadMore());
  }

  void _changedView() {
    _intent++;
    _viewRevision++;
    _actionError = null;
    _notify();
  }

  CatalogFilter _filter(LibraryCategory category) => CatalogFilter(
    sourceType: category == LibraryCategory.local
        ? MusicSourceType.local
        : switch (_source) {
            LibrarySource.all => null,
            LibrarySource.local => MusicSourceType.local,
            LibrarySource.online => MusicSourceType.rest,
          },
    availability: switch (_availability) {
      LibraryAvailability.all => const [],
      LibraryAvailability.available => const [TrackAvailability.available],
      LibraryAvailability.unavailable => TrackAvailability.values.where(
        (value) => value != TrackAvailability.available,
      ),
    },
  );

  Future<void> loadMore() {
    final target = page;
    if (_disposed ||
        target.category == LibraryCategory.playlists ||
        target.loading ||
        target.capped ||
        (target.phase == LoadPhase.data && !target.hasMore) ||
        target.phase == LoadPhase.empty) {
      return Future.value();
    }
    final token = target._token;
    target._loading = true;
    target._phase = target.items.isEmpty ? LoadPhase.loading : LoadPhase.data;
    _notify();
    return _track(() async {
      try {
        final repository = this.repository;
        if (repository == null) throw StateError('Library unavailable');
        final request = PageRequest(
          offset: target._offset,
          limit: (200 - target._offset).clamp(1, 20),
        );
        final filter = _filter(target.category);
        final Future<PageResult<Object>> query = switch (target.category) {
          LibraryCategory.albums => repository.browseAlbums(
            CatalogAlbumQuery(
              filter: filter,
              sort: CatalogAlbumSort.values[target.sort],
              direction: target.direction,
            ),
            request,
            cancellation: token,
          ),
          LibraryCategory.artists => repository.browseArtists(
            CatalogArtistQuery(
              filter: filter,
              sort: CatalogArtistSort.values[target.sort],
              direction: target.direction,
            ),
            request,
            cancellation: token,
          ),
          LibraryCategory.tracks ||
          LibraryCategory.local => repository.browseTracks(
            CatalogTrackQuery(
              filter: filter,
              sort: CatalogTrackSort.values[target.sort],
              direction: target.direction,
            ),
            request,
            cancellation: token,
          ),
          LibraryCategory.playlists => throw StateError(
            'Playlist stream required',
          ),
        };
        final result = await query;
        if (_disposed || token.isCancelled) return;
        final raw = result.items.take(request.limit).toList();
        final seen = target.items.map(_identity).toSet();
        target._items = List.unmodifiable([
          ...target.items,
          ...raw.where((item) => seen.add(_identity(item))),
        ]);
        target._offset += raw.length;
        target._hasMore = raw.isNotEmpty && result.hasMore;
        target._phase = target.items.isEmpty ? LoadPhase.empty : LoadPhase.data;
      } catch (_) {
        if (!_disposed && !token.isCancelled) target._phase = LoadPhase.error;
      } finally {
        if (!token.isCancelled) target._loading = false;
        _notify();
      }
    });
  }

  void _watchPlaylists() {
    final generation = ++_playlistGeneration;
    final old = _playlistSubscription;
    _playlistSubscription = null;
    if (old != null) _cancelOld(old);
    final target = _pages[LibraryCategory.playlists]!;
    target._phase = LoadPhase.loading;
    _notify();
    try {
      final collection = this.collection;
      if (collection == null) throw StateError('Collection unavailable');
      _playlistSubscription = collection.watchPlaylists().listen(
        (items) {
          if (_disposed || generation != _playlistGeneration) return;
          target._items = List.unmodifiable(items.take(200));
          target._hasMore = items.length > 200;
          target._offset = target.items.length;
          target._phase = target.items.isEmpty
              ? LoadPhase.empty
              : LoadPhase.data;
          _notify();
        },
        onError: (Object _) {
          if (_disposed || generation != _playlistGeneration) return;
          target._phase = LoadPhase.error;
          _notify();
        },
      );
    } catch (_) {
      target._phase = LoadPhase.error;
      _notify();
    }
  }

  /// Re-subscribes only to favorites; a failure never hides the catalog.
  void retryFavorites() {
    if (_disposed) return;
    final generation = ++_favoriteGeneration;
    final old = _favoriteSubscription;
    _favoriteSubscription = null;
    if (old != null) _cancelOld(old);
    _favoritesReady = false;
    _favoriteError = null;
    try {
      final collection = this.collection;
      if (collection == null) throw StateError('Favorites unavailable');
      _favoriteSubscription = collection.watchFavorites().listen(
        (items) {
          if (_disposed || generation != _favoriteGeneration) return;
          _favorites = Set.unmodifiable(items.map((item) => item.track));
          _favoritesReady = true;
          _favoriteError = null;
          _notify();
        },
        onError: (Object _) {
          if (generation == _favoriteGeneration) _favoritesFailed();
        },
      );
    } catch (_) {
      _favoritesFailed();
    }
  }

  void _favoritesFailed() {
    if (_disposed) return;
    _favoritesReady = false;
    _favoriteError = '收藏状态读取失败，可重试；曲库不受影响。';
    _notify();
  }

  void _cancelOld(StreamSubscription<Object?> subscription) {
    unawaited(
      _track(() async {
        try {
          await subscription.cancel();
        } catch (_) {
          /* Old generations cannot publish. */
        }
      }),
    );
  }

  bool _visible(Track track) =>
      page.items.whereType<Track>().any((item) => item.ref == track.ref);
  bool canPlay(Track track) =>
      !_disposed &&
      _active &&
      !_busy &&
      _visible(track) &&
      track.availability == TrackAvailability.available &&
      playback.isAvailable;
  bool canFavorite(Track track) =>
      !_disposed && _active && !_busy && _visible(track) && _favoritesReady;
  bool _valid(int intent) => !_disposed && _active && intent == _intent;
  void setActive(bool value) {
    if (_disposed || value == _active) return;
    _active = value;
    if (!value) _intent++;
  }

  Future<void> play(Track track) {
    if (!canPlay(track)) return Future.value();
    final intent = _intent;
    return _action(
      () => playback.playCatalogTrack(track.ref, canPlay: () => _valid(intent)),
    );
  }

  Future<void> toggleFavorite(Track track) {
    if (!canFavorite(track)) return Future.value();
    final next = !isFavorite(track);
    return _action(() => collection!.setFavorite(track.ref, favorite: next));
  }

  Future<void> _action(Future<void> Function() action) {
    _busy = true;
    _actionError = null;
    _notify();
    return _track(() async {
      try {
        await action();
      } catch (_) {
        if (!_disposed) _actionError = '操作未完成，请重试。';
      } finally {
        _busy = false;
        _notify();
      }
    });
  }

  static Object _identity(Object item) => switch (item) {
    Track() => item.ref,
    Album() => item.ref,
    Artist() => item.ref,
    Playlist() => item.id,
    _ => throw StateError('Unexpected catalog entity'),
  };
  Future<void> _track(Future<void> Function() action) {
    late final Future<void> future;
    future = Future<void>.sync(action)
        .whenComplete(() => _pending.remove(future));
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
    for (final page in _pages.values) {
      page._token.cancel();
    }
    super.dispose();
    _closeFuture = Future.wait<void>([
      if (_sourceSubscription != null) _sourceSubscription!.cancel(),
      if (_favoriteSubscription != null) _favoriteSubscription!.cancel(),
      if (_playlistSubscription != null) _playlistSubscription!.cancel(),
      ..._pending,
    ]).then((_) {});
    unawaited(_closeFuture!.catchError((Object _) {}));
  }

  Future<void> close() {
    dispose();
    return _closeFuture!;
  }
}
