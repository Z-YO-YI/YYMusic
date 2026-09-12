import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/domain/models/queue_edit.dart';
import 'package:yymusic/features/playlists/common/system_playlist_controller.dart';
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
    );
    page.start();
    await waitForSystem(page.read, () => page.read.isCurrent);
  });
  tearDown(() async {
    await page.close();
    await f.close();
  });

  test(
    'bounded projection binds full root identity without another queue',
    () async {
      expect(page.expected, same(f.graph.queue.state));
      expect(page.read.content!.entries, hasLength(20));
      expect(page.canEdit(page.read.content!), isTrue);
      await expandSystemWindow(page.read);
      expect(page.read.content!.entries, hasLength(200));
      page.read.showNextWindow(page.read.content!);
      await waitForSystem(page.read, () => page.read.isCurrent);
      expect(page.read.content!.page.offset, 200);
      expect(page.read.content!.entries, hasLength(5));
      expect(page.canEdit(page.read.content!), isTrue);
    },
  );
  test('exact duplicate play survives root current-ID publication', () async {
    await page.read.playEntry(page.read.content!, 'q-1');
    await waitForSystem(page.read, () => page.read.isCurrent);
    expect(f.engine.calls, ['load', 'play']);
    expect(f.graph.queue.state.currentEntryId, 'q-1');
    expect(page.canEdit(page.read.content!), isTrue);
  });
  test(
    'same-value replacement revokes an old permission and rebinds reads',
    () async {
      final old = page.read.content!, permit = page.permit();
      final snapshot = page.expected;
      await f.graph.queue.replace(
        snapshot.entries,
        currentEntryId: snapshot.currentEntryId,
      );
      await waitForSystem(page.read, () => page.read.isCurrent);
      expect(permit(), isFalse);
      expect(page.canEdit(old), isFalse);
      expect(page.canEdit(page.read.content!), isTrue);
    },
  );
  test(
    'refresh, resize invalidation and hiding revoke captured callbacks',
    () async {
      var permit = page.permit();
      page.read.refresh();
      expect(permit(), isFalse);
      await waitForSystem(page.read, () => page.read.isCurrent);
      permit = page.permit();
      page.invalidate();
      expect(permit(), isFalse);
      permit = page.permit();
      page.setActive(false);
      page.setActive(true);
      expect(permit(), isFalse);
    },
  );
  test(
    'move at group boundary uses root anchor and preserves current item',
    () async {
      await expandSystemWindow(page.read);
      page.read.showNextWindow(page.read.content!);
      await waitForSystem(page.read, () => page.read.isCurrent);
      final result = await page.submit(
        QueueEdit.move(page.expected, 'q-200', beforeEntryId: 'q-199'),
        page.permit(),
      );
      expect(result.status, QueueEditStatus.applied);
      await waitForSystem(page.read, () => page.read.isCurrent);
      expect(f.graph.queue.state.entries[199].id, 'q-200');
      expect(f.graph.queue.state.currentEntryId, 'q-0');
      expect(page.read.content!.entries.first.entryId, 'q-199');
      expect(f.engine.calls, isEmpty);
    },
  );
  test('mismatched repository rows cannot authorize queue changes', () async {
    f.collection.systemReader = (_, page) async =>
        systemWindow(limit: page.limit);
    page.read.refresh();
    await waitForSystem(page.read, () => page.read.isCurrent);
    expect(page.matches(page.read.content!), isFalse);
    expect(page.canEdit(page.read.content!), isFalse);
  });
  test('close revokes pending work and root error outlives the page', () async {
    f.collection.beforeQueueWrite = (_) async =>
        throw StateError('private-marker');
    final result = await page.submit(
      QueueEdit.remove(page.expected, 'q-2'),
      page.permit(),
    );
    expect(result.status, QueueEditStatus.failed);
    final permit = page.permit();
    await page.close();
    expect(permit(), isFalse);
    expect(f.graph.queue.editFailure, same(result.failure));
    expect(f.graph.systemPlaylists.retainedSessionCount, 0);
  });
}
