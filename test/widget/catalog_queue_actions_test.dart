import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/catalog_detail_location.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/design_system/yy_context_menu.dart';
import 'package:yymusic/features/catalog_detail/common/catalog_detail_screen.dart';
import 'package:yymusic/features/catalog_detail/common/catalog_detail_sections.dart';
import 'package:yymusic/features/catalog_detail/common/catalog_detail_state.dart';
import 'package:yymusic/features/catalog_detail/phone/phone_catalog_detail_layout.dart';
import 'package:yymusic/features/queue/common/queue_operation_feedback.dart';
import 'package:yymusic/features/queue/common/queue_screen.dart';

import '../support/catalog_detail_graph_fixture.dart';
import '../support/catalog_detail_harness.dart';
import '../support/catalog_detail_menu_harness.dart';
import '../support/design_harness.dart';
import '../support/playlist_content_harness.dart' show settleContent;
import 'library_queue_actions_test.dart' show tapQueueFeedback;

CatalogDetailScreen catalogScreen(WidgetTester tester) =>
    tester.widget<CatalogDetailScreen>(find.byType(CatalogDetailScreen));

Future<YYContextMenu> openCatalogQueueMenu(
  WidgetTester tester,
  CatalogDetailGraphFixture f, {
  int index = 0,
  bool windows = false,
}) async {
  final row = await revealDetailTrack(tester, f.repository.trackData[index]);
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
  for (final artist in [false, true]) {
    for (final (platform, size) in const [
      (YYPlatform.android, Size(390, 1000)),
      (YYPlatform.android, Size(1024, 768)),
      (YYPlatform.windows, Size(1024, 900)),
    ]) {
      testWidgets(
        'detail artist=$artist actual queue gestures $platform $size preserve playing',
        (tester) async {
          final f = CatalogDetailGraphFixture(trackCount: 4);
          await mountDetail(
            tester,
            f,
            platform: platform,
            size: size,
            location: artist
                ? catalogDetailLocation(ArtistDetailTarget(f.artist.ref))
                      .toString()
                : null,
          );
          await tester.runAsync(
            () => f.graph.playback.playCatalogTrack(
              f.repository.trackData.first.ref,
            ),
          );
          await settleContent(tester);
          final current = f.graph.queue.state.currentEntryId;
          final calls = [...f.engine.calls];
          await openCatalogQueueMenu(
            tester,
            f,
            windows: platform == YYPlatform.windows,
          );
          await tester.tap(find.text('添加到队列'));
          await settleContent(tester);
          expect(
            f.graph.queue.state.entries.map((e) => e.id).toSet(),
            hasLength(2),
          );
          expect(
            f.graph.queue.state.entries.every(
              (e) => e.track == f.repository.trackData.first.ref,
            ),
            isTrue,
          );
          await openCatalogQueueMenu(
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
          expect(
            f.graph.queue.state.entries[1].track,
            f.repository.trackData[1].ref,
          );
          expect(f.graph.queue.state.currentEntryId, current);
          expect(f.engine.calls, calls);
          await tapQueueFeedback(tester, '查看播放队列');
          expect(find.byType(QueueScreen), findsOneWidget);
          expect(tester.takeException(), isNull);
          await closeDetail(tester, f);
        },
      );
    }
  }
  for (final reason in [
    'refresh',
    'replace',
    'resize',
    'leave',
    'zero',
    'dispose',
    'dismiss',
    'tab',
  ]) {
    testWidgets('old detail queue menu cannot insert after $reason', (
      tester,
    ) async {
      final f = CatalogDetailGraphFixture(trackCount: 4);
      await mountDetail(
        tester,
        f,
        location: catalogDetailLocation(ArtistDetailTarget(f.artist.ref))
            .toString(),
      );
      final old = await openCatalogQueueMenu(tester, f);
      switch (reason) {
        case 'refresh':
          unawaited(detailState(tester).controller.refresh());
        case 'replace':
          await tester.runAsync(() => f.graph.queue.replace([]));
        case 'resize':
          tester.view.physicalSize = const Size(430, 932);
        case 'leave':
          catalogScreen(tester).navigation.openPlayer();
        case 'zero':
          tester.view.physicalSize = Size.zero;
        case 'dispose':
          await tester.pumpWidget(const SizedBox.shrink());
        case 'dismiss':
          old.onDismiss!();
        case 'tab':
          tester
              .widget<PhoneCatalogDetailLayout>(
                find.byType(PhoneCatalogDetailLayout),
              )
              .sections
              .onTab(CatalogDetailTab.albums);
      }
      await settleContent(tester);
      f.collection.queueWrites.clear();
      old.onSelected!('queue');
      await settleContent(tester);
      expect(f.collection.queueWrites, isEmpty);
      expect(f.graph.queue.state.entries, isEmpty);
      expect(f.engine.calls, isEmpty);
      if (reason == 'resize') {
        // The original resize UX remains: a newly rendered menu is usable.
        await tester.tap(find.text('添加到队列'));
        await settleContent(tester);
        expect(f.graph.queue.state.entries, hasLength(1));
      }
      expect(tester.takeException(), isNull);
      await closeDetail(tester, f);
    });
  }
  testWidgets('missing detail track inserts without becoming playable', (
    tester,
  ) async {
    final f = CatalogDetailGraphFixture(trackCount: 4);
    await mountDetail(tester, f);
    final menu = await openCatalogQueueMenu(tester, f, index: 2);
    expect(menu.items.singleWhere((i) => i.id == 'play').enabled, isFalse);
    expect(menu.items.singleWhere((i) => i.id == 'queue').enabled, isTrue);
    await tester.tap(find.text('添加到队列'));
    await settleContent(tester);
    expect(
      f.graph.queue.state.entries.single.track,
      f.repository.trackData[2].ref,
    );
    expect(f.graph.queue.state.currentEntryId, isNull);
    expect(f.engine.calls, isEmpty);
    await closeDetail(tester, f);
  });
  testWidgets(
    'detail root failure survives covered route and retries same ID',
    (tester) async {
      final f = CatalogDetailGraphFixture(trackCount: 4);
      await mountDetail(tester, f);
      f.collection.beforeQueueWrite = (_) async =>
          throw StateError('private-marker');
      await openCatalogQueueMenu(tester, f);
      await tester.tap(find.text('下一首播放'));
      await settleContent(tester);
      final failure = f.graph.queue.editFailure!;
      final navigation = catalogScreen(tester).navigation;
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
      await closeDetail(tester, f);
    },
  );
  testWidgets(
    'detail busy prevents duplicate and accepted write drains after dispose',
    (tester) async {
      final f = CatalogDetailGraphFixture(trackCount: 4);
      await mountDetail(tester, f);
      final gate = Completer<void>(), entered = Completer<void>();
      addTearDown(() {
        if (!gate.isCompleted) gate.complete();
      });
      f.collection.beforeQueueWrite = (_) async {
        entered.complete();
        await gate.future;
      };
      final old = await openCatalogQueueMenu(tester, f);
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
      await closeDetail(tester, f);
    },
  );
  testWidgets('detail picker return restores queue action permission', (
    tester,
  ) async {
    final f = CatalogDetailGraphFixture(trackCount: 4);
    await mountDetail(tester, f);
    final navigation = catalogScreen(tester).navigation;
    final old = await openCatalogQueueMenu(tester, f);
    old.onSelected!('playlist');
    await settleContent(tester);
    navigation.back();
    await settleContent(tester);
    await openCatalogQueueMenu(tester, f);
    await tester.tap(find.text('添加到队列'));
    await settleContent(tester);
    expect(f.graph.queue.state.entries, hasLength(1));
    await closeDetail(tester, f);
  });
  testWidgets('old detail notice dismissal cannot clear a newer notice', (
    tester,
  ) async {
    final f = CatalogDetailGraphFixture(trackCount: 4);
    await mountDetail(tester, f);
    await openCatalogQueueMenu(tester, f);
    await tester.tap(find.text('添加到队列'));
    await settleContent(tester);
    final old = tester
        .widget<QueueOperationFeedback>(find.byType(QueueOperationFeedback))
        .onDismissNotice;
    await openCatalogQueueMenu(tester, f, index: 1);
    await tester.tap(find.text('下一首播放'));
    await settleContent(tester);
    old();
    await tester.pumpAndSettle();
    expect(find.text('已设为下一首播放。当前播放不会中断。'), findsOneWidget);
    expect(f.graph.queue.state.entries, hasLength(2));
    await closeDetail(tester, f);
  });
}
