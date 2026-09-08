import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/design_system/yy_theme.dart';
import 'package:yymusic/domain/models/collection_models.dart';

import '../support/design_harness.dart';
import '../support/system_playlist_fixture.dart';
import '../support/system_playlist_harness.dart';
import '../widget/system_playlist_management_screen_test.dart'
    show openSystemFavoriteMenu;

void main() {
  setUpAll(loadDesignAssets);
  for (final (name, platform, size, dark, clear) in const [
    ('phone_menu', YYPlatform.android, Size(390, 1000), false, false),
    ('phone_clear', YYPlatform.android, Size(390, 1000), false, true),
    ('tablet_clear', YYPlatform.android, Size(1024, 768), true, true),
    ('windows_menu', YYPlatform.windows, Size(1440, 1000), true, false),
    ('windows_clear', YYPlatform.windows, Size(1440, 1000), true, true),
  ]) {
    testWidgets(
      'Phase6H14 native system management $name',
      (tester) async {
        final f = SystemPlaylistFixture();
        f.graph.appearance.setMode(dark ? YYThemeMode.dark : YYThemeMode.light);
        debugDisableShadows = false;
        try {
          await mountSystemPlaylist(
            tester,
            f,
            platform: platform,
            size: size,
            type: clear
                ? SystemPlaylistType.recent
                : SystemPlaylistType.favorites,
          );
          if (clear) {
            await tester.tap(find.text('清除播放历史'));
            await tester.pumpAndSettle();
          } else {
            await openSystemFavoriteMenu(tester, f);
          }
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(const ValueKey('system-playlist-golden')),
            matchesGoldenFile('baselines/system_management_$name.png'),
          );
        } finally {
          debugDisableShadows = true;
          await closeSystemPlaylist(tester, f);
        }
      },
      skip: !Platform.isWindows,
      tags: ['windows-golden'],
    );
  }
}
