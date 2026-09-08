import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/app_routes.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/design_system/yy_button.dart';
import 'package:yymusic/domain/models/load_state.dart';
import 'package:yymusic/features/library/common/library_controller.dart';
import 'package:yymusic/features/library/common/library_screen.dart';
import 'package:yymusic/features/local_music/common/local_music_controller.dart';
import 'package:yymusic/features/local_music/common/local_music_panel.dart';
import 'package:yymusic/features/local_music/phone/phone_local_music_layout.dart';
import 'package:yymusic/features/local_music/tablet/tablet_local_music_layout.dart';
import 'package:yymusic/features/local_music/windows/windows_local_music_layout.dart';

import '../support/design_harness.dart';
import '../support/library_graph_fixture.dart';
import '../support/local_music_harness.dart';
import '../support/local_music_probe.dart';
import '../unit/local_library_overview_test.dart' show localTrack;
import 'library_screen_test.dart' show mountLibrary, closeLibrary;

Finder localButton(String label) =>
    find.byWidgetPredicate((w) => w is YYButton && w.label == label);

void main() {
  setUpAll(loadDesignAssets);
  for (final (platform, size, layout) in const [
    (YYPlatform.android, Size(390, 1000), PhoneLocalMusicLayout),
    (YYPlatform.android, Size(1024, 768), TabletLocalMusicLayout),
    (YYPlatform.windows, Size(1440, 1000), WindowsLocalMusicLayout),
  ]) {
    testWidgets(
      '$layout displays real statistics folder state and exact native pagination',
      (tester) async {
        final probe = LocalMusicProbe();
        probe.data.tracks.addAll([
          localTrack('a'),
          localTrack('b', remote: true),
        ]);
        probe.data.folders.addAll(
          List.generate(21, (i) => localFolder(i, enabled: i.isEven)),
        );
        final controller = LocalMusicController(repository: probe);
        await mountLocalPanel(
          tester,
          controller,
          platform: platform,
          size: size,
        );
        expect(find.byType(layout), findsOneWidget);
        expect(find.text('已入库歌曲'), findsOneWidget);
        expect(find.text('可用记录 1 · 不可用 0'), findsOneWidget);
        expect(find.text('第 1–20 条，共 21 条'), findsOneWidget);
        expect(find.textContaining('当前权限未验证'), findsWidgets);
        final next = tester.widget<YYButton>(localButton('下一页目录')).onPressed!;
        await tester.ensureVisible(localButton('下一页目录'));
        await tester.tap(localButton('下一页目录'));
        await tester.pumpAndSettle();
        expect(find.text('第 21–21 条，共 21 条'), findsOneWidget);
        expect(controller.content!.folders.single.id, 'folder-020');
        next(); // Callback from the old page cannot advance or re-query.
        await tester.pumpAndSettle();
        expect(probe.calls, hasLength(2));
        expect(tester.takeException(), isNull);
        await unmountLocalPanel(tester, controller);
        await probe.close();
      },
    );
  }

  testWidgets(
    'loading failure retry and empty remain distinct without fake zero values',
    (tester) async {
      final probe = LocalMusicProbe();
      final gate = Completer<void>();
      probe.onRead = (_, _) async {
        await gate.future;
        throw StateError('private-marker');
      };
      final controller = LocalMusicController(repository: probe);
      await mountLocalPanel(tester, controller);
      expect(find.text('正在读取本地索引…'), findsOneWidget);
      expect(find.text('已入库歌曲'), findsNothing);
      gate.complete();
      await tester.pumpAndSettle();
      expect(find.text('本地概览暂不可用'), findsOneWidget);
      expect(find.textContaining('private-marker'), findsNothing);
      probe.onRead = null;
      await tester.tap(localButton('重试'));
      await tester.pumpAndSettle();
      expect(find.text('暂无文件夹记录'), findsOneWidget);
      expect(controller.phase, LoadPhase.empty);
      expect(find.text('本地概览暂不可用'), findsNothing);
      await unmountLocalPanel(tester, controller);
      await probe.close();
    },
  );

  testWidgets(
    'phone tablet and zero-size transitions keep root window but revoke old actions',
    (tester) async {
      final probe = LocalMusicProbe();
      probe.data.folders.addAll(List.generate(25, localFolder));
      final controller = LocalMusicController(repository: probe);
      await mountLocalPanel(tester, controller);
      controller.next(controller.content!);
      await tester.pumpAndSettle();
      final old = tester.widget<YYButton>(localButton('上一页目录')).onPressed!;
      for (final size in [
        const Size(800, 1280),
        const Size(1024, 768),
        const Size(390, 1000),
      ]) {
        tester.view.physicalSize = size;
        await tester.pumpAndSettle();
        expect(controller.content!.page.offset, 20);
        expect(tester.takeException(), isNull);
      }
      tester.view.physicalSize = Size.zero;
      await tester.pumpAndSettle();
      old();
      expect(controller.content!.page.offset, 20);
      tester.view.physicalSize = const Size(390, 1000);
      await tester.pumpAndSettle();
      expect(controller.content!.page.offset, 20);
      expect(tester.takeException(), isNull);
      await unmountLocalPanel(tester, controller);
      await probe.close();
    },
  );

  testWidgets(
    'covered panel blocks captured buttons and resumes from fresh data',
    (tester) async {
      final probe = LocalMusicProbe();
      probe.data.folders.addAll(List.generate(21, localFolder));
      final controller = LocalMusicController(repository: probe);
      final enabled = ValueNotifier(true);
      addTearDown(enabled.dispose);
      await mountLocalPanel(tester, controller, enabled: enabled);
      final old = tester.widget<YYButton>(localButton('下一页目录')).onPressed!;
      enabled.value = false;
      await tester.pumpAndSettle();
      old();
      probe.changes.add(null);
      await tester.pumpAndSettle();
      expect(probe.calls, hasLength(1));
      enabled.value = true;
      await tester.pumpAndSettle();
      expect(controller.content!.page.offset, 0);
      expect(probe.calls, hasLength(2));
      await unmountLocalPanel(tester, controller);
      await probe.close();
    },
  );

  testWidgets(
    'native Windows Enter activates focused refresh without audio controls',
    (tester) async {
      final fixture = LibraryGraphFixture(count: 0);
      await mountLibrary(
        tester,
        fixture,
        platform: YYPlatform.windows,
        size: const Size(1440, 1000),
      );
      fixture.graph.libraryController.selectCategory(LibraryCategory.local);
      await tester.pumpAndSettle();
      final old = fixture.graph.localMusic.content;
      bool refreshHasFocus() =>
          FocusManager.instance.primaryFocus?.context
              ?.findAncestorWidgetOfExactType<YYButton>()
              ?.label ==
          '刷新概览';
      for (var i = 0; i < 60 && !refreshHasFocus(); i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
      }
      expect(refreshHasFocus(), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(fixture.graph.localMusic.content, isNot(same(old)));
      expect(fixture.engine.calls, isEmpty);
      expect(tester.takeException(), isNull);
      await closeLibrary(tester, fixture);
    },
  );

  testWidgets(
    'actual app local category is root-wired and leaving stops reads without replacing playback',
    (tester) async {
      final fixture = LibraryGraphFixture(count: 4);
      await mountLibrary(tester, fixture);
      final player = fixture.graph.playback;
      final local = fixture.graph.localMusic;
      fixture.graph.libraryController.selectCategory(LibraryCategory.local);
      await tester.pumpAndSettle();
      expect(find.byType(LocalMusicPanel), findsOneWidget);
      expect(local.content!.tracks.totalCount, 2);
      expect(local.isCurrent, isTrue);
      fixture.graph.libraryController.selectCategory(LibraryCategory.tracks);
      await tester.pumpAndSettle();
      expect(local.isCurrent, isFalse);
      fixture.graph.libraryController.selectCategory(LibraryCategory.local);
      await tester.pumpAndSettle();
      expect(local.isCurrent, isTrue);
      expect(fixture.graph.playback, same(player));
      final navigation = tester
          .widget<LibraryScreen>(find.byType(LibraryScreen))
          .navigation;
      final oldRefresh = tester
          .widget<YYButton>(localButton('刷新概览'))
          .onPressed!;
      navigation.openPlayer();
      await tester.pumpAndSettle();
      expect(local.isCurrent, isFalse);
      final covered = local.content;
      oldRefresh();
      await tester.pumpAndSettle();
      expect(local.content, same(covered));
      navigation.back();
      await tester.pumpAndSettle();
      expect(local.isCurrent, isTrue);
      fixture.localLibrary.folders.addAll(List.generate(25, localFolder));
      local.refresh();
      await tester.pumpAndSettle();
      local.next(local.content!);
      await tester.pumpAndSettle();
      for (final size in [
        const Size(800, 1280),
        const Size(1024, 768),
        const Size(390, 1000),
      ]) {
        tester.view.physicalSize = size;
        await tester.pumpAndSettle();
        expect(local.isCurrent, isTrue);
        expect(local.content!.page.offset, 20);
        expect(fixture.graph.playback, same(player));
        expect(tester.takeException(), isNull);
      }
      expect(
        fixture.graph.viewState.scrollOffset(AppRoute.library),
        greaterThanOrEqualTo(0),
      );
      await closeLibrary(tester, fixture);
    },
  );
}
