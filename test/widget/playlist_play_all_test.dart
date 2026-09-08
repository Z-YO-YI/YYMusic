import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/design_system/yy_button.dart';
import 'package:yymusic/features/playlists/common/playlist_content_screen.dart';

import '../support/design_harness.dart';
import '../support/playlist_content_fixture.dart';
import '../support/playlist_content_harness.dart';
import 'playlist_window_navigation_test.dart'
    show expandPlaylistWindow, tapWindow;

Finder playAllButton({bool shuffle = false}) => find.byKey(
  ValueKey(shuffle ? 'playlist-play-shuffle' : 'playlist-play-all'),
);

Future<void> tapPlayAll(WidgetTester tester, {bool shuffle = false}) async {
  playlistState(tester).scroll.jumpTo(0);
  await tester.pumpAndSettle();
  await tester.ensureVisible(playAllButton(shuffle: shuffle));
  await tester.tap(playAllButton(shuffle: shuffle));
  await settleContent(tester);
}

void main() {
  setUpAll(loadDesignAssets);
  testWidgets(
    'Windows minimize retains the route but cancels a pending native playlist load',
    (tester) async {
      final f = PlaylistContentFixture(count: 5);
      await mountPlaylist(
        tester,
        f,
        platform: YYPlatform.windows,
        size: const Size(1440, 1000),
      );
      final c = playlistState(tester).controller;
      final gate = Completer<void>();
      addTearDown(() {
        if (!gate.isCompleted) gate.complete();
      });
      f.engine.loadGate = gate.future;
      await tester.tap(playAllButton());
      await settleContent(tester);
      expect(f.engine.calls, ['load']);
      tester.view.physicalSize = Size.zero;
      await settleContent(tester);
      expect(find.byType(PlaylistContentScreen), findsNothing);
      expect(
        find.byType(PlaylistContentScreen, skipOffstage: false),
        findsOneWidget,
      );
      gate.complete();
      await settleContent(tester);
      expect(f.engine.calls, ['load', 'stop']);
      tester.view.physicalSize = const Size(1440, 1000);
      await settleContent(tester);
      expect(playlistState(tester).controller, same(c));
      expect(f.engine.calls, isNot(contains('play')));
      expect(tester.takeException(), isNull);
      await closePlaylist(tester, f);
    },
  );
  for (final (name, platform, size) in const [
    ('phone', YYPlatform.android, Size(390, 1000)),
    ('tablet', YYPlatform.android, Size(1024, 768)),
    ('windows', YYPlatform.windows, Size(1440, 1000)),
  ]) {
    testWidgets(
      '$name plays all from a later window, switches shuffle and preserves root across layouts',
      (tester) async {
        final f = PlaylistContentFixture(count: 205);
        await mountPlaylist(tester, f, platform: platform, size: size);
        final c = playlistState(tester).controller;
        await expandPlaylistWindow(tester);
        await tapWindow(tester, 'next');
        expect(c.content!.page.offset, 200);
        await tapPlayAll(tester);
        final player = f.graph.playback;
        expect(player.state.queue.entries.length, 203);
        expect(player.state.currentTrack!.ref, f.tracks.first.ref);
        expect(player.state.shuffleEnabled, isFalse);
        expect(c.actionNote, contains('跳过 2 条不可用引用'));
        expect(f.collection.queueWrites.length, 1);
        await tapPlayAll(tester, shuffle: true);
        expect(player.state.shuffleEnabled, isTrue);
        expect(player.state.queue.entries.length, 203);
        expect(f.collection.queueWrites.length, 2);
        expect(f.engine.calls.where((e) => e == 'play').length, 2);
        final queue = player.state.queue;
        for (final resize in [const Size(800, 1100), Size.zero, size]) {
          tester.view.physicalSize = resize;
          await settleContent(tester);
          // Windows offstages its retained route below minimum dimensions.
          expect(
            tester
                .state<PlaylistContentScreenState>(
                  find.byType(PlaylistContentScreen, skipOffstage: false),
                )
                .controller,
            same(c),
          );
          expect(f.graph.playback.state.queue, same(queue));
          expect(tester.takeException(), isNull);
        }
        expect((await f.collection.getPlaylistEntries(f.id)).length, 205);
        expect(f.graph.playlistContents.retainedSessionCount, 1);
        await closePlaylist(tester, f);
      },
    );
  }
  testWidgets(
    'empty playlist disables both buttons; failed read remains safe and retryable',
    (tester) async {
      final empty = PlaylistContentFixture(count: 0);
      await mountPlaylist(tester, empty);
      expect(tester.widget<YYButton>(playAllButton()).onPressed, isNull);
      expect(
        tester.widget<YYButton>(playAllButton(shuffle: true)).onPressed,
        isNull,
      );
      await closePlaylist(tester, empty);
      final f = PlaylistContentFixture(count: 5);
      await mountPlaylist(tester, f);
      f.collection.playbackPlanReader = (_) async =>
          throw StateError('private-marker');
      await tapPlayAll(tester);
      expect(find.text('歌单播放未完成，请重试。'), findsOneWidget);
      expect(find.textContaining('private-marker'), findsNothing);
      expect(f.collection.queueWrites, isEmpty);
      f.collection.playbackPlanReader = null;
      await tapPlayAll(tester);
      expect(f.graph.playback.state.queue.entries.length, 3);
      expect(find.text('歌单播放未完成，请重试。'), findsNothing);
      expect(tester.takeException(), isNull);
      await closePlaylist(tester, f);
    },
  );
  testWidgets(
    'retained callbacks cannot play behind menus, covered routes or stale snapshots',
    (tester) async {
      final f = PlaylistContentFixture(count: 5);
      await mountPlaylist(tester, f);
      final retained = tester.widget<YYButton>(playAllButton()).onPressed!;
      await openEntryMenu(tester, 'e-0');
      retained();
      await settleContent(tester);
      expect(f.collection.playbackPlanReadCalls, isEmpty);
      await tester.binding.handlePopRoute();
      await settleContent(tester);
      final router = GoRouter.of(
        tester.element(find.byType(PlaylistContentScreen)),
      );
      unawaited(router.push<void>('/licenses'));
      await settleContent(tester);
      retained();
      await settleContent(tester);
      expect(f.collection.playbackPlanReadCalls, isEmpty);
      router.pop();
      await settleContent(tester);
      playlistState(tester).controller.refresh();
      await settleContent(tester);
      retained();
      await settleContent(tester);
      expect(f.collection.playbackPlanReadCalls, isEmpty);
      await tapPlayAll(tester);
      final queue = f.graph.playback.state.queue;
      unawaited(router.push<void>('/licenses'));
      await settleContent(tester);
      expect(f.graph.playback.state.queue, same(queue));
      expect(f.engine.calls, isNot(contains('stop')));
      await closePlaylist(tester, f);
      retained();
      expect(f.collection.playbackPlanReadCalls.length, 1);
    },
  );
  for (final key in [LogicalKeyboardKey.enter, LogicalKeyboardKey.space]) {
    testWidgets(
      'Windows ${key.keyLabel} activates the focused playlist action once',
      (tester) async {
        final f = PlaylistContentFixture(count: 5);
        await mountPlaylist(
          tester,
          f,
          platform: YYPlatform.windows,
          size: const Size(1440, 1000),
        );
        final node = Focus.of(
          tester.element(
            find
                .descendant(of: playAllButton(), matching: find.byType(Text))
                .first,
          ),
        );
        node.requestFocus();
        await tester.pumpAndSettle();
        expect(FocusManager.instance.primaryFocus, same(node));
        await tester.sendKeyEvent(key);
        await settleContent(tester);
        expect(f.collection.playbackPlanReadCalls, [f.id]);
        expect(f.engine.calls.where((e) => e == 'play').length, 1);
        expect(f.engine.calls, isNot(contains('pause')));
        expect(tester.takeException(), isNull);
        await closePlaylist(tester, f);
      },
    );
  }
}
