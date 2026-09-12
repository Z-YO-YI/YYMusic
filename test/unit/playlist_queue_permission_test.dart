import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/domain/models/load_state.dart';
import 'package:yymusic/domain/models/playlist_content.dart';
import 'package:yymusic/features/playlists/common/playlist_content_controller.dart';

import '../support/playlist_content_fixture.dart';
import '../support/playlist_content_probe.dart';
import 'playlist_content_actions_test.dart' show startContent;

void main() {
  test(
    'queue source requires exact window and entry, not matching IDs',
    () async {
      final f = PlaylistContentFixture(count: 5);
      addTearDown(f.close);
      final c = await startContent(f);
      final snapshot = c.content!, entry = c.content!.entries.first;
      expect(c.queueSourcePermit(snapshot, entry)!(), isTrue);
      expect(
        c.queueSourcePermit(
          snapshot,
          PlaylistContentEntry(entry: entry.entry, track: entry.track),
        ),
        isNull,
      );
      final clone = PlaylistContent(
        playlist: snapshot.playlist,
        page: snapshot.page,
        totalCount: snapshot.totalCount,
        entries: snapshot.entries,
      );
      expect(c.queueSourcePermit(clone, entry), isNull);
    },
  );
  for (final id in ['e-2', 'e-3']) {
    test('missing or unresolved $id remains a queue soft reference', () async {
      final f = PlaylistContentFixture(count: 5);
      addTearDown(f.close);
      final c = await startContent(f);
      expect(c.canPlayEntry(id), isFalse);
      expect(c.queueSourcePermit(c.content!, c.entryFor(id)!)!(), isTrue);
      expect(f.engine.calls, isEmpty);
    });
  }
  for (final reason in ['refresh', 'expand', 'hide', 'close']) {
    test(
      'playlist queue source is revoked permanently after $reason',
      () async {
        final f = PlaylistContentFixture(count: 25);
        addTearDown(f.close);
        final c = await startContent(f);
        final permit = c.queueSourcePermit(
          c.content!,
          c.content!.entries.first,
        )!;
        switch (reason) {
          case 'refresh':
            c.refresh();
            await waitForContent(c, () => c.isCurrent);
          case 'expand':
            c.loadMore();
            await waitForContent(c, () => c.isCurrent);
          case 'hide':
            c.setActive(false);
            c.setActive(true);
          case 'close':
            await c.close();
        }
        expect(permit(), isFalse);
      },
    );
  }
  test(
    'moving between bounded groups never reauthorizes an old entry',
    () async {
      final f = PlaylistContentFixture(count: 205);
      addTearDown(f.close);
      final c = await startContent(f);
      while (c.canLoadMore) {
        c.loadMore();
        await waitForContent(c, () => c.isCurrent);
      }
      final old = c.content!, entry = c.content!.entries.last;
      final permit = c.queueSourcePermit(old, entry)!;
      c.showNextWindow(old);
      await waitForContent(c, () => c.isCurrent);
      expect(c.content!.page.offset, 200);
      expect(permit(), isFalse);
      c.showPreviousWindow(c.content!);
      await waitForContent(c, () => c.isCurrent);
      expect(c.entryFor(entry.entry.id), isNotNull);
      expect(permit(), isFalse);
    },
  );
  test(
    'retained stale rows after a read failure cannot grant queue permission',
    () async {
      final f = PlaylistContentFixture(count: 5);
      addTearDown(f.close);
      final c = await startContent(f);
      final old = c.content!, entry = c.content!.entries.first;
      final permit = c.queueSourcePermit(old, entry)!;
      f.collection.contentReader = (_, _) async =>
          throw StateError('private-marker');
      c.refresh();
      await waitForContent(c, () => c.phase == LoadPhase.error);
      expect(c.content, same(old));
      expect(permit(), isFalse);
      expect(c.queueSourcePermit(old, entry), isNull);
    },
  );
}
