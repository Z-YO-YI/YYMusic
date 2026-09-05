import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/domain/models/track.dart';

import 'fake_audio_engine.dart';
import 'fake_domain_repositories.dart';
import 'fake_playback_dependencies.dart';
import 'fake_search_repositories.dart';

class SearchGraphFixture {
  SearchGraphFixture({int count = 4}) {
    tracks = [
      for (var i = 0; i < count; i++)
        Track(
          id: 'search-$i',
          sourceId: 'local-test',
          sourceType: MusicSourceType.local,
          title: '夜航 ${i + 1}',
          artists: const ['测试艺术家'],
          duration: const Duration(seconds: 185),
          localPath: '/fixture-only/$i.wav',
        ),
      if (count > 0)
        Track(
          id: 'search-0',
          sourceId: 'rest-test',
          sourceType: MusicSourceType.rest,
          title: '夜航 · 在线引用',
          artists: const ['测试艺术家'],
          duration: const Duration(seconds: 185),
        ),
    ];
    repository = FakeSearchRepository(tracks: tracks);
    graph = DependencyGraph(
      audioEngine: engine,
      library: FakeLibraryRepository(tracks: tracks),
      collection: collection,
      catalogSearch: repository,
      searchHistory: history,
      musicSources: sources,
      playbackSourceResolver: FakePlaybackSourceResolver(),
    );
  }
  late final List<Track> tracks;
  late final FakeSearchRepository repository;
  final history = FakeSearchHistoryRepository();
  final engine = FakeAudioEngine();
  final collection = FakeCollectionRepository();
  final sources = FakeMusicSourceRepository();
  late final DependencyGraph graph;
  Future<void> disposeFakes() async {
    await collection.dispose();
    await sources.dispose();
    await history.dispose();
  }

  Future<void> close() async {
    await graph.close();
    await disposeFakes();
  }
}
