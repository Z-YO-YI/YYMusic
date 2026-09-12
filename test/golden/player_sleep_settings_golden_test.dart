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
import '../widget/player_sleep_settings_test.dart' show openPlayerSleep;

void main() {
  setUpAll(loadDesignAssets);
  for (final (name, platform, size, dark) in const [
    ('phone', YYPlatform.android, Size(390, 900), false),
    ('phone_landscape', YYPlatform.android, Size(844, 390), false),
    ('tablet_dark', YYPlatform.android, Size(800, 1000), true),
    ('windows', YYPlatform.windows, Size(1440, 1000), false),
  ]) {
    testWidgets(
      'production sleep modal $name at 130 percent',
      (tester) async {
        final f = await mountFullscreenApp(
          tester,
          fullscreen: FakeFullscreenGateway()..supported = false,
          window: FakeWindowGateway(),
          platform: platform,
          size: size,
        );
        f.graph.appearance.setMode(dark ? YYThemeMode.dark : YYThemeMode.light);
        await settleLyrics(tester);
        await openPlayerSleep(tester);
        await tester.ensureVisible(find.byKey(const ValueKey('sleep-thirty')));
        await tester.tap(find.byKey(const ValueKey('sleep-thirty')));
        await settleLyrics(tester);
        expect(
          f.graph.playback.sleepTimer.duration,
          PlaybackSleepDuration.thirty,
        );
        debugDisableShadows = false;
        try {
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(const ValueKey('fullscreen-app')),
            matchesGoldenFile('baselines/player_sleep_modal_$name.png'),
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
