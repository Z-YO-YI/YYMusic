import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/design_system/yy_playlist_card.dart';
import 'package:yymusic/design_system/yy_track_tile.dart';
import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/features/library/common/library_controller.dart';
import 'package:yymusic/features/library/common/library_screen.dart';
import 'package:yymusic/features/playlists/common/system_playlist_screen.dart';

import '../support/design_harness.dart';
import '../support/playlist_content_harness.dart' show settleContent;
import '../support/system_playlist_fixture.dart';
import '../support/system_playlist_harness.dart';

void main() {
  setUpAll(loadDesignAssets);
  for (final (name, platform, size) in const [
    ('phone', YYPlatform.android, Size(390, 1000)),
    ('tablet', YYPlatform.android, Size(1024, 768)),
    ('windows', YYPlatform.windows, Size(1440, 1000)),
  ]) {
    testWidgets(
      '$name plays the exact duplicate queue entry without management',
      (tester) async {
        final f = SystemPlaylistFixture();
        await mountSystemPlaylist(tester, f, platform: platform, size: size);
        await revealSystemRow(tester, 'q-1');
        await tester.tap(systemRow('q-1'));
        await settleContent(tester);
        expect(f.graph.playback.state.queue.currentEntryId, 'q-1');
        expect(f.graph.playback.state.queue.entries.length, 5);
        expect(f.engine.calls, ['load', 'play']);
        expect(tester.widget<YYTrackTile>(systemRow('q-1')).playing, isTrue);
        expect(tester.widget<YYTrackTile>(systemRow('q-0')).playing, isFalse);
        await revealSystemRow(tester, 'q-3');
        expect(tester.widget<YYTrackTile>(systemRow('q-3')).title, '未解析的歌曲');
        for (final id in ['q-2', 'q-3']) {
          final tile = tester.widget<YYTrackTile>(systemRow(id));
          expect(tile.onPressed, isNull);
          expect(tile.showMore, isFalse);
        }
        expect(find.text('删除歌单'), findsNothing);
        expect(tester.takeException(), isNull);
        await closeSystemPlaylist(tester, f);
      },
    );
  }

  testWidgets(
    'three Library entries open typed routes, restore category and reject old overlay callbacks',
    (tester) async {
      final f = SystemPlaylistFixture();
      await mountSystemPlaylist(tester, f, location: '/library');
      f.graph.libraryController.selectCategory(LibraryCategory.playlists);
      await settleContent(tester);
      for (final type in SystemPlaylistType.values) {
        final link = find.byKey(ValueKey(('system-playlist-open', type)));
        await tester.ensureVisible(link);
        await tester.pumpAndSettle();
        await tester.tap(link);
        await settleContent(tester);
        expect(systemState(tester).controller.type, type);
        expect(f.graph.systemPlaylists.retainedSessionCount, 1);
        await tester.binding.handlePopRoute();
        await settleContent(tester);
        expect(find.byType(LibraryScreen), findsOneWidget);
        expect(f.graph.libraryController.category, LibraryCategory.playlists);
        expect(f.graph.systemPlaylists.retainedSessionCount, 0);
      }
      final link = find.byKey(
        const ValueKey(('system-playlist-open', SystemPlaylistType.queue)),
      );
      final old = tester.widget<YYPlaylistCard>(link).onPressed!;
      await tester.ensureVisible(find.text('新建歌单'));
      await tester.tap(find.text('新建歌单'));
      await tester.pumpAndSettle();
      old();
      await settleContent(tester);
      expect(find.byType(SystemPlaylistScreen), findsNothing);
      expect(f.graph.systemPlaylists.retainedSessionCount, 0);
      expect(f.engine.calls, isEmpty);
      await closeSystemPlaylist(tester, f);
    },
  );

  testWidgets('Windows row Enter and Space activate only the selected entry', (
    tester,
  ) async {
    final f = SystemPlaylistFixture();
    await mountSystemPlaylist(
      tester,
      f,
      platform: YYPlatform.windows,
      size: const Size(1440, 1000),
    );
    await revealSystemRow(tester, 'q-1');
    final primary = find
        .descendant(
          of: systemRow('q-1'),
          matching: find.byType(GestureDetector),
        )
        .first;
    final focus = Focus.of(tester.element(primary));
    focus.requestFocus();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await settleContent(tester);
    expect(f.graph.playback.state.queue.currentEntryId, 'q-1');
    expect(f.engine.calls.where((c) => c == 'play').length, 1);
    focus.requestFocus();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await settleContent(tester);
    expect(f.engine.calls.where((c) => c == 'play').length, 2);
    expect(f.engine.calls, isNot(contains('pause')));
    expect(tester.takeException(), isNull);
    await closeSystemPlaylist(tester, f);
  });

  testWidgets('Windows keyboard system entry restores its focus after Escape', (
    tester,
  ) async {
    final f = SystemPlaylistFixture();
    await mountSystemPlaylist(
      tester,
      f,
      platform: YYPlatform.windows,
      size: const Size(1440, 1000),
      location: '/library',
    );
    f.graph.libraryController.selectCategory(LibraryCategory.playlists);
    await settleContent(tester);
    final card = find.byKey(
      const ValueKey(('system-playlist-open', SystemPlaylistType.queue)),
    );
    final primary = find
        .descendant(of: card, matching: find.byType(GestureDetector))
        .first;
    final focus = Focus.of(tester.element(primary));
    focus.requestFocus();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await settleContent(tester);
    expect(systemState(tester).controller.type, SystemPlaylistType.queue);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await settleContent(tester);
    expect(find.byType(SystemPlaylistScreen), findsNothing);
    expect(FocusManager.instance.primaryFocus, same(focus));
    expect(f.engine.calls, isEmpty);
    await closeSystemPlaylist(tester, f);
  });

  testWidgets('initial read failure retries to a genuine empty system view', (
    tester,
  ) async {
    final f = SystemPlaylistFixture(count: 0);
    f.collection.systemReader = (_, _) async =>
        throw StateError('private-marker');
    await mountSystemPlaylist(tester, f);
    expect(find.text('系统歌单读取失败'), findsOneWidget);
    expect(find.textContaining('private-marker'), findsNothing);
    f.collection.systemReader = null;
    await tester.ensureVisible(find.text('重试系统歌单'));
    await tester.tap(find.text('重试系统歌单'));
    await settleContent(tester);
    expect(systemState(tester).controller.content!.totalCount, 0);
    expect(find.byType(YYTrackTile), findsNothing);
    expect(f.engine.calls, isEmpty);
    await closeSystemPlaylist(tester, f);
  });

  testWidgets(
    'failed refresh keeps disabled rows and revokes retained callbacks',
    (tester) async {
      final f = SystemPlaylistFixture();
      await mountSystemPlaylist(tester, f);
      await revealSystemRow(tester, 'q-1');
      final old = tester.widget<YYTrackTile>(systemRow('q-1')).onPressed!;
      f.collection.systemReader = (_, _) async =>
          throw StateError('private-marker');
      systemState(tester).controller.refresh();
      old();
      await settleContent(tester);
      await revealSystemRow(tester, 'q-1');
      expect(tester.widget<YYTrackTile>(systemRow('q-1')).onPressed, isNull);
      expect(f.engine.calls, isEmpty);
      await closeSystemPlaylist(tester, f);
    },
  );

  testWidgets(
    'invalid system identity never opens a session or custom parent',
    (tester) async {
      final f = SystemPlaylistFixture();
      await mountSystemPlaylist(
        tester,
        f,
        location: '/system-playlist?type=queue&type=favorites',
      );
      expect(find.text('无法打开系统歌单'), findsOneWidget);
      expect(f.graph.systemPlaylists.retainedSessionCount, 0);
      expect(f.engine.calls, isEmpty);
      await closeSystemPlaylist(tester, f);
    },
  );
}
