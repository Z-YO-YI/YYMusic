import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/domain/models/music_source.dart';
import 'package:yymusic/domain/models/track.dart';

import 'fake_audio_engine.dart';
import 'fake_domain_repositories.dart';
import 'fake_playback_dependencies.dart';

/// Only deterministic test labels; production Home never imports fixtures.
final class HomeGraphFixture {
  HomeGraphFixture({bool empty = false}) {
    tracks = empty
        ? []
        : [
            for (var i = 0; i < 8; i++)
              Track(
                id: 'home-fixture-$i',
                sourceId: 'local-test',
                sourceType: MusicSourceType.local,
                title: i == 0 ? '沿着海岸慢慢走' : '曲库测试 ${i + 1}',
                artists: const ['测试艺人'],
                duration: Duration(seconds: 188 + i),
                localPath: '/fixture-only/$i.wav',
                availability: i == 7
                    ? TrackAvailability.localMissing
                    : TrackAvailability.available,
              ),
          ];
    library = FakeLibraryRepository(tracks: tracks);
    collection = FakeCollectionRepository(
      history: [
        for (final track in tracks.take(6))
          PlayHistoryEntry(
            id: track.id,
            track: track.ref,
            startedAt: DateTime.utc(2026, 9, 5),
            lastPosition: Duration.zero,
          ),
      ],
    );
    graph = DependencyGraph(
      library: library,
      collection: collection,
      musicSources: sources,
      audioEngine: engine,
      playbackSourceResolver: FakePlaybackSourceResolver(),
    );
  }
  late final List<Track> tracks;
  late final FakeLibraryRepository library;
  late final FakeCollectionRepository collection;
  final sources = FakeMusicSourceRepository();
  final engine = FakeAudioEngine();
  late final DependencyGraph graph;
  Future<void> initialize({bool source = true}) async {
    if (source) {
      await sources.saveSource(
        MusicSourceConfig(
          id: 'home-source',
          name: '我的音乐源',
          type: MusicSourceType.rest,
          baseUrl: Uri.parse('https://private-endpoint.invalid'),
          credentialRef: 'opaque-reference-not-for-ui',
          authType: MusicSourceAuthType.bearer,
          enabled: true,
          status: MusicSourceStatus.unauthorized,
        ),
      );
    }
    await graph.initialize();
  }

  Future<void> disposeFakes() async {
    await collection.dispose();
    await sources.dispose();
  }
}
