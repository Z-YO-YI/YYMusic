import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/design_system/yy_theme.dart';
import 'package:yymusic/platform/audio_output/audio_output_controller.dart';
import 'package:yymusic/platform/contracts/audio_output_gateway.dart';

import '../support/close_audio_output.dart';
import '../support/design_harness.dart';
import '../support/fake_audio_output_gateway.dart';
import '../support/sleep_panel_harness.dart';

void main() {
  setUpAll(loadDesignAssets);
  for (final (name, platform, size, dark) in const [
    ('phone_unknown', YYPlatform.android, Size(390, 900), false),
    ('tablet_default', YYPlatform.android, Size(1280, 900), true),
    ('windows_unavailable', YYPlatform.windows, Size(1440, 650), false),
  ]) {
    testWidgets(
      'audio output $name at 130 percent',
      (tester) async {
        final snapshot = name == 'windows_unavailable'
            ? const AudioOutputSnapshot.unavailable()
            : AudioOutputSnapshot(
                route: name == 'phone_unknown'
                    ? const AudioOutputRoute.unknown()
                    : AudioOutputRoute.systemDefault('USB 音频输出 · 外接数字音频设备'),
                canOpenSettings: true,
              );
        final gateway = FakeAudioOutputGateway()..onRead = () async => snapshot;
        final output = AudioOutputController(gateway);
        await output.initialize();
        final fixture = SleepPanelFixture(output: output);
        fixture.appearance.setMode(dark ? YYThemeMode.dark : YYThemeMode.light);
        debugDisableShadows = false;
        try {
          await mountSleepPanel(
            tester,
            fixture,
            platform: platform,
            size: size,
          );
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(const ValueKey('sleep-golden')),
            matchesGoldenFile('baselines/audio_output_$name.png'),
          );
        } finally {
          debugDisableShadows = true;
          await closeSleepPanel(tester, fixture);
          await closeAudioOutput(tester, output, gateway);
        }
      },
      skip: !Platform.isWindows,
      tags: ['windows-golden'],
    );
  }
}
