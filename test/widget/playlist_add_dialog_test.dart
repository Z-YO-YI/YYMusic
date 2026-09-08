import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/design_system/yy_button.dart';
import 'package:yymusic/design_system/yy_context_menu.dart';
import 'package:yymusic/design_system/yy_dialog.dart';
import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/features/library/common/library_controller.dart';
import 'package:yymusic/features/playlists/common/playlist_add_dialog.dart';

import '../support/catalog_detail_graph_fixture.dart';
import '../support/catalog_detail_harness.dart';
import '../support/catalog_detail_menu_harness.dart';
import '../support/design_harness.dart';
import '../support/library_graph_fixture.dart';
import '../support/playlist_add_harness.dart';
import '../support/playlist_content_harness.dart';
import '../support/playlist_content_probe.dart';
import 'catalog_detail_screen_test.dart' show focusDetailButton;
import 'library_screen_test.dart' show mountLibrary, closeLibrary;

void main() {
  setUpAll(loadDesignAssets);
  testWidgets(
    'more choices stops at 200 and explicit filtering reaches a later target',
    (tester) async {
      final f = CatalogDetailGraphFixture(trackCount: 5);
      for (var i = 0; i < 235; i++) {
        final id = 'p${i.toString().padLeft(3, '0')}';
        await f.collection.createPlaylist(contentPlaylist(id, name: '歌单$id'));
      }
      await mountDetail(tester, f);
      await openDetailPicker(tester, f);
      final state = pickerState(tester);
      for (var size = 20; size < 200; size += 20) {
        expect(state.controller.snapshot!.items.length, size);
        await tester.ensureVisible(pickerButton('更多歌单'));
        await tester.tap(pickerButton('更多歌单'));
        await settleContent(tester);
      }
      expect(state.controller.snapshot!.items.length, 200);
      expect(pickerButton('更多歌单'), findsNothing);
      expect(find.textContaining('当前只显示前200个'), findsOneWidget);
      expect(f.collection.selectionReadCalls.map((c) => c.page.limit), [
        20,
        40,
        60,
        80,
        100,
        120,
        140,
        160,
        180,
        200,
      ]);
      state.input.text = 'p234';
      await tester.pump();
      await tester.ensureVisible(pickerButton('筛选歌单'));
      await tester.tap(pickerButton('筛选歌单'));
      await settleContent(tester);
      expect(state.controller.snapshot!.items.single.id, 'p234');
      await tester.ensureVisible(choiceButton('p234'));
      await tester.tap(choiceButton('p234'));
      await settleContent(tester);
      expect(
        (await f.collection.getPlaylistEntries('p234')).single.track,
        f.repository.trackData[2].ref,
      );
      expect(tester.takeException(), isNull);
      await closeDetail(tester, f);
    },
  );
  testWidgets(
    'a covered picker denies retained callbacks and resumes its same session',
    (tester) async {
      final f = CatalogDetailGraphFixture(trackCount: 5);
      await f.collection.createPlaylist(contentPlaylist('p'));
      await mountDetail(tester, f);
      await openDetailPicker(tester, f);
      final state = pickerState(tester);
      final oldAdd = tester.widget<YYButton>(choiceButton('p')).onPressed!;
      final oldClose = tester.widget<YYButton>(pickerButton('取消')).onPressed!;
      final navigator = Navigator.of(
        tester.element(find.byType(PlaylistAddDialog)),
        rootNavigator: true,
      );
      unawaited(
        navigator.push<void>(
          RawDialogRoute<void>(
            transitionDuration: Duration.zero,
            pageBuilder: (_, _, _) => const Center(child: Text('覆盖测试')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      oldAdd();
      oldClose();
      await settleContent(tester);
      expect(find.text('覆盖测试'), findsOneWidget);
      expect((await f.collection.getPlaylistEntries('p')), isEmpty);
      expect(state.controller.canAdd('p'), isFalse);
      navigator.pop();
      await settleContent(tester);
      expect(pickerState(tester), same(state));
      expect(state.controller.canAdd('p'), isTrue);
      await tester.tap(choiceButton('p'));
      await settleContent(tester);
      expect((await f.collection.getPlaylistEntries('p')).length, 1);
      await closeDetail(tester, f);
    },
  );
  testWidgets(
    'opening the picker revokes a pending detail playback without stopping existing music',
    (tester) async {
      final f = CatalogDetailGraphFixture(trackCount: 5);
      await f.collection.createPlaylist(contentPlaylist('p'));
      await mountDetail(tester, f);
      final gate = Completer<void>();
      addTearDown(() {
        if (!gate.isCompleted) gate.complete();
      });
      f.engine.loadGate = gate.future;
      final track = f.repository.trackData.first;
      await revealDetailTrack(tester, track);
      await tester.tap(find.byKey(ValueKey(track.ref)));
      await settleContent(tester);
      expect(f.engine.calls, contains('load'));
      await openDetailPicker(tester, f);
      gate.complete();
      await settleContent(tester);
      expect(f.engine.calls, isNot(contains('play')));
      // Cancellation releases the pending load, which is not playing music.
      expect(f.engine.calls, ['load', 'stop']);
      expect(find.byType(PlaylistAddDialog), findsOneWidget);
      await tester.tap(pickerButton('取消'));
      await settleContent(tester);
      expect(detailState(tester).controller.canPlay(track.ref), isTrue);
      final playing = detailState(tester).controller.play(track.ref);
      await settleContent(tester);
      await playing;
      expect(f.engine.calls, contains('play'));
      final beforePicker = List.of(f.engine.calls);
      await openDetailPicker(tester, f);
      expect(f.engine.calls, beforePicker);
      await tester.tap(pickerButton('取消'));
      await settleContent(tester);
      expect(f.engine.calls, beforePicker);
      await closeDetail(tester, f);
    },
  );
  for (final (platform, size) in [
    (YYPlatform.android, const Size(390, 1000)),
    (YYPlatform.android, const Size(800, 1100)),
    (YYPlatform.windows, const Size(1440, 1000)),
  ]) {
    testWidgets(
      '$platform $size adds unavailable full reference to the selected same-name playlist only',
      (tester) async {
        final f = CatalogDetailGraphFixture(trackCount: 5);
        await f.collection.createPlaylist(contentPlaylist('a', name: '夜间聆听'));
        await f.collection.createPlaylist(
          contentPlaylist('b/%?中', name: '夜间聆听'),
        );
        await f.collection.savePlaylist(
          Playlist(
            id: 'system',
            name: '系统歌单',
            createdAt: contentEpoch,
            updatedAt: contentEpoch,
            isSystem: true,
            systemType: SystemPlaylistType.favorites,
          ),
        );
        await mountDetail(tester, f, platform: platform, size: size);
        await openDetailPicker(tester, f);
        expect(
          find.byType(size.width < 600 ? YYBottomSheet : YYDialog),
          findsOneWidget,
        );
        expect(find.text('系统歌单'), findsNothing);
        expect(
          GoRouter.of(tester.element(find.byType(PlaylistAddDialog)))
              .routeInformationProvider
              .value
              .uri
              .path,
          startsWith('/album/'),
        );
        final add = choiceButton('b/%?中');
        await tester.ensureVisible(add);
        await tester.tap(add);
        await settleContent(tester);
        expect(find.textContaining('已添加到“夜间聆听”'), findsOneWidget);
        expect((await f.collection.getPlaylistEntries('a')), isEmpty);
        expect(
          (await f.collection.getPlaylistEntries('b/%?中')).single.track,
          f.repository.trackData[2].ref,
        );
        expect(f.engine.calls, isEmpty);
        await tester.tap(pickerButton('完成'));
        await settleContent(tester);
        expect(find.byType(PlaylistAddDialog), findsNothing);
        expect(f.graph.playlistAdds.retainedSessionCount, 0);
        expect(tester.takeException(), isNull);
        await closeDetail(tester, f);
      },
    );
  }
  testWidgets(
    'library menu adds via the same root writer without changing category or playback',
    (tester) async {
      final f = LibraryGraphFixture(count: 5);
      await f.collection.createPlaylist(contentPlaylist('target'));
      await mountLibrary(tester, f);
      f.graph.libraryController.selectCategory(LibraryCategory.tracks);
      await settleContent(tester);
      final row = find.byKey(ValueKey(f.tracks.first.ref));
      await tester.ensureVisible(row);
      await tester.longPress(row);
      await tester.pumpAndSettle();
      await tester.tap(find.text('添加到歌单'));
      await settleContent(tester);
      await tester.tap(choiceButton('target'));
      await settleContent(tester);
      expect(
        (await f.collection.getPlaylistEntries('target')).single.track,
        f.tracks.first.ref,
      );
      await tester.tap(pickerButton('完成'));
      await settleContent(tester);
      expect(f.graph.libraryController.category, LibraryCategory.tracks);
      expect(f.engine.calls, isEmpty);
      await closeLibrary(tester, f);
    },
  );
  testWidgets(
    'IME and changed input disable old choices until explicit filter, including retained callbacks',
    (tester) async {
      final f = CatalogDetailGraphFixture(trackCount: 5);
      await f.collection.createPlaylist(contentPlaylist('night', name: '夜间聆听'));
      await f.collection.createPlaylist(contentPlaylist('day', name: '白日之声'));
      await mountDetail(tester, f);
      await openDetailPicker(tester, f);
      final state = pickerState(tester),
          stale = tester.widget<YYButton>(choiceButton('night')).onPressed!;
      final reads = f.collection.selectionReadCalls.length;
      state.input.text = ' ' * 513;
      await tester.pump();
      stale();
      await settleContent(tester);
      expect(tester.widget<YYButton>(choiceButton('night')).onPressed, isNull);
      state.inputFocus.requestFocus();
      state.input.value = const TextEditingValue(
        text: '夜',
        selection: TextSelection.collapsed(offset: 1),
        composing: TextRange(start: 0, end: 1),
      );
      await tester.pump();
      stale();
      await settleContent(tester);
      expect(tester.widget<YYButton>(pickerButton('筛选歌单')).onPressed, isNull);
      expect(f.collection.selectionReadCalls.length, reads);
      state.input.value = const TextEditingValue(
        text: '夜',
        selection: TextSelection.collapsed(offset: 1),
      );
      await tester.pump();
      expect(tester.widget<YYButton>(choiceButton('night')).onPressed, isNull);
      await tester.ensureVisible(pickerButton('筛选歌单'));
      await tester.tap(pickerButton('筛选歌单'));
      await settleContent(tester);
      expect(state.controller.snapshot!.items.single.id, 'night');
      stale();
      await settleContent(tester);
      expect((await f.collection.getPlaylistEntries('night')), isEmpty);
      await tester.ensureVisible(choiceButton('night'));
      await tester.tap(choiceButton('night'));
      await settleContent(tester);
      expect((await f.collection.getPlaylistEntries('night')).length, 1);
      expect(tester.takeException(), isNull);
      await closeDetail(tester, f);
    },
  );
  testWidgets(
    'Windows Tab remains modal, Space cannot play, Escape restores the original row focus',
    (tester) async {
      final f = CatalogDetailGraphFixture(trackCount: 5);
      await f.collection.createPlaylist(contentPlaylist('p'));
      await mountDetail(
        tester,
        f,
        platform: YYPlatform.windows,
        size: const Size(1024, 900),
      );
      final track = f.repository.trackData[2];
      final playing = f.graph.playback.playCatalogTrack(
        f.repository.trackData.first.ref,
      );
      await settleContent(tester);
      await playing;
      final pausing = f.graph.playback.pause();
      await settleContent(tester);
      await pausing;
      final engineCalls = f.engine.calls.length;
      await revealDetailTrack(tester, track);
      final origin = await focusDetailButton(tester, '${track.title} 的更多操作');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.tap(find.text('添加到歌单'));
      await settleContent(tester);
      for (var i = 0; i < 12; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        final context = FocusManager.instance.primaryFocus!.context!;
        expect(
          context.findAncestorWidgetOfExactType<PlaylistAddDialog>(),
          isNotNull,
        );
      }
      // Do not assume a fixed Tab count leaves the same button focused.
      // Space on Cancel should activate Cancel; explicitly park on the scope.
      final scope = FocusScope.of(tester.element(pickerButton('取消')));
      scope.requestScopeFocus();
      await tester.pump();
      expect(FocusManager.instance.primaryFocus, same(scope));
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await settleContent(tester);
      expect(f.engine.calls.length, engineCalls);
      expect(find.byType(PlaylistAddDialog), findsOneWidget);
      pickerState(tester).inputFocus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await settleContent(tester);
      expect(f.engine.calls.length, engineCalls);
      expect(find.byType(PlaylistAddDialog), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await settleContent(tester);
      expect(find.byType(PlaylistAddDialog), findsNothing);
      expect(FocusManager.instance.primaryFocus, same(origin));
      expect(f.engine.calls.length, engineCalls);
      await closeDetail(tester, f);
    },
  );
  testWidgets(
    'Android Back closes picker first and stale closed or reopened callbacks cannot add',
    (tester) async {
      final f = CatalogDetailGraphFixture(trackCount: 5);
      await f.collection.createPlaylist(contentPlaylist('p'));
      await mountDetail(tester, f);
      await openDetailPicker(tester, f);
      final old = tester.widget<YYButton>(choiceButton('p')).onPressed!;
      final oldClose = tester.widget<YYButton>(pickerButton('取消')).onPressed!;
      await tester.binding.handlePopRoute();
      await settleContent(tester);
      expect(find.byType(PlaylistAddDialog), findsNothing);
      await openDetailPicker(tester, f);
      old();
      oldClose();
      await settleContent(tester);
      expect((await f.collection.getPlaylistEntries('p')), isEmpty);
      expect(find.byType(PlaylistAddDialog), findsOneWidget);
      final close = tester.widget<YYButton>(pickerButton('取消')).onPressed!;
      close();
      close();
      await settleContent(tester);
      expect(find.byType(PlaylistAddDialog), findsNothing);
      expect(detailState(tester).controller, isNotNull);
      await closeDetail(tester, f);
    },
  );
  testWidgets(
    'rotation zero size and low IME viewport retain picker session input and selection scroll',
    (tester) async {
      final f = CatalogDetailGraphFixture(trackCount: 5);
      for (var i = 0; i < 45; i++) {
        await f.collection.createPlaylist(contentPlaylist('p$i', name: '歌单$i'));
      }
      await mountDetail(tester, f);
      await openDetailPicker(tester, f);
      final state = pickerState(tester);
      state.controller.loadMore();
      await settleContent(tester);
      state.scroll.jumpTo(150);
      state.input.text = '草稿';
      await tester.pump();
      final reads = f.collection.selectionReadCalls.length;
      for (final size in [
        const Size(800, 1100),
        const Size(1024, 768),
        Size.zero,
        const Size(590, 1000),
        const Size(800, 480),
      ]) {
        tester.view.physicalSize = size;
        await tester.pumpAndSettle();
        expect(pickerState(tester), same(state));
        expect(state.input.text, '草稿');
        expect(state.controller.snapshot!.items.length, 40);
        expect(tester.takeException(), isNull);
      }
      tester.view.viewInsets = const FakeViewPadding(bottom: 220);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(f.collection.selectionReadCalls.length, reads);
      expect(state.scroll.offset, greaterThan(0));
      await closeDetail(tester, f);
    },
  );
  testWidgets(
    'empty failed reading and recovery are explicit and no creation or playback is fabricated',
    (tester) async {
      final f = CatalogDetailGraphFixture(trackCount: 5);
      await mountDetail(tester, f);
      await openDetailPicker(tester, f);
      expect(find.textContaining('还没有自定义歌单'), findsOneWidget);
      f.collection.selectionReader = (_, _) async =>
          throw StateError('private-marker');
      pickerState(tester).controller.refresh();
      await settleContent(tester);
      expect(find.text('歌单暂不可选'), findsOneWidget);
      expect(find.textContaining('private-marker'), findsNothing);
      f.collection.selectionReader = null;
      await f.collection.createPlaylist(contentPlaylist('p'));
      await tester.ensureVisible(pickerButton('重试筛选'));
      await tester.tap(pickerButton('重试筛选'));
      await settleContent(tester);
      expect(choiceButton('p'), findsOneWidget);
      expect(f.engine.calls, isEmpty);
      await closeDetail(tester, f);
    },
  );
  testWidgets(
    'old track menu callback cannot reopen a picker after close and same-track reopen',
    (tester) async {
      final f = CatalogDetailGraphFixture(trackCount: 5);
      await f.collection.createPlaylist(contentPlaylist('p'));
      await mountDetail(tester, f);
      final track = f.repository.trackData[2];
      await openDetailMenu(tester, track);
      final old = tester
          .widget<YYContextMenu>(find.byType(YYContextMenu))
          .onSelected;
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      await openDetailMenu(tester, track);
      old!('playlist');
      await settleContent(tester);
      expect(find.byType(PlaylistAddDialog), findsNothing);
      expect(find.byType(YYContextMenu), findsOneWidget);
      await closeDetail(tester, f);
    },
  );
  testWidgets(
    'closed picker failure is retained on Library and busy submissions cannot duplicate writes',
    (tester) async {
      final f = LibraryGraphFixture(count: 5);
      await f.collection.createPlaylist(contentPlaylist('p'));
      await mountLibrary(tester, f);
      f.graph.libraryController.selectCategory(LibraryCategory.tracks);
      await settleContent(tester);
      final row = find.byKey(ValueKey(f.tracks.first.ref));
      await tester.ensureVisible(row);
      await tester.longPress(row);
      await tester.pumpAndSettle();
      await tester.tap(find.text('添加到歌单'));
      await settleContent(tester);
      final gate = Completer<void>();
      addTearDown(() {
        if (!gate.isCompleted) gate.complete();
      });
      f.collection.onPlaylistMutation = (_, _) async {
        await gate.future;
        throw StateError('private-marker');
      };
      final add = tester.widget<YYButton>(choiceButton('p')).onPressed!;
      add();
      add();
      await settleContent(tester);
      expect(
        f.collection.playlistMutationCalls
            .where((v) => v == 'append-entry')
            .length,
        1,
      );
      await tester.tap(pickerButton('关闭'));
      await settleContent(tester);
      gate.complete();
      await settleContent(tester);
      expect(find.textContaining('歌曲条目：'), findsOneWidget);
      expect(find.textContaining('private-marker'), findsNothing);
      expect((await f.collection.getPlaylistEntries('p')), isEmpty);
      await closeLibrary(tester, f);
    },
  );
}
