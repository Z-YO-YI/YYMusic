import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/app/yy_music_app.dart';
import 'package:yymusic/design_system/yy_button.dart';
import 'package:yymusic/design_system/yy_context_menu.dart';
import 'package:yymusic/design_system/yy_track_tile.dart';
import 'package:yymusic/features/library/common/library_controller.dart';
import 'package:yymusic/features/library/common/library_screen.dart';
import 'package:yymusic/features/library/phone/phone_library_layout.dart';
import 'package:yymusic/features/library/tablet/tablet_library_layout.dart';
import 'package:yymusic/features/library/windows/windows_library_layout.dart';

import '../support/close_graph.dart';
import '../support/design_harness.dart';
import '../support/library_graph_fixture.dart';

Future<void> mountLibrary(
  WidgetTester tester,
  LibraryGraphFixture fixture, {
  YYPlatform platform = YYPlatform.android,
  Size size = const Size(390, 1000),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = 1.3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await fixture.graph.initialize();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [dependencyGraphProvider.overrideWithValue(fixture.graph)],
      child: RepaintBoundary(
        key: const ValueKey('library-golden'),
        child: YYMusicApp(platform: platform, initialLocation: '/library'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> closeLibrary(
  WidgetTester tester,
  LibraryGraphFixture fixture,
) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await closeGraph(tester, fixture.graph);
  await tester.runAsync(fixture.disposeFakes);
}

Finder libraryButton(String label) =>
    find.byWidgetPredicate((w) => w is YYButton && w.label == label);

void main() {
  setUpAll(loadDesignAssets);
  testWidgets(
    'five categories, filters and sorting survive three Android layouts',
    (tester) async {
      final fixture = LibraryGraphFixture();
      await mountLibrary(tester, fixture);
      final controller = fixture.graph.libraryController;
      final player = fixture.graph.playback;
      expect(find.byType(PhoneLibraryLayout), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey(LibraryCategory.tracks)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey(LibrarySource.local)));
      await tester.pumpAndSettle();
      await tester.tap(libraryButton('升序'));
      await tester.pumpAndSettle();
      for (final size in [
        const Size(600, 960),
        const Size(1024, 768),
        const Size(844, 390),
        const Size(390, 1000),
      ]) {
        tester.view.physicalSize = size;
        await tester.pumpAndSettle();
        expect(fixture.graph.libraryController, same(controller));
        expect(fixture.graph.playback, same(player));
        expect(controller.source, LibrarySource.local);
        expect(controller.category, LibraryCategory.tracks);
        expect(
          find.byType(TabletLibraryLayout),
          size.width >= 600 ? findsOneWidget : findsNothing,
        );
        expect(tester.takeException(), isNull, reason: '$size');
      }
      controller.selectCategory(LibraryCategory.playlists);
      await tester.pumpAndSettle();
      expect(find.textContaining('已保存的歌单元数据'), findsOneWidget);
      controller.selectCategory(LibraryCategory.local);
      await tester.pumpAndSettle();
      expect(find.textContaining('文件导入、授权和失效恢复尚未接入'), findsOneWidget);
      await closeLibrary(tester, fixture);
    },
  );
  testWidgets(
    'Windows stays Windows; right click menu is modal and Escape restores focus',
    (tester) async {
      final fixture = LibraryGraphFixture();
      await mountLibrary(
        tester,
        fixture,
        platform: YYPlatform.windows,
        size: const Size(1024, 900),
      );
      fixture.graph.libraryController.selectCategory(LibraryCategory.tracks);
      await tester.pumpAndSettle();
      final tile = find.byType(YYTrackTile).first;
      await tester.ensureVisible(tile);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      final previousFocus = FocusManager.instance.primaryFocus;
      await tester.tap(tile, buttons: kSecondaryMouseButton);
      await tester.pumpAndSettle();
      expect(find.byType(YYContextMenu), findsOneWidget);
      expect(fixture.engine.calls, isNot(contains('play')));
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(YYContextMenu), findsNothing);
      expect(FocusManager.instance.primaryFocus, same(previousFocus));
      tester.view.physicalSize = const Size(599, 900);
      await tester.pumpAndSettle();
      expect(find.byType(WindowsLibraryLayout), findsOneWidget);
      expect(tester.takeException(), isNull);
      await closeLibrary(tester, fixture);
    },
  );
  testWidgets(
    'long press and more toggle actual favorites, missing track cannot play',
    (tester) async {
      final fixture = LibraryGraphFixture();
      await mountLibrary(tester, fixture);
      final controller = fixture.graph.libraryController;
      controller.selectCategory(LibraryCategory.tracks);
      await tester.pumpAndSettle();
      final missing = fixture.tracks[2];
      final tile = find.byKey(ValueKey(missing.ref));
      await tester.ensureVisible(tile);
      await tester.pumpAndSettle();
      await tester.longPress(tile);
      await tester.pumpAndSettle();
      final menu = tester.widget<YYContextMenu>(find.byType(YYContextMenu));
      expect(menu.items.first.enabled, isFalse);
      await tester.tap(find.text('收藏歌曲'));
      await tester.pumpAndSettle();
      expect(controller.isFavorite(missing), isTrue);
      expect(find.byType(YYContextMenu), findsNothing);
      final more = find.descendant(
        of: tile,
        matching: find.byType(YYIconButton),
      );
      await tester.tap(more);
      await tester.pumpAndSettle();
      await tester.tap(find.text('取消收藏'));
      await tester.pumpAndSettle();
      expect(controller.isFavorite(missing), isFalse);
      expect(fixture.engine.calls, isNot(contains('play')));
      await closeLibrary(tester, fixture);
    },
  );
  testWidgets(
    'menu playback updates root and current row, route return keeps category',
    (tester) async {
      final fixture = LibraryGraphFixture();
      await mountLibrary(tester, fixture);
      fixture.graph.libraryController.selectCategory(LibraryCategory.tracks);
      await tester.pumpAndSettle();
      final tile = find.byType(YYTrackTile).first;
      await tester.ensureVisible(tile);
      await tester.pumpAndSettle();
      await tester.longPress(tile);
      await tester.pumpAndSettle();
      await tester.tap(find.text('播放歌曲'));
      await tester.pumpAndSettle();
      expect(fixture.graph.queue.state.entries.length, 1);
      expect(tester.widget<YYTrackTile>(tile).playing, isTrue);
      await tester.tap(find.byKey(const ValueKey('nav-home')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('nav-library')));
      await tester.pumpAndSettle();
      expect(fixture.graph.libraryController.category, LibraryCategory.tracks);
      expect(fixture.graph.queue.state.entries.length, 1);
      await closeLibrary(tester, fixture);
    },
  );
  testWidgets(
    'pagination remains lazy and errors retry without fabricating content',
    (tester) async {
      final fixture = LibraryGraphFixture(count: 70);
      await mountLibrary(tester, fixture);
      final controller = fixture.graph.libraryController;
      controller.selectCategory(LibraryCategory.tracks);
      await tester.pumpAndSettle();
      expect(find.byType(YYTrackTile).evaluate().length, lessThan(20));
      fixture.repository.fail = true;
      await controller.loadMore();
      await tester.pumpAndSettle();
      final scroll = find.byKey(const ValueKey('screen-library'));
      await tester.drag(scroll, const Offset(0, -3000));
      await tester.pumpAndSettle();
      expect(find.text('曲库读取失败'), findsOneWidget);
      expect(find.textContaining('private-test-error'), findsNothing);
      fixture.repository.fail = false;
      await tester.tap(find.text('重试曲库'));
      await tester.pumpAndSettle();
      expect(controller.page.items.length, 40);
      controller.setAvailability(LibraryAvailability.unavailable);
      await tester.pumpAndSettle();
      expect(tester.widget<CustomScrollView>(scroll).controller!.offset, 0);
      await closeLibrary(tester, fixture);
    },
  );
  testWidgets('Android Back closes the context menu without leaving Library', (
    tester,
  ) async {
    final fixture = LibraryGraphFixture();
    await mountLibrary(tester, fixture);
    fixture.graph.libraryController.selectCategory(LibraryCategory.tracks);
    await tester.pumpAndSettle();
    final tile = find.byType(YYTrackTile).first;
    await tester.ensureVisible(tile);
    await tester.pumpAndSettle();
    await tester.longPress(tile);
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(YYContextMenu), findsNothing);
    expect(find.byType(LibraryScreen), findsOneWidget);
    await closeLibrary(tester, fixture);
  });
}
