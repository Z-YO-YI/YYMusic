import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/design_system/yy_theme.dart';

import '../support/design_harness.dart';
import '../support/playlist_content_fixture.dart';
import '../support/playlist_content_harness.dart';

void main() {
  setUpAll(loadDesignAssets);
  for (final (name, platform, size, dark, menu) in const [
    ('phone', YYPlatform.android, Size(390, 1000), false, false),
    ('phone_menu', YYPlatform.android, Size(390, 1000), false, true),
    ('tablet_portrait', YYPlatform.android, Size(800, 1100), true, false),
    ('tablet_landscape', YYPlatform.android, Size(1024, 768), false, false),
    ('windows_dark', YYPlatform.windows, Size(1440, 1000), true, false),
  ]) {
    testWidgets(
      'Phase6H5 playlist content $name at 130 percent',
      (tester) async {
        final f = PlaylistContentFixture(count: 5);
        f.graph.appearance.setMode(dark ? YYThemeMode.dark : YYThemeMode.light);
        debugDisableShadows = false;
        try {
          await mountPlaylist(tester, f, platform: platform, size: size);
          if (menu) await openEntryMenu(tester, 'e-3');
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(const ValueKey('playlist-golden')),
            matchesGoldenFile('baselines/playlist_content_$name.png'),
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
