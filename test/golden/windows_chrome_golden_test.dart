import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/app/yy_music_app.dart';
import 'package:yymusic/design_system/yy_theme.dart';

import '../support/design_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadDesignAssets);

  for (final fixture in const [
    _WindowsFixture(
      name: 'expanded_light_coral_1440x900_130',
      size: Size(1440, 900),
      mode: YYThemeMode.light,
      accent: '#FF3B5C',
    ),
    _WindowsFixture(
      name: 'standard_dark_jade_1024x720_130',
      size: Size(1024, 720),
      mode: YYThemeMode.dark,
      accent: '#00A67E',
    ),
    _WindowsFixture(
      name: 'narrow_light_white_840x640_130_reduced',
      size: Size(840, 640),
      mode: YYThemeMode.light,
      accent: '#FFFFFF',
      reduced: true,
    ),
  ]) {
    testWidgets(
      'real Windows shell ${fixture.name}',
      (tester) async {
        tester.view.physicalSize = fixture.size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        final graph = DependencyGraph();
        graph.appearance
          ..setMode(fixture.mode)
          ..setCustomAccent(fixture.accent)
          ..setReduceGlass(fixture.reduced)
          ..setReduceMotion(true);
        debugDisableShadows = false;
        try {
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                dependencyGraphProvider.overrideWith((ref) {
                  ref.onDispose(graph.dispose);
                  return graph;
                }),
              ],
              child: const RepaintBoundary(
                key: ValueKey('windows-app'),
                child: YYMusicApp(platform: YYPlatform.windows),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(const ValueKey('windows-app')),
            matchesGoldenFile('baselines/windows_${fixture.name}.png'),
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

class _WindowsFixture {
  const _WindowsFixture({
    required this.name,
    required this.size,
    required this.mode,
    required this.accent,
    this.reduced = false,
  });

  final String name;
  final Size size;
  final YYThemeMode mode;
  final String accent;
  final bool reduced;
}
