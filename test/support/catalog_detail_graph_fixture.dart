import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/domain/models/library_entities.dart';
import 'package:yymusic/domain/models/music_source.dart';
import 'package:yymusic/domain/models/track.dart';

import 'catalog_detail_probe.dart';
import 'fake_audio_engine.dart';
import 'fake_domain_repositories.dart';
import 'fake_playback_dependencies.dart';

final class CatalogDetailGraphFixture {
  CatalogDetailGraphFixture({int trackCount = 45, int albumCount = 8}) {
    repository.trackData.addAll([
      for (var i = 0; i < trackCount; i++)
        detailTrack(
          i.toString().padLeft(3, '0'),
          availability: i == 2
              ? TrackAvailability.localMissing
              : TrackAvailability.available,
        ),
    ]);
    artist = Artist(
      id: 'artist-a',
      sourceId: 'source-a',
      name: '测试曲目艺人',
      albumCount: albumCount,
      trackCount: trackCount,
    );
    repository.artistData[artist.ref] = artist;
    album = Album(
      id: 'album-a',
      sourceId: 'source-a',
      title: '沿途的声音',
      artists: [ArtistCredit(id: artist.id, name: artist.name)],
      year: 2026,
      trackCount: trackCount,
    );
    repository.albumData[album.ref] = album;
    for (var i = 1; i < albumCount; i++) {
      final extra = Album(
        id: 'album-$i',
        sourceId: 'source-a',
        title: '目录专辑 $i',
        artists: album.artists,
        year: 2025,
        trackCount: 0,
      );
      repository.albumData[extra.ref] = extra;
    }
    graph = DependencyGraph(
      catalogBrowse: repository,
      library: FakeLibraryRepository(tracks: repository.trackData),
      collection: collection,
      musicSources: sources,
      audioEngine: engine,
      playbackSourceResolver: FakePlaybackSourceResolver(),
    );
  }
  final repository = CatalogDetailProbe();
  final collection = FakeCollectionRepository();
  final sources = FakeMusicSourceRepository();
  final engine = FakeAudioEngine();
  late final DependencyGraph graph;
  late final Album album;
  late final Artist artist;
  Future<void> initialize() async {
    await sources.saveSource(
      MusicSourceConfig(
        id: 'source-a',
        name: '我的本地音乐',
        type: MusicSourceType.local,
        authType: MusicSourceAuthType.system,
      ),
    );
    await graph.initialize();
  }

  Future<void> disposeFakes() async {
    await collection.dispose();
    await sources.dispose();
  }

  Future<void> close() async {
    await graph.close();
    await disposeFakes();
  }
}
