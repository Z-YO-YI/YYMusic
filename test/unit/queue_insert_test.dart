import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/domain/models/queue_edit.dart';

import 'queue_edit_test.dart' show editFixture, queueEditEpoch;

void main() {
  for (final next in [false, true]) {
    for (final current in ['a', 'd', null]) {
      test('insert next=$next current=$current keeps complete identity', () {
        final root = editFixture(current: current);
        final entry = QueueEntry(
          id: 'new',
          track: root.entries.first.track,
          position: 99,
          addedAt: queueEditEpoch.add(const Duration(days: 1)),
        );
        final edit = next
            ? QueueEdit.playNext(root, entry)
            : QueueEdit.addToEnd(root, entry);
        expect(edit.expected, same(root));
        expect(edit.insertsEntry, isTrue);
        expect(edit.nextEntryId, next ? 'new' : null);
        final value = edit.apply(updatedAt: queueEditEpoch)!;
        final index = next
            ? (current == 'a'
                  ? 1
                  : current == 'd'
                  ? 4
                  : 0)
            : 4;
        expect(value.entries[index].id, 'new');
        expect(value.entries[index].track, same(entry.track));
        expect(value.entries[index].addedAt, entry.addedAt);
        expect(value.entries.map((e) => e.position), [0, 1, 2, 3, 4]);
        expect(value.currentEntryId, current);
        expect(
          value.entries.where((e) => e.track == entry.track),
          hasLength(2),
        );
        expect(root.entries, hasLength(4));
        expect(() => value.entries.clear(), throwsUnsupportedError);
      });
    }
    test('empty insert next=$next does not select or auto-play', () {
      final empty = editFixture(count: 0, current: null);
      final entry = editFixture().entries.first;
      final value =
          (next
                  ? QueueEdit.playNext(empty, entry)
                  : QueueEdit.addToEnd(empty, entry))
              .apply(updatedAt: queueEditEpoch)!;
      expect(value.currentEntryId, isNull);
      expect(value.entries.single.position, 0);
    });
    test(
      'duplicate entry ID rejected for next=$next, even with different source',
      () {
        final root = editFixture();
        final collision = QueueEntry(
          id: 'b',
          track: root.entries.first.track,
          position: 8,
          addedAt: queueEditEpoch,
        );
        expect(
          () => next
              ? QueueEdit.playNext(root, collision)
              : QueueEdit.addToEnd(root, collision),
          throwsArgumentError,
        );
      },
    );
  }
}
