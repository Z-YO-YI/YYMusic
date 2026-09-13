import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/app_routes.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/design_system/yy_button.dart';
import 'package:yymusic/features/playlists/common/system_playlist_management_panel.dart';
import 'package:yymusic/features/queue/common/queue_screen.dart';

import '../support/design_harness.dart';
import '../support/native_lyrics_harness.dart';
import 'inspector_navigation_test.dart' show inspector;
import 'shell_favorite_test.dart' show shellNavigation;
import 'shell_sleep_settings_test.dart' show mountShellSleep, shellSleepTest;
import 'system_queue_actions_test.dart' show openSystemQueueMenu;

Future<void> openInspectorQueue(WidgetTester tester) async {
  final button = find.byKey(const ValueKey('inspector-open-queue'));
  await tester.ensureVisible(button);
  await tester.tap(button);
  await settleLyrics(tester);
  expect(find.byType(QueueScreen), findsOneWidget);
}

void main() {
  setUpAll(loadDesignAssets);
  for (final platform in YYPlatform.values) {
    for (final empty in [false, true]) {
      shellSleepTest(
        '$platform empty=$empty opens queue without audio changes',
        (tester, f) async {
          if (empty) await tester.runAsync(f.graph.queue.clear);
          await mountShellSleep(tester, f, platform: platform);
          final queue = f.graph.playback.state.queue;
          final calls = List.of(f.engine.calls);
          expect(inspector(tester).queueCount, queue.entries.length);
          final old = inspector(tester).onOpenQueue!;
          final navigation = shellNavigation(tester);
          await openInspectorQueue(tester);
          old();
          await settleLyrics(tester);
          expect(find.byType(QueueScreen), findsOneWidget);
          expect(f.graph.playback.state.queue, same(queue));
          expect(f.engine.calls, calls);
          navigation.back();
          await settleLyrics(tester);
          old();
          await settleLyrics(tester);
          expect(find.byType(QueueScreen), findsNothing);
        },
      );
    }
  }

  shellSleepTest('root reorder and clear update displayed summary', (
    tester,
    f,
  ) async {
    await mountShellSleep(tester, f);
    final before = f.graph.playbackPresenter.queueSummary;
    expect(inspector(tester).currentQueueOrdinal, before.currentOrdinal);
    final current = before.currentEntry;
    expect(current, isNotNull);
    await tester.runAsync(() => f.graph.queue.move(current!.id, 4));
    await settleLyrics(tester);
    expect(inspector(tester).currentQueueOrdinal, 5);
    expect(find.text('当前第 5 首 · 按列表顺序'), findsOneWidget);
    await tester.runAsync(f.graph.queue.clear);
    await settleLyrics(tester);
    expect(inspector(tester).queueCount, 0);
    expect(inspector(tester).currentQueueOrdinal, isNull);
    expect(find.text('队列为空，从音乐库选择曲目后播放。'), findsOneWidget);
  });

  for (final revoke in ['hide', 'zero', 'away-back', 'cover', 'unmount']) {
    shellSleepTest('old Inspector queue action revoked after $revoke', (
      tester,
      f,
    ) async {
      await mountShellSleep(tester, f);
      final old = inspector(tester).onOpenQueue!;
      final navigation = shellNavigation(tester);
      switch (revoke) {
        case 'hide':
          tester.view.physicalSize = const Size(840, 900);
          await settleLyrics(tester);
          tester.view.physicalSize = const Size(1440, 1000);
        case 'zero':
          tester.view.physicalSize = Size.zero;
          await settleLyrics(tester);
          tester.view.physicalSize = const Size(1440, 1000);
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
      expect(find.byType(QueueScreen), findsNothing);
    });
  }

  shellSleepTest('short window scroll exposes queue entry', (tester, f) async {
    await mountShellSleep(tester, f, size: const Size(1440, 600));
    await openInspectorQueue(tester);
    expect(tester.takeException(), isNull);
  });

  shellSleepTest('same-frame queue action is consumed once', (tester, f) async {
    await mountShellSleep(tester, f);
    final navigation = shellNavigation(tester);
    final open = inspector(tester).onOpenQueue!;
    open();
    open();
    await settleLyrics(tester);
    expect(find.byType(QueueScreen), findsOneWidget);
    navigation.back();
    await settleLyrics(tester);
    expect(find.byType(QueueScreen), findsNothing);
  });

  shellSleepTest('inline menu revokes queue action even after dismissal', (
    tester,
    f,
  ) async {
    await mountShellSleep(
      tester,
      f,
      location: '/system-playlist?type=favorites',
    );
    final old = inspector(tester).onOpenQueue!;
    await openSystemQueueMenu(tester);
    old();
    await settleLyrics(tester);
    expect(find.byType(QueueScreen), findsNothing);
    tester
        .widget<SystemPlaylistManagementPanel>(
          find.byType(SystemPlaylistManagementPanel),
        )
        .onDismiss();
    await settleLyrics(tester);
    old();
    await settleLyrics(tester);
    expect(find.byType(QueueScreen), findsNothing);
    await openInspectorQueue(tester);
  });

  shellSleepTest('queue entry is keyboard reachable', (tester, f) async {
    await mountShellSleep(tester, f);
    for (var i = 0; i < 100; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await settleLyrics(tester);
      if (FocusManager.instance.primaryFocus?.context
              ?.findAncestorWidgetOfExactType<YYButton>()
              ?.key ==
          const ValueKey('inspector-open-queue')) {
        break;
      }
    }
    expect(
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<YYButton>()
          ?.key,
      const ValueKey('inspector-open-queue'),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await settleLyrics(tester);
    expect(find.byType(QueueScreen), findsOneWidget);
  });
}
