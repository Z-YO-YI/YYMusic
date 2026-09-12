import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/layout_class.dart';

import '../support/design_harness.dart';
import '../support/playlist_content_harness.dart' show settleContent;
import '../support/system_playlist_fixture.dart';
import '../support/system_playlist_harness.dart';
import 'queue_screen_test.dart' show queuePage, queueRow, revealQueue;

Future<TestGesture> startQueueDrag(
  WidgetTester tester,
  String id, {
  bool windows = false,
}) async {
  await revealQueue(tester, id);
  final anchor = windows
      ? tester.getCenter(
          find.byKey(
            ValueKey<Object>((
              'queue-drag-handle',
              ValueKey(('queue-row', id)),
            )),
          ),
        )
      : tester.getTopLeft(queueRow(id)) + const Offset(24, 28);
  final gesture = await tester.startGesture(
    anchor,
    kind: windows ? PointerDeviceKind.mouse : PointerDeviceKind.touch,
  );
  if (windows) {
    await gesture.moveBy(const Offset(0, 24));
  }
  await tester.pump(const Duration(milliseconds: 650));
  return gesture;
}

void main() {
  setUpAll(loadDesignAssets);
  for (final (platform, size) in const [
    (YYPlatform.android, Size(390, 1000)),
    (YYPlatform.android, Size(1024, 768)),
    (YYPlatform.windows, Size(1440, 1000)),
  ]) {
    testWidgets(
      '$platform $size actual drag moves exact duplicate to window end without starting audio',
      (tester) async {
        final f = SystemPlaylistFixture();
        await mountSystemPlaylist(
          tester,
          f,
          location: '/queue',
          platform: platform,
          size: size,
        );
        final target =
            tester.getBottomLeft(queueRow('q-4')) + const Offset(24, 70);
        final drag = await startQueueDrag(
          tester,
          'q-1',
          windows: platform == YYPlatform.windows,
        );
        await drag.moveTo(target);
        await tester.pump(const Duration(milliseconds: 300));
        await drag.up();
        await settleContent(tester);
        expect(f.graph.queue.state.entries.map((e) => e.id), [
          'q-0',
          'q-2',
          'q-3',
          'q-4',
          'q-1',
        ]);
        expect(f.graph.queue.state.currentEntryId, 'q-0');
        expect(f.engine.calls, isEmpty);
        expect(tester.takeException(), isNull);
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
    'cancel',
    'drop-leave',
  ]) {
    testWidgets('native drag and delayed callback cancel on $reason', (
      tester,
    ) async {
      final f = SystemPlaylistFixture();
      await mountSystemPlaylist(tester, f, location: '/queue');
      final target = tester.getCenter(queueRow('q-3')) + const Offset(0, 20);
      final drag = await startQueueDrag(tester, 'q-1');
      final old = tester
          .widget<SliverReorderableList>(find.byType(SliverReorderableList))
          .onReorderItem!;
      await drag.moveTo(target);
      await tester.pump(const Duration(milliseconds: 60));
      switch (reason) {
        case 'refresh':
          queuePage(tester).controller.read.refresh();
        case 'replace':
          await tester.runAsync(
            () => f.graph.queue.replace(
              f.graph.queue.state.entries,
              currentEntryId: 'q-0',
            ),
          );
        case 'resize':
          tester.view.physicalSize = const Size(430, 932);
        case 'leave':
          queuePage(tester).widget.navigation.openPlayer();
        case 'zero':
          tester.view.physicalSize = Size.zero;
        case 'dispose':
          await tester.pumpWidget(const SizedBox.shrink());
        case 'cancel':
          await drag.cancel();
        case 'drop-leave':
          await drag.up();
          await tester.pump(const Duration(milliseconds: 20));
          queuePage(tester).widget.navigation.openPlayer();
      }
      await settleContent(tester);
      if (reason != 'cancel' && reason != 'drop-leave') await drag.up();
      if (reason != 'cancel') old(1, 3);
      await settleContent(tester);
      expect(f.graph.queue.state.entries.map((e) => e.id), [
        'q-0',
        'q-1',
        'q-2',
        'q-3',
        'q-4',
      ]);
      expect(f.engine.calls, isEmpty);
      expect(tester.takeException(), isNull);
      await closeSystemPlaylist(tester, f);
    });
  }
  testWidgets(
    'native semantic reorder binds snapshot and missing items are sortable',
    (tester) async {
      final f = SystemPlaylistFixture();
      await mountSystemPlaylist(tester, f, location: '/queue');
      final old = tester
          .widget<SliverReorderableList>(find.byType(SliverReorderableList))
          .onReorderItem!;
      old(2, 0);
      await settleContent(tester);
      expect(f.graph.queue.state.entries.first.id, 'q-2');
      f.collection.queueWrites.clear();
      old(1, 3);
      await settleContent(tester);
      expect(f.collection.queueWrites, isEmpty);
      expect(f.engine.calls, isEmpty);
      await closeSystemPlaylist(tester, f);
    },
  );
  testWidgets(
    'long press without movement returns to original queue without write',
    (tester) async {
      final f = SystemPlaylistFixture();
      await mountSystemPlaylist(tester, f, location: '/queue');
      final drag = await startQueueDrag(tester, 'q-2');
      await drag.up();
      await settleContent(tester);
      expect(f.collection.queueWrites, isEmpty);
      expect(f.engine.calls, isEmpty);
      expect(tester.takeException(), isNull);
      await closeSystemPlaylist(tester, f);
    },
  );
  testWidgets(
    'edge drag auto-scrolls a lazy window and preserves unseen root tail',
    (tester) async {
      final f = SystemPlaylistFixture(count: 80);
      await mountSystemPlaylist(tester, f, location: '/queue');
      final page = queuePage(tester),
          initialOffset = queuePage(tester).scroll.offset;
      final bounds = tester.getRect(find.byType(CustomScrollView).first);
      final drag = await startQueueDrag(tester, 'q-1');
      await drag.moveTo(bounds.bottomCenter - const Offset(0, 5));
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 40));
      }
      expect(page.scroll.offset, greaterThan(initialOffset));
      expect(page.controller.read.content!.entries, hasLength(20));
      await drag.up();
      await settleContent(tester);
      expect(f.graph.queue.state.entries[1].id, isNot('q-1'));
      expect(f.graph.queue.state.entries[20].id, 'q-20');
      expect(f.graph.queue.state.entries.last.id, 'q-79');
      expect(f.engine.calls, isEmpty);
      expect(tester.takeException(), isNull);
      await closeSystemPlaylist(tester, f);
    },
  );
  testWidgets(
    'dragging the actively playing item preserves the audio session',
    (tester) async {
      final f = SystemPlaylistFixture();
      await mountSystemPlaylist(tester, f, location: '/queue');
      await tester.runAsync(f.graph.playback.play);
      await settleContent(tester);
      expect(f.engine.calls, ['load', 'play']);
      final target =
          tester.getBottomLeft(queueRow('q-4')) + const Offset(24, 70);
      final drag = await startQueueDrag(tester, 'q-0');
      expect(queuePage(tester).controller.read.isCurrent, isTrue);
      expect(queuePage(tester).controller.read.busy, isFalse);
      expect(find.byType(ReorderableDelayedDragStartListener), findsWidgets);
      await drag.moveTo(target);
      await tester.pump(const Duration(milliseconds: 300));
      await drag.up();
      // Native reorder submits only after its drop animation. Drain the real
      // persistence work after that animation, not before its callback runs.
      await tester.pumpAndSettle();
      await settleContent(tester);
      expect(f.graph.queue.editBusy, isFalse);
      expect(f.graph.queue.state.entries.map((e) => e.id), [
        'q-1',
        'q-2',
        'q-3',
        'q-4',
        'q-0',
      ]);
      expect(f.graph.queue.state.currentEntryId, 'q-0');
      expect(f.engine.calls, ['load', 'play']);
      expect(tester.takeException(), isNull);
      await closeSystemPlaylist(tester, f);
    },
  );
  testWidgets('Windows consecutive keyboard moves retain the focused action', (
    tester,
  ) async {
    final f = SystemPlaylistFixture();
    await mountSystemPlaylist(
      tester,
      f,
      location: '/queue',
      platform: YYPlatform.windows,
      size: const Size(1440, 1000),
    );
    final action = find.descendant(
      of: queueRow('q-1'),
      matching: find.byKey(const ValueKey('queue-action-down')),
    );
    final focus = Focus.of(tester.element(action));
    focus.requestFocus();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await settleContent(tester);
    expect(f.graph.queue.state.entries[2].id, 'q-1');
    expect(FocusManager.instance.primaryFocus, same(focus));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await settleContent(tester);
    expect(f.graph.queue.state.entries[3].id, 'q-1');
    expect(f.engine.calls, isEmpty);
    await closeSystemPlaylist(tester, f);
  });
}
