import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/app_routes.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/design_system/yy_button.dart';
import 'package:yymusic/design_system/yy_option_card.dart';
import 'package:yymusic/design_system/yy_theme.dart';
import 'package:yymusic/features/lyrics/common/lyrics_screen.dart';
import 'package:yymusic/features/player/common/player_screen.dart';
import 'package:yymusic/features/player/common/sleep_settings_panel.dart';
import 'package:yymusic/playback/playback_sleep_timer_state.dart';

import '../support/design_harness.dart';
import '../support/native_lyrics_harness.dart';

Future<void> openPlayerSleep(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('player-page-settings')));
  await settleLyrics(tester);
  expect(find.byType(SleepSettingsPanel), findsOneWidget);
}

void main() {
  setUpAll(loadDesignAssets);
  testWidgets('keyboard entry, Space option and close restore original focus', (
    tester,
  ) async {
    final f = await mountLyrics(
      tester,
      platform: YYPlatform.windows,
      size: const Size(1280, 900),
      route: '/player',
    );
    for (var i = 0; i < 20; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await settleLyrics(tester);
      if (FocusManager.instance.primaryFocus?.context
              ?.findAncestorWidgetOfExactType<YYButton>()
              ?.key ==
          const ValueKey('player-page-settings')) {
        break;
      }
    }
    expect(
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<YYButton>()
          ?.key,
      const ValueKey('player-page-settings'),
    );
    final previous = FocusManager.instance.primaryFocus;
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await settleLyrics(tester);
    expect(find.byType(SleepSettingsPanel), findsOneWidget);
    for (var i = 0; i < 10; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await settleLyrics(tester);
      if (FocusManager.instance.primaryFocus?.context
              ?.findAncestorWidgetOfExactType<YYOptionCard>()
              ?.title ==
          '15 分钟') {
        break;
      }
    }
    expect(
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<YYOptionCard>()
          ?.title,
      '15 分钟',
    );
    final audio = List.of(f.engine.calls);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await settleLyrics(tester);
    expect(f.graph.playback.sleepTimer.duration, PlaybackSleepDuration.fifteen);
    expect(f.engine.calls, audio);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await settleLyrics(tester);
    expect(FocusManager.instance.primaryFocus, same(previous));
  });

  testWidgets(
    'track switch invalidates old option and fresh option binds new entry',
    (tester) async {
      final f = await mountLyrics(tester, route: '/player');
      await openPlayerSleep(tester);
      final old = tester
          .widget<YYOptionCard>(
            find.byKey(const ValueKey('sleep-currentEntry')),
          )
          .onPressed!;
      await tester.runAsync(f.graph.playback.skipNext);
      await settleLyrics(tester);
      old();
      expect(f.graph.playback.sleepTimer.phase, PlaybackSleepPhase.off);
      await tester.tap(find.byKey(const ValueKey('sleep-currentEntry')));
      await settleLyrics(tester);
      expect(f.graph.playback.sleepTimer.entryId, 'entry-1');
    },
  );
  for (final (name, platform, size) in const [
    ('phone', YYPlatform.android, Size(390, 900)),
    ('tablet', YYPlatform.android, Size(800, 1000)),
    ('windows', YYPlatform.windows, Size(1440, 1000)),
  ]) {
    testWidgets(
      '$name production settings changes root and closes without pause',
      (tester) async {
        final f = await mountLyrics(
          tester,
          platform: platform,
          size: size,
          route: '/player',
        );
        final queue = f.graph.playback.state.queue;
        final calls = List.of(f.engine.calls);
        final oldOpen = tester
            .widget<YYButton>(
              find.byKey(const ValueKey('player-page-settings')),
            )
            .onPressed!;
        oldOpen();
        oldOpen();
        await settleLyrics(tester);
        expect(find.byType(SleepSettingsPanel), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('sleep-thirty')));
        await settleLyrics(tester);
        expect(
          f.graph.playback.sleepTimer.duration,
          PlaybackSleepDuration.thirty,
        );
        final oldSelect = tester
            .widget<YYOptionCard>(find.byKey(const ValueKey('sleep-sixty')))
            .onPressed!;
        final oldClose = tester
            .widget<YYButton>(find.byKey(const ValueKey('sleep-done')))
            .onPressed!;
        await tester.tap(find.byKey(const ValueKey('sleep-done')));
        await settleLyrics(tester);
        expect(find.byType(SleepSettingsPanel), findsNothing);
        expect(find.byType(PlayerScreen), findsOneWidget);
        oldOpen();
        oldSelect();
        oldClose();
        await settleLyrics(tester);
        expect(find.byType(SleepSettingsPanel), findsNothing);
        expect(
          f.graph.playback.sleepTimer.duration,
          PlaybackSleepDuration.thirty,
        );
        expect(f.graph.playback.state.queue, same(queue));
        expect(f.engine.calls, calls);
        await openPlayerSleep(tester);
        expect(
          tester
              .widget<YYOptionCard>(find.byKey(const ValueKey('sleep-thirty')))
              .selected,
          isTrue,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('$name route change removes only the owned modal', (
      tester,
    ) async {
      final f = await mountLyrics(
        tester,
        platform: platform,
        size: size,
        route: '/player',
      );
      final navigation = tester
          .widget<PlayerScreen>(find.byType(PlayerScreen))
          .navigation;
      await openPlayerSleep(tester);
      final oldClose = tester
          .widget<YYButton>(find.byKey(const ValueKey('sleep-done')))
          .onPressed!;
      final oldSelect = tester
          .widget<YYOptionCard>(
            find.byKey(const ValueKey('sleep-currentEntry')),
          )
          .onPressed!;
      navigation.openLyrics();
      await settleLyrics(tester);
      expect(find.byType(SleepSettingsPanel), findsNothing);
      expect(find.byType(LyricsScreen), findsOneWidget);
      oldClose();
      oldSelect();
      await settleLyrics(tester);
      expect(find.byType(LyricsScreen), findsOneWidget);
      expect(f.graph.playback.sleepTimer.phase, PlaybackSleepPhase.off);
      expect(tester.takeException(), isNull);
    });
  }

  for (final close in ['barrier', 'escape', 'back', 'system']) {
    testWidgets('$close closes settings before the player page', (
      tester,
    ) async {
      final f = await mountLyrics(
        tester,
        platform: YYPlatform.windows,
        size: const Size(1280, 900),
        route: '/player',
      );
      final navigation = tester
          .widget<PlayerScreen>(find.byType(PlayerScreen))
          .navigation;
      await openPlayerSleep(tester);
      await tester.tap(find.byKey(const ValueKey('sleep-fifteen')));
      await settleLyrics(tester);
      switch (close) {
        case 'barrier':
          await tester.tapAt(const Offset(5, 150));
        case 'escape':
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        case 'back':
          navigation.back();
        case 'system':
          await tester.binding.handlePopRoute();
      }
      await settleLyrics(tester);
      expect(find.byType(SleepSettingsPanel), findsNothing);
      expect(find.byType(PlayerScreen), findsOneWidget);
      expect(
        f.graph.playback.sleepTimer.duration,
        PlaybackSleepDuration.fifteen,
      );
    });
  }

  testWidgets(
    'main navigation revokes settings before a delayed close can act',
    (tester) async {
      final f = await mountLyrics(tester, route: '/player');
      final navigation = tester
          .widget<PlayerScreen>(find.byType(PlayerScreen))
          .navigation;
      await openPlayerSleep(tester);
      final old = tester
          .widget<YYButton>(find.byKey(const ValueKey('sleep-done')))
          .onPressed!;
      navigation.goTo(AppRoute.library);
      await settleLyrics(tester);
      old();
      await settleLyrics(tester);
      expect(find.byType(SleepSettingsPanel), findsNothing);
      expect(find.byType(PlayerScreen), findsNothing);
      expect(f.graph.playback.sleepTimer.phase, PlaybackSleepPhase.off);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('empty queue opens settings and refuses current entry only', (
    tester,
  ) async {
    final f = await mountLyrics(tester, route: '/player', empty: true);
    await openPlayerSleep(tester);
    expect(
      tester
          .widget<YYOptionCard>(
            find.byKey(const ValueKey('sleep-currentEntry')),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.byKey(const ValueKey('sleep-sixty')));
    await settleLyrics(tester);
    expect(f.graph.playback.sleepTimer.duration, PlaybackSleepDuration.sixty);
  });

  testWidgets('theme and viewport changes flow through the real modal', (
    tester,
  ) async {
    final f = await mountLyrics(
      tester,
      platform: YYPlatform.android,
      route: '/player',
    );
    await openPlayerSleep(tester);
    f.graph.appearance.setMode(YYThemeMode.dark);
    tester.view.physicalSize = const Size(1000, 800);
    await settleLyrics(tester);
    expect(find.byKey(const ValueKey('yy-dialog')), findsOneWidget);
    final context = tester.element(find.byType(SleepSettingsPanel));
    expect(
      YYTheme.of(context).colors.base,
      f.graph.appearance.resolve(Brightness.light).colors.base,
    );
    await tester.tap(find.byKey(const ValueKey('sleep-currentEntry')));
    await settleLyrics(tester);
    expect(f.graph.playback.sleepTimer.entryId, 'entry-0');
  });

  testWidgets('unhandled Space in the modal never toggles underlying audio', (
    tester,
  ) async {
    final f = await mountLyrics(
      tester,
      platform: YYPlatform.windows,
      size: const Size(1280, 900),
      route: '/player',
    );
    await openPlayerSleep(tester);
    final before = List.of(f.engine.calls);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await settleLyrics(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await settleLyrics(tester);
    expect(f.engine.calls, before);
  });

  testWidgets('unmount while modal is open leaves callbacks inert', (
    tester,
  ) async {
    final f = await mountLyrics(tester, route: '/player');
    await openPlayerSleep(tester);
    final old = tester
        .widget<YYOptionCard>(find.byKey(const ValueKey('sleep-thirty')))
        .onPressed!;
    await tester.pumpWidget(const SizedBox.shrink());
    await settleLyrics(tester);
    old();
    expect(f.graph.playback.sleepTimer.phase, PlaybackSleepPhase.off);
    expect(tester.takeException(), isNull);
  });
}
