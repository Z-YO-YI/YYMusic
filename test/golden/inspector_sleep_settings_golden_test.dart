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
import '../widget/inspector_sleep_settings_test.dart' show openInspectorSleep;

void main() {
  setUpAll(loadDesignAssets);
  for (final (name, platform, size, dark, quick) in const [
    ('windows', YYPlatform.windows, Size(1440, 1000), false, false),
    ('tablet_dark', YYPlatform.android, Size(1280, 900), true, true),
    ('windows_short', YYPlatform.windows, Size(1440, 600), true, true),
  ]) {
    testWidgets(
      'production Inspector sleep $name at 130 percent',
      (tester) async {
        // Set the paint policy before mounting: changing this global only at
        // capture time leaves cached background rows with stale shadow paint.
        debugDisableShadows = false;
        addTearDown(() => debugDisableShadows = true);
        final f = await mountFullscreenApp(
          tester,
          playbackClock: () => DateTime.utc(2026, 9, 13),
          fullscreen: FakeFullscreenGateway()..supported = false,
          window: FakeWindowGateway(),
          platform: platform,
          size: size,
          route: '/home',
        );
        f.graph.appearance.setReduceMotion(true);
        f.graph.appearance.setMode(dark ? YYThemeMode.dark : YYThemeMode.light);
        await settleLyrics(tester);
        await openInspectorSleep(tester, quick: quick);
        await tester.ensureVisible(find.byKey(const ValueKey('sleep-fifteen')));
        await tester.tap(find.byKey(const ValueKey('sleep-fifteen')));
        await settleLyrics(tester);
        expect(
          f.graph.playback.sleepTimer.duration,
          PlaybackSleepDuration.fifteen,
        );
        debugDisableShadows = false;
        try {
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(const ValueKey('fullscreen-app')),
            matchesGoldenFile('baselines/inspector_sleep_modal_$name.png'),
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
