import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/design_system/yy_theme.dart';
import 'package:yymusic/features/local_music/common/local_music_controller.dart';

import '../support/design_harness.dart';
import '../support/local_music_harness.dart';
import '../support/local_music_probe.dart';
import '../unit/local_library_overview_test.dart' show localTrack;

void main() {
  setUpAll(loadDesignAssets);
  for (final (name, platform, size, dark, state) in const [
    ('phone_empty', YYPlatform.android, Size(390, 1000), false, 'empty'),
    ('phone_data', YYPlatform.android, Size(430, 1200), false, 'data'),
    ('tablet_landscape', YYPlatform.android, Size(1024, 768), true, 'data'),
    ('tablet_portrait', YYPlatform.android, Size(800, 1280), false, 'data'),
    ('windows', YYPlatform.windows, Size(1440, 900), true, 'data'),
    ('windows_error', YYPlatform.windows, Size(840, 640), false, 'error'),
  ]) {
    testWidgets(
      'Phase6I2 native local music $name',
      (tester) async {
        final probe = LocalMusicProbe();
        if (state == 'data') {
          probe.data.tracks.addAll([localTrack('a'), localTrack('b')]);
          probe.data.folders.addAll([
            localFolder(0),
            localFolder(1, enabled: false),
          ]);
        }
        if (state == 'error') {
          probe.onRead = (_, _) async => throw StateError('fixture-only');
        }
        final controller = LocalMusicController(repository: probe);
        final appearance = YYAppearanceController()
          ..setMode(dark ? YYThemeMode.dark : YYThemeMode.light);
        addTearDown(appearance.dispose);
        debugDisableShadows = false;
        try {
          await mountLocalPanel(
            tester,
            controller,
            platform: platform,
            size: size,
            appearance: appearance,
          );
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(const ValueKey('local-music-golden')),
            matchesGoldenFile('baselines/local_music_$name.png'),
          );
        } finally {
          debugDisableShadows = true;
          await unmountLocalPanel(tester, controller);
          await probe.close();
        }
      },
      skip: !Platform.isWindows,
      tags: ['windows-golden'],
    );
  }
}
