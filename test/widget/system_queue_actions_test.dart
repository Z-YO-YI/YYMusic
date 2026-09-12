import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/design_system/yy_button.dart';
import 'package:yymusic/design_system/yy_context_menu.dart';
import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/features/playlists/common/system_playlist_management_panel.dart';
import 'package:yymusic/features/playlists/common/system_playlist_screen.dart';
import 'package:yymusic/features/queue/common/queue_operation_feedback.dart';
import 'package:yymusic/features/queue/common/queue_screen.dart';

import '../support/design_harness.dart';
import '../support/playlist_content_harness.dart' show settleContent;
import '../support/system_playlist_fixture.dart';
import '../support/system_playlist_harness.dart';
import 'library_queue_actions_test.dart' show tapQueueFeedback;

SystemPlaylistScreen systemScreen(WidgetTester tester) =>
    tester.widget<SystemPlaylistScreen>(find.byType(SystemPlaylistScreen));

Future<YYContextMenu> openSystemQueueMenu(
  WidgetTester tester, {
  Object? id,
  bool windows = false,
}) async {
  id ??= systemState(tester).controller.content!.entries.first.identity;
  if (systemRow(id).evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      systemRow(id),
      600,
      maxScrolls: 100,
      scrollable: find
          .descendant(
            of: find.byType(SystemPlaylistScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
  }
  await revealSystemRow(tester, id);
  if (windows) {
    await tester.tap(systemRow(id), buttons: kSecondaryMouseButton);
  } else {
    await tester.longPress(systemRow(id));
  }
  await tester.pumpAndSettle();
  return tester.widget<YYContextMenu>(find.byType(YYContextMenu));
}

void main() {
  setUpAll(loadDesignAssets);
  for (final type in [
    SystemPlaylistType.favorites,
    SystemPlaylistType.recent,
  ]) {
    for (final (platform, size) in const [
      (YYPlatform.android, Size(390, 1000)),
      (YYPlatform.android, Size(1024, 768)),
      (YYPlatform.windows, Size(1024, 900)),
    ]) {
      testWidgets(
        '$type $platform $size gestures queue without changing history/favorites/audio',
        (tester) async {
          final f = SystemPlaylistFixture();
          await mountSystemPlaylist(
            tester,
            f,
            type: type,
            platform: platform,
            size: size,
          );
          await tester.runAsync(() => f.graph.playback.playEntry('q-0'));
          await settleContent(tester);
          final before = systemState(tester).controller.content!;
          final favorites = await tester.runAsync(
            () => f.collection.watchFavorites().first,
          );
          final history = await tester.runAsync(
            () => f.collection.watchHistory().first,
          );
          final calls = [...f.engine.calls],
              current = f.graph.queue.state.currentEntryId;
          final entry = before.entries.first;
          final menu = await openSystemQueueMenu(
            tester,
            id: entry.identity,
            windows: platform == YYPlatform.windows,
          );
          expect(
            menu.items.any((i) => i.id == 'remove-favorite'),
            type == SystemPlaylistType.favorites,
          );
          expect(menu.items.any((i) => i.id == 'clear-history'), isFalse);
          await tester.tap(find.text('添加到队列'));
          await settleContent(tester);
          final firstId = f.graph.queue.state.entries.last.id;
          expect(f.graph.queue.state.entries.last.track, entry.reference);
          expect(firstId, isNot(entry.entryId));
          await openSystemQueueMenu(
            tester,
            id: entry.identity,
            windows: platform == YYPlatform.windows,
          );
          if (platform == YYPlatform.windows) {
            await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
            await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          } else {
            await tester.tap(find.text('下一首播放'));
          }
          await settleContent(tester);
          final queue = f.graph.queue.state;
          expect(queue.entries, hasLength(7));
          expect(queue.entries[1].track, entry.reference);
          expect(queue.entries[1].id, isNot(firstId));
          expect(queue.entries.map((e) => e.id).toSet(), hasLength(7));
          expect(queue.currentEntryId, current);
          expect(f.engine.calls, calls);
          expect(
            await tester.runAsync(() => f.collection.watchFavorites().first),
            favorites,
          );
          expect(
            await tester.runAsync(() => f.collection.watchHistory().first),
            history,
          );
          await tapQueueFeedback(tester, '查看播放队列');
          expect(find.byType(QueueScreen), findsOneWidget);
          expect(tester.takeException(), isNull);
          await closeSystemPlaylist(tester, f);
        },
      );
    }
    testWidgets(
      '$type missing and unresolved references remain unplayable after insertion',
      (tester) async {
        final f = SystemPlaylistFixture();
        await mountSystemPlaylist(tester, f, type: type);
        final entries = systemState(tester).controller.content!.entries
            .where((e) => !e.isAvailable)
            .toList();
        expect(entries, hasLength(2));
        for (final entry in entries) {
          final menu = await openSystemQueueMenu(tester, id: entry.identity);
          expect(
            menu.items.singleWhere((i) => i.id == 'play').enabled,
            isFalse,
          );
          expect(
            menu.items.singleWhere((i) => i.id == 'queue').enabled,
            isTrue,
          );
          await tester.tap(find.text('添加到队列'));
          await settleContent(tester);
          expect(f.graph.queue.state.entries.last.track, entry.reference);
        }
        expect(f.engine.calls, isEmpty);
        expect(f.graph.queue.state.currentEntryId, 'q-0');
        expect(systemState(tester).controller.content!.totalCount, 4);
        await closeSystemPlaylist(tester, f);
      },
    );
  }
  for (final reason in [
    'refresh',
    'replace',
    'resize',
    'leave',
    'zero',
    'dispose',
    'dismiss',
    'reopen',
  ]) {
    testWidgets('old recent menu and barrier are harmless after $reason', (
      tester,
    ) async {
      final f = SystemPlaylistFixture();
      await mountSystemPlaylist(tester, f, type: SystemPlaylistType.recent);
      final old = await openSystemQueueMenu(tester);
      final barrier = tester
          .widget<ModalBarrier>(
            find.byWidgetPredicate(
              (widget) =>
                  widget is ModalBarrier && widget.semanticsLabel == '关闭系统歌单操作',
            ),
          )
          .onDismiss!;
      switch (reason) {
        case 'refresh':
          systemState(tester).controller.refresh();
        case 'replace':
          await tester.runAsync(() => f.graph.queue.replace([]));
        case 'resize':
          tester.view.physicalSize = const Size(1024, 768);
        case 'leave':
          systemScreen(tester).navigation.openPlayer();
        case 'zero':
          tester.view.physicalSize = Size.zero;
        case 'dispose':
          await tester.pumpWidget(const SizedBox.shrink());
        case 'dismiss':
          old.onDismiss!();
        case 'reopen':
          old.onDismiss!();
          await tester.pumpAndSettle();
          await openSystemQueueMenu(tester);
      }
      await settleContent(tester);
      final before = f.graph.queue.state;
      f.collection.queueWrites.clear();
      old.onSelected!('queue');
      old.onSelected!('clear-history');
      old.onDismiss!();
      barrier();
      await settleContent(tester);
      expect(f.graph.queue.state, same(before));
      expect(f.collection.queueWrites, isEmpty);
      expect(
        await tester.runAsync(() => f.collection.watchHistory().first),
        hasLength(4),
      );
      if (reason == 'resize' || reason == 'reopen') {
        await tester.tap(find.text('添加到队列'));
        await settleContent(tester);
        expect(f.graph.queue.state.entries, hasLength(6));
      }
      expect(tester.takeException(), isNull);
      await closeSystemPlaylist(tester, f);
    });
  }
  testWidgets(
    'recent menu cannot clear history and resized confirmation needs its new callback',
    (tester) async {
      final f = SystemPlaylistFixture();
      await mountSystemPlaylist(tester, f, type: SystemPlaylistType.recent);
      final menu = await openSystemQueueMenu(tester);
      menu.onSelected!('clear-history');
      await settleContent(tester);
      expect(systemState(tester).controller.content!.totalCount, 4);
      systemState(tester).scroll.jumpTo(0);
      await tester.pumpAndSettle();
      await tester.tap(find.text('清除播放历史'));
      await tester.pumpAndSettle();
      final old = tester
          .widget<YYButton>(find.widgetWithText(YYButton, '确认清除'))
          .onPressed!;
      tester.view.physicalSize = const Size(1024, 768);
      await tester.pumpAndSettle();
      old();
      await settleContent(tester);
      expect(systemState(tester).controller.content!.totalCount, 4);
      await tester.runAsync(() => f.graph.queue.replace([]));
      await settleContent(tester);
      expect(find.byType(SystemPlaylistManagementPanel), findsOneWidget);
      await tester.tap(find.widgetWithText(YYButton, '确认清除'));
      await settleContent(tester);
      expect(systemState(tester).controller.content!.totalCount, 0);
      expect(f.graph.queue.state.entries, isEmpty);
      await closeSystemPlaylist(tester, f);
    },
  );
  testWidgets(
    'system queue failure survives cover and explicitly retries the same ID',
    (tester) async {
      final f = SystemPlaylistFixture();
      await mountSystemPlaylist(tester, f, type: SystemPlaylistType.favorites);
      f.collection.beforeQueueWrite = (_) async =>
          throw StateError('private-marker');
      await openSystemQueueMenu(tester);
      await tester.tap(find.text('下一首播放'));
      await settleContent(tester);
      final failure = f.graph.queue.editFailure!;
      final navigation = systemScreen(tester).navigation;
      navigation.openPlayer();
      await settleContent(tester);
      navigation.back();
      await settleContent(tester);
      expect(find.text('队列操作未完成'), findsOneWidget);
      expect(find.textContaining('private-marker'), findsNothing);
      f.collection.beforeQueueWrite = null;
      await tapQueueFeedback(tester, '重试队列操作');
      final expected = failure.edit.apply(
        updatedAt: f.graph.queue.state.updatedAt,
      )!;
      expect(
        f.graph.queue.state.entries.map((e) => e.id),
        expected.entries.map((e) => e.id),
      );
      expect(f.graph.queue.editFailure, isNull);
      expect(f.engine.calls, isEmpty);
      await closeSystemPlaylist(tester, f);
    },
  );
  testWidgets(
    'busy rejects repeat and accepted system queue write drains after disposal',
    (tester) async {
      final f = SystemPlaylistFixture();
      await mountSystemPlaylist(tester, f, type: SystemPlaylistType.recent);
      final gate = Completer<void>();
      var writes = 0;
      addTearDown(() {
        if (!gate.isCompleted) gate.complete();
      });
      f.collection.beforeQueueWrite = (_) async {
        writes++;
        await gate.future;
      };
      final old = await openSystemQueueMenu(tester);
      old.onSelected!('queue');
      old.onSelected!('queue');
      await settleContent(tester);
      expect(writes, 1);
      expect(f.graph.queue.editBusy, isTrue);
      expect(find.text('正在更新播放队列…'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      gate.complete();
      await settleContent(tester);
      expect(f.collection.queueWrites, hasLength(1));
      expect(f.graph.queue.state.entries, hasLength(6));
      expect(f.engine.calls, isEmpty);
      await closeSystemPlaylist(tester, f);
    },
  );
  testWidgets('old system notice cannot dismiss the new insertion notice', (
    tester,
  ) async {
    final f = SystemPlaylistFixture();
    await mountSystemPlaylist(tester, f, type: SystemPlaylistType.favorites);
    await openSystemQueueMenu(tester);
    await tester.tap(find.text('添加到队列'));
    await settleContent(tester);
    final old = tester
        .widget<QueueOperationFeedback>(find.byType(QueueOperationFeedback))
        .onDismissNotice;
    await openSystemQueueMenu(tester);
    await tester.tap(find.text('下一首播放'));
    await settleContent(tester);
    old();
    await tester.pumpAndSettle();
    expect(find.text('已设为下一首播放。当前播放不会中断。'), findsOneWidget);
    await closeSystemPlaylist(tester, f);
  });
  testWidgets(
    'favorites window change only queues a newly selected exact entry',
    (tester) async {
      final f = SystemPlaylistFixture(count: 205);
      await mountSystemPlaylist(tester, f, type: SystemPlaylistType.favorites);
      final c = systemState(tester).controller;
      while (c.canLoadMore) {
        c.loadMore(c.content!);
        await settleContent(tester);
      }
      final old = await openSystemQueueMenu(
        tester,
        id: c.content!.entries.last.identity,
      );
      c.showNextWindow(c.content!);
      await settleContent(tester);
      old.onSelected!('queue');
      await settleContent(tester);
      expect(f.collection.queueWrites, isEmpty);
      expect(c.content!.page.offset, 200);
      final entry = c.content!.entries.first;
      await openSystemQueueMenu(tester, id: entry.identity);
      await tester.tap(find.text('添加到队列'));
      await settleContent(tester);
      expect(f.graph.queue.state.entries.last.track, entry.reference);
      expect(c.content!.totalCount, 204);
      await closeSystemPlaylist(tester, f);
    },
  );
}
