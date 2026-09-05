import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../domain/models/catalog_search.dart';
import '../../../domain/models/library_entities.dart';
import '../../../domain/models/load_state.dart';
import '../../../domain/models/music_source.dart';
import '../../../domain/models/pagination.dart';
import '../../../domain/models/track.dart';
import '../../../domain/repositories/catalog_search_repository.dart';
import '../../../domain/repositories/music_source_repository.dart';
import '../../../domain/repositories/search_history_repository.dart';
import '../../../playback/playback_controller.dart';

enum SearchFilter {
  all('全部'),
  tracks('曲目'),
  albums('专辑'),
  artists('艺术家'),
  local('本地音乐'),
  online('在线来源');

  const SearchFilter(this.label);
  final String label;
}

enum SearchKind {
  tracks('曲目'),
  albums('专辑'),
  artists('艺术家');

  const SearchKind(this.label);
  final String label;
}

typedef _Fetch<T> = Future<PageResult<T>> Function(
  CatalogQuery query,
  PageRequest page, {
  SearchCancellation? cancellation,
});

/// Each typed bucket owns pagination and errors. Mutations stay in its T scope.
final class SearchBucket<T extends Object> {
  SearchBucket(this.kind, this.sourceType, this._fetch, this._identity);
  final SearchKind kind;
  final MusicSourceType sourceType;
  final _Fetch<T>? _fetch;
  final Object Function(T) _identity;
  List<T> _items = List<T>.empty();
  List<T> get items => _items;
  LoadPhase _phase = LoadPhase.idle;
  LoadPhase get phase => _phase;
  bool _loading = false, _hasMore = false;
  bool get loading => _loading;
  bool get hasMore => _hasMore;
  int _offset = 0;
  bool get capped => _offset >= 200 && _hasMore;
  String get id => '${sourceType.name}-${kind.name}';
  String get title =>
      '${sourceType == MusicSourceType.local ? '本地' : '已入库在线来源'} · ${kind.label}';

  void _reset() {
    _items = List<T>.empty();
    _offset = 0;
    _phase = LoadPhase.idle;
    _loading = _hasMore = false;
  }

  Future<void> _load(String text, SearchCancellation token) async {
    if (_loading || capped || token.isCancelled) return;
    _loading = true;
    _phase = _items.isEmpty ? LoadPhase.loading : LoadPhase.data;
    try {
      final fetch = _fetch;
      if (fetch == null) throw StateError('Catalog unavailable');
      final page = await fetch(
        CatalogQuery(text, sourceType: sourceType),
        PageRequest(offset: _offset, limit: 20),
        cancellation: token,
      );
      if (token.isCancelled) return;
      // Defend the bounded projection even against a misbehaving adapter.
      final raw = page.items.take(20).toList();
      final seen = _items.map(_identity).toSet();
      _items = List<T>.unmodifiable([
        ..._items,
        ...raw.where((item) => seen.add(_identity(item))),
      ]);
      _offset += raw.length;
      _hasMore = raw.isNotEmpty && page.hasMore;
      _phase = _items.isEmpty ? LoadPhase.empty : LoadPhase.data;
    } catch (_) {
      if (!token.isCancelled) _phase = LoadPhase.error;
    } finally {
      // Old requests must not clear the loading flag of a new generation.
      if (!token.isCancelled) _loading = false;
    }
  }
}

/// Root-owned state; repositories and the sole player are borrowed, never created.
final class CatalogSearchController extends ChangeNotifier {
  CatalogSearchController({
    required this.playback,
    this.repository,
    this.historyRepository,
    this.sourceRepository,
    this.debounce = const Duration(milliseconds: 300),
  }) {
    buckets = List.unmodifiable([
      for (final type in MusicSourceType.values) ...[
        SearchBucket<Track>(
          SearchKind.tracks,
          type,
          repository?.searchTracks,
          (track) => track.ref,
        ),
        SearchBucket<Album>(
          SearchKind.albums,
          type,
          repository?.searchAlbums,
          (album) => (album.sourceId, album.id),
        ),
        SearchBucket<Artist>(
          SearchKind.artists,
          type,
          repository?.searchArtists,
          (artist) => (artist.sourceId, artist.id),
        ),
      ],
    ]);
  }
  final PlaybackController playback;
  final CatalogSearchRepository? repository;
  final SearchHistoryRepository? historyRepository;
  final MusicSourceRepository? sourceRepository;
  final Duration debounce;
  late final List<SearchBucket<Object>> buckets;
  final _pending = <Future<void>>{};
  Future<void> _historyTail = Future.value();
  StreamSubscription<List<MusicSourceConfig>>? _sources;
  Timer? _timer;
  SearchCancellation _token = SearchCancellation();
  Future<void>? _closeFuture;
  bool _started = false, _disposed = false, _composing = false;
  bool _active = true, _busy = false;
  int _intent = 0, _focusRequest = 0;
  String _input = '', _query = '';
  String? _inputError, _actionError, _historyError;
  SearchFilter _filter = SearchFilter.all;
  List<SearchHistoryEntry> _history = const [];
  Map<String, String> _sourceNames = const {};
  bool _historyBusy = false;
  String get input => _input;
  String get query => _query;
  String? get inputError => _inputError;
  String? get actionError => _actionError;
  String? get historyError => _historyError;
  bool get busy => _busy;
  bool get historyBusy => _historyBusy;
  int get focusRequest => _focusRequest;
  SearchFilter get filter => _filter;
  List<SearchHistoryEntry> get history => _history;
  bool get canSubmit =>
      !_disposed && !_composing && _query.isNotEmpty && _inputError == null;
  Iterable<SearchBucket<Object>> get visibleBuckets => buckets.where(
    (bucket) => switch (_filter) {
      SearchFilter.all => true,
      SearchFilter.tracks => bucket.kind == SearchKind.tracks,
      SearchFilter.albums => bucket.kind == SearchKind.albums,
      SearchFilter.artists => bucket.kind == SearchKind.artists,
      SearchFilter.local => bucket.sourceType == MusicSourceType.local,
      SearchFilter.online => bucket.sourceType == MusicSourceType.rest,
    },
  );
  String sourceLabel(String id, MusicSourceType type) =>
      _sourceNames[id] ?? (type == MusicSourceType.local ? '本地' : '在线来源');

  void start() {
    if (_disposed || _started) return;
    _started = true;
    unawaited(refreshHistory());
    try {
      _sources = sourceRepository?.watchSources().listen(
        (sources) {
          if (_disposed) return;
          _sourceNames = Map.unmodifiable({
            for (final source in sources) source.id: source.name,
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
  }

  void requestFocus() {
    if (_disposed) return;
    _focusRequest++;
    _notify();
  }

  /// No notification: called by route visibility updates during layout.
  void setActive(bool active) {
    if (_active == active) return;
    _active = active;
    if (!active) _intent++;
  }

  void updateInput(String text, {bool composing = false}) {
    if (_disposed || (_input == text && _composing == composing)) return;
    _input = text;
    _composing = composing;
    _invalidate();
    _inputError = null;
    _actionError = null;
    try {
      _query = normalizeSearchText(text);
    } catch (_) {
      _query = '';
      _inputError = '请输入不超过 2048 个字符的单行关键词。';
    }
    if (canSubmit) _timer = Timer(debounce, () => unawaited(_search()));
    _notify();
  }

  void selectFilter(SearchFilter value) {
    if (_disposed || _filter == value) return;
    _filter = value;
    _invalidate();
    if (canSubmit) unawaited(_search());
    _notify();
  }

  void _invalidate() {
    _intent++;
    _timer?.cancel();
    _token.cancel();
    _token = SearchCancellation();
    for (final bucket in buckets) {
      bucket._reset();
    }
  }

  Future<void> _search({int? playIntent}) {
    if (!canSubmit) return Future.value();
    return _track(() async {
      final token = _token;
      final futures = {
        for (final bucket in visibleBuckets) bucket: _load(bucket, token),
      };
      if (playIntent != null) {
        // Local tracks are preferred. Album/artist and slow remote queries
        // must not delay an already available local first result.
        for (final bucket in futures.keys.whereType<SearchBucket<Track>>()) {
          await futures[bucket];
          if (!_validIntent(playIntent)) break;
          final first = bucket.items
              .where(
                (track) => track.availability == TrackAvailability.available,
              )
              .firstOrNull;
          if (first != null) {
            await _play(first, playIntent);
            break;
          }
        }
      }
      await Future.wait(futures.values);
    });
  }

  Future<void> _load(
    SearchBucket<Object> bucket,
    SearchCancellation token,
  ) async {
    final result = bucket._load(_query, token);
    _notify();
    await result;
    if (!token.isCancelled) _notify();
  }

  Future<void> loadMore(SearchBucket<Object> bucket) {
    if (!canSubmit ||
        !visibleBuckets.contains(bucket) ||
        bucket.loading ||
        bucket.capped ||
        (bucket.phase != LoadPhase.error && !bucket.hasMore)) {
      return Future.value();
    }
    return _track(() => _load(bucket, _token));
  }

  Future<void> submit({bool playFirst = false}) {
    if (!canSubmit) return Future.value();
    _invalidate();
    final intent = _intent;
    final text = _query;
    // Only explicit submission persists; history failure never hides results.
    unawaited(_historyAction((repository) => repository.record(text)));
    return _search(playIntent: playFirst ? intent : null);
  }

  bool canPlay(Track track) =>
      !_disposed &&
      !_busy &&
      playback.isAvailable &&
      track.availability == TrackAvailability.available;
  Future<void> play(Track track) {
    if (!canPlay(track)) return Future.value();
    return _play(track, ++_intent);
  }

  bool _validIntent(int intent) => !_disposed && _active && intent == _intent;
  Future<void> _play(Track track, int intent) {
    if (!canPlay(track) || !_validIntent(intent)) return Future.value();
    _busy = true;
    _actionError = null;
    _notify();
    return _track(() async {
      try {
        await playback.playCatalogTrack(
          track.ref,
          canPlay: () => _validIntent(intent),
        );
      } catch (_) {
        if (_validIntent(intent)) _actionError = '播放未完成，请重试或选择其他曲目。';
      } finally {
        _busy = false;
        _notify();
      }
    });
  }

  Future<void> refreshHistory() => _historyAction((_) async {});
  Future<void> clearHistory() =>
      _historyAction((repository) => repository.clear());
  Future<void> _historyAction(
    Future<void> Function(SearchHistoryRepository) action,
  ) {
    if (_disposed) return Future.value();
    final future = _historyTail.then((_) async {
      if (_disposed) return;
      _historyBusy = true;
      _historyError = null;
      _notify();
      try {
        final repository = historyRepository;
        if (repository == null) throw StateError('History unavailable');
        await action(repository);
        final items = await repository.listHistory();
        if (!_disposed) _history = List.unmodifiable(items.take(20));
      } catch (_) {
        if (!_disposed) _historyError = '搜索历史操作未完成，请重试。';
      } finally {
        _historyBusy = false;
        _notify();
      }
    });
    _historyTail = future;
    return _track(() => future);
  }

  Future<void> _track(Future<void> Function() task) {
    late final Future<void> future;
    future = Future<void>.sync(task)
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
    _timer?.cancel();
    _token.cancel();
    super.dispose();
    _closeFuture = Future.wait<void>([
      if (_sources != null) _sources!.cancel(),
      ..._pending,
    ]).then((_) {});
    unawaited(_closeFuture!.catchError((Object _) {}));
  }

  Future<void> close() {
    dispose();
    return _closeFuture!;
  }
}
