import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/design_system/yy_button.dart';
import 'package:yymusic/design_system/yy_lyrics_player_dock.dart';
import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/features/lyrics/common/lyrics_screen.dart';

import '../support/close_graph.dart';
import '../support/design_harness.dart';
import '../support/native_lyrics_harness.dart';
import '../support/system_playlist_fixture.dart';
import '../support/system_playlist_harness.dart';

YYLyricsPlayerDock favoriteDock(WidgetTester tester) =>
    tester.widget<YYLyricsPlayerDock>(find.byType(YYLyricsPlayerDock));

Future<SystemPlaylistFixture> mountFavoriteLyrics(
  WidgetTester tester, {
  YYPlatform platform = YYPlatform.windows,
  Size size = const Size(1024, 720),
  SystemPlaylistFixture? fixture,
}) async {
  final f = fixture ?? SystemPlaylistFixture();
  await f.initialize();
  f.graph.appearance.setReduceMotion(true);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await closeGraph(tester, f.graph);
    await tester.runAsync(f.collection.dispose);
  });
  await mountSystemPlaylist(
    tester,
    f,
    platform: platform,
    size: size,
    location: '/lyrics',
  );
  await settleLyrics(tester);
  return f;
}

void main() {
  setUpAll(loadDesignAssets);
  for (final platform in YYPlatform.values) {
    testWidgets('lyrics favorite uses root persistence on $platform', (
      tester,
    ) async {
      final f = await mountFavoriteLyrics(tester, platform: platform);
      final queue = f.graph.playback.state.queue;
      final calls = List.of(f.engine.calls);
      expect(favoriteDock(tester).data.favorite, isTrue);
      await tester.tap(find.bySemanticsLabel('取消收藏'));
      await settleLyrics(tester);
      expect(favoriteDock(tester).data.favorite, isFalse);
      expect(f.collection.favoriteWriteCount, 1);
      expect(f.graph.playback.state.queue, same(queue));
      expect(f.engine.calls, calls);
      await tester.runAsync(
        () => f.collection.setFavorite(f.tracks.first.ref, favorite: true),
      );
      await settleLyrics(tester);
      expect(favoriteDock(tester).data.favorite, isTrue);
    });
  }
  testWidgets('phone retains exported hidden favorite rule', (tester) async {
    await mountFavoriteLyrics(
      tester,
      platform: YYPlatform.android,
      size: const Size(390, 844),
    );
    expect(find.bySemanticsLabel('取消收藏'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('empty selection has no false unfavorited control', (
    tester,
  ) async {
    await mountFavoriteLyrics(tester, fixture: SystemPlaylistFixture(count: 0));
    expect(favoriteDock(tester).showFavorite, isFalse);
    expect(favoriteDock(tester).onToggleFavorite, isNull);
  });
  for (final revoke in ['resize', 'route', 'queue', 'external', 'dispose']) {
    testWidgets('old favorite callback is revoked by $revoke', (tester) async {
      final f = await mountFavoriteLyrics(tester);
      final old = favoriteDock(tester).onToggleFavorite!;
      switch (revoke) {
        case 'resize':
          tester.view.physicalSize = const Size(800, 720);
          await tester.pumpAndSettle();
        case 'route':
          tester
              .widget<LyricsScreen>(find.byType(LyricsScreen))
              .navigation
              .openPlayer();
          await tester.pumpAndSettle();
        case 'queue':
          await tester.runAsync(
            () => f.graph.queue.replace(
              f.graph.playback.state.queue.entries,
              currentEntryId: 'q-1',
            ),
          );
        case 'external':
          await tester.runAsync(
            () => f.collection.setFavorite(f.tracks.last.ref, favorite: false),
          );
        case 'dispose':
          await tester.pumpWidget(const SizedBox.shrink());
      }
      await settleLyrics(tester);
      final writes = f.collection.favoriteWriteCount;
      old();
      await settleLyrics(tester);
      expect(f.collection.favoriteWriteCount, writes);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'busy does not lock return; accepted write drains after leaving',
    (tester) async {
      final f = await mountFavoriteLyrics(tester);
      final gate = Completer<void>();
      f.collection.favoriteGate = gate.future;
      favoriteDock(tester).onToggleFavorite!();
      await settleLyrics(tester);
      expect(favoriteDock(tester).favoriteBusy, isTrue);
      expect(favoriteDock(tester).onToggleFavorite, isNull);
      expect(favoriteDock(tester).data.favorite, isTrue);
      expect(favoriteDock(tester).loading, isFalse);
      favoriteDock(tester).onReturnToPlayer!();
      await tester.pumpAndSettle();
      gate.complete();
      await settleLyrics(tester);
      expect(f.graph.playbackFavorite.state.isFavorite, isFalse);
    },
  );
  testWidgets('write failure is safe and retries captured intent', (
    tester,
  ) async {
    final f = await mountFavoriteLyrics(tester);
    final gate = Completer<void>();
    f.collection.favoriteGate = gate.future;
    favoriteDock(tester).onToggleFavorite!();
    await settleLyrics(tester);
    gate.completeError(StateError('private-test-path'));
    await settleLyrics(tester);
    expect(find.textContaining('private-test-path'), findsNothing);
    expect(favoriteDock(tester).data.favorite, isTrue);
    final retry = tester
        .widget<YYButton>(find.widgetWithText(YYButton, '重试收藏操作'))
        .onPressed!;
    f.collection.favoriteGate = null;
    retry();
    await settleLyrics(tester);
    expect(favoriteDock(tester).data.favorite, isFalse);
    expect(f.graph.playbackFavorite.failure, isNull);
    retry();
    await settleLyrics(tester);
    expect(f.collection.favoriteWriteCount, 1);
  });
  testWidgets(
    'read failure retries explicitly; old retry cannot replace new stream',
    (tester) async {
      final f = SystemPlaylistFixture();
      f.collection.favoriteReader = () =>
          Stream<List<FavoriteEntry>>.error(StateError('private-read'));
      await mountFavoriteLyrics(tester, fixture: f);
      expect(favoriteDock(tester).showFavorite, isFalse);
      expect(find.textContaining('private-read'), findsNothing);
      final retry = tester
          .widget<YYButton>(find.widgetWithText(YYButton, '重试读取收藏'))
          .onPressed!;
      f.collection.favoriteReader = null;
      retry();
      await settleLyrics(tester);
      final state = f.graph.playbackFavorite.state;
      expect(state.isFavorite, isTrue);
      retry();
      await settleLyrics(tester);
      expect(f.graph.playbackFavorite.state, same(state));
    },
  );
}
