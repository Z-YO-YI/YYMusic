import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/design_system/yy_theme.dart';

import '../support/design_harness.dart';
import '../support/fake_window_gateway.dart';
import '../support/playback_graph_fixture.dart';
import '../support/window_app_harness.dart';

void main() {
  setUpAll(loadDesignAssets);
  for (final (name, size, route, mode) in const [
    ('home_light', Size(1440, 900), '/home', YYThemeMode.light),
    ('licenses_dark', Size(840, 640), '/settings/licenses', YYThemeMode.dark),
  ]) {
    testWidgets(
      'Phase5C root window chrome $name at 130 percent',
      (tester) async {
        final fixture = PlaybackGraphFixture();
        final window = FakeWindowGateway();
        fixture.graph.appearance
          ..setMode(mode)
          ..setReduceMotion(true);
        debugDisableShadows = false;
        try {
          await mountWindowApp(
            tester,
            fixture,
            window,
            size: size,
            route: route,
          );
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(const ValueKey('window-app')),
            matchesGoldenFile('baselines/window_app_${name}_130.png'),
          );
        } finally {
          debugDisableShadows = true;
          await closeWindowApp(tester, fixture, window);
        }
      },
      skip: !Platform.isWindows,
      tags: ['windows-golden'],
    );
  }
}
