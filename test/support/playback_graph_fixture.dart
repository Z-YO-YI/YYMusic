import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/domain/models/software_license.dart';
import 'package:yymusic/domain/models/track.dart';
import 'package:yymusic/domain/repositories/license_repository.dart';

import 'fake_audio_engine.dart';
import 'fake_domain_repositories.dart';
import 'fake_playback_dependencies.dart';

final class PlaybackGraphFixture {
  PlaybackGraphFixture() {
    graph = DependencyGraph(
      audioEngine: engine,
      library: FakeLibraryRepository(tracks: tracks),
      playbackSourceResolver: FakePlaybackSourceResolver(),
      licenses: const _EmptyLicenses(),
    );
  }
  final engine = FakeAudioEngine();
  late final DependencyGraph graph;
  final tracks = [
    for (final id in ['a', 'b'])
      Track(
        id: id,
        sourceId: 'test-only',
        sourceType: MusicSourceType.rest,
        title: '测试曲目 $id · Long title for responsive playback',
        artists: const ['测试艺人 / Artist'],
        duration: const Duration(minutes: 3),
      ),
  ];

  Future<void> queue() => graph.queue.replace([
    for (final (index, track) in tracks.indexed)
      QueueEntry(
        id: track.id,
        track: track.ref,
        position: index,
        addedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      ),
  ], currentEntryId: 'a');
}

final class _EmptyLicenses implements LicenseRepository {
  const _EmptyLicenses();
  @override
  Future<List<SoftwareLicense>> load() async => const [];
}
