import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/playback/playback_controller.dart';
import 'package:yymusic/playback/queue_controller.dart';

import 'fake_audio_engine.dart';
import 'fake_domain_repositories.dart';
import 'fake_playback_dependencies.dart';

final class QueueInsertFixture {
  final engine = FakeAudioEngine();
  final collection = FakeCollectionRepository();
  final library = FakeLibraryRepository(tracks: [playbackFixtureTrack]);
  late final player = PlaybackController(
    engine,
    collection: collection,
    library: library,
    sourceResolver: FakePlaybackSourceResolver(),
    randomIndex: (_) => 0,
  );
  late final queue = QueueController(player);
  QueueEntry entry(String id) => QueueEntry(
    id: id,
    track: playbackFixtureTrack.ref,
    position: 99,
    addedAt: DateTime.utc(2026, 9, 12),
  );
  Future<void> initialize() async {
    await player.initialize();
    await queue.replace([
      entry('a'),
      entry('b'),
      entry('c'),
    ], currentEntryId: 'b');
    await queue.play('b');
    engine.calls.clear();
    collection.queueWrites.clear();
  }

  Future<void> close() async {
    await queue.close();
    await player.close();
    await engine.dispose();
    await collection.dispose();
    await library.dispose();
  }
}
