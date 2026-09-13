import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/design_system/yy_theme.dart';

import '../support/design_harness.dart';
import '../support/fake_fullscreen_gateway.dart';
import '../support/fake_window_gateway.dart';
import '../support/fullscreen_app_harness.dart';
import '../support/native_lyrics_harness.dart';

void main() {
  setUpAll(loadDesignAssets);
  for (final (name, platform, size, dark, empty) in const [
    ('windows', YYPlatform.windows, Size(1440, 1000), false, false),
    ('tablet', YYPlatform.android, Size(1280, 900), true, false),
    ('short_empty', YYPlatform.windows, Size(1440, 600), true, true),
  ]) {
    testWidgets(
      'Inspector queue summary $name at 130 percent',
      (tester) async {
        debugDisableShadows = false;
        try {
          final f = await mountFullscreenApp(
            tester,
            fullscreen: FakeFullscreenGateway()..supported = false,
            window: FakeWindowGateway(),
            platform: platform,
            size: size,
            route: '/home',
          );
          f.graph.appearance.setReduceMotion(true);
          f.graph.appearance.setMode(
            dark ? YYThemeMode.dark : YYThemeMode.light,
          );
          if (empty) await tester.runAsync(f.graph.queue.clear);
          await settleLyrics(tester);
          await tester.ensureVisible(
            find.byKey(const ValueKey('inspector-open-queue')),
          );
          await settleLyrics(tester);
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(const ValueKey('fullscreen-app')),
            matchesGoldenFile('baselines/inspector_queue_$name.png'),
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
