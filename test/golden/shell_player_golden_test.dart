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
  for (final (name, platform, size, mode, accent) in const [
    (
      'phone_light',
      YYPlatform.android,
      Size(390, 844),
      YYThemeMode.light,
      '#FF3B5C',
    ),
    (
      'tablet_dark',
      YYPlatform.android,
      Size(1024, 768),
      YYThemeMode.dark,
      '#00A67E',
    ),
    (
      'windows_white',
      YYPlatform.windows,
      Size(1440, 900),
      YYThemeMode.light,
      '#FFFFFF',
    ),
  ]) {
    testWidgets(
      'Phase5A playing shell $name at 130 percent',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final fixture = PlaybackGraphFixture();
        fixture.graph.appearance
          ..setMode(mode)
          ..setCustomAccent(accent)
          ..setReduceMotion(true);
        await fixture.queue();
        await fixture.graph.playbackPresenter.togglePlayback();
        // Deterministic fake-engine state, never a native playback claim.
        await fixture.graph.playback.seek(const Duration(seconds: 74));
        await fixture.graph.playback.play();
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
                key: const ValueKey('playing-shell'),
                child: YYMusicApp(platform: platform),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(const ValueKey('playing-shell')),
            matchesGoldenFile('baselines/shell_player_${name}_130.png'),
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
