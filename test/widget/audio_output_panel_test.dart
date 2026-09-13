import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/design_system/yy_button.dart';
import 'package:yymusic/platform/audio_output/audio_output_controller.dart';
import 'package:yymusic/platform/contracts/audio_output_gateway.dart';

import '../support/close_audio_output.dart';
import '../support/design_harness.dart';
import '../support/fake_audio_output_gateway.dart';
import '../support/sleep_panel_harness.dart';

void main() {
  setUpAll(loadDesignAssets);
  late FakeAudioOutputGateway gateway;
  late AudioOutputController output;
  late SleepPanelFixture fixture;

  Future<void> mount(WidgetTester tester, AudioOutputSnapshot snapshot) async {
    gateway = FakeAudioOutputGateway()..onRead = () async => snapshot;
    output = AudioOutputController(gateway);
    await output.initialize();
    fixture = SleepPanelFixture(output: output);
    await mountSleepPanel(tester, fixture);
  }

  Future<void> close(WidgetTester tester) async {
    await closeSleepPanel(tester, fixture);
    await closeAudioOutput(tester, output, gateway);
  }

  const unknown = AudioOutputSnapshot(
    route: AudioOutputRoute.unknown(),
    canOpenSettings: true,
  );
  for (final (platform, size) in const [
    (YYPlatform.android, Size(320, 568)),
    (YYPlatform.windows, Size(1000, 500)),
  ]) {
    testWidgets(
      '$platform long output label keeps lower sleep choices reachable',
      (tester) async {
        await mount(
          tester,
          AudioOutputSnapshot(
            route: AudioOutputRoute.systemDefault(List.filled(128, '音').join()),
            canOpenSettings: true,
          ),
        );
        await mountSleepPanel(tester, fixture, platform: platform, size: size);
        await tester.ensureVisible(
          find.byKey(const ValueKey('sleep-currentEntry')),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('sleep-currentEntry')).hitTestable(),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('sleep-done')).hitTestable(),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await close(tester);
      },
    );
  }
  for (final route in [
    const AudioOutputRoute.unknown(),
    AudioOutputRoute.systemDefault('USB 音频输出'),
    AudioOutputRoute.playerRoute('有线耳机'),
  ]) {
    testWidgets(
      'panel describes ${route.observation.name} without simulated switching',
      (tester) async {
        await mount(
          tester,
          AudioOutputSnapshot(route: route, canOpenSettings: true),
        );
        expect(find.text(route.label ?? '暂时无法确认当前输出'), findsOneWidget);
        expect(find.text('蓝牙耳机'), findsNothing);
        expect(
          find.byKey(const ValueKey('audio-output-source')),
          findsOneWidget,
        );
        expect(gateway.calls, ['initialize']);
        await close(tester);
      },
    );
  }

  testWidgets('unavailable settings is disabled with explicit explanation', (
    tester,
  ) async {
    await mount(tester, const AudioOutputSnapshot.unavailable());
    expect(
      tester
          .widget<YYButton>(find.byKey(const ValueKey('audio-output-settings')))
          .onPressed,
      isNull,
    );
    expect(find.text('此环境无法打开系统声音设置。'), findsOneWidget);
    await close(tester);
  });

  testWidgets(
    'actual button opens settings without changing route or playback',
    (tester) async {
      await mount(tester, unknown);
      await tester.tap(find.byKey(const ValueKey('audio-output-settings')));
      await tester.pumpAndSettle();
      expect(gateway.calls, ['initialize', 'open']);
      expect(find.textContaining('已请求打开系统设置'), findsOneWidget);
      expect(output.snapshot, unknown);
      expect(fixture.engine.calls, isEmpty);
      await close(tester);
    },
  );

  testWidgets('native failure is safe and button allows retry', (tester) async {
    await mount(tester, unknown);
    gateway.onOpen = () async => throw StateError('private-output-detail');
    await tester.tap(find.byKey(const ValueKey('audio-output-settings')));
    await tester.pumpAndSettle();
    expect(find.textContaining('未能打开系统设置'), findsOneWidget);
    expect(find.textContaining('private-output-detail'), findsNothing);
    gateway.onOpen = null;
    await tester.tap(find.byKey(const ValueKey('audio-output-settings')));
    await tester.pumpAndSettle();
    expect(gateway.calls, ['initialize', 'open', 'open']);
    await close(tester);
  });

  testWidgets('revoked owner rejects a retained settings callback', (
    tester,
  ) async {
    await mount(tester, unknown);
    final old = tester
        .widget<YYButton>(find.byKey(const ValueKey('audio-output-settings')))
        .onPressed!;
    fixture.current = false;
    old();
    await tester.pumpAndSettle();
    expect(gateway.calls, ['initialize']);
    await close(tester);
  });

  testWidgets(
    'hidden surface rejects callback retained before cover and uncover',
    (tester) async {
      await mount(tester, unknown);
      final old = tester
          .widget<YYButton>(find.byKey(const ValueKey('audio-output-settings')))
          .onPressed!;
      await mountSleepPanel(tester, fixture, tickersEnabled: false);
      old();
      await tester.pumpAndSettle();
      await mountSleepPanel(tester, fixture);
      old();
      await tester.pumpAndSettle();
      expect(gateway.calls, ['initialize']);
      await close(tester);
    },
  );

  testWidgets(
    'slow launch disables repeats and late result cannot update a closed panel',
    (tester) async {
      await mount(tester, unknown);
      final gate = Completer<AudioOutputSettingsResult>();
      gateway.onOpen = () => gate.future;
      final old = tester
          .widget<YYButton>(find.byKey(const ValueKey('audio-output-settings')))
          .onPressed!;
      old();
      await tester.pump();
      expect(
        tester
            .widget<YYButton>(
              find.byKey(const ValueKey('audio-output-settings')),
            )
            .loading,
        isTrue,
      );
      old();
      await tester.pump();
      expect(gateway.calls, ['initialize', 'open']);
      fixture.current = false;
      await tester.pumpWidget(const SizedBox.shrink());
      gate.complete(AudioOutputSettingsResult.opened);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await close(tester);
    },
  );
}
