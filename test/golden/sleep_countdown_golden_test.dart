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
    ('tablet_dark', YYPlatform.android, Size(1280, 900), true),
    ('windows_short', YYPlatform.windows, Size(1440, 600), false),
  ]) {
    testWidgets(
      'elapsed sleep countdown $name at 130 percent',
      (tester) async {
        var now = DateTime.utc(2026, 9, 13);
        final f = SleepPanelFixture(clock: () => now);
        f.appearance.setMode(dark ? YYThemeMode.dark : YYThemeMode.light);
        f.playback.setSleepTimer(PlaybackSleepDuration.fifteen);
        debugDisableShadows = false;
        try {
          await mountSleepPanel(tester, f, platform: platform, size: size);
          now = now.add(const Duration(seconds: 61));
          await tester.pump(const Duration(seconds: 1));
          await tester.ensureVisible(find.text('剩余 13:59'));
          await tester.pumpAndSettle();
          expect(find.text('已设置 15 分钟，到期自动暂停'), findsOneWidget);
          expect(find.text('剩余 13:59'), findsOneWidget);
          expect(f.playback.sleepTimer.duration, PlaybackSleepDuration.fifteen);
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(const ValueKey('sleep-golden')),
            matchesGoldenFile('baselines/sleep_countdown_$name.png'),
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
