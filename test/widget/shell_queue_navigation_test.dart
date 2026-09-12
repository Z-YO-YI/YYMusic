import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/app_routes.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/features/playlists/common/system_playlist_management_panel.dart';
import 'package:yymusic/features/queue/common/queue_screen.dart';

import '../support/design_harness.dart';
import '../support/native_lyrics_harness.dart';
import '../support/system_playlist_fixture.dart';
import '../support/system_playlist_harness.dart';
import 'shell_favorite_test.dart' show favoriteBar, shellNavigation;
import 'system_queue_actions_test.dart' show openSystemQueueMenu;

void main() {
  setUpAll(loadDesignAssets);
  for (final platform in YYPlatform.values) {
    for (final count in [0, 5]) {
      testWidgets('shell queue on $platform with $count entries', (
        tester,
      ) async {
        final f = SystemPlaylistFixture(count: count);
        try {
          await mountSystemPlaylist(
            tester,
            f,
            platform: platform,
            size: const Size(1280, 900),
            location: '/home',
          );
          await settleLyrics(tester);
          final root = f.graph.playback.state.queue;
          final audio = List.of(f.engine.calls);
          final navigation = shellNavigation(tester);
          final old = favoriteBar(tester).onOpenQueue!;
          await tester.tap(
            find.byKey(const ValueKey('player-control-desktop-queue')),
          );
          old();
          await settleLyrics(tester);
          expect(find.byType(QueueScreen), findsOneWidget);
          expect(f.graph.playback.state.queue, same(root));
          expect(f.engine.calls, audio);
          navigation.back();
          await settleLyrics(tester);
          expect(find.byType(QueueScreen), findsNothing);
          old();
          await settleLyrics(tester);
          expect(find.byType(QueueScreen), findsNothing);
          favoriteBar(tester).onOpenQueue!();
          await settleLyrics(tester);
          expect(find.byType(QueueScreen), findsOneWidget);
          expect(tester.takeException(), isNull);
        } finally {
          await closeSystemPlaylist(tester, f);
        }
      });
    }
    testWidgets('inline menu revokes shell queue on $platform', (tester) async {
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
        final old = favoriteBar(tester).onOpenQueue!;
        await openSystemQueueMenu(
          tester,
          windows: platform == YYPlatform.windows,
        );
        old();
        await settleLyrics(tester);
        expect(find.byType(QueueScreen), findsNothing);
        tester
            .widget<SystemPlaylistManagementPanel>(
              find.byType(SystemPlaylistManagementPanel),
            )
            .onDismiss();
        await settleLyrics(tester);
        old();
        await settleLyrics(tester);
        expect(find.byType(QueueScreen), findsNothing);
        favoriteBar(tester).onOpenQueue!();
        await settleLyrics(tester);
        expect(find.byType(QueueScreen), findsOneWidget);
      } finally {
        await closeSystemPlaylist(tester, f);
      }
    });
  }
  for (final revoke in [
    'navigation',
    'away-back',
    'cover',
    'resize',
    'zero',
    'dispose',
  ]) {
    testWidgets('retained queue navigation revoked by $revoke', (tester) async {
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
        final old = favoriteBar(tester).onOpenQueue!;
        final navigation = shellNavigation(tester);
        switch (revoke) {
          case 'navigation':
            navigation.goTo(AppRoute.library);
          case 'away-back':
            navigation.goTo(AppRoute.library);
            await settleLyrics(tester);
            navigation.goTo(AppRoute.home);
          case 'cover':
            navigation.openPlayer();
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
        expect(find.byType(QueueScreen), findsNothing);
        expect(tester.takeException(), isNull);
      } finally {
        await closeSystemPlaylist(tester, f);
      }
    });
  }
}
