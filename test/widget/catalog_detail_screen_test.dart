import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:yymusic/app/catalog_detail_location.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/design_system/yy_album_card.dart';
import 'package:yymusic/design_system/yy_button.dart';
import 'package:yymusic/design_system/yy_segmented_control.dart';
import 'package:yymusic/design_system/yy_track_tile.dart';
import 'package:yymusic/domain/models/library_entities.dart';
import 'package:yymusic/features/catalog_detail/common/catalog_detail_screen.dart';
import 'package:yymusic/features/catalog_detail/common/catalog_detail_sections.dart';
import 'package:yymusic/features/catalog_detail/common/catalog_detail_state.dart';
import 'package:yymusic/features/catalog_detail/phone/phone_catalog_detail_layout.dart';
import 'package:yymusic/features/catalog_detail/tablet/tablet_catalog_detail_layout.dart';
import 'package:yymusic/features/catalog_detail/windows/windows_catalog_detail_layout.dart';
import 'package:yymusic/features/home/common/home_screen.dart';
import 'package:yymusic/features/library/common/library_controller.dart';
import 'package:yymusic/features/library/common/library_screen.dart';

import '../support/catalog_detail_graph_fixture.dart';
import '../support/catalog_detail_harness.dart';
import '../support/design_harness.dart';

Finder detailButton(String label) =>
    find.byWidgetPredicate((w) => w is YYButton && w.label == label);
Finder detailScrollable() => find
    .descendant(
      of: find.byKey(const PageStorageKey('detail-scroll')),
      matching: find.byType(Scrollable),
    )
    .first;

Future<FocusNode> focusDetailButton(WidgetTester tester, String label) async {
  for (var i = 0; i < 60; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    final focus = FocusManager.instance.primaryFocus;
    if (focus?.context?.findAncestorWidgetOfExactType<YYButton>()?.label ==
        label) {
      return focus!;
    }
  }
  throw TestFailure('Keyboard did not reach the requested button');
}

void main() {
  setUpAll(loadDesignAssets);
  testWidgets(
    'library album to artist to album returns through the real preserved route stack',
    (tester) async {
      final f = CatalogDetailGraphFixture();
      await mountDetail(tester, f, location: '/library');
      final library = f.graph.libraryController;
      await tester.tap(find.byType(YYAlbumCard).first);
      await tester.pumpAndSettle();
      final first = detailState(tester).controller;
      expect(find.text('沿途的声音'), findsOneWidget);
      expect(f.graph.catalogDetails.retainedSessionCount, 1);
      await tester.tap(detailButton(f.artist.name));
      await tester.pumpAndSettle();
      final artist = detailState(tester).controller;
      expect(artist.target, isA<ArtistDetailTarget>());
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey(CatalogDetailTab.albums)),
        240,
        scrollable: detailScrollable(),
      );
      await tester.tap(find.byKey(const ValueKey(CatalogDetailTab.albums)));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byType(YYAlbumCard).first,
        200,
        scrollable: detailScrollable(),
      );
      await tester.tap(find.byType(YYAlbumCard).first);
      await tester.pumpAndSettle();
      expect(f.graph.catalogDetails.retainedSessionCount, 3);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(detailState(tester).controller, same(artist));
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey(CatalogDetailTab.albums)),
        -240,
        scrollable: detailScrollable(),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<YYSegmentedControl<CatalogDetailTab>>(
              find.byType(YYSegmentedControl<CatalogDetailTab>),
            )
            .value,
        CatalogDetailTab.albums,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(detailState(tester).controller, same(first));
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(LibraryScreen), findsOneWidget);
      expect(f.graph.libraryController, same(library));
      expect(library.category, LibraryCategory.albums);
      expect(f.graph.catalogDetails.retainedSessionCount, 0);
      expect(tester.takeException(), isNull);
      await closeDetail(tester, f);
    },
  );

  testWidgets(
    'library artist action opens its exact reference and Windows Escape returns',
    (tester) async {
      final f = CatalogDetailGraphFixture();
      await mountDetail(
        tester,
        f,
        location: '/library',
        platform: YYPlatform.windows,
        size: const Size(1024, 900),
      );
      f.graph.libraryController.selectCategory(LibraryCategory.artists);
      await tester.pumpAndSettle();
      final entryFocus = await focusDetailButton(tester, '查看艺人');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(
        (detailState(tester).controller.target as ArtistDetailTarget).reference,
        f.artist.ref,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(LibraryScreen), findsOneWidget);
      expect(f.graph.libraryController.category, LibraryCategory.artists);
      expect(f.graph.catalogDetails.retainedSessionCount, 0);
      expect(FocusManager.instance.primaryFocus, same(entryFocus));
      await closeDetail(tester, f);
    },
  );

  testWidgets(
    'detail track action updates the sole player and unavailable rows have no fake menu',
    (tester) async {
      final f = CatalogDetailGraphFixture();
      await mountDetail(tester, f);
      final track = f.repository.trackData.first;
      await tester.scrollUntilVisible(
        find.byKey(ValueKey(track.ref)),
        240,
        scrollable: detailScrollable(),
      );
      await tester.tap(find.byKey(ValueKey(track.ref)));
      await tester.pumpAndSettle();
      expect(f.engine.calls.where((call) => call == 'play').length, 1);
      expect(f.graph.playback.state.queue.entries.single.track, track.ref);
      expect(
        tester.widget<YYTrackTile>(find.byKey(ValueKey(track.ref))).playing,
        isTrue,
      );
      final missing = f.repository.trackData[2];
      await tester.scrollUntilVisible(
        find.byKey(ValueKey(missing.ref)),
        180,
        scrollable: detailScrollable(),
      );
      final row = tester.widget<YYTrackTile>(find.byKey(ValueKey(missing.ref)));
      expect(row.onPressed, isNull);
      expect(row.showMore, isFalse);
      expect(row.sourceLabel, '文件失效');
      expect(
        find.descendant(
          of: find.byKey(ValueKey(missing.ref)),
          matching: find.byType(YYIconButton),
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
      await closeDetail(tester, f);
    },
  );

  testWidgets(
    'artist selection, session and page survive Android breakpoint and orientation changes',
    (tester) async {
      final f = CatalogDetailGraphFixture(albumCount: 28);
      await mountDetail(
        tester,
        f,
        location: catalogDetailLocation(ArtistDetailTarget(f.artist.ref))
            .toString(),
      );
      final controller = detailState(tester).controller;
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey(CatalogDetailTab.albums)),
        200,
        scrollable: detailScrollable(),
      );
      await tester.tap(find.byKey(const ValueKey(CatalogDetailTab.albums)));
      await tester.pumpAndSettle();
      unawaited(controller.loadMoreAlbums());
      await tester.pumpAndSettle();
      expect(controller.albums.items.length, 28);
      final reads = f.repository.calls.length;
      for (final size in [
        const Size(599, 900),
        const Size(600, 960),
        const Size(800, 1200),
        const Size(1024, 768),
        const Size(1280, 800),
        const Size(844, 390),
        const Size(390, 1000),
      ]) {
        tester.view.physicalSize = size;
        await tester.pumpAndSettle();
        expect(detailState(tester).controller, same(controller));
        expect(f.graph.catalogDetails.retainedSessionCount, 1);
        expect(controller.albums.items.length, 28);
        expect(
          find.byType(PhoneCatalogDetailLayout),
          size.width < 600 ? findsOneWidget : findsNothing,
        );
        expect(
          find.byType(TabletCatalogDetailLayout),
          size.width >= 600 ? findsOneWidget : findsNothing,
        );
        final segment = tester.widget<YYSegmentedControl<CatalogDetailTab>>(
          find.byType(YYSegmentedControl<CatalogDetailTab>),
        );
        expect(segment.value, CatalogDetailTab.albums);
        expect(tester.takeException(), isNull, reason: '$size');
      }
      expect(f.repository.calls.length, reads);
      await closeDetail(tester, f);
    },
  );

  testWidgets(
    'detail scroll offset survives shell replacement and a zero-sized view',
    (tester) async {
      final f = CatalogDetailGraphFixture();
      await mountDetail(tester, f);
      final controller = detailState(tester).controller;
      final scroll = tester
          .widget<CustomScrollView>(
            find.byKey(const PageStorageKey('detail-scroll')),
          )
          .controller!;
      scroll.jumpTo(240);
      await tester.pumpAndSettle();
      final reads = f.repository.calls.length;
      for (final size in [
        const Size(600, 960),
        const Size(1024, 768),
        Size.zero,
        const Size(390, 1000),
      ]) {
        tester.view.physicalSize = size;
        await tester.pumpAndSettle();
        expect(detailState(tester).controller, same(controller));
        if (size != Size.zero) expect(scroll.offset, closeTo(240, 0.1));
        expect(tester.takeException(), isNull, reason: '$size');
      }
      expect(f.repository.calls.length, reads);
      await closeDetail(tester, f);
    },
  );

  testWidgets(
    'Windows remains desktop at narrow sizes with reachable keyboard actions',
    (tester) async {
      final f = CatalogDetailGraphFixture();
      await mountDetail(
        tester,
        f,
        platform: YYPlatform.windows,
        size: const Size(840, 640),
      );
      final controller = detailState(tester).controller;
      for (final size in [
        const Size(1440, 900),
        const Size(1024, 720),
        const Size(599, 800),
        const Size(840, 640),
      ]) {
        tester.view.physicalSize = size;
        await tester.pumpAndSettle();
        expect(find.byType(WindowsCatalogDetailLayout), findsOneWidget);
        expect(detailState(tester).controller, same(controller));
        expect(tester.takeException(), isNull, reason: '$size');
      }
      await focusDetailButton(tester, '刷新详情');
      final revision = controller.revision;
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(controller.revision, revision + 1);
      await closeDetail(tester, f);
    },
  );

  testWidgets(
    'pagination retry retains old rows and refresh restarts current page',
    (tester) async {
      final f = CatalogDetailGraphFixture();
      await mountDetail(tester, f);
      final controller = detailState(tester).controller;
      expect(find.byType(YYTrackTile).evaluate().length, lessThan(20));
      f.repository.onTracks = (_, _, _) async =>
          throw StateError('private-marker');
      await tester.scrollUntilVisible(
        detailButton('更多歌曲'),
        300,
        scrollable: detailScrollable(),
      );
      await tester.pumpAndSettle();
      await Scrollable.ensureVisible(
        tester.element(detailButton('更多歌曲')),
        alignment: 0.5,
      );
      await tester.pumpAndSettle();
      expect(detailButton('更多歌曲').hitTestable(), findsOneWidget);
      await tester.tap(detailButton('更多歌曲'));
      await tester.pumpAndSettle();
      expect(controller.tracks.items.length, 20);
      expect(find.text('歌曲读取失败'), findsOneWidget);
      f.repository.onTracks = null;
      await tester.tap(detailButton('重试歌曲'));
      await tester.pumpAndSettle();
      expect(controller.tracks.items.length, 40);
      tester
          .widget<CustomScrollView>(
            find.byKey(const PageStorageKey('detail-scroll')),
          )
          .controller!
          .jumpTo(0);
      await tester.pumpAndSettle();
      await tester.tap(detailButton('刷新详情'));
      await tester.pumpAndSettle();
      expect(controller.tracks.items.length, 20);
      expect(tester.takeException(), isNull);
      await closeDetail(tester, f);
    },
  );

  testWidgets(
    'summary error retries to data and a valid missing reference shows honest empty state',
    (tester) async {
      final f = CatalogDetailGraphFixture(trackCount: 0);
      f.repository.onAlbum = (_, _) async => throw StateError('private-marker');
      await mountDetail(tester, f);
      expect(find.text('详情读取失败'), findsOneWidget);
      f.repository.onAlbum = null;
      await tester.tap(detailButton('重试详情'));
      await tester.pumpAndSettle();
      expect(find.text('沿途的声音'), findsOneWidget);
      expect(find.textContaining('此目录中暂无歌曲'), findsOneWidget);
      f.repository.albumData.clear();
      await tester.tap(detailButton('刷新详情'));
      await tester.pumpAndSettle();
      expect(find.textContaining('此内容已不在目录中'), findsOneWidget);
      await closeDetail(tester, f);
    },
  );

  testWidgets(
    'invalid detail links reveal no identifiers and issue no catalog queries',
    (tester) async {
      final f = CatalogDetailGraphFixture();
      await mountDetail(
        tester,
        f,
        location: '/album/private-marker?source=x&source=y',
      );
      expect(find.text('无法打开详情'), findsOneWidget);
      expect(find.textContaining('private-marker'), findsNothing);
      expect(f.repository.calls, isEmpty);
      expect(f.graph.catalogDetails.retainedSessionCount, 0);
      await tester.tap(detailButton('返回'));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      await closeDetail(tester, f);
    },
  );

  testWidgets('actual router preserves encoded source and entity separators', (
    tester,
  ) async {
    final f = CatalogDetailGraphFixture(trackCount: 0);
    final album = Album(
      id: '复杂 /?%2F#',
      sourceId: '本地/a?x%#',
      title: '转义标识专辑',
      artists: f.album.artists,
      trackCount: 0,
    );
    f.repository.albumData[album.ref] = album;
    await mountDetail(
      tester,
      f,
      location: catalogDetailLocation(AlbumDetailTarget(album.ref)).toString(),
    );
    expect(find.text('转义标识专辑'), findsOneWidget);
    expect(
      (detailState(tester).controller.target as AlbumDetailTarget).reference,
      album.ref,
    );
    await closeDetail(tester, f);
  });

  testWidgets(
    'replacing a detail URL with a same-ID different source creates the correct session',
    (tester) async {
      final f = CatalogDetailGraphFixture(trackCount: 0);
      await mountDetail(tester, f);
      final previous = detailState(tester).controller;
      final album = Album(
        id: f.album.id,
        sourceId: 'another-source',
        title: '另一个来源的同标识专辑',
        artists: f.album.artists,
        trackCount: 0,
      );
      f.repository.albumData[album.ref] = album;
      final router = GoRouter.of(
        tester.element(find.byType(CatalogDetailScreen)),
      );
      final location = catalogDetailLocation(AlbumDetailTarget(album.ref))
          .toString();
      router.go(location);
      await tester.pumpAndSettle();
      final current = detailState(tester).controller;
      expect((current.target as AlbumDetailTarget).reference, album.ref);
      expect(current, isNot(same(previous)));
      expect(find.text(album.title), findsOneWidget);
      expect(f.graph.catalogDetails.retainedSessionCount, 1);
      router.go(location);
      await tester.pumpAndSettle();
      expect(detailState(tester).controller, same(current));
      await closeDetail(tester, f);
    },
  );

  testWidgets(
    'covering a retained detail route revokes pending playback without closing its session',
    (tester) async {
      final f = CatalogDetailGraphFixture();
      await mountDetail(tester, f);
      final controller = detailState(tester).controller;
      final gate = Completer<void>();
      f.engine.loadGate = gate.future;
      final track = f.repository.trackData.first;
      await tester.scrollUntilVisible(
        find.byKey(ValueKey(track.ref)),
        240,
        scrollable: detailScrollable(),
      );
      await tester.tap(find.byKey(ValueKey(track.ref)));
      await tester.pumpAndSettle();
      expect(f.engine.calls, contains('load'));
      tester
          .widget<CustomScrollView>(
            find.byKey(const PageStorageKey('detail-scroll')),
          )
          .controller!
          .jumpTo(0);
      await tester.pumpAndSettle();
      await tester.tap(detailButton(f.artist.name));
      await tester.pumpAndSettle();
      expect(detailState(tester).controller.target, isA<ArtistDetailTarget>());
      expect(f.graph.catalogDetails.retainedSessionCount, 2);
      gate.complete();
      await tester.pumpAndSettle();
      expect(f.engine.calls, isNot(contains('play')));
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(detailState(tester).controller, same(controller));
      expect(controller.canPlay(track.ref), isTrue);
      expect(f.graph.catalogDetails.retainedSessionCount, 1);
      await closeDetail(tester, f);
    },
  );

  testWidgets(
    'leaving a route during engine load revokes playback before the load finishes',
    (tester) async {
      final f = CatalogDetailGraphFixture();
      await mountDetail(tester, f, location: '/library');
      await tester.tap(find.byType(YYAlbumCard).first);
      await tester.pumpAndSettle();
      final gate = Completer<void>();
      f.engine.loadGate = gate.future;
      final track = f.repository.trackData.first;
      await tester.scrollUntilVisible(
        find.byKey(ValueKey(track.ref)),
        240,
        scrollable: detailScrollable(),
      );
      await tester.tap(find.byKey(ValueKey(track.ref)));
      await tester.pumpAndSettle();
      expect(f.engine.calls, contains('load'));
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(LibraryScreen), findsOneWidget);
      expect(f.graph.catalogDetails.retainedSessionCount, 1);
      gate.complete();
      await tester.pumpAndSettle();
      expect(f.engine.calls, isNot(contains('play')));
      expect(f.graph.catalogDetails.retainedSessionCount, 0);
      await closeDetail(tester, f);
    },
  );
}
