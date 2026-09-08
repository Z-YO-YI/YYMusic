import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/app/playlist_location.dart';
import 'package:yymusic/design_system/yy_button.dart';
import 'package:yymusic/design_system/yy_context_menu.dart';
import 'package:yymusic/design_system/yy_track_tile.dart';
import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/features/library/common/library_controller.dart';
import 'package:yymusic/features/library/common/library_screen.dart';
import 'package:yymusic/features/playlists/common/playlist_content_controller.dart';
import 'package:yymusic/features/playlists/common/playlist_content_screen.dart';
import 'package:yymusic/features/playlists/common/playlist_entry_menu.dart';

import '../support/design_harness.dart';
import '../support/playlist_content_fixture.dart';
import '../support/playlist_content_harness.dart';

void main() {
  setUpAll(loadDesignAssets);
  for (final (name, platform, size) in const [
    ('phone', YYPlatform.android, Size(390, 1000)),
    ('tablet', YYPlatform.android, Size(1024, 768)),
    ('windows', YYPlatform.windows, Size(1440, 1000)),
  ]) {
    testWidgets(
      '$name reads real entry identities, moves and removes unresolved references',
      (tester) async {
        final f = PlaylistContentFixture(count: 5);
        await mountPlaylist(tester, f, platform: platform, size: size);
        expect(find.text('沿途的声音'), findsOneWidget);
        expect(playlistState(tester).controller.content!.totalCount, 5);
        await openEntryMenu(tester, 'e-1');
        await tester.tap(find.text('上移一位'));
        await settleContent(tester);
        expect(
          playlistState(tester).controller.content!.entries.first.entry.id,
          'e-1',
        );
        await openEntryMenu(tester, 'e-3');
        final menu = tester.widget<YYContextMenu>(find.byType(YYContextMenu));
        expect(menu.items.singleWhere((i) => i.id == 'play').enabled, isFalse);
        expect(menu.items.singleWhere((i) => i.id == 'remove').enabled, isTrue);
        await tester.tap(find.text('从歌单移除'));
        await settleContent(tester);
        expect(playlistState(tester).controller.content!.totalCount, 4);
        expect(
          (await f.collection.getPlaylistEntries(f.id)).map((e) => e.id),
          isNot(contains('e-3')),
        );
        expect(f.engine.calls, isEmpty);
        expect(tester.takeException(), isNull);
        await closePlaylist(tester, f);
      },
    );
  }

  testWidgets(
    'library navigation preserves opaque ID, category, focus and Back dismisses menu first',
    (tester) async {
      final f = PlaylistContentFixture(count: 5, id: '旅途/a?%#');
      await mountPlaylist(tester, f, location: '/library');
      f.graph.libraryController.selectCategory(LibraryCategory.playlists);
      await settleContent(tester);
      final open = find.byKey(ValueKey(('playlist-open', f.id)));
      await tester.ensureVisible(open);
      await tester.tap(open);
      await settleContent(tester);
      expect(playlistState(tester).controller.playlistId, f.id);
      await openEntryMenu(tester, 'e-0');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(PlaylistEntryMenu), findsNothing);
      expect(find.byType(PlaylistContentScreen), findsOneWidget);
      await tester.binding.handlePopRoute();
      await settleContent(tester);
      expect(find.byType(LibraryScreen), findsOneWidget);
      expect(f.graph.libraryController.category, LibraryCategory.playlists);
      expect(f.graph.playlistContents.retainedSessionCount, 0);
      expect(f.engine.calls, isEmpty);
      await closePlaylist(tester, f);
    },
  );

  testWidgets(
    'Windows keyboard and right click operate native menu without reaching shell controls',
    (tester) async {
      final f = PlaylistContentFixture(count: 5);
      await mountPlaylist(
        tester,
        f,
        platform: YYPlatform.windows,
        size: const Size(1024, 900),
      );
      final row = await revealPlaylistRow(tester, 'e-0');
      final more = find.descendant(
        of: row,
        matching: find.byType(YYIconButton),
      );
      for (var i = 0; i < 60; i++) {
        final context = FocusManager.instance.primaryFocus?.context;
        if (context != null &&
            (context == tester.element(more) ||
                find
                    .ancestor(
                      of: find.byElementPredicate((e) => e == context),
                      matching: more,
                    )
                    .evaluate()
                    .isNotEmpty)) {
          break;
        }
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
      }
      final returnFocus = FocusManager.instance.primaryFocus;
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(PlaylistEntryMenu), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(PlaylistEntryMenu), findsNothing);
      expect(FocusManager.instance.primaryFocus, same(returnFocus));
      await tester.tap(row, buttons: kSecondaryMouseButton);
      await tester.pumpAndSettle();
      for (var i = 0; i < 12; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(
          FocusManager.instance.primaryFocus?.debugLabel,
          startsWith('YYContextMenu:'),
        );
      }
      await tester.tap(find.text('播放歌曲'));
      await settleContent(tester);
      expect(
        f.graph.playback.state.queue.entries.single.track,
        f.tracks.first.ref,
      );
      expect(f.engine.calls.where((e) => e == 'play').length, 1);
      await closePlaylist(tester, f);
    },
  );

  testWidgets(
    'stale callbacks cannot act after refresh or same-entry menu reopening',
    (tester) async {
      final f = PlaylistContentFixture(count: 5);
      await mountPlaylist(tester, f);
      await openEntryMenu(tester, 'e-0');
      final old = tester.widget<PlaylistEntryMenu>(
        find.byType(PlaylistEntryMenu),
      );
      old.onDismiss();
      await tester.pumpAndSettle();
      await openEntryMenu(tester, 'e-0');
      old.onSelected('remove');
      old.onDismiss();
      await settleContent(tester);
      expect(find.byType(PlaylistEntryMenu), findsOneWidget);
      expect((await f.collection.getPlaylistEntries(f.id)).length, 5);
      final current = tester.widget<PlaylistEntryMenu>(
        find.byType(PlaylistEntryMenu),
      );
      playlistState(tester).controller.refresh();
      current.onSelected('remove');
      await settleContent(tester);
      expect(find.byType(PlaylistEntryMenu), findsNothing);
      expect((await f.collection.getPlaylistEntries(f.id)).length, 5);
      await closePlaylist(tester, f);
    },
  );

  testWidgets(
    'loading error retry empty and missing remain distinct without fake content',
    (tester) async {
      final f = PlaylistContentFixture(count: 0);
      f.collection.contentReader = (_, _) async =>
          throw StateError('private-marker');
      await mountPlaylist(tester, f);
      expect(find.text('歌单读取失败'), findsOneWidget);
      expect(find.textContaining('private-marker'), findsNothing);
      f.collection.contentReader = null;
      await tester.tap(find.text('重试歌单'));
      await settleContent(tester);
      expect(find.text('歌单中还没有歌曲。'), findsOneWidget);
      await f.collection.deletePlaylist(f.id);
      await settleContent(tester);
      expect(find.text('此歌单已不存在。'), findsOneWidget);
      expect(find.text('沿途的声音'), findsNothing);
      await closePlaylist(tester, f);
    },
  );

  testWidgets(
    'malformed route and system playlists never expose custom management actions',
    (tester) async {
      final f = PlaylistContentFixture(count: 0);
      await mountPlaylist(tester, f, location: '/playlist?id=a&id=b');
      expect(find.text('无法打开歌单'), findsOneWidget);
      expect(f.graph.playlistContents.retainedSessionCount, 0);
      await f.collection.savePlaylist(
        Playlist(
          id: 'system',
          name: '喜欢的音乐',
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
          isSystem: true,
          systemType: SystemPlaylistType.favorites,
        ),
      );
      GoRouter.of(tester.element(find.text('无法打开歌单')))
          .go(playlistLocation('system').toString());
      await settleContent(tester);
      expect(find.text('歌单读取失败'), findsOneWidget);
      expect(find.byType(YYTrackTile), findsNothing);
      await closePlaylist(tester, f);
    },
  );

  testWidgets(
    'phone tablet rotation and zero area keep the session, visible prefix and scroll',
    (tester) async {
      final f = PlaylistContentFixture(count: 60);
      await mountPlaylist(tester, f);
      final state = playlistState(tester);
      state.scroll.jumpTo(300);
      state.controller.loadMore();
      await settleContent(tester);
      final reads = f.collection.contentReadCalls.length;
      for (final size in [
        const Size(800, 1100),
        const Size(1024, 768),
        const Size(0, 0),
        const Size(590, 700),
        const Size(800, 480),
      ]) {
        tester.view.physicalSize = size;
        await settleContent(tester);
        expect(playlistState(tester), same(state));
        expect(state.controller.content!.entries.length, 40);
        expect(f.collection.contentReadCalls.length, reads);
        expect(tester.takeException(), isNull);
      }
      expect(state.scroll.offset, greaterThan(0));
      await closePlaylist(tester, f);
    },
  );

  testWidgets(
    'more expands a consistent group and its 200 entry boundary exposes real navigation',
    (tester) async {
      final f = PlaylistContentFixture(count: 237);
      await mountPlaylist(tester, f);
      final state = playlistState(tester);
      expect(state.controller.content!.entries.length, 20);
      expect(state.controller.canLoadMore, isTrue);
      final scrolling = find
          .descendant(
            of: find.byKey(const PageStorageKey('playlist-scroll')),
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
      final c = playlistState(tester).controller;
      expect(c.content!.entries.length, 40);
      for (var count = 60; count <= 200; count += 20) {
        c.loadMore();
        await settleContent(tester);
        expect(c.content!.entries.length, count);
      }
      expect(find.text('更多歌曲'), findsNothing);
      state.scroll.jumpTo(state.scroll.position.maxScrollExtent);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey(('playlist-window-next', 'bottom'))),
        500,
        scrollable: scrolling,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey(('playlist-window-next', 'bottom'))),
      );
      await tester.pumpAndSettle();
      expect(find.text('当前第 1–200 条 / 共 237 条'), findsWidgets);
      expect(
        tester
            .widget<YYButton>(
              find.byKey(const ValueKey(('playlist-window-next', 'bottom'))),
            )
            .onPressed,
        isNotNull,
      );
      await openEntryMenu(tester, 'e-199');
      final menu = tester.widget<YYContextMenu>(find.byType(YYContextMenu));
      expect(menu.items.singleWhere((e) => e.id == 'down').enabled, isFalse);
      expect(tester.takeException(), isNull);
      await closePlaylist(tester, f);
    },
  );

  testWidgets(
    'covered route dismisses menus and revokes an in-flight playback intent',
    (tester) async {
      final f = PlaylistContentFixture(count: 5);
      await mountPlaylist(tester, f);
      final state = playlistState(tester);
      final router = GoRouter.of(
        tester.element(find.byType(PlaylistContentScreen)),
      );
      final gate = Completer<void>();
      f.engine.loadGate = gate.future;
      final play = state.controller.playEntry('e-0');
      await settleContent(tester);
      expect(f.engine.calls, contains('load'));
      unawaited(router.push<void>('/design-system'));
      await tester.pumpAndSettle();
      gate.complete();
      await settleContent(tester);
      await play;
      expect(f.engine.calls, isNot(contains('play')));
      router.pop();
      await settleContent(tester);
      expect(playlistState(tester), same(state));
      await openEntryMenu(tester, 'e-0');
      final old = tester.widget<PlaylistEntryMenu>(
        find.byType(PlaylistEntryMenu),
      );
      unawaited(router.push<void>('/design-system'));
      await tester.pumpAndSettle();
      old.onSelected('remove');
      router.pop();
      await settleContent(tester);
      expect(find.byType(PlaylistEntryMenu), findsNothing);
      expect((await f.collection.getPlaylistEntries(f.id)).length, 5);
      await closePlaylist(tester, f);
    },
  );

  testWidgets(
    'failed refresh keeps stale rows but disables their playback and management',
    (tester) async {
      final f = PlaylistContentFixture(count: 5);
      await mountPlaylist(tester, f);
      f.collection.contentReader = (_, _) async =>
          throw StateError('private-marker');
      playlistState(tester).controller.refresh();
      await settleContent(tester);
      final row = await revealPlaylistRow(tester, 'e-0');
      final tile = tester.widget<YYTrackTile>(
        find.descendant(of: row, matching: find.byType(YYTrackTile)),
      );
      expect(tile.onPressed, isNull);
      expect(tile.onMore, isNull);
      await tester.longPress(row);
      await tester.pumpAndSettle();
      expect(find.byType(PlaylistEntryMenu), findsNothing);
      expect(f.engine.calls, isEmpty);
      await closePlaylist(tester, f);
    },
  );

  testWidgets(
    'accepted removal failure after leaving is visible on Library and can be cleared',
    (tester) async {
      final f = PlaylistContentFixture(count: 5);
      await mountPlaylist(tester, f, location: '/library');
      f.graph.libraryController.selectCategory(LibraryCategory.playlists);
      await settleContent(tester);
      await tester.tap(find.byKey(ValueKey(('playlist-open', f.id))));
      await settleContent(tester);
      final gate = Completer<void>();
      f.collection.onPlaylistMutation = (_, _) async {
        await gate.future;
        throw StateError('private-marker');
      };
      await openEntryMenu(tester, 'e-0');
      await tester.tap(find.text('从歌单移除'));
      await tester.pump();
      await tester.binding.handlePopRoute();
      await tester.pump();
      gate.complete();
      await settleContent(tester);
      expect(find.byType(LibraryScreen), findsOneWidget);
      expect(find.textContaining('歌曲条目：歌单操作未完成'), findsOneWidget);
      expect(find.textContaining('private-marker'), findsNothing);
      expect((await f.collection.getPlaylistEntries(f.id)).length, 5);
      await tester.tap(find.text('知道了'));
      await tester.pumpAndSettle();
      expect(f.graph.playlists.entryFailure, isNull);
      await closePlaylist(tester, f);
    },
  );
}
