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
import '../support/home_graph_fixture.dart';

void main() {
  setUpAll(loadDesignAssets);
  for (final (name, platform, size, dark, empty, offset) in const [
    ('phone_light', YYPlatform.android, Size(390, 1000), false, false, 0.0),
    ('phone_empty', YYPlatform.android, Size(390, 844), false, true, 0.0),
    (
      'tablet_portrait_dark',
      YYPlatform.android,
      Size(800, 1200),
      true,
      false,
      0.0,
    ),
    (
      'tablet_landscape_sources',
      YYPlatform.android,
      Size(1024, 768),
      false,
      false,
      640.0,
    ),
    ('windows_dark', YYPlatform.windows, Size(1440, 1000), true, false, 0.0),
    (
      'windows_narrow_sources',
      YYPlatform.windows,
      Size(840, 900),
      false,
      false,
      640.0,
    ),
  ]) {
    testWidgets(
      'Phase6B Home $name with native widgets at 130 percent',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final fixture = HomeGraphFixture(empty: empty);
        fixture.graph.appearance
          ..setMode(dark ? YYThemeMode.dark : YYThemeMode.light)
          ..setReduceMotion(true);
        await fixture.initialize(source: !empty);
        debugDisableShadows = false;
        try {
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                dependencyGraphProvider.overrideWithValue(fixture.graph),
              ],
              child: RepaintBoundary(
                key: const ValueKey('home-golden'),
                child: YYMusicApp(platform: platform),
              ),
            ),
          );
          await tester.pumpAndSettle();
          if (offset > 0) {
            final scroll = tester.widget<SingleChildScrollView>(
              find.byKey(const ValueKey('screen-home')),
            );
            scroll.controller!.jumpTo(offset);
            await tester.pumpAndSettle();
          }
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(const ValueKey('home-golden')),
            matchesGoldenFile('baselines/home_$name.png'),
          );
        } finally {
          debugDisableShadows = true;
          await tester.pumpWidget(const SizedBox.shrink());
          await closeGraph(tester, fixture.graph);
          await tester.runAsync(fixture.disposeFakes);
        }
      },
      skip: !Platform.isWindows,
      tags: ['windows-golden'],
    );
  }
}
