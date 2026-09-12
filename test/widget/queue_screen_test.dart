import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/design_system/yy_button.dart';
import 'package:yymusic/design_system/yy_queue_tile.dart';
import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/features/queue/common/queue_screen.dart';

import '../support/design_harness.dart';
import '../support/playlist_content_harness.dart' show settleContent;
import '../support/system_playlist_fixture.dart';
import '../support/system_playlist_harness.dart';

Finder queueRow(String id) => find.byKey(ValueKey(('queue-row', id)));
QueueScreenState queuePage(WidgetTester tester) =>
    tester.state(find.byType(QueueScreen));
YYQueueTile tile(WidgetTester tester, String id) => tester.widget(queueRow(id));

Future<void> revealQueue(WidgetTester tester, String id) async {
  final scroll = queuePage(tester).scroll;
  if (queueRow(id).evaluate().isEmpty) {
    scroll.jumpTo(0);
    await tester.pumpAndSettle();
  }
  for (var i = 0; i < 20 && queueRow(id).evaluate().isEmpty; i++) {
    scroll.jumpTo(
      (scroll.offset + 80).clamp(0, scroll.position.maxScrollExtent),
    );
    await tester.pumpAndSettle();
  }
  await tester.ensureVisible(queueRow(id));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadDesignAssets);
  for (final (name, platform, size) in const [
    ('phone', YYPlatform.android, Size(360, 800)),
    ('phone-landscape', YYPlatform.android, Size(568, 320)),
    ('tablet', YYPlatform.android, Size(1024, 768)),
    ('windows', YYPlatform.windows, Size(1440, 900)),
  ]) {
    testWidgets(
      '$name exact play, independent missing-item management and move',
      (tester) async {
        final f = SystemPlaylistFixture();
        await mountSystemPlaylist(
          tester,
          f,
          location: '/queue',
          platform: platform,
          size: size,
        );
        final page = queuePage(tester);
        await revealQueue(tester, 'q-1');
        tile(tester, 'q-1').onPressed!();
        await settleContent(tester);
        expect(f.engine.calls, ['load', 'play']);
        expect(f.graph.queue.state.currentEntryId, 'q-1');
        await revealQueue(tester, 'q-2');
        final missing = tile(tester, 'q-2');
        expect(missing.onPressed, isNull);
        expect(missing.allowManagementWhenDisabled, isTrue);
        missing.onMoveUp!();
        await settleContent(tester);
        expect(f.graph.queue.state.entries[1].id, 'q-2');
        expect(f.engine.calls, ['load', 'play']);
        await revealQueue(tester, 'q-2');
        if (platform == YYPlatform.android) {
          await tester.tap(
            find.descendant(
              of: queueRow('q-2'),
              matching: find.byKey(const ValueKey('queue-action-x')),
            ),
          );
        } else {
          tile(tester, 'q-2').onRemove!();
        }
        await settleContent(tester);
        expect(
          f.graph.queue.state.entries.map((e) => e.id),
          isNot(contains('q-2')),
        );
        expect(page.controller.read.content!.totalCount, 4);
        expect(tester.takeException(), isNull);
        await closeSystemPlaylist(tester, f);
      },
    );
  }
  testWidgets('current removal confirms stop and clear confirms separately', (
    tester,
  ) async {
    final f = SystemPlaylistFixture();
    await mountSystemPlaylist(tester, f, location: '/queue');
    tile(tester, 'q-0').onPressed!();
    await settleContent(tester);
    tile(tester, 'q-0').onRemove!();
    await tester.pumpAndSettle();
    expect(find.text('移除当前队列项'), findsOneWidget);
    expect(f.graph.queue.state.entries, hasLength(5));
    await tester.tap(find.text('确认移除'));
    await settleContent(tester);
    expect(f.graph.queue.state.currentEntryId, 'q-1');
    expect(f.engine.calls, ['load', 'play', 'stop']);
    await tester.tap(find.text('清空'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确认清空'));
    await settleContent(tester);
    expect(f.graph.queue.state.entries, isEmpty);
    expect(find.textContaining('播放队列为空。'), findsOneWidget);
    await closeSystemPlaylist(tester, f);
  });
  for (final change in [
    'resize',
    'replace',
    'leave',
    'refresh',
    'zero',
    'dispose',
  ]) {
    testWidgets('old edit and confirmation cannot affect queue after $change', (
      tester,
    ) async {
      final f = SystemPlaylistFixture();
      await mountSystemPlaylist(tester, f, location: '/queue');
      final remove = tile(tester, 'q-2').onRemove!;
      await tester.tap(find.text('清空'));
      await tester.pumpAndSettle();
      final confirm = tester
          .widget<YYButton>(find.widgetWithText(YYButton, '确认清空'))
          .onPressed!;
      switch (change) {
        case 'resize':
          tester.view.physicalSize = const Size(430, 932);
        case 'replace':
          await tester.runAsync(
            () => f.graph.queue.replace(
              f.graph.queue.state.entries,
              currentEntryId: 'q-0',
            ),
          );
        case 'leave':
          queuePage(tester).widget.navigation.openPlayer();
        case 'refresh':
          queuePage(tester).controller.read.refresh();
        case 'zero':
          tester.view.physicalSize = Size.zero;
        case 'dispose':
          await tester.pumpWidget(const SizedBox.shrink());
      }
      await settleContent(tester);
      remove();
      confirm();
      await settleContent(tester);
      expect(f.graph.queue.state.entries, hasLength(5));
      expect(f.engine.calls, isEmpty);
      expect(tester.takeException(), isNull);
      await closeSystemPlaylist(tester, f);
    });
  }
  testWidgets('safe failure survives reopen, requires explicit retry', (
    tester,
  ) async {
    final f = SystemPlaylistFixture();
    await mountSystemPlaylist(tester, f, location: '/queue');
    f.collection.beforeQueueWrite = (_) async =>
        throw StateError('private-marker');
    tile(tester, 'q-2').onRemove!();
    await settleContent(tester);
    expect(find.text('队列操作未完成'), findsOneWidget);
    expect(find.textContaining('private-marker'), findsNothing);
    final nav = queuePage(tester).widget.navigation;
    nav.back();
    await settleContent(tester);
    nav.openSystemPlaylist(SystemPlaylistType.queue);
    await settleContent(tester);
    expect(find.text('队列操作未完成'), findsOneWidget);
    f.collection.beforeQueueWrite = null;
    await tester.tap(find.text('重试队列操作'));
    await settleContent(tester);
    expect(f.graph.queue.state.entries, hasLength(4));
    expect(f.graph.queue.editFailure, isNull);
    await closeSystemPlaylist(tester, f);
  });
  testWidgets(
    'Windows Enter on missing remove, Escape dismisses only confirmation',
    (tester) async {
      final f = SystemPlaylistFixture();
      await mountSystemPlaylist(
        tester,
        f,
        location: '/queue',
        platform: YYPlatform.windows,
        size: const Size(1440, 900),
      );
      final action = find.descendant(
        of: queueRow('q-2'),
        matching: find.byKey(const ValueKey('queue-action-x')),
      );
      Focus.of(tester.element(action)).requestFocus();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await settleContent(tester);
      expect(f.graph.queue.state.entries, hasLength(4));
      await tester.tap(find.text('清空'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('确认清空'), findsNothing);
      expect(find.byType(QueueScreen), findsOneWidget);
      expect(f.graph.queue.state.entries, hasLength(4));
      await closeSystemPlaylist(tester, f);
    },
  );
  testWidgets('rapid repeated queue navigation retains one session', (
    tester,
  ) async {
    final f = SystemPlaylistFixture();
    await mountSystemPlaylist(tester, f, location: '/queue');
    final nav = queuePage(tester).widget.navigation;
    nav.openSystemPlaylist(SystemPlaylistType.queue);
    nav.openSystemPlaylist(SystemPlaylistType.queue);
    await settleContent(tester);
    expect(f.graph.systemPlaylists.retainedSessionCount, 1);
    nav.openPlayer();
    await settleContent(tester);
    nav.openSystemPlaylist(SystemPlaylistType.queue);
    await settleContent(tester);
    expect(find.byType(QueueScreen), findsOneWidget);
    expect(f.graph.systemPlaylists.retainedSessionCount, 1);
    expect(tester.takeException(), isNull);
    await closeSystemPlaylist(tester, f);
  });
  testWidgets(
    'busy is immediate and a repeated old callback cannot write twice',
    (tester) async {
      final f = SystemPlaylistFixture();
      await mountSystemPlaylist(tester, f, location: '/queue');
      final gate = Completer<void>();
      addTearDown(() {
        if (!gate.isCompleted) gate.complete();
      });
      f.collection.queueWrites.clear();
      f.collection.beforeQueueWrite = (_) => gate.future;
      final remove = tile(tester, 'q-2').onRemove!;
      remove();
      remove();
      await settleContent(tester);
      expect(find.text('正在处理队列操作…'), findsOneWidget);
      expect(
        tester.widget<YYButton>(find.widgetWithText(YYButton, '清空')).onPressed,
        isNull,
      );
      gate.complete();
      await settleContent(tester);
      expect(f.collection.queueWrites, hasLength(1));
      expect(f.graph.queue.state.entries, hasLength(4));
      expect(tester.takeException(), isNull);
      await closeSystemPlaylist(tester, f);
    },
  );
}
