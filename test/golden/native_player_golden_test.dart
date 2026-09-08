import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/app/yy_music_app.dart';
import 'package:yymusic/design_system/yy_theme.dart';

import '../support/close_graph.dart';
import '../support/design_harness.dart';
import '../support/playback_graph_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadDesignAssets);
  for (final (name, platform, size, dark, state) in [
    ('phone_light', YYPlatform.android, const Size(390, 844), false, 'playing'),
    ('phone_empty', YYPlatform.android, const Size(360, 800), true, 'empty'),
    (
      'android_landscape',
      YYPlatform.android,
      const Size(844, 390),
      false,
      'paused',
    ),
    (
      'tablet_portrait',
      YYPlatform.android,
      const Size(800, 1280),
      true,
      'playing',
    ),
    (
      'tablet_landscape',
      YYPlatform.android,
      const Size(1280, 800),
      false,
      'playing',
    ),
    (
      'windows_light',
      YYPlatform.windows,
      const Size(1440, 900),
      false,
      'playing',
    ),
    ('windows_dark', YYPlatform.windows, const Size(1024, 720), true, 'paused'),
    ('windows_error', YYPlatform.windows, const Size(840, 640), false, 'error'),
  ]) {
    testWidgets(
      'independent player $name at 130 percent',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final fixture = PlaybackGraphFixture();
        fixture.graph.appearance
          ..setMode(dark ? YYThemeMode.dark : YYThemeMode.light)
          ..setReduceMotion(true);
        if (state != 'empty') {
          await fixture.queue();
          await fixture.graph.playback.play();
          await fixture.graph.playback.seek(const Duration(seconds: 74));
          if (state == 'playing') await fixture.graph.playback.play();
          if (state == 'error') {
            fixture.engine.loadError = StateError('Test-only failure');
            await fixture.graph.playbackPresenter.next();
          }
        }
        debugDisableShadows = false;
        try {
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                dependencyGraphProvider.overrideWith((ref) {
                  ref.onDispose(fixture.graph.dispose);
                  return fixture.graph;
                }),
              ],
              child: RepaintBoundary(
                key: const ValueKey('native-player-golden'),
                child: YYMusicApp(
                  platform: platform,
                  initialLocation: '/player',
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(const ValueKey('native-player-golden')),
            matchesGoldenFile('baselines/native_player_$name.png'),
          );
        } finally {
          debugDisableShadows = true;
          await tester.pumpWidget(const SizedBox.shrink());
          await closeGraph(tester, fixture.graph);
        }
      },
      skip: !Platform.isWindows,
      tags: ['windows-golden'],
    );
  }
}
