import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/domain/models/load_state.dart';
import 'package:yymusic/domain/models/system_playlist_content.dart';
import 'package:yymusic/features/playlists/common/system_playlist_controller.dart';

import '../support/system_playlist_fixture.dart';
import '../support/system_playlist_probe.dart';

void main() {
  for (final type in [
    SystemPlaylistType.favorites,
    SystemPlaylistType.recent,
  ]) {
    test('$type queue permission requires exact window and entry', () async {
      final f = SystemPlaylistFixture();
      addTearDown(f.close);
      final c = await f.open(type), snapshot = c.content!;
      final entry = snapshot.entries.first;
      expect(c.queueSourcePermit(snapshot, entry)!(), isTrue);
      expect(
        c.queueSourcePermit(
          snapshot,
          SystemPlaylistEntry(
            reference: entry.reference,
            position: entry.position,
            addedAt: entry.addedAt,
            entryId: entry.entryId,
            track: entry.track,
          ),
        ),
        isNull,
      );
      expect(
        c.queueSourcePermit(
          SystemPlaylistContent(
            type: type,
            page: snapshot.page,
            totalCount: snapshot.totalCount,
            entries: snapshot.entries,
          ),
          entry,
        ),
        isNull,
      );
      for (final unavailable in snapshot.entries.where((e) => !e.isAvailable)) {
        expect(c.queueSourcePermit(snapshot, unavailable)!(), isTrue);
        expect(c.canPlayEntry(snapshot, unavailable.identity), isFalse);
      }
      expect(f.engine.calls, isEmpty);
    });
    for (final reason in ['refresh', 'hide', 'close', 'error']) {
      test('$type queue permission stays revoked after $reason', () async {
        final f = SystemPlaylistFixture();
        addTearDown(f.close);
        final c = await f.open(type), snapshot = c.content!;
        final permit = c.queueSourcePermit(snapshot, snapshot.entries.first)!;
        switch (reason) {
          case 'refresh':
            c.refresh();
            await waitForSystem(c, () => c.isCurrent);
          case 'hide':
            c.setActive(false);
            c.setActive(true);
          case 'close':
            await c.close();
          case 'error':
            f.collection.systemReader = (_, _) async =>
                throw StateError('private-marker');
            c.refresh();
            await waitForSystem(c, () => c.phase == LoadPhase.error);
            expect(c.content, same(snapshot));
            expect(
              c.queueSourcePermit(snapshot, snapshot.entries.first),
              isNull,
            );
        }
        expect(permit(), isFalse);
      });
    }
  }
  test(
    'legacy queue projection never authorizes a second insertion source',
    () async {
      final f = SystemPlaylistFixture();
      addTearDown(f.close);
      final c = await f.open(SystemPlaylistType.queue);
      expect(c.canOpenEntry(c.content!, c.content!.entries.first), isFalse);
      expect(c.queueSourcePermit(c.content!, c.content!.entries.first), isNull);
    },
  );
  test(
    'favorites expansion and 200-entry group changes revoke old permissions',
    () async {
      final f = SystemPlaylistFixture(count: 205);
      addTearDown(f.close);
      final c = await f.open(SystemPlaylistType.favorites);
      final first = c.queueSourcePermit(c.content!, c.content!.entries.first)!;
      await expandSystemWindow(c);
      expect(first(), isFalse);
      final old = c.content!, entry = c.content!.entries.last;
      final permit = c.queueSourcePermit(old, entry)!;
      c.showNextWindow(old);
      await waitForSystem(c, () => c.isCurrent);
      expect(c.content!.page.offset, 200);
      expect(permit(), isFalse);
      c.showPreviousWindow(c.content!);
      await waitForSystem(c, () => c.isCurrent);
      expect(permit(), isFalse);
      expect(c.queueSourcePermit(c.content!, entry), isNull);
    },
  );
}
