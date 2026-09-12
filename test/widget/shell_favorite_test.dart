import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/adaptive_root.dart';
import 'package:yymusic/app/app_routes.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/design_system/yy_button.dart';
import 'package:yymusic/design_system/yy_player_surface.dart';
import 'package:yymusic/domain/models/collection_models.dart';

import '../support/design_harness.dart';
import '../support/native_lyrics_harness.dart';
import '../support/system_playlist_fixture.dart';
import '../support/system_playlist_harness.dart';

YYDesktopPlayerBar favoriteBar(WidgetTester tester) =>
    tester.widget<YYDesktopPlayerBar>(find.byType(YYDesktopPlayerBar));
AppNavigation shellNavigation(WidgetTester tester) =>
    tester.widget<AdaptiveRoot>(find.byType(AdaptiveRoot).last).navigation;

Future<SystemPlaylistFixture> mountFavoriteShell(
  WidgetTester tester, {
  YYPlatform platform = YYPlatform.windows,
  Size size = const Size(1440, 900),
  SystemPlaylistFixture? fixture,
}) async {
  final f = fixture ?? SystemPlaylistFixture();
  addTearDown(() => closeSystemPlaylist(tester, f));
  await mountSystemPlaylist(
    tester,
    f,
    platform: platform,
    size: size,
    location: '/home',
  );
  await settleLyrics(tester);
  return f;
}

void main() {
  setUpAll(loadDesignAssets);
  for (final platform in YYPlatform.values) {
    testWidgets('wide shell favorite persists on $platform', (tester) async {
      final f = await mountFavoriteShell(
        tester,
        platform: platform,
        size: const Size(1280, 900),
      );
      final queue = f.graph.playback.state.queue;
      final audio = List.of(f.engine.calls);
      await tester.tap(
        find.byKey(const ValueKey('player-control-desktop-favorite')),
      );
      await settleLyrics(tester);
      expect(favoriteBar(tester).data.favorite, isFalse);
      expect(f.collection.favoriteWriteCount, 1);
      expect(f.graph.playback.state.queue, same(queue));
      expect(f.engine.calls, audio);
    });
  }
  for (final revoke in [
    'navigation',
    'away-back',
    'cover',
    'resize',
    'zero',
    'queue',
    'dispose',
  ]) {
    testWidgets('retained shell favorite revoked by $revoke', (tester) async {
      final f = await mountFavoriteShell(tester);
      final old = favoriteBar(tester).onToggleFavorite!;
      final navigation = shellNavigation(tester);
      switch (revoke) {
        case 'navigation':
          navigation.goTo(AppRoute.library);
        case 'away-back':
          navigation.goTo(AppRoute.library);
          await tester.pumpAndSettle();
          navigation.goTo(AppRoute.home);
        case 'cover':
          navigation.openPlayer();
        case 'resize':
          tester.view.physicalSize = const Size(1300, 900);
        case 'zero':
          tester.view.physicalSize = Size.zero;
        case 'queue':
          await f.graph.queue.replace(
            f.graph.playback.state.queue.entries,
            currentEntryId: 'q-1',
          );
        case 'dispose':
          await tester.pumpWidget(const SizedBox.shrink());
      }
      await settleLyrics(tester);
      old();
      await settleLyrics(tester);
      expect(f.collection.favoriteWriteCount, 0);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('immediate main navigation revokes unaccepted save', (
    tester,
  ) async {
    final f = await mountFavoriteShell(tester);
    favoriteBar(tester).onToggleFavorite!();
    shellNavigation(tester).goTo(AppRoute.library);
    await settleLyrics(tester);
    expect(f.collection.favoriteWriteCount, 0);
  });
  testWidgets('accepted save survives tab change with independent busy', (
    tester,
  ) async {
    final f = await mountFavoriteShell(tester);
    final gate = Completer<void>();
    f.collection.favoriteGate = gate.future;
    favoriteBar(tester).onToggleFavorite!();
    await settleLyrics(tester);
    expect(favoriteBar(tester).favoriteBusy, isTrue);
    expect(favoriteBar(tester).loading, isFalse);
    expect(favoriteBar(tester).onToggleFavorite, isNull);
    shellNavigation(tester).goTo(AppRoute.library);
    await settleLyrics(tester);
    gate.complete();
    await settleLyrics(tester);
    expect(favoriteBar(tester).data.favorite, isFalse);
  });
  testWidgets(
    'write failure remains across tab change with safe same-target retry',
    (tester) async {
      final f = await mountFavoriteShell(tester);
      final gate = Completer<void>();
      f.collection.favoriteGate = gate.future;
      favoriteBar(tester).onToggleFavorite!();
      await settleLyrics(tester);
      gate.completeError(StateError('private-test'));
      await settleLyrics(tester);
      final ack = tester
          .widget<YYButton>(find.widgetWithText(YYButton, '知道了'))
          .onPressed!;
      shellNavigation(tester).goTo(AppRoute.library);
      await settleLyrics(tester);
      final failure = f.graph.playbackFavorite.failure;
      ack();
      expect(f.graph.playbackFavorite.failure, same(failure));
      expect(find.textContaining('private-test'), findsNothing);
      f.collection.favoriteGate = null;
      await tester.tap(find.text('重试收藏操作'));
      await settleLyrics(tester);
      expect(favoriteBar(tester).data.favorite, isFalse);
      expect(f.graph.playbackFavorite.failure, isNull);
    },
  );
  testWidgets('unknown stream has unknown semantics and explicit read retry', (
    tester,
  ) async {
    final f = SystemPlaylistFixture();
    f.collection.favoriteReader = () =>
        Stream<List<FavoriteEntry>>.error(StateError('test-only'));
    await mountFavoriteShell(tester, fixture: f);
    expect(favoriteBar(tester).favoriteKnown, isFalse);
    expect(find.bySemanticsLabel('收藏状态未知'), findsOneWidget);
    f.collection.favoriteReader = null;
    await tester.tap(find.text('重试读取收藏'));
    await settleLyrics(tester);
    expect(favoriteBar(tester).favoriteKnown, isTrue);
    expect(favoriteBar(tester).data.favorite, isTrue);
  });
  testWidgets('phone and narrow bars keep original no-heart layout', (
    tester,
  ) async {
    await mountFavoriteShell(
      tester,
      platform: YYPlatform.android,
      size: const Size(390, 844),
    );
    expect(find.byType(YYMiniPlayer), findsOneWidget);
    expect(
      find.byKey(const ValueKey('player-control-desktop-favorite')),
      findsNothing,
    );
    tester.view.physicalSize = const Size(620, 844);
    await settleLyrics(tester);
    expect(
      find.byKey(const ValueKey('player-control-desktop-favorite')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
}
