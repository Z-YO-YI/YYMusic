import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/app_routes.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/design_system/yy_theme.dart';

import '../support/design_harness.dart';
import '../support/fake_playback_continuation_repository.dart';
import '../support/settings_harness.dart';

void main() {
  setUpAll(loadDesignAssets);
  for (final (name, platform, size, failed) in const [
    ('phone', YYPlatform.android, Size(390, 844), false),
    ('tablet_dark', YYPlatform.android, Size(1280, 800), false),
    ('windows_error', YYPlatform.windows, Size(1024, 720), true),
  ]) {
    testWidgets(
      'continuation settings $name at 130 percent',
      (tester) async {
        final repo = FakePlaybackContinuationRepository()..stored = false;
        if (failed) repo.readError = StateError('fixture');
        final graph = DependencyGraph(continuationRepository: repo);
        graph.viewState.select(AppRoute.settings, 'playback');
        if (name == 'tablet_dark') graph.appearance.setMode(YYThemeMode.dark);
        debugDisableShadows = false;
        try {
          await mountSettings(tester, graph, platform: platform, size: size);
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(const ValueKey('settings-golden')),
            matchesGoldenFile('baselines/continuation_settings_$name.png'),
          );
        } finally {
          debugDisableShadows = true;
          await unmountSettings(tester, graph);
        }
      },
      skip: !Platform.isWindows,
      tags: ['windows-golden'],
    );
  }
}
