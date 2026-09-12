import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/app_routes.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/design_system/yy_button.dart';
import 'package:yymusic/design_system/yy_option_card.dart';
import 'package:yymusic/design_system/yy_player_surface.dart';
import 'package:yymusic/features/player/common/player_screen.dart';
import 'package:yymusic/features/player/common/sleep_settings_panel.dart';
import 'package:yymusic/features/playlists/common/system_playlist_management_panel.dart';
import 'package:yymusic/playback/playback_sleep_timer_state.dart';

import '../support/design_harness.dart';
import '../support/native_lyrics_harness.dart';
import 'inspector_navigation_test.dart' show inspector;
import 'player_sleep_settings_test.dart' show openPlayerSleep;
import 'shell_favorite_test.dart' show favoriteBar, shellNavigation;
import 'shell_sleep_settings_test.dart' show mountShellSleep, shellSleepTest;
import 'system_queue_actions_test.dart' show openSystemQueueMenu;

Future<void> openInspectorSleep(
  WidgetTester tester, {
  bool quick = false,
}) async {
  final button = find.byKey(
    ValueKey(quick ? 'inspector-settings-device' : 'inspector-settings-more'),
  );
  await tester.ensureVisible(button);
  await tester.tap(button);
  await settleLyrics(tester);
  expect(find.byType(SleepSettingsPanel), findsOneWidget);
}

void main() {
  setUpAll(loadDesignAssets);
  for (final platform in YYPlatform.values) {
    for (final quick in [false, true]) {
      shellSleepTest(
        'inspector $platform quick=$quick shares one modal with bar',
        (tester, f) async {
          await mountShellSleep(tester, f, platform: platform);
          final queue = f.graph.playback.state.queue;
          final calls = List.of(f.engine.calls);
          final oldInspector = inspector(tester).onOpenSettings!;
          final oldBar = favoriteBar(tester).onOpenSettings!;
          await openInspectorSleep(tester, quick: quick);
          oldInspector();
          oldBar();
          await settleLyrics(tester);
          expect(find.byType(SleepSettingsPanel), findsOneWidget);
          await tester.tap(find.byKey(const ValueKey('sleep-thirty')));
          await settleLyrics(tester);
          final oldChoice = tester
              .widget<YYOptionCard>(find.byKey(const ValueKey('sleep-sixty')))
              .onPressed!;
          await tester.tap(find.byKey(const ValueKey('sleep-done')));
          await settleLyrics(tester);
          oldInspector();
          oldBar();
          oldChoice();
          await settleLyrics(tester);
          expect(find.byType(SleepSettingsPanel), findsNothing);
          expect(
            f.graph.playback.sleepTimer.duration,
            PlaybackSleepDuration.thirty,
          );
          expect(f.graph.playback.state.queue, same(queue));
          expect(f.engine.calls, calls);
          await openInspectorSleep(tester, quick: !quick);
          expect(
            tester
                .widget<YYOptionCard>(
                  find.byKey(const ValueKey('sleep-thirty')),
                )
                .selected,
            isTrue,
          );
        },
      );
    }
    shellSleepTest(
      'short $platform Inspector scroll reveals real quick setting',
      (tester, f) async {
        await mountShellSleep(
          tester,
          f,
          platform: platform,
          size: const Size(1440, 600),
        );
        await openInspectorSleep(tester, quick: true);
        await tester.tap(find.byKey(const ValueKey('sleep-fifteen')));
        await settleLyrics(tester);
        expect(
          f.graph.playback.sleepTimer.duration,
          PlaybackSleepDuration.fifteen,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final (name, platform, size, mini) in const [
    ('phone', YYPlatform.android, Size(390, 900), true),
    ('tablet_portrait', YYPlatform.android, Size(800, 1000), false),
    ('windows_narrow', YYPlatform.windows, Size(840, 800), false),
    ('windows_small', YYPlatform.windows, Size(500, 800), false),
  ]) {
    shellSleepTest('$name reaches sleep through original metadata entry', (
      tester,
      f,
    ) async {
      await mountShellSleep(tester, f, platform: platform, size: size);
      expect(find.byType(YYNowPlayingInspector), findsNothing);
      expect(
        find.byKey(const ValueKey('player-control-desktop-settings')),
        findsNothing,
      );
      await tester.tap(
        find.byKey(
          ValueKey(mini ? 'mini-player-track' : 'desktop-player-track'),
        ),
      );
      await settleLyrics(tester);
      expect(find.byType(PlayerScreen), findsOneWidget);
      await openPlayerSleep(tester);
      await tester.ensureVisible(find.byKey(const ValueKey('sleep-sixty')));
      await tester.tap(find.byKey(const ValueKey('sleep-sixty')));
      await settleLyrics(tester);
      expect(f.graph.playback.sleepTimer.duration, PlaybackSleepDuration.sixty);
    });
  }

  for (final revoke in [
    'hide-return',
    'zero-return',
    'navigation',
    'away-back',
    'cover',
    'unmount',
  ]) {
    shellSleepTest('Inspector old settings revoked after $revoke', (
      tester,
      f,
    ) async {
      await mountShellSleep(tester, f);
      final old = inspector(tester).onOpenSettings!;
      final navigation = shellNavigation(tester);
      switch (revoke) {
        case 'hide-return':
          tester.view.physicalSize = const Size(840, 900);
          await settleLyrics(tester);
          expect(find.byType(YYNowPlayingInspector), findsNothing);
          tester.view.physicalSize = const Size(1440, 1000);
        case 'zero-return':
          tester.view.physicalSize = Size.zero;
          await settleLyrics(tester);
          tester.view.physicalSize = const Size(1440, 1000);
        case 'navigation':
          navigation.goTo(AppRoute.library);
        case 'away-back':
          navigation.goTo(AppRoute.library);
          await settleLyrics(tester);
          navigation.goTo(AppRoute.home);
        case 'cover':
          navigation.openLyrics();
        case 'unmount':
          await tester.pumpWidget(const SizedBox.shrink());
      }
      await settleLyrics(tester);
      old();
      await settleLyrics(tester);
      expect(find.byType(SleepSettingsPanel), findsNothing);
      expect(f.graph.playback.sleepTimer.phase, PlaybackSleepPhase.off);
    });
  }

  shellSleepTest(
    'menu cover and restore permanently revokes Inspector settings',
    (tester, f) async {
      await mountShellSleep(
        tester,
        f,
        location: '/system-playlist?type=favorites',
      );
      final old = inspector(tester).onOpenSettings!;
      await openSystemQueueMenu(tester);
      old();
      await settleLyrics(tester);
      expect(find.byType(SleepSettingsPanel), findsNothing);
      tester
          .widget<SystemPlaylistManagementPanel>(
            find.byType(SystemPlaylistManagementPanel),
          )
          .onDismiss();
      await settleLyrics(tester);
      old();
      await settleLyrics(tester);
      expect(find.byType(SleepSettingsPanel), findsNothing);
      await openInspectorSleep(tester);
    },
  );

  shellSleepTest('Inspector keyboard entry returns exact focus on Escape', (
    tester,
    f,
  ) async {
    await mountShellSleep(tester, f);
    for (var i = 0; i < 100; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await settleLyrics(tester);
      if (FocusManager.instance.primaryFocus?.context
              ?.findAncestorWidgetOfExactType<YYButton>()
              ?.key ==
          const ValueKey('inspector-settings-more')) {
        break;
      }
    }
    expect(
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<YYButton>()
          ?.key,
      const ValueKey('inspector-settings-more'),
    );
    final previous = FocusManager.instance.primaryFocus;
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await settleLyrics(tester);
    expect(find.byType(SleepSettingsPanel), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await settleLyrics(tester);
    expect(find.byType(SleepSettingsPanel), findsNothing);
    expect(FocusManager.instance.primaryFocus, same(previous));
  });
}
