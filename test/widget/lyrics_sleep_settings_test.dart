import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/app_routes.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/design_system/yy_button.dart';
import 'package:yymusic/design_system/yy_option_card.dart';
import 'package:yymusic/features/lyrics/common/lyrics_screen.dart';
import 'package:yymusic/features/lyrics/common/lyrics_viewport.dart';
import 'package:yymusic/features/player/common/player_screen.dart';
import 'package:yymusic/features/player/common/sleep_settings_panel.dart';
import 'package:yymusic/playback/playback_sleep_timer_state.dart';

import '../support/design_harness.dart';
import '../support/fake_fullscreen_gateway.dart';
import '../support/fullscreen_app_harness.dart';
import '../support/native_lyrics_harness.dart';
import 'player_sleep_settings_test.dart' show openPlayerSleep;

Future<void> openLyricsSleep(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('lyrics-page-settings')));
  await settleLyrics(tester);
  expect(find.byType(SleepSettingsPanel), findsOneWidget);
}

VoidCallback option(WidgetTester tester, String name) =>
    tester.widget<YYOptionCard>(find.byKey(ValueKey('sleep-$name'))).onPressed!;

void main() {
  setUpAll(loadDesignAssets);
  testWidgets(
    'narrow fullscreen header retains readable metadata and translation',
    (tester) async {
      await mountFullscreenApp(
        tester,
        platform: YYPlatform.android,
        size: const Size(360, 800),
        route: '/lyrics',
        fullscreen: FakeFullscreenGateway(),
      );
      final metadata = find
          .descendant(
            of: find.byType(LyricsScreen),
            matching: find.text('Test-only same title'),
          )
          .first;
      expect(tester.getSize(metadata).width, greaterThanOrEqualTo(70));
      final settings = find.byKey(const ValueKey('lyrics-page-settings'));
      final translation = find.byKey(const ValueKey('lyrics-translation'));
      expect(
        tester.getTopLeft(translation).dy,
        greaterThan(tester.getTopLeft(settings).dy),
      );
      await tester.tap(translation);
      await settleLyrics(tester);
      expect(
        tester
            .widget<LyricsViewport>(find.byType(LyricsViewport))
            .showTranslation,
        isFalse,
      );
      await openLyricsSleep(tester);
      expect(tester.takeException(), isNull);
    },
  );
  for (final (name, platform, size) in const [
    ('phone', YYPlatform.android, Size(390, 900)),
    ('tablet', YYPlatform.android, Size(800, 1000)),
    ('windows', YYPlatform.windows, Size(1440, 1000)),
  ]) {
    testWidgets('$name lyrics settings uses five real choices and one modal', (
      tester,
    ) async {
      final f = await mountLyrics(tester, platform: platform, size: size);
      final calls = List.of(f.engine.calls);
      final queue = f.graph.playback.state.queue;
      final oldOpen = tester
          .widget<YYButton>(find.byKey(const ValueKey('lyrics-page-settings')))
          .onPressed!;
      oldOpen();
      oldOpen();
      await settleLyrics(tester);
      expect(find.byType(SleepSettingsPanel), findsOneWidget);
      for (final (choice, duration) in [
        ('fifteen', PlaybackSleepDuration.fifteen),
        ('thirty', PlaybackSleepDuration.thirty),
        ('sixty', PlaybackSleepDuration.sixty),
      ]) {
        await tester.tap(find.byKey(ValueKey('sleep-$choice')));
        await settleLyrics(tester);
        expect(f.graph.playback.sleepTimer.duration, duration);
      }
      await tester.tap(find.byKey(const ValueKey('sleep-currentEntry')));
      await settleLyrics(tester);
      expect(f.graph.playback.sleepTimer.entryId, 'entry-0');
      await tester.tap(find.byKey(const ValueKey('sleep-off')));
      await settleLyrics(tester);
      expect(f.graph.playback.sleepTimer.phase, PlaybackSleepPhase.off);
      final oldSelect = option(tester, 'thirty');
      await tester.tap(find.byKey(const ValueKey('sleep-done')));
      await settleLyrics(tester);
      oldOpen();
      oldSelect();
      await settleLyrics(tester);
      expect(find.byType(SleepSettingsPanel), findsNothing);
      expect(find.byType(LyricsScreen), findsOneWidget);
      expect(f.graph.playback.sleepTimer.phase, PlaybackSleepPhase.off);
      expect(f.graph.playback.state.queue, same(queue));
      expect(f.engine.calls, calls);
    });

    testWidgets('$name lyrics to player keeps timer and rejects former owner', (
      tester,
    ) async {
      final f = await mountLyrics(tester, platform: platform, size: size);
      final lyrics = tester.widget<LyricsScreen>(find.byType(LyricsScreen));
      final rawOldOwner = lyrics.onOpenSettings!;
      await openLyricsSleep(tester);
      option(tester, 'thirty')();
      await settleLyrics(tester);
      final oldSelect = option(tester, 'sixty');
      final oldClose = tester
          .widget<YYButton>(find.byKey(const ValueKey('sleep-done')))
          .onPressed!;
      lyrics.navigation.openPlayer();
      await settleLyrics(tester);
      rawOldOwner();
      oldSelect();
      oldClose();
      await settleLyrics(tester);
      expect(find.byType(PlayerScreen), findsOneWidget);
      expect(find.byType(SleepSettingsPanel), findsNothing);
      expect(
        f.graph.playback.sleepTimer.duration,
        PlaybackSleepDuration.thirty,
      );
      await openPlayerSleep(tester);
      expect(
        tester
            .widget<YYOptionCard>(find.byKey(const ValueKey('sleep-thirty')))
            .selected,
        isTrue,
      );
      oldClose();
      await settleLyrics(tester);
      expect(find.byType(SleepSettingsPanel), findsOneWidget);
    });
  }

  for (final close in ['barrier', 'escape', 'back', 'system']) {
    testWidgets('$close closes lyrics settings without leaving lyrics', (
      tester,
    ) async {
      final f = await mountLyrics(
        tester,
        platform: YYPlatform.windows,
        size: const Size(1280, 900),
      );
      final navigation = tester
          .widget<LyricsScreen>(find.byType(LyricsScreen))
          .navigation;
      await openLyricsSleep(tester);
      option(tester, 'fifteen')();
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
      expect(find.byType(LyricsScreen), findsOneWidget);
      expect(
        f.graph.playback.sleepTimer.duration,
        PlaybackSleepDuration.fifteen,
      );
    });
  }

  testWidgets('covered lyrics revokes old seek even after modal closes', (
    tester,
  ) async {
    final f = await mountLyrics(tester);
    final oldSeek = tester
        .widget<LyricsViewport>(find.byType(LyricsViewport))
        .onSeek!;
    await openLyricsSleep(tester);
    final calls = List.of(f.engine.calls);
    oldSeek(0);
    await settleLyrics(tester);
    expect(f.engine.calls, calls);
    expect(f.graph.lyricsController.isActive, isFalse);
    expect(find.byType(LyricsViewport, skipOffstage: false), findsNothing);
    await tester.tap(find.byKey(const ValueKey('sleep-done')));
    await settleLyrics(tester);
    oldSeek(0);
    await settleLyrics(tester);
    expect(f.engine.calls, calls);
    final restored = tester.widget<LyricsViewport>(find.byType(LyricsViewport));
    expect(restored.active, isTrue);
    restored.onSeek!(0);
    await settleLyrics(tester);
    expect(f.engine.calls.length, greaterThan(calls.length));
  });

  testWidgets('player owner cannot open a lyrics modal after navigation', (
    tester,
  ) async {
    await mountLyrics(tester, route: '/player');
    final player = tester.widget<PlayerScreen>(find.byType(PlayerScreen));
    player.navigation.openLyrics();
    await settleLyrics(tester);
    player.onOpenSettings!();
    await settleLyrics(tester);
    expect(find.byType(SleepSettingsPanel), findsNothing);
    await openLyricsSleep(tester);
  });

  testWidgets('empty lyrics keeps minutes available but disables entry end', (
    tester,
  ) async {
    final f = await mountLyrics(tester, empty: true);
    await openLyricsSleep(tester);
    expect(
      tester
          .widget<YYOptionCard>(
            find.byKey(const ValueKey('sleep-currentEntry')),
          )
          .onPressed,
      isNull,
    );
    option(tester, 'sixty')();
    await settleLyrics(tester);
    expect(f.graph.playback.sleepTimer.duration, PlaybackSleepDuration.sixty);
  });

  for (final (keyboardPlatform, keyboardSize) in const [
    (YYPlatform.windows, Size(1280, 900)),
    (YYPlatform.android, Size(390, 900)),
  ]) {
    testWidgets(
      'lyrics keyboard $keyboardSize entry and Escape restore header focus',
      (tester) async {
        final f = await mountLyrics(
          tester,
          platform: keyboardPlatform,
          size: keyboardSize,
        );
        for (var i = 0; i < 20; i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await settleLyrics(tester);
          if (FocusManager.instance.primaryFocus?.context
                  ?.findAncestorWidgetOfExactType<YYButton>()
                  ?.key ==
              const ValueKey('lyrics-page-settings')) {
            break;
          }
        }
        expect(
          FocusManager.instance.primaryFocus?.context
              ?.findAncestorWidgetOfExactType<YYButton>()
              ?.key,
          const ValueKey('lyrics-page-settings'),
        );
        final previous = FocusManager.instance.primaryFocus;
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await settleLyrics(tester);
        expect(find.byType(SleepSettingsPanel), findsOneWidget);
        final calls = List.of(f.engine.calls);
        Focus.of(tester.element(find.byType(SleepSettingsPanel)))
            .requestFocus();
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await settleLyrics(tester);
        expect(f.engine.calls, calls);
        expect(find.byType(SleepSettingsPanel), findsOneWidget);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await settleLyrics(tester);
        expect(FocusManager.instance.primaryFocus, same(previous));
      },
    );
  }

  testWidgets('main navigation and unmount revoke lyrics settings actions', (
    tester,
  ) async {
    final f = await mountLyrics(tester);
    final navigation = tester
        .widget<LyricsScreen>(find.byType(LyricsScreen))
        .navigation;
    await openLyricsSleep(tester);
    final old = option(tester, 'thirty');
    navigation.goTo(AppRoute.library);
    await settleLyrics(tester);
    old();
    expect(find.byType(SleepSettingsPanel), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await settleLyrics(tester);
    old();
    expect(f.graph.playback.sleepTimer.phase, PlaybackSleepPhase.off);
    expect(tester.takeException(), isNull);
  });
}
