import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/design_system/yy_button.dart';
import 'package:yymusic/domain/models/load_state.dart';
import 'package:yymusic/domain/models/playlist_content.dart';
import 'package:yymusic/features/playlists/common/playlist_content_screen.dart';

import '../support/design_harness.dart';
import '../support/playlist_content_fixture.dart';
import '../support/playlist_content_harness.dart';
import '../support/playlist_content_probe.dart';

Finder windowButton(String direction, [String location = 'top']) =>
    find.byKey(ValueKey(('playlist-window-$direction', location)));

Future<void> expandPlaylistWindow(WidgetTester tester) async {
  final c = playlistState(tester).controller;
  while (c.canLoadMore) {
    c.loadMore(c.content!);
    await settleContent(tester);
  }
}

Future<void> tapWindow(WidgetTester tester, String direction) async {
  final button = windowButton(direction);
  // The top group navigation is in the first sliver for all three layouts.
  playlistState(tester).scroll.jumpTo(0);
  await tester.pumpAndSettle();
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await settleContent(tester);
}

void main() {
  setUpAll(loadDesignAssets);
  for (final (name, platform, size) in const [
    ('phone', YYPlatform.android, Size(390, 1000)),
    ('tablet', YYPlatform.android, Size(1024, 768)),
    ('windows', YYPlatform.windows, Size(1440, 1000)),
  ]) {
    testWidgets(
      '$name browses and manages entries after 200, preserves one root and rejects retained callbacks',
      (tester) async {
        final f = PlaylistContentFixture(count: 405);
        await mountPlaylist(tester, f, platform: platform, size: size);
        final state = playlistState(tester);
        final c = state.controller;
        expect(find.text('当前第 1–20 条 / 共 405 条'), findsWidgets);
        expect(tester.widget<YYButton>(windowButton('next')).onPressed, isNull);
        await expandPlaylistWindow(tester);
        final next = tester.widget<YYButton>(windowButton('next')).onPressed!;
        await tapWindow(tester, 'next');
        expect(c.content!.page.offset, 200);
        expect(c.content!.entries.length, 200);
        expect(state.scroll.offset, 0);
        expect(find.text('当前第 201–400 条 / 共 405 条'), findsWidgets);
        final reads = f.collection.contentReadCalls.length;
        next();
        await settleContent(tester);
        expect(f.collection.contentReadCalls.length, reads);
        await openEntryMenu(tester, 'e-200');
        await tester.tap(find.text('从歌单移除'));
        await settleContent(tester);
        expect(c.content!.entries.first.entry.id, 'e-201');
        expect(c.content!.totalCount, 404);
        await tapWindow(tester, 'next');
        expect(c.content!.entries.map((e) => e.entry.id), [
          'e-401',
          'e-402',
          'e-403',
          'e-404',
        ]);
        expect(tester.widget<YYButton>(windowButton('next')).onPressed, isNull);
        await openEntryMenu(tester, 'e-401');
        await tester.tap(find.text('播放歌曲'));
        await settleContent(tester);
        expect(
          f.graph.playback.state.queue.entries.single.track,
          f.tracks[401].ref,
        );
        await tapWindow(tester, 'previous');
        expect(c.content!.page.offset, 200);
        expect(
          f.graph.playback.state.queue.entries.single.track,
          f.tracks[401].ref,
        );
        expect(f.engine.calls.where((e) => e == 'play').length, 1);
        expect(f.graph.playlistContents.retainedSessionCount, 1);
        expect(tester.takeException(), isNull);
        await closePlaylist(tester, f);
      },
    );
  }

  testWidgets(
    'later group and scroll survive rotation, refresh, zero area and navigation away',
    (tester) async {
      final f = PlaylistContentFixture(count: 405);
      await mountPlaylist(tester, f);
      final state = playlistState(tester);
      final c = state.controller;
      await expandPlaylistWindow(tester);
      await tapWindow(tester, 'next');
      state.scroll.jumpTo(900);
      await tester.pumpAndSettle();
      c.refresh();
      await settleContent(tester);
      expect(state.scroll.offset, 900);
      for (final size in [
        const Size(800, 1100),
        const Size(1024, 768),
        Size.zero,
        const Size(390, 1000),
      ]) {
        tester.view.physicalSize = size;
        await settleContent(tester);
        expect(playlistState(tester).controller, same(c));
        expect(c.content!.page.offset, 200);
        expect(c.content!.entries.length, 200);
        expect(tester.takeException(), isNull);
      }
      expect(state.scroll.offset, 900);
      final router = GoRouter.of(
        tester.element(find.byType(PlaylistContentScreen)),
      );
      unawaited(router.push<void>('/licenses'));
      await settleContent(tester);
      c.showNextWindow(c.content!);
      await settleContent(tester);
      expect(c.content!.page.offset, 200);
      router.pop();
      await settleContent(tester);
      expect(state.scroll.offset, 900);
      expect(f.engine.calls, isEmpty);
      await closePlaylist(tester, f);
    },
  );

  testWidgets(
    'read failure disables stale rows and retry reaches the requested later group',
    (tester) async {
      final f = PlaylistContentFixture(count: 205);
      await mountPlaylist(tester, f);
      await expandPlaylistWindow(tester);
      f.collection.contentReader = (_, _) async =>
          throw StateError('private-marker');
      await tapWindow(tester, 'next');
      final c = playlistState(tester).controller;
      expect(c.phase, LoadPhase.error);
      expect(c.content!.page.offset, 0);
      expect(find.text('歌单读取失败'), findsOneWidget);
      expect(tester.widget<YYButton>(windowButton('next')).onPressed, isNull);
      expect(find.textContaining('private-marker'), findsNothing);
      f.collection.contentReader = null;
      await tester.ensureVisible(find.text('重试歌单'));
      await tester.tap(find.text('重试歌单'));
      await settleContent(tester);
      expect(c.content!.page.offset, 200);
      expect(c.content!.entries.length, 5);
      expect(playlistState(tester).scroll.offset, 0);
      await closePlaylist(tester, f);
    },
  );

  testWidgets(
    'Windows native Enter activates a group button without calling global playback',
    (tester) async {
      final f = PlaylistContentFixture(count: 205);
      await mountPlaylist(
        tester,
        f,
        platform: YYPlatform.windows,
        size: const Size(1024, 900),
      );
      await expandPlaylistWindow(tester);
      final button = windowButton('next');
      final node = Focus.of(
        tester.element(
          find.descendant(of: button, matching: find.byType(Text)).first,
        ),
      );
      node.requestFocus();
      await tester.pumpAndSettle();
      expect(FocusManager.instance.primaryFocus, same(node));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await settleContent(tester);
      expect(playlistState(tester).controller.content!.page.offset, 200);
      expect(f.engine.calls, isEmpty);
      expect(tester.takeException(), isNull);
      await closePlaylist(tester, f);
    },
  );

  testWidgets(
    'menu blocks retained navigation and a group completed at zero size resets scroll when visible again',
    (tester) async {
      final f = PlaylistContentFixture(count: 405);
      await mountPlaylist(tester, f);
      final state = playlistState(tester);
      final c = state.controller;
      await expandPlaylistWindow(tester);
      final callback = tester.widget<YYButton>(windowButton('next')).onPressed!;
      await openEntryMenu(tester, 'e-0');
      final reads = f.collection.contentReadCalls.length;
      callback();
      await settleContent(tester);
      expect(f.collection.contentReadCalls.length, reads);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      state.scroll.jumpTo(900);
      await tester.pumpAndSettle();
      final gate = Completer<PlaylistContent?>();
      f.collection.contentReader = (_, _) => gate.future;
      callback();
      await settleContent(tester);
      expect(c.loading, isTrue);
      tester.view.physicalSize = Size.zero;
      await settleContent(tester);
      gate.complete(
        contentWindow(id: f.id, count: 405, offset: 200, limit: 200),
      );
      await settleContent(tester);
      expect(c.content!.page.offset, 200);
      tester.view.physicalSize = const Size(390, 1000);
      await settleContent(tester);
      expect(state.scroll.offset, 0);
      expect(find.text('当前第 201–400 条 / 共 405 条'), findsWidgets);
      expect(tester.takeException(), isNull);
      await closePlaylist(tester, f);
    },
  );
}
