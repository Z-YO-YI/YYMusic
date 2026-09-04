import '../app/app_data_services.dart';
import '../domain/models/collection_models.dart';
import '../domain/models/lyrics.dart';
import '../domain/models/music_source.dart';
import '../domain/models/pagination.dart';
import '../domain/models/track.dart';

/// Deterministic sample data derived from the audited HTML reference.
///
/// It is only seeded into a fresh ephemeral database by `main_dev.dart`.
/// The reserved `.invalid` source stays disabled and carries no credential,
/// playable URL, local path or fake connectivity result.
final class YYDevFixture {
  YYDevFixture() {
    source = MusicSourceConfig(
      id: sourceId,
      name: 'Design Fixture（已禁用）',
      type: MusicSourceType.rest,
      baseUrl: Uri.parse('https://fixture.invalid'),
      authType: MusicSourceAuthType.none,
      enabled: false,
      status: MusicSourceStatus.disabled,
    );
    tracks = List.unmodifiable([
      _track(
        id: 'quiet_orbit',
        title: 'A Quiet Orbit',
        artist: 'Luna Harbor',
        albumId: 'the_small_hours',
        album: 'The Small Hours',
        seconds: 228,
      ),
      _track(
        id: 'slow_lines',
        title: 'Slow Lines',
        artist: 'Mira Coast',
        albumId: 'blue_hour',
        album: 'Blue Hour',
        seconds: 252,
      ),
      _track(
        id: 'warm_static',
        title: 'Warm Static',
        artist: 'Field Notes',
        albumId: 'noon_geometry',
        album: 'Noon Geometry',
        seconds: 176,
      ),
      _track(
        id: 'current_no_4',
        title: 'Current No. 4',
        artist: 'Sora Vale',
        albumId: 'deep_current',
        album: 'Deep Current',
        seconds: 303,
      ),
    ]);
    playlists = List.unmodifiable([
      Playlist(
        id: nightPlaylistId,
        name: '夜间聆听',
        description: '安静、低干扰的播放列表 · Dev Fixture',
        createdAt: fixtureTime,
        updatedAt: fixtureTime,
      ),
      Playlist(
        id: focusPlaylistId,
        name: '专注时刻',
        description: '工作与阅读背景音乐 · Dev Fixture',
        createdAt: fixtureTime,
        updatedAt: fixtureTime,
      ),
    ]);
    playlistEntries = Map.unmodifiable({
      nightPlaylistId: List<PlaylistEntry>.unmodifiable([
        _playlistEntry(nightPlaylistId, tracks[0], 0),
        _playlistEntry(nightPlaylistId, tracks[1], 1),
      ]),
      focusPlaylistId: List<PlaylistEntry>.unmodifiable([
        _playlistEntry(focusPlaylistId, tracks[2], 0),
        _playlistEntry(focusPlaylistId, tracks[3], 1),
      ]),
    });
    queue = QueueSnapshot(
      entries: [
        _queueEntry(tracks[1], 0),
        _queueEntry(tracks[2], 1),
        _queueEntry(tracks[3], 2),
      ],
      currentEntryId: 'fixture_queue_0',
      updatedAt: fixtureTime,
    );
    lyrics = _quietOrbitLyrics(tracks[0].ref);
  }

  static const String sourceId = 'dev_fixture_source';
  static const String nightPlaylistId = 'dev_fixture_night';
  static const String focusPlaylistId = 'dev_fixture_focus';
  static final DateTime fixtureTime = DateTime.utc(2026, 1, 1, 12);

  late final MusicSourceConfig source;
  late final List<Track> tracks;
  late final List<Playlist> playlists;
  late final Map<String, List<PlaylistEntry>> playlistEntries;
  late final QueueSnapshot queue;
  late final LyricsDocument lyrics;

  Track _track({
    required String id,
    required String title,
    required String artist,
    required String albumId,
    required String album,
    required int seconds,
  }) => Track(
    id: id,
    sourceId: sourceId,
    sourceType: MusicSourceType.rest,
    title: title,
    artists: [artist],
    duration: Duration(seconds: seconds),
    albumId: albumId,
    albumTitle: album,
    availability: TrackAvailability.sourceDisabled,
    metadata: const {'fixture': 'audited-html-reference'},
  );

  PlaylistEntry _playlistEntry(String playlistId, Track track, int position) =>
      PlaylistEntry(
        id: '${playlistId}_entry_$position',
        playlistId: playlistId,
        track: track.ref,
        position: position,
        addedAt: fixtureTime,
      );

  QueueEntry _queueEntry(Track track, int position) => QueueEntry(
    id: 'fixture_queue_$position',
    track: track.ref,
    position: position,
    addedAt: fixtureTime,
  );
}

final class DevFixtureSeeder {
  const DevFixtureSeeder(this.fixture);

  final YYDevFixture fixture;

  Future<void> seedEmpty(AppDataServices services) async {
    await _requireEmpty(services);
    await services.musicSources.saveSource(fixture.source);
    await services.library.upsertTracks(fixture.tracks);
    for (final playlist in fixture.playlists) {
      await services.collection.savePlaylist(playlist);
      await services.collection.replacePlaylistEntries(
        playlist.id,
        fixture.playlistEntries[playlist.id]!,
      );
    }
    await services.collection.saveQueue(fixture.queue);
    await services.lyrics.saveLyrics(fixture.lyrics);
  }

  Future<void> _requireEmpty(AppDataServices services) async {
    final tracks = await services.library.listTracks(PageRequest(limit: 1));
    final playlists = await services.collection.watchPlaylists().first;
    final queue = await services.collection.loadQueue();
    final sources = await services.musicSources.watchSources().first;
    if (tracks.items.isNotEmpty ||
        playlists.isNotEmpty ||
        queue.entries.isNotEmpty ||
        sources.isNotEmpty) {
      throw StateError('Dev Fixture requires a fresh ephemeral data store');
    }
  }
}

LyricsDocument _quietOrbitLyrics(TrackRef track) {
  const rows = <({int start, String text, String translation})>[
    (start: 0, text: '♪', translation: '前奏'),
    (start: 12, text: 'Let the room grow quiet', translation: '让房间慢慢安静下来'),
    (start: 31, text: 'We move in a smaller orbit', translation: '我们沿着更小的轨道前行'),
    (
      start: 52,
      text: 'Every light becomes a distance',
      translation: '每一道光都化成了距离',
    ),
    (
      start: 75,
      text: 'Every distance finds a home',
      translation: '而每段距离终会找到归处',
    ),
    (
      start: 99,
      text: 'Stay until the morning opens',
      translation: '留下吧，直到清晨开启',
    ),
    (
      start: 126,
      text: 'Keep the silence close beside us',
      translation: '让寂静贴近我们身旁',
    ),
    (start: 151, text: 'Nothing here is asking why', translation: '这里没有什么追问缘由'),
    (
      start: 178,
      text: 'All the stars return in slow time',
      translation: '所有星光缓慢归来',
    ),
    (start: 205, text: 'In our quiet orbit tonight', translation: '回到今夜安静的轨道'),
  ];
  return LyricsDocument(
    track: track,
    kind: LyricsKind.synchronized,
    lines: [
      for (var index = 0; index < rows.length; index++)
        LyricsLine(
          start: Duration(seconds: rows[index].start),
          end: Duration(
            seconds: index + 1 < rows.length ? rows[index + 1].start : 228,
          ),
          text: rows[index].text,
          translation: rows[index].translation,
        ),
    ],
    language: 'en',
    translationLanguage: 'zh-Hans',
  );
}
