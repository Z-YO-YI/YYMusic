import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:yymusic/design_system/yy_track_tile.dart';
import 'package:yymusic/features/playlists/common/system_playlist_controller.dart';
import 'package:yymusic/features/playlists/common/system_playlist_screen.dart';

import '../support/design_harness.dart';
import '../support/playlist_content_harness.dart' show settleContent;
import '../support/system_playlist_fixture.dart';
import '../support/system_playlist_harness.dart';

void main() {
  setUpAll(loadDesignAssets);
  testWidgets(
    'rotation split-screen and zero area retain the same bounded session and scroll',
    (tester) async {
      final f = SystemPlaylistFixture(count: 60);
      await mountSystemPlaylist(tester, f);
      final state = systemState(tester);
      state.scroll.jumpTo(300);
      state.controller.loadMore(state.controller.content!);
      await settleContent(tester);
      final reads = f.collection.systemReadCalls.length;
      for (final size in const [
        Size(800, 1100),
        Size(1024, 768),
        Size.zero,
        Size(590, 700),
        Size(800, 480),
      ]) {
        tester.view.physicalSize = size;
        await settleContent(tester);
        expect(systemState(tester), same(state));
        expect(state.controller.content!.entries.length, 40);
        expect(f.collection.systemReadCalls.length, reads);
        expect(tester.takeException(), isNull);
      }
      expect(state.scroll.offset, greaterThan(0));
      await closeSystemPlaylist(tester, f);
    },
  );

  for (final hidden in ['covered', 'zero-area']) {
    testWidgets('$hidden revokes a pending load and old row callback', (
      tester,
    ) async {
      final f = SystemPlaylistFixture();
      await mountSystemPlaylist(tester, f);
      final state = systemState(tester);
      final router = GoRouter.of(
        tester.element(find.byType(SystemPlaylistScreen)),
      );
      await revealSystemRow(tester, 'q-1');
      final old = tester.widget<YYTrackTile>(systemRow('q-1')).onPressed!;
      final gate = Completer<void>();
      f.engine.loadGate = gate.future;
      final play = state.controller.playEntry(state.controller.content!, 'q-1');
      await settleContent(tester);
      expect(f.engine.calls, contains('load'));
      if (hidden == 'covered') {
        unawaited(router.push<void>('/design-system'));
      } else {
        tester.view.physicalSize = Size.zero;
      }
      await tester.pumpAndSettle();
      old();
      gate.complete();
      await settleContent(tester);
      await play;
      expect(f.engine.calls, isNot(contains('play')));
      if (hidden == 'covered') {
        router.pop();
      } else {
        tester.view.physicalSize = const Size(390, 1000);
      }
      await settleContent(tester);
      expect(systemState(tester), same(state));
      expect(tester.takeException(), isNull);
      await closeSystemPlaylist(tester, f);
    });
  }

  testWidgets(
    'real more and next/previous controls preserve bounded reads and reset group scroll',
    (tester) async {
      final f = SystemPlaylistFixture(count: 237);
      await mountSystemPlaylist(tester, f);
      final state = systemState(tester), c = state.controller;
      final scrolling = find
          .descendant(
            of: find.byKey(const PageStorageKey('system-playlist-scroll')),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.text('更多歌曲'),
        500,
        scrollable: scrolling,
      );
      await tester.ensureVisible(find.text('更多歌曲'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('更多歌曲'));
      await settleContent(tester);
      expect(c.content!.entries.length, 40);
      while (c.canLoadMore) {
        c.loadMore(c.content!);
        await settleContent(tester);
      }
      expect(c.content!.entries.length, 200);
      state.scroll.jumpTo(0);
      await tester.pumpAndSettle();
      final next = find.byKey(const ValueKey(('system-next', 'top')));
      await tester.ensureVisible(next);
      await tester.pumpAndSettle();
      await tester.tap(next);
      await settleContent(tester);
      expect(c.content!.page.offset, 200);
      expect(c.content!.entries.length, 37);
      expect(state.scroll.offset, 0);
      expect(c.content!.entries.first.entryId, 'q-200');
      final previous = find.byKey(const ValueKey(('system-previous', 'top')));
      await tester.ensureVisible(previous);
      await tester.pumpAndSettle();
      await tester.tap(previous);
      await settleContent(tester);
      expect(c.content!.page.offset, 0);
      expect(c.content!.entries.length, 200);
      expect(state.scroll.offset, 0);
      expect(f.engine.calls, isEmpty);
      expect(tester.takeException(), isNull);
      await closeSystemPlaylist(tester, f);
    },
  );
}
