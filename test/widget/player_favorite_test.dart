import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/design_system/yy_button.dart';
import 'package:yymusic/design_system/yy_lyrics_player_dock.dart';
import 'package:yymusic/design_system/yy_player_surface.dart';
import 'package:yymusic/features/player/common/player_screen.dart';

import '../support/design_harness.dart';
import '../support/native_lyrics_harness.dart';
import '../support/system_playlist_fixture.dart';
import '../support/system_playlist_harness.dart';

YYFullPlayerContent favoriteContent(WidgetTester tester) =>
    tester.widget<YYFullPlayerContent>(find.byType(YYFullPlayerContent));
PlayerScreen favoriteScreen(WidgetTester tester) =>
    tester.widget<PlayerScreen>(find.byType(PlayerScreen));

Future<SystemPlaylistFixture> mountFavoritePlayer(
  WidgetTester tester, {
  YYPlatform platform = YYPlatform.windows,
  Size size = const Size(1024, 720),
}) async {
  final f = SystemPlaylistFixture();
  addTearDown(() => closeSystemPlaylist(tester, f));
  await mountSystemPlaylist(
    tester,
    f,
    platform: platform,
    size: size,
    location: '/player',
  );
  await settleLyrics(tester);
  return f;
}

void main() {
  setUpAll(loadDesignAssets);
  for (final (platform, size) in const [
    (YYPlatform.android, Size(390, 844)),
    (YYPlatform.android, Size(800, 1280)),
    (YYPlatform.windows, Size(1024, 720)),
    (YYPlatform.windows, Size(500, 640)),
  ]) {
    testWidgets('native player favorite $platform $size', (tester) async {
      final f = await mountFavoritePlayer(
        tester,
        platform: platform,
        size: size,
      );
      final queue = f.graph.playback.state.queue;
      final calls = List.of(f.engine.calls);
      expect(favoriteContent(tester).data.favorite, isTrue);
      await tester.ensureVisible(
        find.byKey(const ValueKey('player-control-page-favorite')),
      );
      await tester.tap(
        find.byKey(const ValueKey('player-control-page-favorite')),
      );
      await settleLyrics(tester);
      expect(favoriteContent(tester).data.favorite, isFalse);
      expect(f.collection.favoriteWriteCount, 1);
      expect(f.graph.playback.state.queue, same(queue));
      expect(f.engine.calls, calls);
      expect(tester.takeException(), isNull);
    });
  }
  for (final revoke in [
    'resize',
    'zero',
    'route',
    'queue',
    'external',
    'dispose',
  ]) {
    testWidgets('player favorite captured callback revoked by $revoke', (
      tester,
    ) async {
      final f = await mountFavoritePlayer(tester);
      final old = favoriteContent(tester).onToggleFavorite!;
      switch (revoke) {
        case 'resize':
          tester.view.physicalSize = const Size(840, 720);
          await tester.pumpAndSettle();
        case 'zero':
          tester.view.physicalSize = Size.zero;
          await tester.pumpAndSettle();
        case 'route':
          favoriteScreen(tester).navigation.openLyrics();
          await tester.pumpAndSettle();
        case 'queue':
          await f.graph.queue.replace(
            f.graph.playback.state.queue.entries,
            currentEntryId: 'q-1',
          );
        case 'external':
          await f.collection.setFavorite(f.tracks.last.ref, favorite: false);
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
    'unaccepted favorite is cancelled when player leaves immediately',
    (tester) async {
      final f = await mountFavoritePlayer(tester);
      favoriteContent(tester).onToggleFavorite!();
      favoriteScreen(tester).navigation.openLyrics();
      await settleLyrics(tester);
      expect(f.collection.favoriteWriteCount, 0);
      expect(f.graph.playbackFavorite.state.isFavorite, isTrue);
    },
  );
  testWidgets('favorite truth is shared when going player to lyrics and back', (
    tester,
  ) async {
    final f = await mountFavoritePlayer(tester);
    final navigation = favoriteScreen(tester).navigation;
    favoriteContent(tester).onToggleFavorite!();
    await settleLyrics(tester);
    navigation.openLyrics();
    await settleLyrics(tester);
    final dock = tester.widget<YYLyricsPlayerDock>(
      find.byType(YYLyricsPlayerDock),
    );
    expect(dock.data.favorite, isFalse);
    dock.onToggleFavorite!();
    await settleLyrics(tester);
    navigation.openPlayer();
    await settleLyrics(tester);
    expect(favoriteContent(tester).data.favorite, isTrue);
    expect(f.collection.favoriteWriteCount, 2);
    expect(f.collection.favoriteWatchCount, 1);
  });
  testWidgets(
    'busy remains independent and accepted save survives navigation',
    (tester) async {
      final f = await mountFavoritePlayer(tester);
      final gate = Completer<void>();
      f.collection.favoriteGate = gate.future;
      favoriteContent(tester).onToggleFavorite!();
      await settleLyrics(tester);
      expect(favoriteContent(tester).favoriteBusy, isTrue);
      expect(favoriteContent(tester).onToggleFavorite, isNull);
      expect(favoriteContent(tester).loading, isFalse);
      favoriteScreen(tester).navigation.openLyrics();
      await settleLyrics(tester);
      gate.complete();
      await settleLyrics(tester);
      expect(f.graph.playbackFavorite.state.isFavorite, isFalse);
    },
  );
  testWidgets('write failure retained across lyrics and exact retry succeeds', (
    tester,
  ) async {
    final f = await mountFavoritePlayer(tester);
    final gate = Completer<void>();
    f.collection.favoriteGate = gate.future;
    final navigation = favoriteScreen(tester).navigation;
    favoriteContent(tester).onToggleFavorite!();
    await settleLyrics(tester);
    gate.completeError(StateError('private-test-only'));
    await settleLyrics(tester);
    final oldAck = tester
        .widget<YYButton>(find.widgetWithText(YYButton, '知道了'))
        .onPressed!;
    navigation.openLyrics();
    await settleLyrics(tester);
    final failure = f.graph.playbackFavorite.failure;
    oldAck();
    expect(f.graph.playbackFavorite.failure, same(failure));
    expect(find.textContaining('private-test-only'), findsNothing);
    f.collection.favoriteGate = null;
    await tester.tap(find.text('重试收藏操作'));
    await settleLyrics(tester);
    expect(f.graph.playbackFavorite.failure, isNull);
    navigation.openPlayer();
    await settleLyrics(tester);
    expect(favoriteContent(tester).data.favorite, isFalse);
  });
}
