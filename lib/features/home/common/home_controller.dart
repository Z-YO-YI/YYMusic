import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../domain/models/collection_models.dart';
import '../../../domain/models/domain_failure.dart';
import '../../../domain/models/load_state.dart';
import '../../../domain/models/music_source.dart';
import '../../../domain/models/pagination.dart';
import '../../../domain/models/track.dart';
import '../../../domain/repositories/collection_repository.dart';
import '../../../domain/repositories/library_repository.dart';
import '../../../domain/repositories/music_source_repository.dart';
import '../../../playback/playback_controller.dart';
import '../../../playback/playback_state.dart';

/// Bounded repository projection. A layout never owns a player or database.
final class HomeController extends ChangeNotifier {
  HomeController({
    required this.playback,
    this.library,
    this.collection,
    this.sourceRepository,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final PlaybackController playback;
  final LibraryRepository? library;
  final CollectionRepository? collection;
  final MusicSourceRepository? sourceRepository;
  final DateTime Function() _clock;
  final _pending = <Future<void>>{};
  StreamSubscription<List<PlayHistoryEntry>>? _historySubscription;
  StreamSubscription<List<MusicSourceConfig>>? _sourceSubscription;
  var _catalogVersion = 0;
  var _historyVersion = 0;
  var _sourceVersion = 0;
  var _started = false;
  var _disposed = false;
  var _sequence = 0;
  Future<void>? _closeFuture;
  bool _busy = false;
  bool get busy => _busy;
  String? _actionError;
  LoadState<List<Track>> _recent = const LoadState.idle();
  LoadState<List<Track>> _history = const LoadState.idle();
  LoadState<List<Track>> _localSelection = const LoadState.idle();
  LoadState<List<MusicSourceConfig>> _sources = const LoadState.idle();

  String? get actionError => _actionError;
  LoadState<List<Track>> get recent => _recent;
  LoadState<List<Track>> get history => _history;
  LoadState<List<Track>> get localSelection => _localSelection;
  LoadState<List<MusicSourceConfig>> get sources => _sources;

  List<Track> get featured => List.unmodifiable(
    (_history.data?.any(_available) ?? false)
        ? _history.data!.where(_available).take(6)
        : (_localSelection.data ?? const <Track>[]).where(_available).take(6),
  );

  void start() {
    if (_started || _disposed) return;
    _started = true;
    unawaited(refreshCatalog());
    retryHistory();
    retrySources();
  }

  Future<void> refreshCatalog() {
    if (_disposed) return Future.value();
    final version = ++_catalogVersion;
    _recent = const LoadState.loading();
    _localSelection = const LoadState.loading();
    notifyListeners();
    return _track(() async {
      final library = this.library;
      if (library == null) {
        _recent = _failure('catalog');
        _localSelection = _failure('selection');
        _notify();
        return;
      }
      // Independent operations: a recent-date query failure must not hide the
      // fallback local selection. Both are bounded database queries.
      await Future.wait([
        () async {
          try {
            final until = _clock().toUtc();
            final page = await library.listRecentlyAdded(
              PageRequest(limit: 20),
              since: until.subtract(const Duration(days: 7)),
              until: until,
            );
            if (_disposed || version != _catalogVersion) return;
            _recent = _loaded(page.items);
          } catch (_) {
            if (_disposed || version != _catalogVersion) return;
            _recent = _failure('catalog');
          }
          _notify();
        }(),
        () async {
          try {
            final page = await library.listTracks(PageRequest(limit: 20));
            if (_disposed || version != _catalogVersion) return;
            _localSelection = _loaded(
              page.items.where(
                (track) => track.sourceType == MusicSourceType.local,
              ),
            );
          } catch (_) {
            if (_disposed || version != _catalogVersion) return;
            _localSelection = _failure('selection');
          }
          _notify();
        }(),
      ]);
    });
  }

  void retryHistory() {
    if (_disposed) return;
    final subscriptionVersion = ++_historyVersion;
    final old = _historySubscription;
    _historySubscription = null;
    if (old != null) {
      unawaited(
        _track(() async {
          try {
            await old.cancel();
          } catch (_) {}
        }),
      );
    }
    _history = const LoadState.loading();
    _notify();
    try {
      final collection = this.collection;
      final library = this.library;
      if (collection == null || library == null) {
        _history = _failure('history');
        _notify();
        return;
      }
      var eventVersion = 0;
      _historySubscription = collection.watchHistory().listen(
        (entries) {
          final event = ++eventVersion;
          unawaited(
            _track(() async {
              try {
                final refs = entries
                    .take(20)
                    .map((entry) => entry.track)
                    .toSet();
                final tracks = await Future.wait(refs.map(library.getTrack));
                if (_disposed ||
                    subscriptionVersion != _historyVersion ||
                    event != eventVersion) {
                  return;
                }
                _history = _loaded(tracks.whereType<Track>());
              } catch (_) {
                if (_disposed ||
                    subscriptionVersion != _historyVersion ||
                    event != eventVersion) {
                  return;
                }
                _history = _failure('history');
              }
              _notify();
            }),
          );
        },
        onError: (Object _) {
          eventVersion++;
          if (_disposed || subscriptionVersion != _historyVersion) return;
          _history = _failure('history');
          _notify();
        },
      );
    } catch (_) {
      _history = _failure('history');
      _notify();
    }
  }

  void retrySources() {
    if (_disposed) return;
    final version = ++_sourceVersion;
    final old = _sourceSubscription;
    _sourceSubscription = null;
    if (old != null) {
      unawaited(
        _track(() async {
          try {
            await old.cancel();
          } catch (_) {}
        }),
      );
    }
    _sources = const LoadState.loading();
    _notify();
    try {
      final repository = sourceRepository;
      if (repository == null) {
        _sources = _failure('sources');
        _notify();
        return;
      }
      _sourceSubscription = repository.watchSources().listen(
        (items) {
          if (_disposed || version != _sourceVersion) return;
          _sources = _loaded(items.take(20));
          _notify();
        },
        onError: (Object _) {
          if (_disposed || version != _sourceVersion) return;
          _sources = _failure('sources');
          _notify();
        },
      );
    } catch (_) {
      _sources = _failure('sources');
      _notify();
    }
  }

  bool canPlay(Track track) =>
      !_disposed &&
      !_busy &&
      playback.isAvailable &&
      playback.state.phase != PlaybackPhase.loading &&
      _available(track);

  bool get canClearHistory =>
      !_disposed &&
      !_busy &&
      collection != null &&
      (_history.data?.isNotEmpty ?? false);

  /// Called only after the view has obtained explicit confirmation.
  Future<void> clearHistory() {
    if (!canClearHistory) return Future.value();
    _busy = true;
    _actionError = null;
    _notify();
    return _track(() async {
      try {
        await collection!.clearHistory();
      } catch (_) {
        _actionError = '历史未能清除，请重试。';
      } finally {
        _busy = false;
        _notify();
      }
    });
  }

  /// Preserve the user's queue; selecting an existing track reuses its entry.
  Future<void> play(Track track) {
    if (!canPlay(track)) return Future.value();
    _busy = true;
    _actionError = null;
    _notify();
    return _track(() async {
      try {
        var entryId = playback.state.queue.entries
            .where((entry) => entry.track == track.ref)
            .firstOrNull
            ?.id;
        if (entryId == null) {
          final now = _clock().toUtc();
          var candidate = 'home-${now.microsecondsSinceEpoch}-${_sequence++}';
          final ids = playback.state.queue.entries
              .map((entry) => entry.id)
              .toSet();
          while (ids.contains(candidate)) {
            candidate = 'home-${now.microsecondsSinceEpoch}-${_sequence++}';
          }
          await playback.addToEnd(
            QueueEntry(
              id: candidate,
              track: track.ref,
              position: playback.state.queue.entries.length,
              addedAt: now,
            ),
          );
          entryId = candidate;
        }
        if (!_disposed) await playback.playEntry(entryId);
        if (playback.state.failure != null) _actionError = '播放未完成，请重试或选择其他曲目。';
      } catch (_) {
        _actionError = '播放未完成，请重试或选择其他曲目。';
      } finally {
        _busy = false;
        _notify();
      }
    });
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
    super.dispose();
    _closeFuture = _drain();
    unawaited(_closeFuture!.catchError((Object _) {}));
  }

  Future<void> close() {
    dispose();
    return _closeFuture!;
  }

  Future<void> _drain() async {
    await Future.wait([
      if (_historySubscription != null) _historySubscription!.cancel(),
      if (_sourceSubscription != null) _sourceSubscription!.cancel(),
      ..._pending,
    ]);
  }
}

bool _available(Track track) =>
    track.availability == TrackAvailability.available;
LoadState<List<T>> _loaded<T>(Iterable<T> values) {
  final items = List<T>.unmodifiable(values);
  return items.isEmpty ? const LoadState.empty() : LoadState.data(items);
}

LoadState<List<T>> _failure<T>(String section) => LoadState.error(
  DomainFailure(
    code: DomainFailureCode.unknown,
    diagnosticId: 'home.$section',
    retryable: true,
  ),
);
