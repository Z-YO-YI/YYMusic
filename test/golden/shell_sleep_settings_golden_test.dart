import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/design_system/yy_theme.dart';
import 'package:yymusic/playback/playback_sleep_timer_state.dart';

import '../support/design_harness.dart';
import '../support/fake_fullscreen_gateway.dart';
import '../support/fake_window_gateway.dart';
import '../support/fullscreen_app_harness.dart';
import '../support/native_lyrics_harness.dart';
import '../widget/shell_sleep_settings_test.dart' show openShellSleep;

void main() {
  setUpAll(loadDesignAssets);
  for (final (name, platform, size, dark, route) in const [
    ('windows', YYPlatform.windows, Size(1440, 1000), false, '/home'),
    ('tablet_dark', YYPlatform.android, Size(1280, 900), true, '/home'),
    (
      'system_queue',
      YYPlatform.windows,
      Size(1440, 1000),
      true,
      '/system-playlist?type=queue',
    ),
  ]) {
    testWidgets(
      'production shell sleep modal $name at 130 percent',
      (tester) async {
        final f = await mountFullscreenApp(
          tester,
          playbackClock: () => DateTime.utc(2026, 9, 13),
          fullscreen: FakeFullscreenGateway()..supported = false,
          window: FakeWindowGateway(),
          platform: platform,
          size: size,
          route: route,
        );
        f.graph.appearance.setMode(dark ? YYThemeMode.dark : YYThemeMode.light);
        f.graph.appearance.setReduceMotion(true);
        await settleLyrics(tester);
        await openShellSleep(tester);
        await tester.tap(find.byKey(const ValueKey('sleep-sixty')));
        await settleLyrics(tester);
        expect(
          f.graph.playback.sleepTimer.duration,
          PlaybackSleepDuration.sixty,
        );
        debugDisableShadows = false;
        try {
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(const ValueKey('fullscreen-app')),
            matchesGoldenFile('baselines/shell_sleep_modal_$name.png'),
          );
        } finally {
          debugDisableShadows = true;
        }
      },
      skip: !Platform.isWindows,
      tags: ['windows-golden'],
    );
  }
}
