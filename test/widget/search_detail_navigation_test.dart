import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/design_system/yy_button.dart';
import 'package:yymusic/domain/models/catalog_reference.dart';
import 'package:yymusic/features/catalog_detail/common/catalog_detail_state.dart';
import 'package:yymusic/features/search/common/search_controller.dart';
import 'package:yymusic/features/search/common/search_screen.dart';

import '../support/catalog_detail_harness.dart' show detailState;
import '../support/design_harness.dart';
import '../support/search_detail_fixture.dart';
import 'search_screen_test.dart' show mountSearch, closeSearch;

Finder resultButton(String kind, Object reference) {
  final key = switch (reference) {
    AlbumRef() => ValueKey(('search-$kind', reference)),
    ArtistRef() => ValueKey(('search-$kind', reference)),
    _ => throw ArgumentError('Expected album or artist reference'),
  };
  return find.descendant(of: find.byKey(key), matching: find.byType(YYButton));
}

Finder searchScrollable() => find
    .descendant(
      of: find.byKey(const ValueKey('screen-search')),
      matching: find.byType(Scrollable),
    )
    .first;
Future<void> revealResult(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(target, 250, scrollable: searchScrollable());
  await tester.pumpAndSettle();
  await Scrollable.ensureVisible(tester.element(target), alignment: .5);
  await tester.pumpAndSettle();
  expect(target.hitTestable(), findsOneWidget);
}

Future<void> searchForAlbums(
  WidgetTester tester,
  SearchDetailFixture fixture,
) async {
  await tester.enterText(find.byType(EditableText), '夜航');
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();
  FocusManager.instance.primaryFocus?.unfocus();
  fixture.search.graph.search.selectFilter(SearchFilter.albums);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadDesignAssets);
  for (final (platform, size) in const [
    (YYPlatform.android, Size(390, 1000)),
    (YYPlatform.android, Size(1024, 768)),
    (YYPlatform.windows, Size(840, 900)),
  ]) {
    testWidgets(
      '$platform $size search opens exact source and returns with results and scroll',
      (tester) async {
        final f = SearchDetailFixture();
        await mountSearch(tester, f.search, platform: platform, size: size);
        await searchForAlbums(tester, f);
        final controller = f.search.graph.search;
        final requestCount = f.search.repository.requests.length;
        for (final album in f.albums) {
          final button = resultButton('album', album.ref);
          await revealResult(tester, button);
          final scroll = tester
              .widget<CustomScrollView>(
                find.byKey(const ValueKey('screen-search')),
              )
              .controller!;
          final offset = scroll.offset;
          await tester.tap(button);
          await tester.pumpAndSettle();
          expect(
            (detailState(tester).controller.target as AlbumDetailTarget)
                .reference,
            album.ref,
          );
          expect(f.search.graph.catalogDetails.retainedSessionCount, 1);
          final albumSession = detailState(tester).controller;
          await tester.tap(
            find.byWidgetPredicate((w) => w is YYButton && w.label == '夜航艺人'),
          );
          await tester.pumpAndSettle();
          expect(
            (detailState(tester).controller.target as ArtistDetailTarget)
                .reference,
            f.artists.singleWhere((a) => a.sourceId == album.sourceId).ref,
          );
          expect(f.search.graph.catalogDetails.retainedSessionCount, 2);
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(detailState(tester).controller, same(albumSession));
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(find.byType(SearchScreen), findsOneWidget);
          expect(f.search.graph.search, same(controller));
          expect(controller.query, '夜航');
          expect(controller.filter, SearchFilter.albums);
          expect(scroll.offset, closeTo(offset, .1));
          expect(f.search.graph.catalogDetails.retainedSessionCount, 0);
          expect(f.search.repository.requests.length, requestCount);
        }
        controller.selectFilter(SearchFilter.artists);
        await tester.pumpAndSettle();
        // Changing filters deliberately starts one request per visible source.
        expect(
          f.search.repository.requests.skip(requestCount).map((r) => r.$1),
          ['artists', 'artists'],
        );
        final artist = f.artists.last;
        final button = resultButton('artist', artist.ref);
        await revealResult(tester, button);
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(
          (detailState(tester).controller.target as ArtistDetailTarget)
              .reference,
          artist.ref,
        );
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(controller.filter, SearchFilter.artists);
        expect(f.search.repository.requests.length, requestCount + 2);
        expect(f.search.history.calls.where((c) => c == 'record'), isEmpty);
        expect(f.search.engine.calls, isEmpty);
        expect(tester.takeException(), isNull);
        await closeSearch(tester, f.search);
      },
    );
  }

  testWidgets(
    'keyboard opens search result and Escape returns focus to the same button',
    (tester) async {
      final f = SearchDetailFixture();
      await mountSearch(
        tester,
        f.search,
        platform: YYPlatform.windows,
        size: const Size(1024, 900),
      );
      await searchForAlbums(tester, f);
      final button = resultButton('album', f.albums.first.ref);
      await revealResult(tester, button);
      FocusNode? entry;
      for (var i = 0; i < 50; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        final focused = FocusManager.instance.primaryFocus;
        if (focused?.context
                ?.findAncestorWidgetOfExactType<YYButton>()
                ?.label ==
            '查看专辑') {
          entry = focused;
          break;
        }
      }
      expect(entry, isNotNull);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(detailState(tester).controller.target, isA<AlbumDetailTarget>());
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(SearchScreen), findsOneWidget);
      expect(FocusManager.instance.primaryFocus, same(entry));
      expect(f.search.engine.calls, isEmpty);
      await closeSearch(tester, f.search);
    },
  );

  testWidgets(
    'removed search reference shows missing content instead of a same-name replacement',
    (tester) async {
      final f = SearchDetailFixture();
      await mountSearch(tester, f.search, size: const Size(390, 1000));
      await searchForAlbums(tester, f);
      f.catalog.albumData.remove(f.albums.first.ref);
      final button = resultButton('album', f.albums.first.ref);
      await revealResult(tester, button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.textContaining('此内容已不在目录中'), findsOneWidget);
      expect(
        (detailState(tester).controller.target as AlbumDetailTarget).reference,
        f.albums.first.ref,
      );
      expect(f.catalog.albumData.containsKey(f.albums.last.ref), isTrue);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(f.search.graph.search.query, '夜航');
      await closeSearch(tester, f.search);
    },
  );

  testWidgets(
    'opening detail while search playback is loading cancels the pending search intent',
    (tester) async {
      final f = SearchDetailFixture();
      await mountSearch(tester, f.search, size: const Size(390, 1000));
      await tester.enterText(find.byType(EditableText), '夜航');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      final gate = Completer<void>();
      f.search.engine.loadGate = gate.future;
      unawaited(f.search.graph.search.play(f.search.tracks.first));
      await tester.pumpAndSettle();
      expect(f.search.engine.calls, contains('load'));
      FocusManager.instance.primaryFocus?.unfocus();
      final button = resultButton('album', f.albums.first.ref);
      await revealResult(tester, button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      gate.complete();
      await tester.pumpAndSettle();
      expect(f.search.engine.calls, isNot(contains('play')));
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(f.search.graph.search.canPlay(f.search.tracks.first), isTrue);
      await closeSearch(tester, f.search);
    },
  );
}
