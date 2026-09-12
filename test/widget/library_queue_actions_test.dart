import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/app_routes.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/design_system/yy_context_menu.dart';
import 'package:yymusic/features/library/common/library_controller.dart';
import 'package:yymusic/features/library/common/library_screen.dart';
import 'package:yymusic/features/queue/common/queue_operation_feedback.dart';
import 'package:yymusic/features/queue/common/queue_screen.dart';

import '../support/design_harness.dart';
import '../support/library_graph_fixture.dart';
import '../support/playlist_content_harness.dart' show settleContent;
import 'library_screen_test.dart' show mountLibrary, closeLibrary;

Future<YYContextMenu> openLibraryQueueMenu(
  WidgetTester tester,
  LibraryGraphFixture f, {
  int index = 0,
  bool windows = false,
}) async {
  f.graph.libraryController.selectCategory(LibraryCategory.tracks);
  await settleContent(tester);
  final row = find.byKey(ValueKey(f.tracks[index].ref));
  await tester.ensureVisible(row);
  await tester.pumpAndSettle();
  if (windows) {
    await tester.tap(row, buttons: kSecondaryMouseButton);
  } else {
    await tester.longPress(row);
  }
  await tester.pumpAndSettle();
  return tester.widget<YYContextMenu>(find.byType(YYContextMenu));
}

LibraryScreen libraryScreen(WidgetTester tester) =>
    tester.widget<LibraryScreen>(find.byType(LibraryScreen));

Future<void> tapQueueFeedback(WidgetTester tester, String label) async {
  final button = find.text(label);
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await settleContent(tester);
}

void main() {
  setUpAll(loadDesignAssets);
  for (final (platform, size) in const [
    (YYPlatform.android, Size(390, 1000)),
    (YYPlatform.android, Size(1024, 768)),
    (YYPlatform.windows, Size(1024, 900)),
  ]) {
    testWidgets(
      'actual library insert and next on $platform $size preserve active audio',
      (tester) async {
        final f = LibraryGraphFixture(count: 4);
        await mountLibrary(tester, f, platform: platform, size: size);
        await tester.runAsync(
          () => f.graph.playback.playCatalogTrack(f.tracks.first.ref),
        );
        await settleContent(tester);
        final current = f.graph.queue.state.currentEntryId;
        final calls = [...f.engine.calls];
        await openLibraryQueueMenu(
          tester,
          f,
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
        await openLibraryQueueMenu(
          tester,
          f,
          index: 1,
          windows: platform == YYPlatform.windows,
        );
        if (platform == YYPlatform.windows) {
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        } else {
          await tester.tap(find.text('下一首播放'));
        }
        await settleContent(tester);
        expect(f.graph.queue.state.entries[1].track, f.tracks[1].ref);
        expect(f.graph.queue.state.currentEntryId, current);
        expect(f.engine.calls, calls);
        expect(find.text('已设为下一首播放。当前播放不会中断。'), findsOneWidget);
        await tapQueueFeedback(tester, '查看播放队列');
        expect(find.byType(QueueScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
        await closeLibrary(tester, f);
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
  ]) {
    testWidgets('captured library menu cannot insert after $reason', (
      tester,
    ) async {
      final f = LibraryGraphFixture(count: 4);
      await mountLibrary(tester, f);
      final old = await openLibraryQueueMenu(tester, f);
      switch (reason) {
        case 'refresh':
          f.graph.libraryController.refresh();
        case 'replace':
          await tester.runAsync(() => f.graph.queue.replace([]));
        case 'resize':
          tester.view.physicalSize = const Size(430, 932);
        case 'leave':
          libraryScreen(tester).navigation.openPlayer();
        case 'zero':
          tester.view.physicalSize = Size.zero;
        case 'dispose':
          await tester.pumpWidget(const SizedBox.shrink());
        case 'dismiss':
          old.onDismiss!();
      }
      await settleContent(tester);
      f.collection.queueWrites.clear();
      old.onSelected!('queue');
      await settleContent(tester);
      expect(f.graph.queue.state.entries, isEmpty);
      expect(f.collection.queueWrites, isEmpty);
      expect(f.engine.calls, isEmpty);
      expect(tester.takeException(), isNull);
      await closeLibrary(tester, f);
    });
  }
  testWidgets('missing file can be added without becoming playable', (
    tester,
  ) async {
    final f = LibraryGraphFixture(count: 4);
    await mountLibrary(tester, f);
    final menu = await openLibraryQueueMenu(tester, f, index: 2);
    expect(menu.items.singleWhere((i) => i.id == 'play').enabled, isFalse);
    expect(menu.items.singleWhere((i) => i.id == 'queue').enabled, isTrue);
    await tester.tap(find.text('添加到队列'));
    await settleContent(tester);
    expect(f.graph.queue.state.entries.single.track, f.tracks[2].ref);
    expect(f.graph.queue.state.currentEntryId, isNull);
    expect(f.engine.calls, isEmpty);
    await closeLibrary(tester, f);
  });
  testWidgets(
    'failure survives route return and explicit retry keeps one entry ID',
    (tester) async {
      final f = LibraryGraphFixture(count: 4);
      await mountLibrary(tester, f);
      f.collection.beforeQueueWrite = (_) async =>
          throw StateError('private-marker');
      await openLibraryQueueMenu(tester, f);
      await tester.tap(find.text('下一首播放'));
      await settleContent(tester);
      final failure = f.graph.queue.editFailure!;
      expect(find.textContaining('private-marker'), findsNothing);
      libraryScreen(tester).navigation.goTo(AppRoute.settings);
      await settleContent(tester);
      // Return through the actual main navigation.
      await tester.tap(find.text('音乐库').last);
      await settleContent(tester);
      expect(find.text('队列操作未完成'), findsOneWidget);
      f.collection.beforeQueueWrite = null;
      await tapQueueFeedback(tester, '重试队列操作');
      expect(f.graph.queue.state.entries.single.id, failure.edit.nextEntryId);
      expect(f.graph.queue.editFailure, isNull);
      expect(f.engine.calls, isEmpty);
      await closeLibrary(tester, f);
    },
  );
  testWidgets(
    'busy blocks duplicate selection and accepted write survives leaving',
    (tester) async {
      final f = LibraryGraphFixture(count: 4);
      await mountLibrary(tester, f);
      final gate = Completer<void>(), entered = Completer<void>();
      addTearDown(() {
        if (!gate.isCompleted) gate.complete();
      });
      f.collection.beforeQueueWrite = (_) async {
        entered.complete();
        await gate.future;
      };
      final menu = await openLibraryQueueMenu(tester, f);
      menu.onSelected!('queue');
      menu.onSelected!('queue');
      await settleContent(tester);
      expect(entered.isCompleted, isTrue);
      expect(f.graph.queue.editBusy, isTrue);
      expect(find.text('正在更新播放队列…'), findsOneWidget);
      libraryScreen(tester).navigation.goTo(AppRoute.settings);
      await settleContent(tester);
      gate.complete();
      await settleContent(tester);
      expect(f.collection.queueWrites, hasLength(1));
      expect(f.graph.queue.state.entries, hasLength(1));
      expect(f.engine.calls, isEmpty);
      await closeLibrary(tester, f);
    },
  );
  testWidgets('return from playlist picker permits another queue menu', (
    tester,
  ) async {
    final f = LibraryGraphFixture(count: 4);
    await mountLibrary(tester, f);
    final navigation = libraryScreen(tester).navigation;
    final menu = await openLibraryQueueMenu(tester, f);
    menu.onSelected!('playlist');
    await settleContent(tester);
    navigation.back();
    await settleContent(tester);
    await openLibraryQueueMenu(tester, f);
    await tester.tap(find.text('添加到队列'));
    await settleContent(tester);
    expect(f.graph.queue.state.entries, hasLength(1));
    await closeLibrary(tester, f);
  });
  testWidgets(
    'old notice dismissal cannot dismiss a newer successful operation',
    (tester) async {
      final f = LibraryGraphFixture(count: 4);
      await mountLibrary(tester, f);
      await openLibraryQueueMenu(tester, f);
      await tester.tap(find.text('添加到队列'));
      await settleContent(tester);
      final old = tester
          .widget<QueueOperationFeedback>(find.byType(QueueOperationFeedback))
          .onDismissNotice;
      await openLibraryQueueMenu(tester, f, index: 1);
      await tester.tap(find.text('添加到队列'));
      await settleContent(tester);
      old();
      await tester.pumpAndSettle();
      expect(find.text('已添加到队列末尾。当前播放不会中断。'), findsOneWidget);
      expect(f.graph.queue.state.entries, hasLength(2));
      await closeLibrary(tester, f);
    },
  );
}
