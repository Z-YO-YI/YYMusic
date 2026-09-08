import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/app/system_playlist_location.dart';
import 'package:yymusic/app/yy_music_app.dart';
import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/features/playlists/common/system_playlist_screen.dart';

import 'close_graph.dart';
import 'playlist_content_harness.dart' show settleContent;
import 'system_playlist_fixture.dart';

Future<void> mountSystemPlaylist(
  WidgetTester tester,
  SystemPlaylistFixture f, {
  YYPlatform platform = YYPlatform.android,
  Size size = const Size(390, 1000),
  SystemPlaylistType type = SystemPlaylistType.queue,
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
        key: const ValueKey('system-playlist-golden'),
        child: YYMusicApp(
          platform: platform,
          initialLocation: location ?? systemPlaylistLocation(type).toString(),
        ),
      ),
    ),
  );
  await settleContent(tester);
}

SystemPlaylistScreenState systemState(WidgetTester tester) =>
    tester.state<SystemPlaylistScreenState>(find.byType(SystemPlaylistScreen));
Finder systemRow(Object id) => find.byKey(ValueKey(('system-entry', id)));

Future<void> revealSystemRow(WidgetTester tester, Object id) async {
  final row = systemRow(id);
  if (row.evaluate().isEmpty) {
    final scroll = systemState(tester).scroll;
    scroll.jumpTo(scroll.position.maxScrollExtent);
    await tester.pumpAndSettle();
  }
  await tester.ensureVisible(row);
  await tester.pumpAndSettle();
}

Future<void> closeSystemPlaylist(
  WidgetTester tester,
  SystemPlaylistFixture f,
) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await closeGraph(tester, f.graph);
  await tester.runAsync(f.collection.dispose);
}
