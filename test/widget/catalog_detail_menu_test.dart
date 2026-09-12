import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:yymusic/app/catalog_detail_location.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/design_system/yy_album_card.dart';
import 'package:yymusic/design_system/yy_context_menu.dart';
import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/features/catalog_detail/common/catalog_detail_screen.dart';
import 'package:yymusic/features/catalog_detail/common/catalog_detail_state.dart';
import 'package:yymusic/features/catalog_detail/common/catalog_detail_track_menu.dart';
import 'package:yymusic/features/library/common/library_screen.dart';

import '../support/catalog_detail_graph_fixture.dart';
import '../support/catalog_detail_harness.dart';
import '../support/catalog_detail_menu_harness.dart';
import '../support/design_harness.dart';
import 'catalog_detail_screen_test.dart' show focusDetailButton;

void main() {
  setUpAll(loadDesignAssets);

  testWidgets(
    'Phone overflow and long press favorite an unavailable full reference without playback',
    (tester) async {
      final f = CatalogDetailGraphFixture();
      await mountDetail(tester, f);
      final track = f.repository.trackData[2];
      final baseline = f.collection.favoriteWatchCount;
      await openDetailMenu(tester, track);
      expect(f.collection.favoriteWatchCount, baseline + 1);
      final menu = tester.widget<YYContextMenu>(find.byType(YYContextMenu));
      expect(menu.items.singleWhere((i) => i.id == 'play').enabled, isFalse);
      expect(menu.items.singleWhere((i) => i.id == 'favorite').enabled, isTrue);
      await tester.tap(find.text('收藏歌曲'));
      await tester.pumpAndSettle();
      expect(find.byType(CatalogDetailTrackMenu), findsNothing);
      expect(detailState(tester).controller.isFavorite(track.ref), isTrue);
      final row = await revealDetailTrack(tester, track);
      await tester.longPress(row);
      await tester.pumpAndSettle();
      await tester.tap(find.text('取消收藏'));
      await tester.pumpAndSettle();
      expect(detailState(tester).controller.isFavorite(track.ref), isFalse);
      expect(f.collection.favoriteWriteCount, 2);
      expect(f.engine.calls, isEmpty);
      expect(tester.takeException(), isNull);
      await closeDetail(tester, f);
    },
  );

  testWidgets(
    'Windows keyboard Escape restores overflow focus and secondary click plays through the root',
    (tester) async {
      final f = CatalogDetailGraphFixture();
      await mountDetail(
        tester,
        f,
        platform: YYPlatform.windows,
        size: const Size(840, 900),
      );
      final track = f.repository.trackData.first;
      await revealDetailTrack(tester, track);
      final entry = await focusDetailButton(tester, '${track.title} 的更多操作');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(CatalogDetailTrackMenu), findsOneWidget);
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        'YYContextMenu:play',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(CatalogDetailScreen), findsOneWidget);
      expect(find.byType(CatalogDetailTrackMenu), findsNothing);
      expect(FocusManager.instance.primaryFocus, same(entry));
      final row = await revealDetailTrack(tester, track);
      await tester.tap(row, buttons: kSecondaryMouseButton);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(detailState(tester).controller.isFavorite(track.ref), isTrue);
      await tester.tap(row, buttons: kSecondaryMouseButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text('播放歌曲'));
      await tester.pumpAndSettle();
      expect(f.engine.calls.where((call) => call == 'play').length, 1);
      expect(f.graph.playback.state.queue.entries.single.track, track.ref);
      expect(tester.takeException(), isNull);
      await closeDetail(tester, f);
    },
  );

  testWidgets(
    'Android Back dismisses the modal before popping the preserved detail route',
    (tester) async {
      final f = CatalogDetailGraphFixture();
      await mountDetail(tester, f, location: '/library');
      await tester.tap(find.byType(YYAlbumCard).first);
      await tester.pumpAndSettle();
      final c = detailState(tester).controller;
      await openDetailMenu(tester, f.repository.trackData.first);
      expect(
        find.byWidgetPredicate(
          (w) => w is ModalBarrier && w.semanticsLabel == '关闭曲目菜单',
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate((w) => w is ExcludeFocus && w.excluding),
        findsWidgets,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(CatalogDetailTrackMenu), findsNothing);
      expect(detailState(tester).controller, same(c));
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(LibraryScreen), findsOneWidget);
      await drainMenuWork(tester);
      expect(f.graph.catalogDetails.retainedSessionCount, 0);
      await closeDetail(tester, f);
    },
  );

  testWidgets(
    'favorite read retry and safe write failure do not reload the detail catalog',
    (tester) async {
      final f = CatalogDetailGraphFixture();
      await mountDetail(tester, f);
      f.collection.favoriteReader = () =>
          Stream.error(StateError('private-marker'));
      final reads = f.repository.calls.length;
      final track = f.repository.trackData.first;
      await openDetailMenu(tester, track);
      expect(find.text('收藏暂不可用'), findsOneWidget);
      expect(find.textContaining('private-marker'), findsNothing);
      f.collection.favoriteReader = null;
      await tester.tap(find.text('重试收藏状态'));
      await tester.pumpAndSettle();
      expect(find.text('收藏歌曲'), findsOneWidget);
      final gate = Completer<void>();
      f.collection.favoriteGate = gate.future;
      await tester.tap(find.text('收藏歌曲'));
      await tester.pumpAndSettle();
      gate.completeError(StateError('private-marker'));
      await tester.pumpAndSettle();
      expect(detailState(tester).controller.actionError, '收藏未完成，请重试。');
      expect(find.textContaining('private-marker'), findsNothing);
      expect(f.repository.calls.length, reads);
      expect(f.collection.favoriteWriteCount, 0);
      expect(tester.takeException(), isNull);
      await closeDetail(tester, f);
    },
  );

  testWidgets(
    'accepted favorite writes survive actual route removal and session disposal drains',
    (tester) async {
      final f = CatalogDetailGraphFixture();
      await mountDetail(tester, f, location: '/library');
      await tester.tap(find.byType(YYAlbumCard).first);
      await tester.pumpAndSettle();
      final track = f.repository.trackData.first;
      await openDetailMenu(tester, track);
      final gate = Completer<void>();
      f.collection.favoriteGate = gate.future;
      await tester.tap(find.text('收藏歌曲'));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(LibraryScreen), findsOneWidget);
      expect(f.graph.catalogDetails.retainedSessionCount, 1);
      gate.complete();
      await tester.pumpAndSettle();
      await drainMenuWork(tester);
      expect(f.collection.favoriteWriteCount, 1);
      expect(f.graph.catalogDetails.retainedSessionCount, 0);
      expect(
        await tester.runAsync(() => f.collection.watchFavorites().first),
        contains(predicate<FavoriteEntry>((entry) => entry.track == track.ref)),
      );
      await closeDetail(tester, f);
    },
  );

  testWidgets('refresh and covering a retained route discard its old menu', (
    tester,
  ) async {
    final f = CatalogDetailGraphFixture();
    await mountDetail(tester, f);
    final c = detailState(tester).controller;
    final track = f.repository.trackData.first;
    await openDetailMenu(tester, track);
    unawaited(c.refresh());
    await tester.pumpAndSettle();
    expect(find.byType(CatalogDetailTrackMenu), findsNothing);
    await openDetailMenu(tester, track);
    final router = GoRouter.of(
      tester.element(find.byType(CatalogDetailScreen)),
    );
    unawaited(
      router.push(
        catalogDetailLocation(ArtistDetailTarget(f.artist.ref)).toString(),
      ),
    );
    await tester.pumpAndSettle();
    expect(f.graph.catalogDetails.retainedSessionCount, 2);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(detailState(tester).controller, same(c));
    expect(find.byType(CatalogDetailTrackMenu), findsNothing);
    expect(tester.takeException(), isNull);
    await closeDetail(tester, f);
  });

  testWidgets(
    'open menu remains usable across Phone and Tablet breakpoints at 130 percent',
    (tester) async {
      final f = CatalogDetailGraphFixture();
      await mountDetail(tester, f);
      final c = detailState(tester).controller;
      await openDetailMenu(tester, f.repository.trackData.first);
      final reads = f.repository.calls.length;
      for (final size in [
        const Size(600, 960),
        const Size(1024, 768),
        const Size(844, 390),
        const Size(390, 1000),
      ]) {
        tester.view.physicalSize = size;
        await tester.pumpAndSettle();
        // More native actions can exceed the short landscape viewport.
        await tester.ensureVisible(find.text('关闭菜单'));
        await tester.pumpAndSettle();
        expect(find.text('关闭菜单').hitTestable(), findsOneWidget);
        expect(detailState(tester).controller, same(c));
        expect(tester.takeException(), isNull, reason: '$size');
      }
      await tester.tap(find.text('关闭菜单'));
      await tester.pumpAndSettle();
      expect(find.byType(CatalogDetailTrackMenu), findsNothing);
      expect(f.repository.calls.length, reads);
      await closeDetail(tester, f);
    },
  );
}
