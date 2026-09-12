import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/adaptive_root.dart';
import 'package:yymusic/app/app_routes.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/design_system/src/yy_control_action.dart';
import 'package:yymusic/design_system/yy_button.dart';
import 'package:yymusic/design_system/yy_option_card.dart';
import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/features/player/common/sleep_settings_panel.dart';
import 'package:yymusic/features/playlists/common/system_playlist_management_panel.dart';
import 'package:yymusic/playback/playback_sleep_timer_state.dart';

import '../support/design_harness.dart';
import '../support/native_lyrics_harness.dart';
import '../support/system_playlist_fixture.dart';
import '../support/system_playlist_harness.dart';
import 'foundation_app_test.dart' show mount;
import 'shell_favorite_test.dart' show favoriteBar, shellNavigation;
import 'system_queue_actions_test.dart' show openSystemQueueMenu;

Future<void> mountShellSleep(
  WidgetTester tester,
  SystemPlaylistFixture f, {
  String location = '/home',
  YYPlatform platform = YYPlatform.windows,
  Size size = const Size(1440, 1000),
}) async {
  f.graph.appearance.setReduceMotion(true);
  await mount(
    tester,
    platform: platform,
    size: size,
    graph: f.graph,
    route: location,
    scale: 1.3,
  );
  await settleLyrics(tester);
}

Future<void> openShellSleep(WidgetTester tester) async {
  await tester.tap(
    find.byKey(const ValueKey('player-control-desktop-settings')),
  );
  await settleLyrics(tester);
  expect(find.byType(SleepSettingsPanel), findsOneWidget);
}

void shellSleepTest(
  String description,
  Future<void> Function(WidgetTester, SystemPlaylistFixture) body,
) {
  testWidgets(description, (tester) async {
    late final SystemPlaylistFixture f;
    await tester.runAsync(() async {
      f = SystemPlaylistFixture();
      await f.initialize();
    });
    try {
      await body(tester, f);
    } finally {
      // Drain real/Fake async cancellation before the binding checks timers.
      await closeSystemPlaylist(tester, f);
    }
  });
}

void main() {
  setUpAll(loadDesignAssets);
  shellSleepTest(
    'shell keyboard opens settings and Escape restores exact focus',
    (tester, f) async {
      await mountShellSleep(tester, f);
      for (var i = 0; i < 80; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await settleLyrics(tester);
        if (FocusManager.instance.primaryFocus?.context
                ?.findAncestorWidgetOfExactType<YYControlAction>()
                ?.label ==
            '播放设置') {
          break;
        }
      }
      expect(
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<YYControlAction>()
            ?.label,
        '播放设置',
      );
      final previous = FocusManager.instance.primaryFocus;
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await settleLyrics(tester);
      expect(find.byType(SleepSettingsPanel), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await settleLyrics(tester);
      expect(find.byType(SleepSettingsPanel), findsNothing);
      expect(FocusManager.instance.primaryFocus, same(previous));
    },
  );
  for (final platform in YYPlatform.values) {
    shellSleepTest(
      'wide $platform settings opens once and retains root choice',
      (tester, f) async {
        await mountShellSleep(tester, f, platform: platform);
        final before = List.of(f.engine.calls);
        final queue = f.graph.playback.state.queue;
        final oldOpen = favoriteBar(tester).onOpenSettings!;
        await openShellSleep(tester);
        oldOpen();
        await settleLyrics(tester);
        expect(find.byType(SleepSettingsPanel), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('sleep-thirty')));
        await settleLyrics(tester);
        final oldChoice = tester
            .widget<YYOptionCard>(find.byKey(const ValueKey('sleep-sixty')))
            .onPressed!;
        await tester.tap(find.byKey(const ValueKey('sleep-done')));
        await settleLyrics(tester);
        oldOpen();
        oldChoice();
        await settleLyrics(tester);
        expect(find.byType(SleepSettingsPanel), findsNothing);
        expect(
          f.graph.playback.sleepTimer.duration,
          PlaybackSleepDuration.thirty,
        );
        expect(f.engine.calls, before);
        expect(f.graph.playback.state.queue, same(queue));
        await openShellSleep(tester);
        expect(
          tester
              .widget<YYOptionCard>(find.byKey(const ValueKey('sleep-thirty')))
              .selected,
          isTrue,
        );
      },
    );
  }

  for (final location in [
    '/search',
    '/library',
    '/settings',
    '/playlist?id=test',
    '/system-playlist?type=queue',
    '/queue',
    '/album/test?source=test',
    '/artist/test?source=test',
  ]) {
    shellSleepTest(
      'shell frame $location binds the production settings entry',
      (tester, f) async {
        await mountShellSleep(tester, f, location: location);
        await openShellSleep(tester);
        await tester.tap(find.byKey(const ValueKey('sleep-fifteen')));
        await settleLyrics(tester);
        expect(
          f.graph.playback.sleepTimer.duration,
          PlaybackSleepDuration.fifteen,
        );
        shellNavigation(tester).back();
        await settleLyrics(tester);
        expect(find.byType(SleepSettingsPanel), findsNothing);
        expect(find.byType(AdaptiveRoot), findsOneWidget);
      },
    );
  }

  shellSleepTest(
    'same path different query revokes modal and exact owner callback',
    (tester, f) async {
      await mountShellSleep(
        tester,
        f,
        location: '/system-playlist?type=favorites',
      );
      final rawOld = tester
          .widget<AdaptiveRoot>(find.byType(AdaptiveRoot))
          .onOpenSettings!;
      final navigation = shellNavigation(tester);
      await openShellSleep(tester);
      final oldChoice = tester
          .widget<YYOptionCard>(find.byKey(const ValueKey('sleep-thirty')))
          .onPressed!;
      final oldClose = tester
          .widget<YYButton>(find.byKey(const ValueKey('sleep-done')))
          .onPressed!;
      navigation.openSystemPlaylist(SystemPlaylistType.recent);
      oldChoice();
      await settleLyrics(tester);
      rawOld();
      oldClose();
      await settleLyrics(tester);
      expect(find.byType(SleepSettingsPanel), findsNothing);
      expect(f.graph.playback.sleepTimer.phase, PlaybackSleepPhase.off);
      await openShellSleep(tester);
      oldClose();
      await settleLyrics(tester);
      expect(find.byType(SleepSettingsPanel), findsOneWidget);
    },
  );

  for (final revoke in [
    'navigation',
    'away-back',
    'cover',
    'resize',
    'zero',
    'dispose',
  ]) {
    shellSleepTest('old shell settings action revoked by $revoke', (
      tester,
      f,
    ) async {
      await mountShellSleep(tester, f);
      final old = favoriteBar(tester).onOpenSettings!;
      final navigation = shellNavigation(tester);
      switch (revoke) {
        case 'navigation':
          navigation.goTo(AppRoute.library);
        case 'away-back':
          navigation.goTo(AppRoute.library);
          await settleLyrics(tester);
          navigation.goTo(AppRoute.home);
        case 'cover':
          navigation.openPlayer();
        case 'resize':
          tester.view.physicalSize = const Size(1500, 1000);
        case 'zero':
          tester.view.physicalSize = Size.zero;
        case 'dispose':
          await tester.pumpWidget(const SizedBox.shrink());
      }
      await settleLyrics(tester);
      old();
      await settleLyrics(tester);
      expect(find.byType(SleepSettingsPanel), findsNothing);
      expect(f.graph.playback.sleepTimer.phase, PlaybackSleepPhase.off);
      expect(tester.takeException(), isNull);
    });
  }

  shellSleepTest(
    'inline system menu revokes old settings even after dismissal',
    (tester, f) async {
      await mountShellSleep(
        tester,
        f,
        location: '/system-playlist?type=favorites',
      );
      final old = favoriteBar(tester).onOpenSettings!;
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
      await openShellSleep(tester);
    },
  );

  for (final close in ['escape', 'system', 'barrier']) {
    shellSleepTest('$close only closes shell settings', (tester, f) async {
      await mountShellSleep(tester, f);
      await openShellSleep(tester);
      await tester.tap(find.byKey(const ValueKey('sleep-sixty')));
      await settleLyrics(tester);
      switch (close) {
        case 'escape':
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        case 'system':
          await tester.binding.handlePopRoute();
        case 'barrier':
          await tester.tapAt(const Offset(5, 150));
      }
      await settleLyrics(tester);
      expect(find.byType(SleepSettingsPanel), findsNothing);
      expect(find.byType(AdaptiveRoot), findsOneWidget);
      expect(f.graph.playback.sleepTimer.duration, PlaybackSleepDuration.sixty);
    });
  }
}
