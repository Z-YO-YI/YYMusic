import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/domain/models/queue_edit.dart';
import 'package:yymusic/domain/models/track.dart';

final queueEditEpoch = DateTime.utc(2026, 1, 1);

QueueSnapshot editFixture({String? current = 'b', int count = 4}) =>
    QueueSnapshot(
      entries: [
        for (var i = 0; i < count; i++)
          QueueEntry(
            id: i < 4 ? String.fromCharCode(97 + i) : 'entry-$i',
            track: TrackRef(
              sourceType: i.isEven
                  ? MusicSourceType.local
                  : MusicSourceType.rest,
              sourceId: i < 2 ? 'source-a' : 'source-b',
              trackId: 'same-track',
            ),
            position: i,
            addedAt: queueEditEpoch.add(Duration(seconds: i)),
          ),
      ],
      currentEntryId: current,
      updatedAt: queueEditEpoch,
    );

void main() {
  test(
    'moves before anchors in both directions and preserves full identity',
    () {
      final queue = editFixture();
      final next = QueueEdit.move(
        queue,
        'd',
        beforeEntryId: 'b',
      ).apply(updatedAt: queueEditEpoch)!;
      expect(next.entries.map((e) => e.id), ['a', 'd', 'b', 'c']);
      expect(next.entries.map((e) => e.position), [0, 1, 2, 3]);
      expect(next.currentEntryId, 'b');
      for (final entry in next.entries) {
        final original = queue.entries.singleWhere((e) => e.id == entry.id);
        expect(entry.track, same(original.track));
        expect(entry.addedAt, original.addedAt);
      }
      final forward = QueueEdit.move(
        next,
        'd',
        beforeEntryId: 'c',
      ).apply(updatedAt: queueEditEpoch)!;
      expect(forward.entries.map((e) => e.id), ['a', 'b', 'd', 'c']);
      expect(queue.entries.map((e) => e.id), ['a', 'b', 'c', 'd']);
      expect(() => next.entries.clear(), throwsUnsupportedError);
    },
  );
  test(
    'null anchor appends without confusing source and destination indexes',
    () {
      final result = QueueEdit.move(
        editFixture(),
        'b',
      ).apply(updatedAt: queueEditEpoch)!;
      expect(result.entries.map((e) => e.id), ['a', 'c', 'd', 'b']);
      expect(result.currentEntryId, 'b');
    },
  );
  for (final pair in [('b', 'b'), ('b', 'c'), ('d', null)]) {
    test('unchanged movement $pair returns no mutation', () {
      expect(
        QueueEdit.move(
          editFixture(),
          pair.$1,
          beforeEntryId: pair.$2,
        ).apply(updatedAt: queueEditEpoch),
        isNull,
      );
    });
  }
  test('remove non-current preserves current even with matching track IDs', () {
    final result = QueueEdit.remove(
      editFixture(),
      'a',
    ).apply(updatedAt: queueEditEpoch)!;
    expect(result.entries.map((e) => e.id), ['b', 'c', 'd']);
    expect(result.currentEntryId, 'b');
  });
  for (final pair in [('a', 'b'), ('b', 'c'), ('d', 'c')]) {
    test('remove current ${pair.$1} chooses adjacent ${pair.$2}', () {
      final result = QueueEdit.remove(
        editFixture(current: pair.$1),
        pair.$1,
      ).apply(updatedAt: queueEditEpoch)!;
      expect(result.currentEntryId, pair.$2);
    });
  }
  test(
    'removing the sole entry and clearing both yield valid empty queues',
    () {
      final single = editFixture(count: 1, current: 'a');
      final removed = QueueEdit.remove(
        single,
        'a',
      ).apply(updatedAt: queueEditEpoch)!;
      expect(removed.entries, isEmpty);
      expect(removed.currentEntryId, isNull);
      final cleared = QueueEdit.clear(editFixture())
          .apply(updatedAt: queueEditEpoch)!;
      expect(cleared.entries, isEmpty);
      expect(cleared.currentEntryId, isNull);
      expect(QueueEdit.clear(cleared).apply(updatedAt: queueEditEpoch), isNull);
    },
  );
  test('missing target or anchor fails before any root operation', () {
    final queue = editFixture();
    expect(() => QueueEdit.remove(queue, 'absent'), throwsArgumentError);
    expect(() => QueueEdit.move(queue, 'absent'), throwsArgumentError);
    expect(
      () => QueueEdit.move(queue, 'b', beforeEntryId: 'absent'),
      throwsArgumentError,
    );
  });
  test(
    'large queue uses complete snapshot and permits an offscreen anchor',
    () {
      final queue = editFixture(count: 1003, current: null);
      final last = queue.entries.last;
      final result = QueueEdit.move(
        queue,
        'a',
        beforeEntryId: last.id,
      ).apply(updatedAt: queueEditEpoch)!;
      expect(result.entries.length, 1003);
      expect(result.entries[1001].id, 'a');
      expect(result.entries.last.id, last.id);
      expect(result.currentEntryId, isNull);
    },
  );
}
