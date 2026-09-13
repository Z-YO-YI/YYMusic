import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/design_system/yy_theme.dart';

import '../support/design_harness.dart';
import '../support/fake_sleep_timer_repository.dart';
import '../support/sleep_panel_harness.dart';
import '../support/sleep_persistence_panel_harness.dart';

void main() {
  setUpAll(loadDesignAssets);
  for (final (name, platform, size, state, dark) in const [
    ('phone_restored', YYPlatform.android, Size(390, 900), 'restored', false),
    (
      'tablet_save_failure',
      YYPlatform.android,
      Size(1280, 900),
      'save-failure',
      true,
    ),
    (
      'windows_load_failure',
      YYPlatform.windows,
      Size(1440, 650),
      'load-failure',
      false,
    ),
  ]) {
    testWidgets(
      'sleep persistence $name at 130 percent',
      (tester) async {
        final repo = FakeSleepTimerRepository();
        final f = await persistentSleepFixture(tester, repo, state: state);
        f.appearance.setMode(dark ? YYThemeMode.dark : YYThemeMode.light);
        debugDisableShadows = false;
        try {
          await mountSleepPanel(tester, f, platform: platform, size: size);
          await tester.ensureVisible(
            find.byKey(const ValueKey('sleep-persistence-status')),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(const ValueKey('sleep-golden')),
            matchesGoldenFile('baselines/sleep_persistence_$name.png'),
          );
        } finally {
          debugDisableShadows = true;
          await closePersistentSleepPanel(tester, f, repo);
        }
      },
      skip: !Platform.isWindows,
      tags: ['windows-golden'],
    );
  }
}
