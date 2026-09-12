import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/design_system/yy_player_surface.dart';
import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/features/playlists/common/system_playlist_management_panel.dart';

import '../support/design_harness.dart';
import '../support/native_lyrics_harness.dart';
import '../support/system_playlist_fixture.dart';
import '../support/system_playlist_harness.dart';
import 'system_queue_actions_test.dart' show openSystemQueueMenu;

void main() {
  setUpAll(loadDesignAssets);
  for (final platform in YYPlatform.values) {
    for (final dismissed in [false, true]) {
      for (final type in [
        SystemPlaylistType.favorites,
        SystemPlaylistType.recent,
      ]) {
        testWidgets(
          'covered favorite on $platform $type old callback after dismiss=$dismissed',
          (tester) async {
            final f = SystemPlaylistFixture();
            try {
              await mountSystemPlaylist(
                tester,
                f,
                platform: platform,
                size: const Size(1280, 900),
                type: type,
              );
              await settleLyrics(tester);
              final old = tester
                  .widget<YYDesktopPlayerBar>(find.byType(YYDesktopPlayerBar))
                  .onToggleFavorite!;
              if (type == SystemPlaylistType.favorites) {
                await openSystemQueueMenu(
                  tester,
                  windows: platform == YYPlatform.windows,
                );
              } else {
                await tester.tap(find.text('清除播放历史'));
                await tester.pumpAndSettle();
              }
              if (dismissed) {
                tester
                    .widget<SystemPlaylistManagementPanel>(
                      find.byType(SystemPlaylistManagementPanel),
                    )
                    .onDismiss();
                await settleLyrics(tester);
              }
              old();
              await settleLyrics(tester);
              expect(f.collection.favoriteWriteCount, 0);
              expect(f.graph.playbackFavorite.state.isFavorite, isTrue);
              if (dismissed) {
                tester
                    .widget<YYDesktopPlayerBar>(find.byType(YYDesktopPlayerBar))
                    .onToggleFavorite!();
                await settleLyrics(tester);
                expect(f.collection.favoriteWriteCount, 1);
                expect(f.graph.playbackFavorite.state.isFavorite, isFalse);
              }
              expect(tester.takeException(), isNull);
            } finally {
              await closeSystemPlaylist(tester, f);
            }
          },
        );
      }
    }
  }
}
