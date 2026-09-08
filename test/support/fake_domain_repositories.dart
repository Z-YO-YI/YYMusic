import 'dart:async';

import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/domain/models/domain_failure.dart';
import 'package:yymusic/domain/models/domain_validation.dart';
import 'package:yymusic/domain/models/library_entities.dart';
import 'package:yymusic/domain/models/lyrics.dart';
import 'package:yymusic/domain/models/music_source.dart';
import 'package:yymusic/domain/models/pagination.dart';
import 'package:yymusic/domain/models/playlist_name.dart';
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
    DateTime Function()? clock,
  }) : _albums = List.of(albums),
       _artists = List.of(artists),
       _clock = clock ?? DateTime.now {
    for (final track in tracks) {
      _tracks[_key(track.ref)] = track;
      _addedAt[_key(track.ref)] = _clock().toUtc();
    }
  }

  final Map<String, Track> _tracks = {};
  final List<Album> _albums;
  final List<Artist> _artists;
  final DateTime Function() _clock;
  final Map<String, DateTime> _addedAt = {};
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
  Future<PageResult<Track>> listRecentlyAdded(
    PageRequest request, {
    required DateTime since,
    required DateTime until,
  }) async {
    if (since.isAfter(until)) {
      throw ArgumentError('Invalid catalog time window');
    }
    final tracks =
        _tracks.values.where((track) {
          final added = _addedAt[_key(track.ref)];
          return added != null &&
              !added.isBefore(since) &&
              !added.isAfter(until);
        }).toList()..sort((a, b) {
          final date = _addedAt[_key(b.ref)]!.compareTo(_addedAt[_key(a.ref)]!);
          if (date != 0) return date;
          final type = a.sourceType.name.compareTo(b.sourceType.name);
          if (type != 0) return type;
          final source = a.sourceId.compareTo(b.sourceId);
          return source == 0 ? a.id.compareTo(b.id) : source;
        });
    return _page(tracks, request);
  }

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
      _addedAt.putIfAbsent(_key(track.ref), () => _clock().toUtc());
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
    DateTime Function()? clock,
  }) : _playlists = List.of(playlists),
       _playlistClock = clock ?? DateTime.now,
       _queue =
           queue ??
           QueueSnapshot(
             entries: const [],
             updatedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
           ),
       _favorites = List.of(favorites),
       _history = List.of(history);

  final Map<String, List<PlaylistEntry>> _entries = {};
  final DateTime Function() _playlistClock;
  Future<void> Function(String operation, String id)? onPlaylistMutation;
  final playlistMutationCalls = <String>[];
  int playlistWatchCount = 0, playlistReadCount = 0;
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
  Future<void>? favoriteGate;
  int favoriteWriteCount = 0;
  int favoriteWatchCount = 0;
  Stream<List<FavoriteEntry>> Function()? favoriteReader;
  int disposeCount = 0;

  @override
  Stream<List<Playlist>> watchPlaylists() async* {
    playlistWatchCount++;
    yield List.unmodifiable(_playlists);
    yield* _playlistChanges.stream;
  }

  @override
  Future<Playlist?> getPlaylist(String id) async {
    playlistReadCount++;
    for (final playlist in _playlists) {
      if (playlist.id == id) return playlist;
    }
    return null;
  }

  @override
  Future<void> createPlaylist(Playlist playlist) async {
    playlistMutationCalls.add('create');
    await onPlaylistMutation?.call('create', playlist.id);
    final name = PlaylistName.normalize(playlist.name);
    if (playlist.isSystem) throw _playlistForbidden('playlist-system-create');
    if (_playlists.any((item) => item.id == playlist.id)) {
      throw _playlistForbidden('playlist-id-exists');
    }
    await savePlaylist(
      Playlist(
        id: playlist.id,
        name: name,
        description: playlist.description,
        createdAt: playlist.createdAt,
        updatedAt: playlist.updatedAt,
      ),
    );
  }

  @override
  Future<void> renamePlaylist(String id, String name) async {
    playlistMutationCalls.add('rename');
    await onPlaylistMutation?.call('rename', id);
    final normalized = PlaylistName.normalize(name);
    final existing = _playlists.where((item) => item.id == id).firstOrNull;
    if (existing == null) {
      throw DomainFailure(
        code: DomainFailureCode.notFound,
        diagnosticId: 'collection-repository.playlist-not-found',
      );
    }
    if (existing.isSystem) throw _playlistForbidden('playlist-system-rename');
    final now = _playlistClock().toUtc();
    await savePlaylist(
      Playlist(
        id: id,
        name: normalized,
        description: existing.description,
        createdAt: existing.createdAt,
        updatedAt: now.isBefore(existing.updatedAt) ? existing.updatedAt : now,
      ),
    );
  }

  DomainFailure _playlistForbidden(String operation) => DomainFailure(
    code: DomainFailureCode.forbidden,
    diagnosticId: 'collection-repository.$operation',
  );

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
    playlistMutationCalls.add('delete');
    await onPlaylistMutation?.call('delete', id);
    if (_playlists.any((item) => item.id == id && item.isSystem)) {
      throw _playlistForbidden('playlist-system-delete');
    }
    _playlists = _playlists.where((item) => item.id != id).toList();
    _entries.remove(id);
    _playlistChanges.add(List.unmodifiable(_playlists));
  }

  @override
  Future<List<PlaylistEntry>> getPlaylistEntries(String playlistId) async =>
      List.unmodifiable(_entries[playlistId] ?? const []);

  @override
  Future<void> appendPlaylistEntry(
    String playlistId,
    PlaylistEntryDraft entry,
  ) => _editEntries('append-entry', playlistId, (entries) {
    if (_entries.values.expand((list) => list).any((e) => e.id == entry.id)) {
      throw _playlistForbidden('playlist-entry-id-exists');
    }
    entries.add(
      PlaylistEntry(
        id: entry.id,
        playlistId: playlistId,
        track: entry.track,
        position: entries.length,
        addedAt: entry.addedAt,
      ),
    );
    return true;
  });

  @override
  Future<void> removePlaylistEntry(String playlistId, String entryId) {
    DomainValidation.identifier(playlistId, 'playlistId');
    DomainValidation.identifier(entryId, 'entryId');
    return _editEntries('remove-entry', playlistId, (entries) {
      final entry = _findScopedEntry(playlistId, entryId);
      if (entry == null) return false;
      entries.removeWhere((e) => e.id == entryId);
      return true;
    });
  }

  @override
  Future<void> movePlaylistEntry(
    String playlistId,
    String entryId, {
    String? beforeEntryId,
  }) {
    DomainValidation.identifier(playlistId, 'playlistId');
    DomainValidation.identifier(entryId, 'entryId');
    if (beforeEntryId != null) {
      DomainValidation.identifier(beforeEntryId, 'beforeEntryId');
    }
    return _editEntries('move-entry', playlistId, (entries) {
      final entry = _findScopedEntry(playlistId, entryId);
      if (entry == null) throw _entryNotFound();
      final anchor = beforeEntryId == null
          ? null
          : _findScopedEntry(playlistId, beforeEntryId);
      if (beforeEntryId != null && anchor == null) throw _entryNotFound();
      if (anchor?.id == entryId) return false;
      final from = entry.position;
      final to = anchor == null
          ? entries.length - 1
          : anchor.position > from
          ? anchor.position - 1
          : anchor.position;
      if (from == to) return false;
      entries.insert(to, entries.removeAt(from));
      return true;
    });
  }

  PlaylistEntry? _findScopedEntry(String playlistId, String entryId) {
    final entry = _entries.values
        .expand((list) => list)
        .where((e) => e.id == entryId)
        .firstOrNull;
    if (entry != null && entry.playlistId != playlistId) throw _entryNotFound();
    return entry;
  }

  DomainFailure _entryNotFound() => DomainFailure(
    code: DomainFailureCode.notFound,
    diagnosticId: 'collection-repository.playlist-entry-not-found',
  );

  Future<void> _editEntries(
    String operation,
    String playlistId,
    bool Function(List<PlaylistEntry>) edit,
  ) async {
    DomainValidation.identifier(playlistId, 'playlistId');
    playlistMutationCalls.add(operation);
    await onPlaylistMutation?.call(operation, playlistId);
    final playlist = _playlists.where((p) => p.id == playlistId).firstOrNull;
    if (playlist == null) {
      throw DomainFailure(
        code: DomainFailureCode.notFound,
        diagnosticId: 'collection-repository.playlist-not-found',
      );
    }
    if (playlist.isSystem) throw _playlistForbidden('playlist-system-entries');
    final entries = List<PlaylistEntry>.of(_entries[playlistId] ?? const []);
    for (var i = 0; i < entries.length; i++) {
      if (entries[i].position != i) {
        throw DomainFailure(
          code: DomainFailureCode.databaseCorrupted,
          diagnosticId: 'collection-repository.playlist-entry-positions',
        );
      }
    }
    if (!edit(entries)) return;
    final now = _playlistClock().toUtc();
    final updated = Playlist(
      id: playlist.id,
      name: playlist.name,
      description: playlist.description,
      createdAt: playlist.createdAt,
      updatedAt: now.isBefore(playlist.updatedAt) ? playlist.updatedAt : now,
    );
    _entries[playlistId] = [
      for (var i = 0; i < entries.length; i++)
        PlaylistEntry(
          id: entries[i].id,
          playlistId: playlistId,
          track: entries[i].track,
          position: i,
          addedAt: entries[i].addedAt,
        ),
    ];
    await savePlaylist(updated);
  }

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
  Stream<List<FavoriteEntry>> watchFavorites() {
    favoriteWatchCount++;
    return favoriteReader?.call() ?? _watchFavoriteChanges();
  }

  Stream<List<FavoriteEntry>> _watchFavoriteChanges() async* {
    yield List.unmodifiable(_favorites);
    yield* _favoriteChanges.stream;
  }

  @override
  Future<void> setFavorite(TrackRef track, {required bool favorite}) async {
    if (favoriteGate case final gate?) await gate;
    favoriteWriteCount++;
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
    disposeCount++;
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
  Future<MusicSourceConfig?> Function(String)? sourceReader;
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
  Future<MusicSourceConfig?> getSource(String id) async =>
      sourceReader == null ? _sources[id] : sourceReader!(id);

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
