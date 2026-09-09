import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/layout_class.dart';

import '../support/design_harness.dart';
import '../support/fake_fullscreen_gateway.dart';
import '../support/fake_window_gateway.dart';
import '../support/fullscreen_app_harness.dart';
import '../support/native_lyrics_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadDesignAssets);
  for (final (name, platform, size, route, state) in const [
    (
      'windows_player',
      YYPlatform.windows,
      Size(1440, 900),
      '/player',
      'active',
    ),
    (
      'windows_lyrics',
      YYPlatform.windows,
      Size(1024, 720),
      '/lyrics',
      'active',
    ),
    (
      'windows_windowed',
      YYPlatform.windows,
      Size(840, 640),
      '/lyrics',
      'windowed',
    ),
    ('phone_lyrics', YYPlatform.android, Size(390, 844), '/lyrics', 'active'),
    (
      'phone_landscape',
      YYPlatform.android,
      Size(590, 360),
      '/player',
      'active',
    ),
    ('tablet_lyrics', YYPlatform.android, Size(1280, 800), '/lyrics', 'active'),
    ('tablet_player', YYPlatform.android, Size(800, 1280), '/player', 'active'),
    (
      'windows_recovery',
      YYPlatform.windows,
      Size(840, 640),
      '/lyrics',
      'error',
    ),
  ]) {
    testWidgets(
      'native fullscreen integration $name at 130 percent',
      (tester) async {
        debugDisableShadows = false;
        try {
          final native = FakeFullscreenGateway();
          await mountFullscreenApp(
            tester,
            fullscreen: native,
            window: platform == YYPlatform.windows ? FakeWindowGateway() : null,
            platform: platform,
            size: size,
            route: route,
          );
          if (platform == YYPlatform.windows && state != 'windowed') {
            await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
            await settleLyrics(tester);
          }
          if (state == 'error') {
            native.failRestore = true;
            await tester.sendKeyEvent(LogicalKeyboardKey.escape);
            await settleLyrics(tester);
          }
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(const ValueKey('fullscreen-app')),
            matchesGoldenFile('baselines/fullscreen_$name.png'),
          );
          native.failRestore = false;
        } finally {
          debugDisableShadows = true;
        }
      },
      skip: !Platform.isWindows,
      tags: ['windows-golden'],
    );
  }
}
