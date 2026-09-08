import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/design_system/yy_button.dart';
import 'package:yymusic/design_system/yy_context_menu.dart';
import 'package:yymusic/design_system/yy_dialog.dart';
import 'package:yymusic/design_system/yy_feedback.dart';
import 'package:yymusic/design_system/yy_track_tile.dart';
import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/features/playlists/common/system_playlist_management_panel.dart';
import 'package:yymusic/features/playlists/common/system_playlist_screen.dart';

import '../support/design_harness.dart';
import '../support/playlist_content_harness.dart' show settleContent;
import '../support/system_playlist_fixture.dart';
import '../support/system_playlist_harness.dart';

Future<void> openSystemFavoriteMenu(
  WidgetTester tester,
  SystemPlaylistFixture f, {
  int index = 3,
}) async {
  final id = f.tracks[index].ref;
  await revealSystemRow(tester, id);
  final tile = tester.widget<YYTrackTile>(systemRow(id));
  tile.onMore!();
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadDesignAssets);
  testWidgets(
    'confirmation adapts across breakpoints but zero area revokes its old action',
    (tester) async {
      final f = SystemPlaylistFixture();
      await mountSystemPlaylist(tester, f, type: SystemPlaylistType.recent);
      final controller = systemState(tester).controller;
      await tester.tap(find.text('清除播放历史'));
      await tester.pumpAndSettle();
      tester.view.physicalSize = const Size(1024, 768);
      await tester.pumpAndSettle();
      expect(find.byType(YYDialog), findsOneWidget);
      expect(systemState(tester).controller, same(controller));
      final old = tester
          .widget<YYButton>(find.widgetWithText(YYButton, '确认清除'))
          .onPressed!;
      tester.view.physicalSize = Size.zero;
      await tester.pumpAndSettle();
      old();
      await settleContent(tester);
      tester.view.physicalSize = const Size(390, 1000);
      await tester.pumpAndSettle();
      expect(find.byType(SystemPlaylistManagementPanel), findsNothing);
      expect(controller.content!.totalCount, 4);
      expect(f.engine.calls, isEmpty);
      expect(tester.takeException(), isNull);
      await closeSystemPlaylist(tester, f);
    },
  );

  testWidgets(
    'open menu blocks retained page actions and an old menu cannot remove a new selection',
    (tester) async {
      final f = SystemPlaylistFixture();
      await mountSystemPlaylist(tester, f, type: SystemPlaylistType.favorites);
      final id = f.tracks[0].ref;
      await revealSystemRow(tester, id);
      final play = tester.widget<YYTrackTile>(systemRow(id)).onPressed!;
      final back = tester
          .widget<YYButton>(find.widgetWithText(YYButton, '返回'))
          .onPressed!;
      await openSystemFavoriteMenu(tester, f, index: 0);
      final old = tester
          .widget<YYContextMenu>(find.byType(YYContextMenu))
          .onSelected!;
      play();
      back();
      await settleContent(tester);
      expect(find.byType(SystemPlaylistManagementPanel), findsOneWidget);
      expect(f.engine.calls, isEmpty);
      old('close');
      await tester.pumpAndSettle();
      await openSystemFavoriteMenu(tester, f, index: 2);
      old('remove-favorite');
      await settleContent(tester);
      expect(systemState(tester).controller.content!.totalCount, 4);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(SystemPlaylistManagementPanel), findsNothing);
      expect(find.byType(SystemPlaylistScreen), findsOneWidget);
      await closeSystemPlaylist(tester, f);
    },
  );

  for (final (platform, size) in const [
    (YYPlatform.android, Size(390, 1000)),
    (YYPlatform.android, Size(1024, 768)),
    (YYPlatform.windows, Size(1440, 1000)),
  ]) {
    testWidgets(
      '$platform $size removes unavailable favorites through the native menu, not audio',
      (tester) async {
        final f = SystemPlaylistFixture();
        await mountSystemPlaylist(
          tester,
          f,
          platform: platform,
          size: size,
          type: SystemPlaylistType.favorites,
        );
        final id = f.tracks[3].ref;
        await revealSystemRow(tester, id);
        final tile = tester.widget<YYTrackTile>(systemRow(id));
        expect(tile.onPressed, isNull);
        expect(tile.allowMoreWhenDisabled, isTrue);
        await tester.tap(
          find
              .descendant(
                of: systemRow(id),
                matching: find.byType(YYIconButton),
              )
              .last,
        );
        await tester.pumpAndSettle();
        final menu = tester.widget<YYContextMenu>(find.byType(YYContextMenu));
        expect(
          menu.items.singleWhere((i) => i.id == 'remove-favorite').selected,
          isTrue,
        );
        expect(menu.items.singleWhere((i) => i.id == 'play').enabled, isFalse);
        await tester.tap(find.text('取消喜欢'));
        await settleContent(tester);
        expect(
          (await tester.runAsync(() => f.collection.watchFavorites().first))!
              .any((e) => e.track == id),
          isFalse,
        );
        expect(f.graph.playback.state.queue.entries, hasLength(5));
        expect(f.engine.calls, isEmpty);
        menu.onSelected!('remove-favorite');
        await settleContent(tester);
        expect(systemState(tester).controller.content!.totalCount, 3);
        expect(tester.takeException(), isNull);
        await closeSystemPlaylist(tester, f);
      },
    );

    testWidgets(
      '$platform $size clearing requires fresh confirmation and preserves current playback',
      (tester) async {
        final f = SystemPlaylistFixture();
        await mountSystemPlaylist(
          tester,
          f,
          platform: platform,
          size: size,
          type: SystemPlaylistType.recent,
        );
        await tester.runAsync(f.graph.playback.play);
        await settleContent(tester);
        await tester.tap(find.text('清除播放历史'));
        await tester.pumpAndSettle();
        expect(
          find.byType(
            platform == YYPlatform.android && size.width < 600
                ? YYBottomSheet
                : YYDialog,
          ),
          findsOneWidget,
        );
        final oldConfirm = tester
            .widget<YYButton>(find.widgetWithText(YYButton, '确认清除'))
            .onPressed!;
        await tester.tap(find.widgetWithText(YYButton, '取消'));
        await tester.pumpAndSettle();
        oldConfirm();
        await settleContent(tester);
        expect(systemState(tester).controller.content!.totalCount, 4);
        await tester.tap(find.text('清除播放历史'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(YYButton, '确认清除'));
        await settleContent(tester);
        expect(systemState(tester).controller.content!.totalCount, 0);
        expect(f.engine.calls, ['load', 'play']);
        expect(f.graph.playback.state.queue.entries, hasLength(5));
        expect(f.graph.playbackPresenter.data.playing, isTrue);
        expect(tester.takeException(), isNull);
        await closeSystemPlaylist(tester, f);
      },
    );
  }

  for (final secondary in [false, true]) {
    testWidgets(
      '${secondary ? 'right click' : 'long press'} opens the favorite menu without selecting playback',
      (tester) async {
        final f = SystemPlaylistFixture();
        await mountSystemPlaylist(
          tester,
          f,
          platform: YYPlatform.windows,
          size: const Size(1440, 1000),
          type: SystemPlaylistType.favorites,
        );
        final id = f.tracks[2].ref;
        await revealSystemRow(tester, id);
        if (secondary) {
          final gesture = await tester.startGesture(
            tester.getCenter(systemRow(id)),
            kind: PointerDeviceKind.mouse,
            buttons: kSecondaryMouseButton,
          );
          await gesture.up();
        } else {
          await tester.longPress(systemRow(id));
        }
        await tester.pumpAndSettle();
        expect(find.text('取消喜欢'), findsOneWidget);
        expect(f.engine.calls, isEmpty);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(find.byType(SystemPlaylistManagementPanel), findsNothing);
        expect(find.byType(SystemPlaylistScreen), findsOneWidget);
        await closeSystemPlaylist(tester, f);
      },
    );
  }

  testWidgets('refresh and covered routes revoke old confirmation callbacks', (
    tester,
  ) async {
    final f = SystemPlaylistFixture();
    await mountSystemPlaylist(tester, f, type: SystemPlaylistType.recent);
    for (final covered in [false, true]) {
      await tester.tap(find.text('清除播放历史'));
      await tester.pumpAndSettle();
      final old = tester
          .widget<YYButton>(find.widgetWithText(YYButton, '确认清除'))
          .onPressed!;
      final navigator = Navigator.of(
        tester.element(find.byType(SystemPlaylistScreen)),
      );
      if (covered) {
        unawaited(
          navigator.push<void>(
            PageRouteBuilder(pageBuilder: (_, _, _) => const SizedBox.expand()),
          ),
        );
      } else {
        systemState(tester).controller.refresh();
      }
      await settleContent(tester);
      old();
      await settleContent(tester);
      expect(
        (await tester.runAsync(() => f.collection.watchHistory().first)),
        hasLength(4),
      );
      if (covered) {
        navigator.pop();
        await settleContent(tester);
      }
      expect(find.byType(SystemPlaylistManagementPanel), findsNothing);
    }
    expect(tester.takeException(), isNull);
    await closeSystemPlaylist(tester, f);
  });

  testWidgets(
    'Windows confirmation traps focus, consumes Escape and never clears from initial Enter',
    (tester) async {
      final f = SystemPlaylistFixture();
      await mountSystemPlaylist(
        tester,
        f,
        platform: YYPlatform.windows,
        size: const Size(1440, 1000),
        type: SystemPlaylistType.recent,
      );
      await tester.tap(find.text('清除播放历史'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(SystemPlaylistManagementPanel), findsNothing);
      expect(systemState(tester).controller.content!.totalCount, 4);
      await tester.tap(find.text('清除播放历史'));
      await tester.pumpAndSettle();
      for (var i = 0; i < 9; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        expect(
          FocusManager.instance.primaryFocus?.context
              ?.findAncestorWidgetOfExactType<SystemPlaylistManagementPanel>(),
          isNotNull,
        );
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(SystemPlaylistScreen), findsOneWidget);
      expect(f.engine.calls, isEmpty);
      await closeSystemPlaylist(tester, f);
    },
  );

  testWidgets(
    'failed favorite removal is safely visible and retrying the menu succeeds',
    (tester) async {
      final f = SystemPlaylistFixture();
      await mountSystemPlaylist(tester, f, type: SystemPlaylistType.favorites);
      f.collection.onFavoriteSet = (_, _) async {
        throw StateError('private-marker');
      };
      await openSystemFavoriteMenu(tester, f);
      await tester.tap(find.text('取消喜欢'));
      await settleContent(tester);
      final error = tester.widget<YYErrorBanner>(find.byType(YYErrorBanner));
      expect(error.title, '系统歌单操作未完成');
      expect(find.textContaining('private-marker'), findsNothing);
      expect(systemState(tester).controller.content!.totalCount, 4);
      f.collection.onFavoriteSet = null;
      await openSystemFavoriteMenu(tester, f);
      await tester.tap(find.text('取消喜欢'));
      await settleContent(tester);
      expect(find.byType(YYErrorBanner), findsNothing);
      expect(systemState(tester).controller.content!.totalCount, 3);
      expect(f.engine.calls, isEmpty);
      await closeSystemPlaylist(tester, f);
    },
  );
}
