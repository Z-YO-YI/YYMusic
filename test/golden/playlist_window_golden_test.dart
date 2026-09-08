import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/design_system/yy_theme.dart';

import '../support/design_harness.dart';
import '../support/playlist_content_fixture.dart';
import '../support/playlist_content_harness.dart';
import '../widget/playlist_window_navigation_test.dart'
    show expandPlaylistWindow, tapWindow;

void main() {
  setUpAll(loadDesignAssets);
  for (final (name, platform, size, dark) in const [
    ('phone', YYPlatform.android, Size(390, 1000), false),
    ('tablet_dark', YYPlatform.android, Size(1024, 768), true),
    ('windows', YYPlatform.windows, Size(1440, 1000), false),
  ]) {
    testWidgets(
      'Phase6H8 later playlist window $name at 130 percent',
      (tester) async {
        final f = PlaylistContentFixture(count: 405);
        f.graph.appearance.setMode(dark ? YYThemeMode.dark : YYThemeMode.light);
        debugDisableShadows = false;
        try {
          await mountPlaylist(tester, f, platform: platform, size: size);
          await expandPlaylistWindow(tester);
          await tapWindow(tester, 'next');
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(const ValueKey('playlist-golden')),
            matchesGoldenFile('baselines/playlist_window_$name.png'),
          );
        } finally {
          debugDisableShadows = true;
          await closePlaylist(tester, f);
        }
      },
      skip: !Platform.isWindows,
      tags: ['windows-golden'],
    );
  }
}
