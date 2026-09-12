import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/features/queue/common/queue_page_controller.dart';
import 'package:yymusic/playback/queue_edit_result.dart';

import '../support/system_playlist_fixture.dart';
import '../support/system_playlist_probe.dart';

void main() {
  late SystemPlaylistFixture f;
  late QueuePageController page;
  setUp(() async {
    f = SystemPlaylistFixture(count: 205);
    await f.initialize();
    page = QueuePageController(
      queue: f.graph.queue,
      sessions: f.graph.systemPlaylists,
    )..start();
    await waitForSystem(page.read, () => page.read.isCurrent);
  });
  tearDown(() async {
    await page.close();
    await f.close();
  });
  test(
    'window tail anchors before the next unseen root item, not whole queue end',
    () async {
      final drag = page.beginDrag(page.read.content!, 1, page.permit())!;
      final edit = drag.moveTo(19)!;
      final result = await page.submit(edit, drag.permit);
      expect(result.status, QueueEditStatus.applied);
      expect(f.graph.queue.state.entries[19].id, 'q-1');
      expect(f.graph.queue.state.entries[20].id, 'q-20');
      expect(f.graph.queue.state.entries.last.id, 'q-204');
      expect(f.graph.queue.state.currentEntryId, 'q-0');
      expect(f.engine.calls, isEmpty);
    },
  );
  test('upward normalized target preserves repeated track IDs and addedAt', () {
    final drag = page.beginDrag(page.read.content!, 2, page.permit())!;
    final preview = drag.moveTo(0)!.apply(updatedAt: page.expected.updatedAt)!;
    expect(preview.entries.take(4).map((e) => e.id), [
      'q-2',
      'q-0',
      'q-1',
      'q-3',
    ]);
    expect(preview.entries.first.track, page.expected.entries[2].track);
    expect(preview.entries.first.addedAt, page.expected.entries[2].addedAt);
    expect(preview.entries[1].track, preview.entries[2].track);
  });
  test(
    'last group maps actual queue end and nonzero page offset correctly',
    () async {
      await expandSystemWindow(page.read);
      page.read.showNextWindow(page.read.content!);
      await waitForSystem(page.read, () => page.read.isCurrent);
      final drag = page.beginDrag(page.read.content!, 0, page.permit())!;
      final preview = drag
          .moveTo(4)!
          .apply(updatedAt: page.expected.updatedAt)!;
      expect(preview.entries.skip(199).map((e) => e.id), [
        'q-199',
        'q-201',
        'q-202',
        'q-203',
        'q-204',
        'q-200',
      ]);
    },
  );
  test('no movement and out-of-window indices do not create edits', () {
    final content = page.read.content!;
    expect(page.beginDrag(content, -1, page.permit()), isNull);
    expect(page.beginDrag(content, 20, page.permit()), isNull);
    final drag = page.beginDrag(content, 1, page.permit())!;
    for (final index in [-1, 1, 20, 500]) {
      expect(drag.moveTo(index), isNull);
    }
    expect(f.collection.queueWrites, isEmpty);
  });
  for (final reason in ['refresh', 'replace', 'hide', 'close']) {
    test('drag permission is irrevocably revoked by $reason', () async {
      final drag = page.beginDrag(page.read.content!, 1, page.permit())!;
      switch (reason) {
        case 'refresh':
          page.read.refresh();
        case 'replace':
          await f.graph.queue.replace(
            page.expected.entries,
            currentEntryId: 'q-0',
          );
        case 'hide':
          page.setActive(false);
          page.setActive(true);
        case 'close':
          await page.close();
      }
      expect(drag.permit(), isFalse);
      expect(drag.moveTo(3), isNull);
    });
  }
}
