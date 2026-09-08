import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/layout_class.dart';

import '../widget/foundation_app_test.dart' show mount;
import 'close_graph.dart';
import 'lyrics_fixture.dart';

Future<void> settleLyrics(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(flushLyrics);
    await tester.pumpAndSettle();
  }
}

Future<LyricsFixture> mountLyrics(
  WidgetTester tester, {
  YYPlatform platform = YYPlatform.android,
  Size size = const Size(390, 844),
  String route = '/lyrics',
  bool empty = false,
  void Function(LyricsFixture)? configure,
}) async {
  late LyricsFixture fixture;
  await tester.runAsync(() async {
    fixture = LyricsFixture();
    fixture.graph.appearance.setReduceMotion(true);
    if (empty) {
      await fixture.graph.initialize();
    } else {
      await fixture.initialize();
      await fixture.graph.playback.seek(const Duration(seconds: 15));
      await fixture.graph.playback.play();
    }
    configure?.call(fixture);
  });
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await closeGraph(tester, fixture.graph);
  });
  await mount(
    tester,
    platform: platform,
    size: size,
    scale: 1.3,
    route: route,
    graph: fixture.graph,
  );
  await settleLyrics(tester);
  return fixture;
}
