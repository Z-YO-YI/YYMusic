import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/playback_queue_summary.dart';
import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/domain/models/track.dart';
import 'package:yymusic/playback/audio_engine_state.dart';
import 'package:yymusic/playback/playback_state.dart';

import '../support/playback_graph_fixture.dart';

void main() {
  final ref = TrackRef(
    trackId: 'same-track',
    sourceId: 'test-only',
    sourceType: MusicSourceType.rest,
  );
  List<QueueEntry> entries() => [
    for (var i = 0; i < 3; i++)
      QueueEntry(
        id: 'entry-$i',
        track: ref,
        position: i,
        addedAt: DateTime.utc(2026),
      ),
  ];

  test('empty summary has no fabricated current entry', () {
    final summary = PlaybackQueueSummary.fromQueue(
      QueueSnapshot(entries: [], updatedAt: DateTime.utc(2026)),
    );
    expect(summary.totalCount, 0);
    expect(summary.currentEntry, isNull);
    expect(summary.currentOrdinal, isNull);
  });

  test('populated unselected queue is not presented as first entry', () {
    final summary = PlaybackQueueSummary.fromQueue(
      QueueSnapshot(entries: entries(), updatedAt: DateTime.utc(2026)),
    );
    expect(summary.totalCount, 3);
    expect(summary.currentEntry, isNull);
    expect(summary.currentOrdinal, isNull);
  });

  for (var current = 0; current < 3; current++) {
    test('duplicate TrackRef selects exact queue entry $current', () {
      final original = entries();
      final summary = PlaybackQueueSummary.fromQueue(
        QueueSnapshot(
          entries: original,
          currentEntryId: 'entry-$current',
          updatedAt: DateTime.utc(2026),
        ),
      );
      expect(summary.totalCount, 3);
      expect(summary.currentOrdinal, current + 1);
      expect(summary.currentEntry, same(original[current]));
      original.clear();
      expect(summary.totalCount, 3);
      expect(summary.currentEntry!.id, 'entry-$current');
    });
  }

  group('root presenter', () {
    late PlaybackGraphFixture f;
    setUp(() => f = PlaybackGraphFixture());
    tearDown(() => f.graph.close());

    test(
      'reads cache without issuing audio commands or replacing root',
      () async {
        await f.queue();
        final root = f.graph.playback.state.queue;
        final calls = List.of(f.engine.calls);
        final presenter = f.graph.playbackPresenter;
        final summary = presenter.queueSummary;
        for (var i = 0; i < 100; i++) {
          expect(presenter.queueSummary, same(summary));
        }
        expect(summary.totalCount, presenter.queueCount);
        expect(summary.currentEntry!.id, presenter.entryId);
        expect(f.graph.playback.state.queue, same(root));
        expect(f.engine.calls, calls);
      },
    );

    test('position and mode notifications preserve list projection', () async {
      await f.queue();
      await f.graph.playback.play();
      final presenter = f.graph.playbackPresenter;
      final summary = presenter.queueSummary;
      f.engine.events.add(
        AudioEngineState(
          phase: AudioEnginePhase.playing,
          position: const Duration(seconds: 20),
          duration: const Duration(minutes: 3),
        ),
      );
      expect(presenter.queueSummary, same(summary));
      f.graph.playback.setShuffleEnabled(true);
      f.graph.playback.setRepeatMode(RepeatMode.one);
      expect(presenter.queueSummary, same(summary));
      expect(summary.currentOrdinal, 1);
    });

    test('reorder updates ordinal without mutating retained summary', () async {
      await f.queue();
      final presenter = f.graph.playbackPresenter;
      final before = presenter.queueSummary;
      await f.graph.queue.move('a', 1);
      final after = presenter.queueSummary;
      expect(after, isNot(same(before)));
      expect(after.currentEntry!.id, 'a');
      expect(after.currentOrdinal, 2);
      expect(before.currentOrdinal, 1);
    });

    test('next selects new entry and notifies with new summary', () async {
      await f.queue();
      await f.graph.playback.play();
      final presenter = f.graph.playbackPresenter;
      final before = presenter.queueSummary;
      var sawSecond = false;
      presenter.addListener(() {
        if (presenter.queueSummary.currentEntry?.id == 'b') sawSecond = true;
      });
      await f.graph.playback.skipNext();
      expect(sawSecond, isTrue);
      expect(presenter.queueSummary.currentOrdinal, 2);
      expect(before.currentEntry!.id, 'a');
    });

    test(
      'clear invalidates cache and retains previous immutable data',
      () async {
        await f.queue();
        final presenter = f.graph.playbackPresenter;
        final before = presenter.queueSummary;
        await f.graph.queue.clear();
        expect(presenter.queueSummary.totalCount, 0);
        expect(presenter.queueSummary.currentEntry, isNull);
        expect(presenter.queueSummary.currentOrdinal, isNull);
        expect(before.totalCount, 2);
        expect(before.currentEntry!.id, 'a');
      },
    );
  });
}
