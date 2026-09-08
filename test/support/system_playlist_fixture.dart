import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/domain/models/track.dart';
import 'package:yymusic/features/playlists/common/system_playlist_controller.dart';

import 'catalog_detail_probe.dart';
import 'fake_audio_engine.dart';
import 'fake_domain_repositories.dart';
import 'fake_playback_dependencies.dart';
import 'library_graph_fixture.dart';
import 'playlist_content_probe.dart';
import 'system_playlist_probe.dart';

final class SystemPlaylistFixture {
  SystemPlaylistFixture({int count = 5}) {
    tracks = [
      for (var i = 0; i < count; i++)
        detailTrack(
          '${i == 1 ? 0 : i}',
          availability: i == 2
              ? TrackAvailability.localMissing
              : TrackAvailability.available,
        ),
    ];
    final refs = tracks.map((t) => t.ref).toSet().toList();
    collection = FakeCollectionRepository(
      clock: () => contentEpoch,
      contentTracks: [
        for (var i = 0; i < tracks.length; i++)
          if (i != 3) tracks[i],
      ],
      favorites: [
        for (final ref in refs)
          FavoriteEntry(track: ref, addedAt: contentEpoch),
      ],
      history: [
        for (var i = 0; i < refs.length && i < 20; i++)
          PlayHistoryEntry(
            id: 'h-$i',
            track: refs[i],
            startedAt: contentEpoch,
            lastPosition: Duration.zero,
          ),
      ],
      queue: QueueSnapshot(
        entries: [
          for (var i = 0; i < tracks.length; i++)
            QueueEntry(
              id: 'q-$i',
              track: tracks[i].ref,
              position: i,
              addedAt: contentEpoch,
            ),
        ],
        currentEntryId: count == 0 ? null : 'q-0',
        updatedAt: contentEpoch,
      ),
    );
    library = FakeLibraryRepository(tracks: tracks);
    graph = DependencyGraph(
      collection: collection,
      library: library,
      catalogBrowse: BrowseStub(tracks),
      audioEngine: engine,
      playbackSourceResolver: FakePlaybackSourceResolver(),
    );
  }
  late final List<Track> tracks;
  late final FakeCollectionRepository collection;
  late final FakeLibraryRepository library;
  late final DependencyGraph graph;
  final engine = FakeAudioEngine();
  bool _initialized = false;
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await graph.initialize();
  }

  Future<SystemPlaylistController> open(SystemPlaylistType type) async {
    await initialize();
    final c = graph.systemPlaylists.open(type)..start();
    await waitForSystem(c, () => c.isCurrent);
    return c;
  }

  Future<void> close() async {
    await graph.close();
    await collection.dispose();
  }
}
