import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/app_routes.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/design_system/yy_button.dart';
import 'package:yymusic/design_system/yy_player_surface.dart';
import 'package:yymusic/features/lyrics/common/lyrics_screen.dart';
import 'package:yymusic/features/player/common/player_screen.dart';
import 'package:yymusic/features/playlists/common/system_playlist_management_panel.dart';

import '../support/design_harness.dart';
import '../support/fake_fullscreen_gateway.dart';
import '../support/fake_window_gateway.dart';
import '../support/fullscreen_app_harness.dart';
import '../support/native_lyrics_harness.dart';
import '../support/system_playlist_fixture.dart';
import '../support/system_playlist_harness.dart';
import 'shell_favorite_test.dart' show shellNavigation;
import 'system_queue_actions_test.dart' show openSystemQueueMenu;

YYNowPlayingInspector inspector(WidgetTester tester) =>
    tester.widget<YYNowPlayingInspector>(find.byType(YYNowPlayingInspector));
VoidCallback action(WidgetTester tester, bool lyrics) => lyrics
    ? inspector(tester).onOpenLyrics!
    : inspector(tester).onOpenFullscreen!;
Finder destination(bool lyrics) =>
    find.byType(lyrics ? LyricsScreen : PlayerScreen);

void main() {
  setUpAll(loadDesignAssets);
  for (final platform in YYPlatform.values) {
    for (final lyrics in [false, true]) {
      testWidgets('inspector $platform lyrics=$lyrics preserves root', (
        tester,
      ) async {
        final native = FakeFullscreenGateway();
        final f = await mountFullscreenApp(
          tester,
          fullscreen: native,
          window: FakeWindowGateway(),
          platform: platform,
          size: const Size(1440, 1000),
          route: '/home',
        );
        final queue = f.graph.playback.state.queue;
        final audio = List.of(f.engine.calls);
        final navigation = shellNavigation(tester);
        final old = action(tester, lyrics);
        final button = find.descendant(
          of: find.byType(YYNowPlayingInspector),
          matching: find.byWidgetPredicate(
            (w) => w is YYButton && w.label == (lyrics ? '全屏歌词' : '全屏播放'),
          ),
        );
        await tester.ensureVisible(button);
        await tester.tap(button);
        old();
        await settleLyrics(tester);
        expect(destination(lyrics), findsOneWidget);
        expect(native.enabled, !lyrics || platform == YYPlatform.android);
        expect(f.graph.playback.state.queue, same(queue));
        expect(f.engine.calls, audio);
        navigation.back();
        await settleLyrics(tester);
        expect(destination(lyrics), findsNothing);
        expect(native.enabled, isFalse);
        old();
        await settleLyrics(tester);
        expect(destination(lyrics), findsNothing);
        action(tester, lyrics)();
        await settleLyrics(tester);
        expect(destination(lyrics), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
      testWidgets('inspector menu revokes $platform lyrics=$lyrics', (
        tester,
      ) async {
        final f = SystemPlaylistFixture();
        try {
          await mountSystemPlaylist(
            tester,
            f,
            platform: platform,
            size: const Size(1440, 1000),
            location: '/system-playlist?type=favorites',
          );
          await settleLyrics(tester);
          final old = action(tester, lyrics);
          await openSystemQueueMenu(
            tester,
            windows: platform == YYPlatform.windows,
          );
          old();
          await settleLyrics(tester);
          expect(destination(lyrics), findsNothing);
          tester
              .widget<SystemPlaylistManagementPanel>(
                find.byType(SystemPlaylistManagementPanel),
              )
              .onDismiss();
          await settleLyrics(tester);
          old();
          await settleLyrics(tester);
          expect(destination(lyrics), findsNothing);
          action(tester, lyrics)();
          await settleLyrics(tester);
          expect(destination(lyrics), findsOneWidget);
        } finally {
          await closeSystemPlaylist(tester, f);
        }
      });
    }
    testWidgets('empty inspector on $platform cannot open lyrics', (
      tester,
    ) async {
      final f = SystemPlaylistFixture(count: 0);
      try {
        await mountSystemPlaylist(
          tester,
          f,
          platform: platform,
          size: const Size(1440, 1000),
          location: '/home',
        );
        await settleLyrics(tester);
        expect(inspector(tester).onOpenLyrics, isNull);
        action(tester, false)();
        await settleLyrics(tester);
        expect(find.byType(PlayerScreen), findsOneWidget);
      } finally {
        await closeSystemPlaylist(tester, f);
      }
    });
  }
  for (final lyrics in [false, true]) {
    for (final revoke in [
      'navigation',
      'away-back',
      'hidden',
      'zero',
      'dispose',
    ]) {
      testWidgets('old inspector lyrics=$lyrics revoked by $revoke', (
        tester,
      ) async {
        final f = SystemPlaylistFixture();
        try {
          await mountSystemPlaylist(
            tester,
            f,
            platform: YYPlatform.windows,
            size: const Size(1440, 1000),
            location: '/home',
          );
          await settleLyrics(tester);
          final old = action(tester, lyrics);
          final navigation = shellNavigation(tester);
          switch (revoke) {
            case 'navigation':
              navigation.goTo(AppRoute.library);
            case 'away-back':
              navigation.goTo(AppRoute.library);
              await settleLyrics(tester);
              navigation.goTo(AppRoute.home);
            case 'hidden':
              tester.view.physicalSize = const Size(1040, 900);
            case 'zero':
              tester.view.physicalSize = Size.zero;
            case 'dispose':
              await tester.pumpWidget(const SizedBox.shrink());
          }
          await settleLyrics(tester);
          old();
          await settleLyrics(tester);
          expect(destination(lyrics), findsNothing);
          expect(tester.takeException(), isNull);
        } finally {
          await closeSystemPlaylist(tester, f);
        }
      });
    }
  }
}
