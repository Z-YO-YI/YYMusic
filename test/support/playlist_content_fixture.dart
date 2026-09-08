import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/domain/models/track.dart';

import 'catalog_detail_probe.dart';
import 'fake_audio_engine.dart';
import 'fake_domain_repositories.dart';
import 'fake_playback_dependencies.dart';
import 'library_graph_fixture.dart';
import 'playlist_content_probe.dart';

final class PlaylistContentFixture {
  PlaylistContentFixture({int count = 25, this.id = 'custom'}) {
    tracks = [
      for (var i = 0; i < count; i++)
        detailTrack(
          '${i == 1 ? 0 : i}',
          availability: i == 2
              ? TrackAvailability.localMissing
              : TrackAvailability.available,
        ),
    ];
    collection = FakeCollectionRepository(
      contentTracks: [
        for (var i = 0; i < tracks.length; i++)
          if (i != 3) tracks[i],
      ],
      clock: () => contentEpoch,
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
  final String id;
  late final List<Track> tracks;
  late final FakeCollectionRepository collection;
  late final FakeLibraryRepository library;
  late final DependencyGraph graph;
  final engine = FakeAudioEngine();
  bool _initialized = false;
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await collection.createPlaylist(contentPlaylist(id, name: '沿途的声音'));
    await collection.replacePlaylistEntries(id, [
      for (var i = 0; i < tracks.length; i++)
        contentItem(id, 'e-$i', i, tracks[i]).entry,
    ]);
    await graph.initialize();
  }

  Future<void> close() async {
    await graph.close();
    await collection.dispose();
  }
}
