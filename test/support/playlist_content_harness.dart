import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/app/playlist_location.dart';
import 'package:yymusic/app/yy_music_app.dart';
import 'package:yymusic/design_system/yy_button.dart';
import 'package:yymusic/features/playlists/common/playlist_content_screen.dart';

import 'close_graph.dart';
import 'playlist_content_fixture.dart';

Future<void> settleContent(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(Duration.zero);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
  await tester.pumpAndSettle();
}

Future<void> mountPlaylist(
  WidgetTester tester,
  PlaylistContentFixture f, {
  YYPlatform platform = YYPlatform.android,
  Size size = const Size(390, 1000),
  String? location,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = 1.3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await f.initialize();
  f.graph.appearance.setReduceMotion(true);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [dependencyGraphProvider.overrideWithValue(f.graph)],
      child: RepaintBoundary(
        key: const ValueKey('playlist-golden'),
        child: YYMusicApp(
          platform: platform,
          initialLocation: location ?? playlistLocation(f.id).toString(),
        ),
      ),
    ),
  );
  await settleContent(tester);
}

PlaylistContentScreenState playlistState(WidgetTester tester) => tester
    .state<PlaylistContentScreenState>(find.byType(PlaylistContentScreen));

Finder playlistRow(String id) => find.byKey(ValueKey(('playlist-entry', id)));

Future<Finder> revealPlaylistRow(WidgetTester tester, String id) async {
  final row = playlistRow(id);
  if (row.evaluate().isEmpty) {
    final state = playlistState(tester);
    state.scroll.jumpTo(state.scroll.position.maxScrollExtent);
    await tester.pumpAndSettle();
  }
  await tester.ensureVisible(row);
  await tester.pumpAndSettle();
  return row;
}

Future<void> openEntryMenu(WidgetTester tester, String id) async {
  final row = await revealPlaylistRow(tester, id);
  await tester.tap(
    find.descendant(of: row, matching: find.byType(YYIconButton)),
  );
  await tester.pumpAndSettle();
}

Future<void> closePlaylist(
  WidgetTester tester,
  PlaylistContentFixture f,
) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await closeGraph(tester, f.graph);
  await tester.runAsync(f.collection.dispose);
}
