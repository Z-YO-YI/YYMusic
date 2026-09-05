import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/app/yy_music_app.dart';
import 'package:yymusic/design_system/yy_button.dart';
import 'package:yymusic/design_system/yy_feedback.dart';
import 'package:yymusic/design_system/yy_source_card.dart';
import 'package:yymusic/design_system/yy_track_tile.dart';
import 'package:yymusic/domain/models/load_state.dart';
import 'package:yymusic/domain/models/pagination.dart';
import 'package:yymusic/domain/models/track.dart';
import 'package:yymusic/domain/repositories/library_repository.dart';
import 'package:yymusic/features/home/phone/phone_home_layout.dart';
import 'package:yymusic/features/home/tablet/tablet_home_layout.dart';
import 'package:yymusic/features/home/windows/windows_home_layout.dart';

import '../support/close_graph.dart';
import '../support/design_harness.dart';
import '../support/fake_domain_repositories.dart';
import '../support/home_graph_fixture.dart';

Future<void> mountHome(
  WidgetTester tester,
  HomeGraphFixture fixture, {
  YYPlatform platform = YYPlatform.android,
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = 1.3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await fixture.initialize(source: fixture.tracks.isNotEmpty);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [dependencyGraphProvider.overrideWithValue(fixture.graph)],
      child: YYMusicApp(platform: platform),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> closeHome(WidgetTester tester, HomeGraphFixture fixture) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await closeGraph(tester, fixture.graph);
  await tester.runAsync(fixture.disposeFakes);
}

void main() {
  setUpAll(loadDesignAssets);
  testWidgets(
    'pending reads show skeletons and failures recover through refresh',
    (tester) async {
      final library = _DelayedLibrary();
      final collection = FakeCollectionRepository();
      final sources = FakeMusicSourceRepository();
      final graph = DependencyGraph(
        library: library,
        collection: collection,
        musicSources: sources,
      );
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [dependencyGraphProvider.overrideWithValue(graph)],
          child: const YYMusicApp(platform: YYPlatform.android),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(YYSkeleton), findsWidgets);
      library.pending.completeError(StateError('Authorization private-marker'));
      await tester.pumpAndSettle();
      expect(find.text('精选暂时不可用'), findsOneWidget);
      expect(find.textContaining('private-marker'), findsNothing);
      library.pending = Completer<PageResult<Track>>()
        ..complete(PageResult(items: const [], hasMore: false));
      await tester.tap(
        find.byWidgetPredicate(
          (widget) => widget is YYIconButton && widget.label == '刷新首页',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(YYSkeleton), findsNothing);
      expect(find.text('精选暂时不可用'), findsNothing);
      expect(find.text('暂无可播放的精选曲目'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await closeGraph(tester, graph);
      await tester.runAsync(() async {
        await collection.dispose();
        await sources.dispose();
      });
    },
  );
  testWidgets(
    'three independent Home compositions survive resize and preserve shared scope',
    (tester) async {
      final fixture = HomeGraphFixture();
      await mountHome(tester, fixture, size: const Size(360, 800));
      expect(find.byType(PhoneHomeLayout), findsOneWidget);
      final home = fixture.graph.home;
      for (final size in [
        const Size(600, 960),
        const Size(1024, 768),
        const Size(1280, 800),
        const Size(390, 844),
      ]) {
        tester.view.physicalSize = size;
        await tester.pumpAndSettle();
        expect(fixture.graph.home, same(home));
        expect(
          size.width < 600
              ? find.byType(PhoneHomeLayout)
              : find.byType(TabletHomeLayout),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      }
      expect(find.textContaining('private-endpoint'), findsNothing);
      expect(find.textContaining('opaque-reference'), findsNothing);
      expect(
        tester.widget<YYSourceCard>(find.byType(YYSourceCard)).statusLabel,
        '需授权',
      );
      await closeHome(tester, fixture);
      final windows = HomeGraphFixture();
      await mountHome(
        tester,
        windows,
        platform: YYPlatform.windows,
        size: const Size(1440, 900),
      );
      for (final width in [1440.0, 1024.0, 840.0, 599.0]) {
        tester.view.physicalSize = Size(width, 900);
        await tester.pumpAndSettle();
        expect(find.byType(WindowsHomeLayout), findsOneWidget);
        expect(find.byType(PhoneHomeLayout), findsNothing);
        expect(tester.takeException(), isNull);
      }
      await closeHome(tester, windows);
    },
  );
  testWidgets(
    'empty Home has honest empty states and disabled featured playback',
    (tester) async {
      final fixture = HomeGraphFixture(empty: true);
      await mountHome(tester, fixture);
      expect(find.text('暂无可播放的精选曲目'), findsOneWidget);
      expect(find.text('尚未配置音乐源'), findsOneWidget);
      expect(find.text('A Quiet Orbit'), findsNothing);
      expect(
        tester
            .widget<YYButton>(find.byKey(const ValueKey('home-play-featured')))
            .onPressed,
        isNull,
      );
      expect(fixture.engine.calls, isNot(contains('play')));
      await tester.tap(find.byKey(const ValueKey('home-open-library')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('screen-library')), findsOneWidget);
      await closeHome(tester, fixture);
    },
  );
  testWidgets(
    'Hero drives root player and queue without generating an extra player',
    (tester) async {
      final fixture = HomeGraphFixture();
      await mountHome(tester, fixture);
      await tester.tap(find.byKey(const ValueKey('home-play-featured')));
      await tester.pumpAndSettle();
      expect(
        fixture.graph.playbackPresenter.trackRef,
        fixture.tracks.first.ref,
      );
      expect(fixture.graph.playbackPresenter.data.playing, isTrue);
      expect(fixture.graph.queue.state.entries.length, 1);
      expect(
        tester
            .widgetList<YYTrackTile>(find.byType(YYTrackTile))
            .where((tile) => tile.playing),
        isNotEmpty,
      );
      final missing = tester
          .widgetList<YYTrackTile>(find.byType(YYTrackTile))
          .where((tile) => tile.sourceLabel == '文件失效');
      expect(missing, isNotEmpty);
      expect(missing.every((tile) => tile.onPressed == null), isTrue);
      await closeHome(tester, fixture);
      expect(fixture.engine.disposalCount, 1);
    },
  );
  testWidgets('clear history requires confirmation and cancel preserves data', (
    tester,
  ) async {
    final fixture = HomeGraphFixture();
    await mountHome(tester, fixture);
    final clear = find.text('清除历史');
    await tester.ensureVisible(clear);
    await tester.pumpAndSettle();
    await tester.tap(clear);
    await tester.pumpAndSettle();
    expect(fixture.graph.home.history.phase, LoadPhase.data);
    await tester.ensureVisible(find.text('取消'));
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(fixture.graph.home.history.phase, LoadPhase.data);
    await tester.ensureVisible(clear);
    await tester.tap(clear);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('确认清除'));
    await tester.tap(find.text('确认清除'));
    await tester.pumpAndSettle();
    expect(fixture.graph.home.history.phase, LoadPhase.empty);
    expect(fixture.library.trackSnapshot.length, 8);
    expect(fixture.graph.queue.state.entries, isEmpty);
    expect(tester.takeException(), isNull);
    await closeHome(tester, fixture);
  });
}

final class _DelayedLibrary implements LibraryRepository {
  Completer<PageResult<Track>> pending = Completer<PageResult<Track>>();
  @override
  Future<PageResult<Track>> listTracks(PageRequest request) => pending.future;
  @override
  Future<PageResult<Track>> listRecentlyAdded(
    PageRequest request, {
    required DateTime since,
    required DateTime until,
  }) => pending.future;
  @override
  Future<Track?> getTrack(TrackRef ref) async => null;
  @override
  Future<void> dispose() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
