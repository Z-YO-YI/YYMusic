import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/design_system/yy_toggle.dart';
import 'package:yymusic/domain/models/appearance_settings.dart';

import '../support/design_harness.dart';
import '../support/fake_appearance_settings_repository.dart';
import '../support/settings_harness.dart';

void main() {
  setUpAll(loadDesignAssets);
  for (final (name, platform, size, mode, accent, state) in const [
    (
      'phone_light',
      YYPlatform.android,
      Size(390, 844),
      AppearanceMode.light,
      AppearanceAccent.coral,
      'data',
    ),
    (
      'phone_dark_amber',
      YYPlatform.android,
      Size(430, 932),
      AppearanceMode.dark,
      AppearanceAccent.amber,
      'data',
    ),
    (
      'phone_reduced_custom',
      YYPlatform.android,
      Size(390, 844),
      AppearanceMode.light,
      AppearanceAccent.custom,
      'bottom',
    ),
    (
      'tablet_portrait_jade',
      YYPlatform.android,
      Size(800, 1280),
      AppearanceMode.light,
      AppearanceAccent.jade,
      'data',
    ),
    (
      'tablet_landscape_cobalt',
      YYPlatform.android,
      Size(1280, 800),
      AppearanceMode.dark,
      AppearanceAccent.cobalt,
      'data',
    ),
    (
      'windows_graphite',
      YYPlatform.windows,
      Size(1440, 900),
      AppearanceMode.light,
      AppearanceAccent.graphite,
      'data',
    ),
    (
      'windows_about',
      YYPlatform.windows,
      Size(1024, 720),
      AppearanceMode.dark,
      AppearanceAccent.custom,
      'about',
    ),
    (
      'phone_load_error',
      YYPlatform.android,
      Size(360, 800),
      AppearanceMode.light,
      AppearanceAccent.coral,
      'error',
    ),
  ]) {
    testWidgets(
      'Phase6J2 settings $name at 130 percent',
      (tester) async {
        final repo = FakeAppearanceSettingsRepository()
          ..stored = AppearanceSettings(
            mode: mode,
            accent: accent,
            customAccent: '#ffee12',
            glassEnabled: state != 'bottom',
            reduceMotion: true,
          );
        if (state == 'error') {
          repo.onRead = () async => throw StateError('fixture-only');
        }
        final graph = DependencyGraph(appearanceRepository: repo);
        debugDisableShadows = false;
        try {
          await mountSettings(tester, graph, size: size, platform: platform);
          if (state == 'about') {
            await tester.tap(
              find.byKey(const ValueKey('settings-section-about')),
            );
            await pumpSettings(tester);
          }
          if (state == 'bottom') {
            await tester.ensureVisible(
              find.byWidgetPredicate(
                (widget) => widget is YYToggle && widget.label == '减少动态效果',
              ),
            );
            await tester.pumpAndSettle();
          }
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(const ValueKey('settings-golden')),
            matchesGoldenFile('baselines/settings_${name}_130.png'),
          );
        } finally {
          debugDisableShadows = true;
          await unmountSettings(tester, graph);
          await repo.dispose();
        }
      },
      skip: !Platform.isWindows,
      tags: ['windows-golden'],
    );
  }
}
