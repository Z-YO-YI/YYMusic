import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/design_system/yy_theme.dart';
import 'package:yymusic/playback/playback_sleep_timer_state.dart';

import '../support/design_harness.dart';
import '../support/sleep_panel_harness.dart';

void main() {
  setUpAll(loadDesignAssets);
  for (final (name, platform, size, dark) in const [
    ('phone', YYPlatform.android, Size(390, 900), false),
    ('phone_dark', YYPlatform.android, Size(360, 800), true),
    ('phone_landscape', YYPlatform.android, Size(844, 390), false),
    ('tablet_dark', YYPlatform.android, Size(800, 1000), true),
    ('windows', YYPlatform.windows, Size(1440, 1000), false),
    ('windows_failure', YYPlatform.windows, Size(780, 620), true),
  ]) {
    testWidgets(
      'native sleep settings $name at 130 percent',
      (tester) async {
        final f = SleepPanelFixture(schedulerFails: name.endsWith('failure'));
        f.appearance.setMode(dark ? YYThemeMode.dark : YYThemeMode.light);
        await f.start();
        if (name.contains('landscape') || name.contains('tablet')) {
          f.playback.setSleepAtCurrentEntryEnd();
        } else if (name != 'phone') {
          f.playback.setSleepTimer(PlaybackSleepDuration.thirty);
        }
        debugDisableShadows = false;
        try {
          await mountSleepPanel(tester, f, platform: platform, size: size);
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(const ValueKey('sleep-golden')),
            matchesGoldenFile('baselines/sleep_settings_$name.png'),
          );
        } finally {
          debugDisableShadows = true;
          await closeSleepPanel(tester, f);
        }
      },
      skip: !Platform.isWindows,
      tags: ['windows-golden'],
    );
  }
}
