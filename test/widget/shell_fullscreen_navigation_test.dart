import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/app_routes.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/features/player/common/player_screen.dart';
import 'package:yymusic/features/playlists/common/system_playlist_management_panel.dart';

import '../support/design_harness.dart';
import '../support/fake_fullscreen_gateway.dart';
import '../support/fake_window_gateway.dart';
import '../support/fullscreen_app_harness.dart';
import '../support/native_lyrics_harness.dart';
import '../support/system_playlist_fixture.dart';
import '../support/system_playlist_harness.dart';
import 'shell_favorite_test.dart' show favoriteBar, shellNavigation;
import 'system_queue_actions_test.dart' show openSystemQueueMenu;

void main() {
  setUpAll(loadDesignAssets);
  for (final platform in YYPlatform.values) {
    for (final supported in [true, false]) {
      testWidgets('shell fullscreen $platform supported=$supported', (
        tester,
      ) async {
        final native = FakeFullscreenGateway()..supported = supported;
        final f = await mountFullscreenApp(
          tester,
          fullscreen: native,
          window: FakeWindowGateway(),
          platform: platform,
          size: const Size(1280, 900),
          route: '/home',
        );
        final queue = f.graph.playback.state.queue;
        final audio = List.of(f.engine.calls);
        final navigation = shellNavigation(tester);
        final old = favoriteBar(tester).onOpenFullscreen!;
        await tester.tap(
          find.byKey(const ValueKey('player-control-desktop-fullscreen')),
        );
        old();
        await settleLyrics(tester);
        expect(find.byType(PlayerScreen), findsOneWidget);
        expect(native.enabled, supported);
        expect(
          native.calls.where((c) => c == 'enter').length,
          supported ? 1 : 0,
        );
        expect(f.graph.playback.state.queue, same(queue));
        expect(f.engine.calls, audio);
        navigation.back();
        await settleLyrics(tester);
        expect(find.byType(PlayerScreen), findsNothing);
        expect(native.enabled, isFalse);
        old();
        await settleLyrics(tester);
        expect(find.byType(PlayerScreen), findsNothing);
        favoriteBar(tester).onOpenFullscreen!();
        await settleLyrics(tester);
        expect(find.byType(PlayerScreen), findsOneWidget);
        expect(
          native.calls.where((c) => c == 'enter').length,
          supported ? 2 : 0,
        );
        expect(tester.takeException(), isNull);
      });
    }
    testWidgets('menu revokes shell fullscreen on $platform', (tester) async {
      final f = SystemPlaylistFixture();
      try {
        await mountSystemPlaylist(
          tester,
          f,
          platform: platform,
          size: const Size(1280, 900),
          location: '/system-playlist?type=favorites',
        );
        await settleLyrics(tester);
        final old = favoriteBar(tester).onOpenFullscreen!;
        await openSystemQueueMenu(
          tester,
          windows: platform == YYPlatform.windows,
        );
        old();
        await settleLyrics(tester);
        expect(find.byType(PlayerScreen), findsNothing);
        tester
            .widget<SystemPlaylistManagementPanel>(
              find.byType(SystemPlaylistManagementPanel),
            )
            .onDismiss();
        await settleLyrics(tester);
        old();
        await settleLyrics(tester);
        expect(find.byType(PlayerScreen), findsNothing);
        favoriteBar(tester).onOpenFullscreen!();
        await settleLyrics(tester);
        expect(find.byType(PlayerScreen), findsOneWidget);
      } finally {
        await closeSystemPlaylist(tester, f);
      }
    });
  }
  testWidgets('shell fullscreen native failure preserves playback and page', (
    tester,
  ) async {
    final native = FakeFullscreenGateway()..failEnter = true;
    final f = await mountFullscreenApp(
      tester,
      fullscreen: native,
      window: FakeWindowGateway(),
      route: '/home',
    );
    final audio = List.of(f.engine.calls);
    favoriteBar(tester).onOpenFullscreen!();
    await settleLyrics(tester);
    expect(find.byType(PlayerScreen), findsOneWidget);
    expect(native.enabled, isFalse);
    expect(native.calls.where((c) => c == 'enter'), hasLength(1));
    expect(f.engine.calls, audio);
    expect(find.text('全屏操作未完成。播放不受影响，请恢复系统显示后重试。'), findsOneWidget);
    expect(find.textContaining('private diagnostic'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  for (final revoke in [
    'navigation',
    'away-back',
    'cover',
    'resize',
    'zero',
    'dispose',
  ]) {
    testWidgets('old fullscreen callback revoked by $revoke', (tester) async {
      final f = SystemPlaylistFixture();
      try {
        await mountSystemPlaylist(
          tester,
          f,
          platform: YYPlatform.windows,
          size: const Size(1280, 900),
          location: '/home',
        );
        await settleLyrics(tester);
        final old = favoriteBar(tester).onOpenFullscreen!;
        final navigation = shellNavigation(tester);
        switch (revoke) {
          case 'navigation':
            navigation.goTo(AppRoute.library);
          case 'away-back':
            navigation.goTo(AppRoute.library);
            await settleLyrics(tester);
            navigation.goTo(AppRoute.home);
          case 'cover':
            navigation.openLyrics();
          case 'resize':
            tester.view.physicalSize = const Size(1300, 900);
          case 'zero':
            tester.view.physicalSize = Size.zero;
          case 'dispose':
            await tester.pumpWidget(const SizedBox.shrink());
        }
        await settleLyrics(tester);
        old();
        await settleLyrics(tester);
        expect(find.byType(PlayerScreen), findsNothing);
        expect(tester.takeException(), isNull);
      } finally {
        await closeSystemPlaylist(tester, f);
      }
    });
  }
}
