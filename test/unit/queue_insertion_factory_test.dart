import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/playback/playback_controller.dart';
import 'package:yymusic/playback/queue_controller.dart';

import '../support/fake_audio_engine.dart';
import '../support/fake_domain_repositories.dart';
import '../support/fake_playback_dependencies.dart';

void main() {
  final now = DateTime.utc(2026, 9, 12);
  late PlaybackController player;
  late QueueController queue;
  late FakeCollectionRepository collection;
  late FakeAudioEngine engine;
  setUp(() async {
    engine = FakeAudioEngine();
    collection = FakeCollectionRepository();
    player = PlaybackController(engine, collection: collection);
    queue = QueueController(player, clock: () => now);
    await player.initialize();
  });
  tearDown(() async {
    await queue.close();
    await player.close();
    await engine.dispose();
    await collection.dispose();
  });
  test(
    'same clock prepares unique immutable entries without saving or playing',
    () {
      final snapshot = queue.state, track = playbackFixtureTrack.ref;
      final first = queue.prepareInsertion(snapshot, track, next: false)!;
      final second = queue.prepareInsertion(snapshot, track, next: true)!;
      final a = first.apply(updatedAt: now)!.entries.single;
      final b = second.apply(updatedAt: now)!.entries.single;
      expect(a.id, isNot(b.id));
      expect(a.track, same(track));
      expect(a.addedAt, now);
      expect(a.position, 0);
      expect(second.nextEntryId, b.id);
      expect(first.expected, same(snapshot));
      expect(collection.queueWrites, isEmpty);
      expect(engine.calls, isEmpty);
    },
  );
  test('restored candidate IDs are skipped rather than duplicated', () async {
    await queue.replace([
      for (var i = 0; i < 2; i++)
        QueueEntry(
          id: 'insert-${now.microsecondsSinceEpoch}-$i',
          track: playbackFixtureTrack.ref,
          position: i,
          addedAt: now,
        ),
    ]);
    final edit = queue.prepareInsertion(
      queue.state,
      playbackFixtureTrack.ref,
      next: true,
    )!;
    expect(edit.nextEntryId, 'insert-${now.microsecondsSinceEpoch}-2');
    await queue.submitEdit(edit);
    expect(queue.state.entries.map((entry) => entry.id).toSet(), hasLength(3));
  });
  test(
    'stale, busy and closed preparation do not create an accepted intent',
    () async {
      final old = queue.state;
      await queue.replace([]);
      expect(
        queue.prepareInsertion(old, playbackFixtureTrack.ref, next: true),
        isNull,
      );
      final request = queue.prepareInsertion(
        queue.state,
        playbackFixtureTrack.ref,
        next: false,
      )!;
      final pending = queue.submitEdit(request);
      expect(
        queue.prepareInsertion(
          queue.state,
          playbackFixtureTrack.ref,
          next: true,
        ),
        isNull,
      );
      await pending;
      await queue.close();
      expect(
        queue.prepareInsertion(
          queue.state,
          playbackFixtureTrack.ref,
          next: true,
        ),
        isNull,
      );
    },
  );
}
