import 'dart:async';

import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/domain/models/library_entities.dart';
import 'package:yymusic/domain/models/lyrics.dart';
import 'package:yymusic/domain/models/music_source.dart';
import 'package:yymusic/domain/models/pagination.dart';
import 'package:yymusic/domain/models/sensitive_credential.dart';
import 'package:yymusic/domain/models/track.dart';
import 'package:yymusic/domain/repositories/collection_repository.dart';
import 'package:yymusic/domain/repositories/library_repository.dart';
import 'package:yymusic/domain/repositories/lyrics_repository.dart';
import 'package:yymusic/domain/repositories/music_source_repository.dart';
import 'package:yymusic/platform/contracts/secure_credential_gateway.dart';

final class FakeLibraryRepository implements LibraryRepository {
  FakeLibraryRepository({
    Iterable<Track> tracks = const [],
    Iterable<Album> albums = const [],
    Iterable<Artist> artists = const [],
  }) : _albums = List.of(albums),
       _artists = List.of(artists) {
    for (final track in tracks) {
      _tracks[_key(track.ref)] = track;
    }
  }

  final Map<String, Track> _tracks = {};
  final List<Album> _albums;
  final List<Artist> _artists;
  final _trackChanges = StreamController<List<Track>>.broadcast(sync: true);
  int initializeCount = 0;
  int disposeCount = 0;

  List<Track> get trackSnapshot => List.unmodifiable(_sortedTracks());

  @override
  Future<void> initialize() async => initializeCount++;

  @override
  Stream<List<Track>> watchTracks() async* {
    yield trackSnapshot;
    yield* _trackChanges.stream;
  }

  @override
  Future<PageResult<Track>> listTracks(PageRequest request) async =>
      _page(_sortedTracks(), request);

  @override
  Future<PageResult<Album>> listAlbums(PageRequest request) async =>
      _page(_albums, request);

  @override
  Future<PageResult<Artist>> listArtists(PageRequest request) async =>
      _page(_artists, request);

  @override
  Future<Track?> getTrack(TrackRef reference) async => _tracks[_key(reference)];

  @override
  Future<void> upsertTracks(Iterable<Track> tracks) async {
    for (final track in tracks) {
      _tracks[_key(track.ref)] = track;
    }
    _trackChanges.add(trackSnapshot);
  }

  @override
  Future<void> setAvailability(
    TrackRef reference,
    TrackAvailability availability,
  ) async {
    final track = _tracks[_key(reference)];
    if (track == null) throw StateError('Unknown fake track reference');
    _tracks[_key(reference)] = track.withAvailability(availability);
    _trackChanges.add(trackSnapshot);
  }

  @override
  Future<void> dispose() async {
    disposeCount++;
    if (!_trackChanges.isClosed) await _trackChanges.close();
  }

  List<Track> _sortedTracks() => _tracks.values.toList()
    ..sort((a, b) {
      final source = a.sourceId.compareTo(b.sourceId);
      return source == 0 ? a.id.compareTo(b.id) : source;
    });
}

final class FakeCollectionRepository implements CollectionRepository {
  FakeCollectionRepository({
    Iterable<Playlist> playlists = const [],
    QueueSnapshot? queue,
    Iterable<FavoriteEntry> favorites = const [],
    Iterable<PlayHistoryEntry> history = const [],
  }) : _playlists = List.of(playlists),
       _queue =
           queue ??
           QueueSnapshot(
             entries: const [],
             updatedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
           ),
       _favorites = List.of(favorites),
       _history = List.of(history);

  final Map<String, List<PlaylistEntry>> _entries = {};
  final _playlistChanges = StreamController<List<Playlist>>.broadcast(
    sync: true,
  );
  final _queueChanges = StreamController<QueueSnapshot>.broadcast(sync: true);
  final _favoriteChanges = StreamController<List<FavoriteEntry>>.broadcast(
    sync: true,
  );
  final _historyChanges = StreamController<List<PlayHistoryEntry>>.broadcast(
    sync: true,
  );
  List<Playlist> _playlists;
  QueueSnapshot _queue;
  List<FavoriteEntry> _favorites;
  List<PlayHistoryEntry> _history;

  @override
  Stream<List<Playlist>> watchPlaylists() async* {
    yield List.unmodifiable(_playlists);
    yield* _playlistChanges.stream;
  }

  @override
  Future<Playlist?> getPlaylist(String id) async {
    for (final playlist in _playlists) {
      if (playlist.id == id) return playlist;
    }
    return null;
  }

  @override
  Future<void> savePlaylist(Playlist playlist) async {
    _playlists = [
      ..._playlists.where((item) => item.id != playlist.id),
      playlist,
    ];
    _playlistChanges.add(List.unmodifiable(_playlists));
  }

  @override
  Future<void> deletePlaylist(String id) async {
    _playlists = _playlists.where((item) => item.id != id).toList();
    _entries.remove(id);
    _playlistChanges.add(List.unmodifiable(_playlists));
  }

  @override
  Future<List<PlaylistEntry>> getPlaylistEntries(String playlistId) async =>
      List.unmodifiable(_entries[playlistId] ?? const []);

  @override
  Future<void> replacePlaylistEntries(
    String playlistId,
    Iterable<PlaylistEntry> entries,
  ) async {
    final copy = List<PlaylistEntry>.unmodifiable(entries);
    if (copy.any((entry) => entry.playlistId != playlistId)) {
      throw ArgumentError('Fake playlist entries belong to another playlist');
    }
    _entries[playlistId] = copy;
  }

  @override
  Stream<QueueSnapshot> watchQueue() async* {
    yield _queue;
    yield* _queueChanges.stream;
  }

  @override
  Future<QueueSnapshot> loadQueue() async => _queue;

  @override
  Future<void> saveQueue(QueueSnapshot snapshot) async {
    _queue = snapshot;
    _queueChanges.add(snapshot);
  }

  @override
  Stream<List<FavoriteEntry>> watchFavorites() async* {
    yield List.unmodifiable(_favorites);
    yield* _favoriteChanges.stream;
  }

  @override
  Future<void> setFavorite(TrackRef track, {required bool favorite}) async {
    _favorites = _favorites.where((entry) => entry.track != track).toList();
    if (favorite) {
      _favorites.add(
        FavoriteEntry(
          track: track,
          addedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        ),
      );
    }
    _favoriteChanges.add(List.unmodifiable(_favorites));
  }

  @override
  Stream<List<PlayHistoryEntry>> watchHistory() async* {
    yield List.unmodifiable(_history);
    yield* _historyChanges.stream;
  }

  @override
  Future<void> recordHistory(PlayHistoryEntry entry) async {
    _history = [entry, ..._history.where((item) => item.id != entry.id)];
    _historyChanges.add(List.unmodifiable(_history));
  }

  @override
  Future<void> clearHistory() async {
    _history = [];
    _historyChanges.add(const []);
  }

  Future<void> dispose() async {
    await Future.wait([
      _playlistChanges.close(),
      _queueChanges.close(),
      _favoriteChanges.close(),
      _historyChanges.close(),
    ]);
  }
}

final class FakeLyricsRepository implements LyricsRepository {
  final Map<TrackRef, LyricsDocument> _documents = {};

  @override
  Future<LyricsDocument?> getLyrics(TrackRef track) async => _documents[track];

  @override
  Future<void> saveLyrics(LyricsDocument document) async {
    _documents[document.track] = document;
  }

  @override
  Future<void> removeLyrics(TrackRef track) async => _documents.remove(track);
}

final class FakeMusicSourceRepository implements MusicSourceRepository {
  final Map<String, MusicSourceConfig> _sources = {};
  final _changes = StreamController<List<MusicSourceConfig>>.broadcast(
    sync: true,
  );

  @override
  Stream<List<MusicSourceConfig>> watchSources() async* {
    yield _snapshot;
    yield* _changes.stream;
  }

  @override
  Future<MusicSourceConfig?> getSource(String id) async => _sources[id];

  @override
  Future<void> saveSource(MusicSourceConfig source) async {
    _sources[source.id] = source;
    _changes.add(_snapshot);
  }

  @override
  Future<void> deleteSource(String id) async {
    _sources.remove(id);
    _changes.add(_snapshot);
  }

  List<MusicSourceConfig> get _snapshot {
    final result = _sources.values.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    return List.unmodifiable(result);
  }

  Future<void> dispose() => _changes.close();
}

final class FakeSecureCredentialGateway implements SecureCredentialGateway {
  final Map<String, SensitiveCredential> _credentials = {};
  var _nextId = 1;

  @override
  Future<String> saveCredential(SensitiveCredential credential) async {
    final reference = 'fake-credential-${_nextId++}';
    _credentials[reference] = credential;
    return reference;
  }

  @override
  Future<SensitiveCredential?> readCredential(String reference) async =>
      _credentials[reference];

  @override
  Future<void> deleteCredential(String reference) async {
    _credentials.remove(reference);
  }
}

PageResult<T> _page<T>(List<T> values, PageRequest request) {
  final start = request.offset.clamp(0, values.length);
  final end = (start + request.limit).clamp(start, values.length);
  return PageResult(
    items: values.sublist(start, end),
    hasMore: end < values.length,
  );
}

String _key(TrackRef reference) =>
    '${reference.sourceType.name}\u0000${reference.sourceId}\u0000${reference.trackId}';
