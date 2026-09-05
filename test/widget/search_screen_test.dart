import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/app/yy_music_app.dart';
import 'package:yymusic/design_system/yy_button.dart';
import 'package:yymusic/design_system/yy_search_field.dart';
import 'package:yymusic/design_system/yy_track_tile.dart';
import 'package:yymusic/domain/models/pagination.dart';
import 'package:yymusic/domain/models/track.dart';
import 'package:yymusic/features/search/common/search_controller.dart';
import 'package:yymusic/features/search/phone/phone_search_layout.dart';
import 'package:yymusic/features/search/tablet/tablet_search_layout.dart';
import 'package:yymusic/features/search/windows/windows_search_layout.dart';

import '../support/close_graph.dart';
import '../support/design_harness.dart';
import '../support/search_graph_fixture.dart';

Future<void> mountSearch(
  WidgetTester tester,
  SearchGraphFixture fixture, {
  YYPlatform platform = YYPlatform.android,
  Size size = const Size(390, 844),
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
      child: YYMusicApp(platform: platform, initialLocation: '/search'),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> closeSearch(
  WidgetTester tester,
  SearchGraphFixture fixture,
) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await closeGraph(tester, fixture.graph);
  await tester.runAsync(fixture.disposeFakes);
}

Future<void> pressControlK(WidgetTester tester) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pumpAndSettle();
}

Finder button(String label) =>
    find.byWidgetPredicate((w) => w is YYButton && w.label == label);

void main() {
  setUpAll(loadDesignAssets);
  testWidgets(
    'phone tablet resize and navigation preserve input, results and root player',
    (tester) async {
      final fixture = SearchGraphFixture();
      await mountSearch(tester, fixture, size: const Size(360, 800));
      expect(find.byType(PhoneSearchLayout), findsOneWidget);
      await tester.enterText(find.byType(EditableText), '夜航');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      final controller = fixture.graph.search;
      final player = fixture.graph.playback;
      for (final size in [
        const Size(600, 960),
        const Size(1024, 768),
        const Size(390, 844),
      ]) {
        tester.view.physicalSize = size;
        await tester.pumpAndSettle();
        expect(
          size.width < 600
              ? find.byType(PhoneSearchLayout)
              : find.byType(TabletSearchLayout),
          findsOneWidget,
        );
        expect(fixture.graph.search, same(controller));
        expect(fixture.graph.playback, same(player));
        expect(
          tester
              .widget<EditableText>(find.byType(EditableText))
              .controller
              .text,
          '夜航',
        );
        expect(tester.takeException(), isNull);
      }
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('nav-home')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('nav-search')));
      await tester.pumpAndSettle();
      expect(controller.query, '夜航');
      expect(fixture.repository.requests.length, 6);
      await closeSearch(tester, fixture);
    },
  );

  testWidgets(
    'IME commits with unchanged text dispatch once; pending results never lock editing',
    (tester) async {
      final fixture = SearchGraphFixture();
      final gate = Completer<PageResult<Track>>();
      fixture.repository.trackQuery = (q, p, c) => gate.future;
      await mountSearch(tester, fixture);
      await tester.showKeyboard(find.byType(EditableText));
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '夜',
          selection: TextSelection.collapsed(offset: 1),
          composing: TextRange(start: 0, end: 1),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(fixture.repository.requests, isEmpty);
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '夜',
          selection: TextSelection.collapsed(offset: 1),
          composing: TextRange.empty,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(fixture.repository.requests.length, 6);
      expect(
        tester.widget<YYSearchField>(find.byType(YYSearchField)).loading,
        isFalse,
      );
      await tester.enterText(find.byType(EditableText), '夜航 2');
      await tester.pump(const Duration(milliseconds: 300));
      expect(fixture.repository.requests.length, 12);
      gate.complete(PageResult(items: [], hasMore: false));
      await tester.pumpAndSettle();
      expect(fixture.graph.search.query, '夜航 2');
      await closeSearch(tester, fixture);
    },
  );

  testWidgets(
    'Windows Ctrl K focuses even on same route; Space edits without playback',
    (tester) async {
      final fixture = SearchGraphFixture();
      await mountSearch(
        tester,
        fixture,
        platform: YYPlatform.windows,
        size: const Size(1440, 1000),
      );
      expect(find.byType(WindowsSearchLayout), findsOneWidget);
      await pressControlK(tester);
      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.focusNode.hasFocus, isTrue);
      await tester.enterText(find.byType(EditableText), '夜');
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      // Native text payload is delivered through the IME, not synthesized by CUA.
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '夜 ',
          selection: TextSelection.collapsed(offset: 2),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(editable.controller.text, '夜 ');
      expect(fixture.engine.calls, isEmpty);
      editable.focusNode.unfocus();
      await tester.pumpAndSettle();
      final scroll = tester
          .widget<CustomScrollView>(find.byKey(const ValueKey('screen-search')))
          .controller!;
      scroll.jumpTo(120);
      await tester.pumpAndSettle();
      await pressControlK(tester);
      expect(editable.focusNode.hasFocus, isTrue);
      expect(scroll.offset, 0);
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(fixture.engine.calls, contains('play'));
      expect(
        fixture.graph.playback.state.queue.entries.single.track,
        fixture.tracks.first.ref,
      );
      await closeSearch(tester, fixture);
    },
  );

  testWidgets(
    'history submit, confirmation cancel, confirmed clear and query clear are distinct',
    (tester) async {
      final fixture = SearchGraphFixture();
      await mountSearch(tester, fixture);
      await tester.enterText(find.byType(EditableText), '夜');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byKey(const ValueKey('catalog-search-submit')));
      await tester.pumpAndSettle();
      expect(fixture.graph.search.history.single.query, '夜');
      expect(fixture.engine.calls, isEmpty);
      await tester.tap(button('清除搜索历史'));
      await tester.pumpAndSettle();
      await tester.tap(button('取消'));
      await tester.pumpAndSettle();
      expect(fixture.graph.search.history, hasLength(1));
      await tester.tap(button('清除搜索历史'));
      await tester.pumpAndSettle();
      await tester.tap(button('确认清除搜索历史'));
      await tester.pumpAndSettle();
      expect(fixture.graph.search.history, isEmpty);
      expect(fixture.graph.search.query, '夜');
      await tester.tap(find.byKey(const ValueKey('clear-search')));
      await tester.pumpAndSettle();
      expect(find.text('搜索你的音乐'), findsOneWidget);
      expect(fixture.repository.tracks, isNotEmpty);
      await closeSearch(tester, fixture);
    },
  );

  testWidgets(
    'route exit revokes Enter while results are pending in retained branch',
    (tester) async {
      final fixture = SearchGraphFixture();
      final gate = Completer<PageResult<Track>>();
      fixture.repository.trackQuery = (q, p, c) => gate.future;
      await mountSearch(tester, fixture);
      await tester.enterText(find.byType(EditableText), '夜');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('nav-home')));
      await tester.pumpAndSettle();
      gate.complete(PageResult(items: fixture.tracks, hasMore: false));
      await tester.pumpAndSettle();
      expect(fixture.engine.calls, isEmpty);
      await tester.tap(find.byKey(const ValueKey('nav-search')));
      await tester.pumpAndSettle();
      expect(fixture.graph.search.query, '夜');
      await closeSearch(tester, fixture);
    },
  );

  testWidgets(
    'long result lists build lazily and loaded pages remain reachable',
    (tester) async {
      final fixture = SearchGraphFixture(count: 60);
      await mountSearch(
        tester,
        fixture,
        platform: YYPlatform.windows,
        size: const Size(840, 900),
      );
      fixture.graph.search.selectFilter(SearchFilter.tracks);
      await tester.enterText(find.byType(EditableText), '夜');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      final bucket = fixture.graph.search.buckets
          .whereType<SearchBucket<Track>>()
          .first;
      unawaited(fixture.graph.search.loadMore(bucket));
      await tester.pumpAndSettle();
      expect(bucket.items, hasLength(40));
      expect(find.byType(YYTrackTile).evaluate().length, lessThan(40));
      final scroll = tester
          .widget<CustomScrollView>(find.byKey(const ValueKey('screen-search')))
          .controller!;
      scroll.jumpTo(900);
      await tester.pumpAndSettle();
      expect(find.byType(YYTrackTile), findsWidgets);
      expect(tester.takeException(), isNull);
      await closeSearch(tester, fixture);
    },
  );
}
