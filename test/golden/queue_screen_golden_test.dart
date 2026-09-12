import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/design_system/yy_theme.dart';

import '../support/design_harness.dart';
import '../support/system_playlist_fixture.dart';
import '../support/system_playlist_harness.dart';

void main() {
  setUpAll(loadDesignAssets);
  for (final (name, platform, size, dark, count, confirm, error) in const [
    ('phone_360', YYPlatform.android, Size(360, 800), false, 5, false, false),
    (
      'phone_390_dark',
      YYPlatform.android,
      Size(390, 844),
      true,
      5,
      false,
      false,
    ),
    ('phone_430', YYPlatform.android, Size(430, 932), false, 5, false, false),
    (
      'phone_landscape',
      YYPlatform.android,
      Size(568, 320),
      false,
      5,
      false,
      false,
    ),
    (
      'tablet_portrait',
      YYPlatform.android,
      Size(800, 1280),
      false,
      5,
      false,
      false,
    ),
    (
      'tablet_landscape',
      YYPlatform.android,
      Size(1280, 800),
      true,
      5,
      false,
      false,
    ),
    (
      'windows_expanded',
      YYPlatform.windows,
      Size(1440, 900),
      false,
      5,
      false,
      false,
    ),
    (
      'windows_standard',
      YYPlatform.windows,
      Size(1024, 720),
      true,
      5,
      false,
      false,
    ),
    ('phone_empty', YYPlatform.android, Size(390, 844), false, 0, false, false),
    ('phone_error', YYPlatform.android, Size(390, 844), true, 5, false, true),
    (
      'phone_confirm',
      YYPlatform.android,
      Size(360, 800),
      false,
      5,
      true,
      false,
    ),
    (
      'windows_confirm',
      YYPlatform.windows,
      Size(1024, 720),
      true,
      5,
      true,
      false,
    ),
  ]) {
    testWidgets(
      'Phase7E3 queue $name at 130 percent',
      (tester) async {
        final f = SystemPlaylistFixture(count: count);
        f.graph.appearance.setMode(dark ? YYThemeMode.dark : YYThemeMode.light);
        if (error) {
          f.collection.systemReader = (_, _) async =>
              throw StateError('private-marker');
        }
        debugDisableShadows = false;
        try {
          await mountSystemPlaylist(
            tester,
            f,
            location: '/queue',
            platform: platform,
            size: size,
          );
          if (confirm) {
            await tester.tap(find.text('清空'));
            await tester.pumpAndSettle();
          }
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(const ValueKey('system-playlist-golden')),
            matchesGoldenFile('baselines/queue_$name.png'),
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
