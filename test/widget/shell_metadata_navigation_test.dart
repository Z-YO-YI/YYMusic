import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/app_routes.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/design_system/yy_player_surface.dart';
import 'package:yymusic/features/lyrics/common/lyrics_screen.dart';
import 'package:yymusic/features/player/common/player_screen.dart';
import 'package:yymusic/features/playlists/common/system_playlist_management_panel.dart';

import '../support/design_harness.dart';
import '../support/native_lyrics_harness.dart';
import '../support/system_playlist_fixture.dart';
import '../support/system_playlist_harness.dart';
import 'shell_favorite_test.dart' show shellNavigation;
import 'system_queue_actions_test.dart' show openSystemQueueMenu;

VoidCallback metadataAction(WidgetTester tester, bool phone, bool lyrics) {
  if (phone) {
    final bar = tester.widget<YYMiniPlayer>(find.byType(YYMiniPlayer));
    return (lyrics ? bar.onOpenLyrics : bar.onOpen)!;
  }
  final bar = tester.widget<YYDesktopPlayerBar>(
    find.byType(YYDesktopPlayerBar),
  );
  return (lyrics ? bar.onOpenLyrics : bar.onOpen)!;
}

void main() {
  setUpAll(loadDesignAssets);
  for (final (platform, phone, size) in [
    (YYPlatform.android, true, const Size(390, 1000)),
    (YYPlatform.android, false, const Size(1280, 900)),
    (YYPlatform.windows, false, const Size(1440, 1000)),
  ]) {
    for (final lyrics in [false, true]) {
      for (final scenario in ['return', 'cover', 'menu']) {
        testWidgets(
          'metadata $platform phone=$phone lyrics=$lyrics $scenario',
          (tester) async {
            final f = SystemPlaylistFixture();
            try {
              await mountSystemPlaylist(
                tester,
                f,
                platform: platform,
                size: size,
                location: scenario == 'menu'
                    ? '/system-playlist?type=favorites'
                    : '/home',
              );
              await settleLyrics(tester);
              final old = metadataAction(tester, phone, lyrics);
              final navigation = shellNavigation(tester);
              final queue = f.graph.playback.state.queue;
              final audio = List.of(f.engine.calls);
              final page = find.byType(lyrics ? LyricsScreen : PlayerScreen);
              switch (scenario) {
                case 'return':
                  final track = find.byKey(
                    ValueKey(
                      phone ? 'mini-player-track' : 'desktop-player-track',
                    ),
                  );
                  if (lyrics) {
                    await tester.longPress(track);
                  } else {
                    await tester.tap(track);
                  }
                  old();
                  await settleLyrics(tester);
                  expect(page, findsOneWidget);
                  navigation.back();
                  await settleLyrics(tester);
                case 'cover':
                  if (lyrics) {
                    navigation.openPlayer();
                  } else {
                    navigation.openLyrics();
                  }
                  await settleLyrics(tester);
                case 'menu':
                  await openSystemQueueMenu(
                    tester,
                    windows: platform == YYPlatform.windows,
                  );
                  old();
                  await settleLyrics(tester);
                  expect(page, findsNothing);
                  tester
                      .widget<SystemPlaylistManagementPanel>(
                        find.byType(SystemPlaylistManagementPanel),
                      )
                      .onDismiss();
                  await settleLyrics(tester);
              }
              old();
              await settleLyrics(tester);
              expect(page, findsNothing);
              if (scenario != 'cover') {
                metadataAction(tester, phone, lyrics)();
                await settleLyrics(tester);
                expect(page, findsOneWidget);
              }
              expect(f.graph.playback.state.queue, same(queue));
              expect(f.engine.calls, audio);
              expect(tester.takeException(), isNull);
            } finally {
              await closeSystemPlaylist(tester, f);
            }
          },
        );
      }
    }
  }
  for (final phone in [true, false]) {
    for (final lyrics in [true, false]) {
      testWidgets('old metadata phone=$phone lyrics=$lyrics after navigation', (
        tester,
      ) async {
        final f = SystemPlaylistFixture();
        try {
          await mountSystemPlaylist(
            tester,
            f,
            platform: phone ? YYPlatform.android : YYPlatform.windows,
            size: phone ? const Size(390, 1000) : const Size(1440, 1000),
            location: '/home',
          );
          await settleLyrics(tester);
          final old = metadataAction(tester, phone, lyrics);
          shellNavigation(tester).goTo(AppRoute.library);
          await settleLyrics(tester);
          old();
          await settleLyrics(tester);
          expect(
            find.byType(lyrics ? LyricsScreen : PlayerScreen),
            findsNothing,
          );
        } finally {
          await closeSystemPlaylist(tester, f);
        }
      });
    }
  }
}
