import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/design_system/yy_context_menu.dart';
import 'package:yymusic/features/playlists/common/playlist_content_controller.dart';
import 'package:yymusic/features/playlists/common/playlist_content_screen.dart';
import 'package:yymusic/features/queue/common/queue_operation_feedback.dart';
import 'package:yymusic/features/queue/common/queue_screen.dart';

import '../support/design_harness.dart';
import '../support/playlist_content_fixture.dart';
import '../support/playlist_content_harness.dart';
import 'library_queue_actions_test.dart' show tapQueueFeedback;

PlaylistContentScreen playlistScreen(WidgetTester tester) =>
    tester.widget<PlaylistContentScreen>(find.byType(PlaylistContentScreen));

Future<YYContextMenu> openPlaylistQueueMenu(
  WidgetTester tester, {
  String id = 'e-0',
  bool windows = false,
}) async {
  if (playlistRow(id).evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      playlistRow(id),
      600,
      maxScrolls: 100,
      scrollable: find
          .descendant(
            of: find.byKey(const PageStorageKey('playlist-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
  }
  final row = await revealPlaylistRow(tester, id);
  if (windows) {
    await tester.tap(row, buttons: kSecondaryMouseButton);
  } else {
    await tester.longPress(row);
  }
  await tester.pumpAndSettle();
  return tester.widget<YYContextMenu>(find.byType(YYContextMenu));
}

void main() {
  setUpAll(loadDesignAssets);
  for (final (platform, size) in const [
    (YYPlatform.android, Size(390, 1000)),
    (YYPlatform.android, Size(1024, 768)),
    (YYPlatform.windows, Size(1024, 900)),
  ]) {
    testWidgets(
      'playlist queue $platform $size actual gestures preserve playing and original playlist',
      (tester) async {
        final f = PlaylistContentFixture(count: 5);
        await mountPlaylist(tester, f, platform: platform, size: size);
        final before = await f.collection.getPlaylistEntries(f.id);
        await tester.runAsync(
          () => f.graph.playback.playCatalogTrack(f.tracks.first.ref),
        );
        await settleContent(tester);
        final current = f.graph.queue.state.currentEntryId,
            calls = [...f.engine.calls];
        await openPlaylistQueueMenu(
          tester,
          id: 'e-1',
          windows: platform == YYPlatform.windows,
        );
        await tester.tap(find.text('添加到队列'));
        await settleContent(tester);
        expect(f.graph.queue.state.entries, hasLength(2));
        expect(
          f.graph.queue.state.entries.map((e) => e.id).toSet(),
          hasLength(2),
        );
        expect(
          f.graph.queue.state.entries.every(
            (e) => e.track == f.tracks.first.ref,
          ),
          isTrue,
        );
        expect(f.graph.queue.state.entries.last.id, isNot('e-1'));
        await openPlaylistQueueMenu(
          tester,
          id: 'e-4',
          windows: platform == YYPlatform.windows,
        );
        if (platform == YYPlatform.windows) {
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        } else {
          await tester.tap(find.text('下一首播放'));
        }
        await settleContent(tester);
        expect(f.graph.queue.state.entries[1].track, f.tracks[4].ref);
        expect(f.graph.queue.state.currentEntryId, current);
        expect(f.engine.calls, calls);
        expect(
          (await f.collection.getPlaylistEntries(f.id))
              .map((e) => (e.id, e.position, e.track, e.addedAt)),
          before.map((e) => (e.id, e.position, e.track, e.addedAt)),
        );
        await tapQueueFeedback(tester, '查看播放队列');
        expect(find.byType(QueueScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
        await closePlaylist(tester, f);
      },
    );
  }
  for (final id in ['e-2', 'e-3']) {
    testWidgets(
      'playlist $id missing/unresolved queue reference does not become playable',
      (tester) async {
        final f = PlaylistContentFixture(count: 5);
        await mountPlaylist(tester, f);
        final entry = playlistState(tester).controller.entryFor(id)!;
        final menu = await openPlaylistQueueMenu(tester, id: id);
        expect(menu.items.singleWhere((i) => i.id == 'play').enabled, isFalse);
        expect(menu.items.singleWhere((i) => i.id == 'queue').enabled, isTrue);
        await tester.tap(find.text('添加到队列'));
        await settleContent(tester);
        expect(f.graph.queue.state.entries.single.track, entry.entry.track);
        expect(f.graph.queue.state.currentEntryId, isNull);
        expect(f.engine.calls, isEmpty);
        expect((await f.collection.getPlaylistEntries(f.id)), hasLength(5));
        await closePlaylist(tester, f);
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
    testWidgets('old playlist menu does not queue after $reason', (
      tester,
    ) async {
      final f = PlaylistContentFixture(count: 5);
      await mountPlaylist(tester, f);
      final old = await openPlaylistQueueMenu(tester);
      switch (reason) {
        case 'refresh':
          playlistState(tester).controller.refresh();
        case 'replace':
          await tester.runAsync(() => f.graph.queue.replace([]));
        case 'resize':
          tester.view.physicalSize = const Size(430, 932);
        case 'leave':
          playlistScreen(tester).navigation.openPlayer();
        case 'zero':
          tester.view.physicalSize = Size.zero;
        case 'dispose':
          await tester.pumpWidget(const SizedBox.shrink());
        case 'dismiss':
          old.onDismiss!();
        case 'reopen':
          old.onDismiss!();
          await tester.pumpAndSettle();
          await openPlaylistQueueMenu(tester);
      }
      await settleContent(tester);
      f.collection.queueWrites.clear();
      old.onSelected!('queue');
      old.onDismiss!();
      await settleContent(tester);
      expect(f.graph.queue.state.entries, isEmpty);
      expect(f.collection.queueWrites, isEmpty);
      expect(f.engine.calls, isEmpty);
      if (reason == 'resize' || reason == 'reopen') {
        await tester.tap(find.text('添加到队列'));
        await settleContent(tester);
        expect(f.graph.queue.state.entries, hasLength(1));
      }
      expect(tester.takeException(), isNull);
      await closePlaylist(tester, f);
    });
  }
  testWidgets(
    'playlist failure survives page cover and same-ID explicit retry',
    (tester) async {
      final f = PlaylistContentFixture(count: 5);
      await mountPlaylist(tester, f);
      f.collection.beforeQueueWrite = (_) async =>
          throw StateError('private-marker');
      await openPlaylistQueueMenu(tester);
      await tester.tap(find.text('下一首播放'));
      await settleContent(tester);
      final failure = f.graph.queue.editFailure!;
      final navigation = playlistScreen(tester).navigation;
      navigation.openPlayer();
      await settleContent(tester);
      navigation.back();
      await settleContent(tester);
      expect(find.text('队列操作未完成'), findsOneWidget);
      expect(find.textContaining('private-marker'), findsNothing);
      f.collection.beforeQueueWrite = null;
      await tapQueueFeedback(tester, '重试队列操作');
      expect(f.graph.queue.state.entries.single.id, failure.edit.nextEntryId);
      expect(f.graph.queue.editFailure, isNull);
      expect(f.engine.calls, isEmpty);
      expect((await f.collection.getPlaylistEntries(f.id)), hasLength(5));
      await closePlaylist(tester, f);
    },
  );
  testWidgets(
    'playlist busy blocks duplicate and accepted queue write survives disposal',
    (tester) async {
      final f = PlaylistContentFixture(count: 5);
      await mountPlaylist(tester, f);
      final gate = Completer<void>(), entered = Completer<void>();
      addTearDown(() {
        if (!gate.isCompleted) gate.complete();
      });
      f.collection.beforeQueueWrite = (_) async {
        entered.complete();
        await gate.future;
      };
      final old = await openPlaylistQueueMenu(tester);
      old.onSelected!('queue');
      old.onSelected!('queue');
      await settleContent(tester);
      expect(entered.isCompleted, isTrue);
      expect(f.graph.queue.editBusy, isTrue);
      expect(find.text('正在更新播放队列…'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      gate.complete();
      await settleContent(tester);
      expect(f.collection.queueWrites, hasLength(1));
      expect(f.engine.calls, isEmpty);
      expect((await f.collection.getPlaylistEntries(f.id)), hasLength(5));
      await closePlaylist(tester, f);
    },
  );
  testWidgets(
    'old playlist notice cannot dismiss a newer successful insertion',
    (tester) async {
      final f = PlaylistContentFixture(count: 5);
      await mountPlaylist(tester, f);
      await openPlaylistQueueMenu(tester);
      await tester.tap(find.text('添加到队列'));
      await settleContent(tester);
      final old = tester
          .widget<QueueOperationFeedback>(find.byType(QueueOperationFeedback))
          .onDismissNotice;
      await openPlaylistQueueMenu(tester, id: 'e-1');
      await tester.tap(find.text('下一首播放'));
      await settleContent(tester);
      old();
      await tester.pumpAndSettle();
      expect(find.text('已设为下一首播放。当前播放不会中断。'), findsOneWidget);
      expect(f.graph.queue.state.entries, hasLength(2));
      await closePlaylist(tester, f);
    },
  );
  testWidgets(
    'playlist window change revokes a menu and queues only a newly selected entry',
    (tester) async {
      final f = PlaylistContentFixture(count: 205);
      await mountPlaylist(tester, f);
      final c = playlistState(tester).controller;
      while (c.canLoadMore) {
        c.loadMore();
        await settleContent(tester);
      }
      final old = await openPlaylistQueueMenu(tester, id: 'e-199');
      c.showNextWindow(c.content!);
      await settleContent(tester);
      old.onSelected!('next');
      await settleContent(tester);
      expect(f.graph.queue.state.entries, isEmpty);
      expect(c.content!.page.offset, 200);
      await openPlaylistQueueMenu(tester, id: 'e-200');
      await tester.tap(find.text('添加到队列'));
      await settleContent(tester);
      expect(f.graph.queue.state.entries.single.track, f.tracks[200].ref);
      expect((await f.collection.getPlaylistEntries(f.id)), hasLength(205));
      await closePlaylist(tester, f);
    },
  );
}
