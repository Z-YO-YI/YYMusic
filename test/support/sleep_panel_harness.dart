import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/app/playback_presenter.dart';
import 'package:yymusic/design_system/yy_theme.dart';
import 'package:yymusic/domain/repositories/sleep_timer_repository.dart';
import 'package:yymusic/features/player/common/sleep_settings_panel.dart';
import 'package:yymusic/platform/audio_output/audio_output_controller.dart';
import 'package:yymusic/playback/playback_controller.dart';
import 'package:yymusic/playback/sleep_persistence_controller.dart';

import 'design_harness.dart';
import 'fake_audio_engine.dart';
import 'fake_domain_repositories.dart';
import 'fake_playback_dependencies.dart';

final class SleepPanelFixture {
  SleepPanelFixture({
    bool schedulerFails = false,
    DateTime Function()? clock,
    SleepTimerRepository? repository,
    AudioOutputController? output,
  }) {
    playback = PlaybackController(
      engine,
      library: library,
      sourceResolver: FakePlaybackSourceResolver(),
      clock: clock ?? () => DateTime.utc(2026, 9, 13),
      sleepScheduler: schedulerFails
          ? (_, _) => throw StateError('private-scheduler-detail')
          : null,
    );
    if (repository != null) {
      persistence = SleepPersistenceController(
        playback: playback,
        repository: repository,
      );
    }
    presenter = PlaybackPresenter(
      playback,
      sleepPersistence: persistence,
      audioOutput: output,
    );
  }
  final engine = FakeAudioEngine();
  final library = FakeLibraryRepository(tracks: [playbackFixtureTrack]);
  final appearance = YYAppearanceController()..setReduceMotion(true);
  late final PlaybackController playback;
  late final PlaybackPresenter presenter;
  SleepPersistenceController? persistence;
  bool current = true;
  int closes = 0;

  Future<void> start() async {
    await playback.replaceQueue([playbackFixtureEntry()]);
    await playback.play();
    engine.calls.clear();
  }

  Future<void> close() async {
    presenter.dispose();
    await persistence?.close();
    await playback.close();
    await engine.dispose();
    await library.dispose();
    appearance.dispose();
  }
}

Future<void> mountSleepPanel(
  WidgetTester tester,
  SleepPanelFixture f, {
  YYPlatform platform = YYPlatform.android,
  Size size = const Size(390, 900),
  bool tickersEnabled = true,
  bool focusable = true,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  await tester.pumpWidget(
    designHarness(
      TickerMode(
        enabled: tickersEnabled,
        child: Focus(
          descendantsAreFocusable: focusable,
          child: RepaintBoundary(
            key: const ValueKey('sleep-golden'),
            child: Builder(
              builder: (context) => ColoredBox(
                color: YYTheme.of(context).colors.base,
                child: SleepSettingsPanel(
                  presenter: f.presenter,
                  platform: platform,
                  isCurrent: () => f.current,
                  onClose: () => f.closes++,
                ),
              ),
            ),
          ),
        ),
      ),
      appearance: f.appearance,
      scale: 1.3,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> closeSleepPanel(WidgetTester tester, SleepPanelFixture f) async {
  await tester.pumpWidget(const SizedBox.shrink());
  var closed = false;
  final closing = f.close().then((_) => closed = true);
  for (var i = 0; i < 12 && !closed; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(Duration.zero);
  }
  expect(closed, isTrue, reason: 'Sleep fixture shutdown must drain');
  await closing;
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
}
