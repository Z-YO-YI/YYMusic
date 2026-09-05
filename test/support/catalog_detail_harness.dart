import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/catalog_detail_location.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/app/yy_music_app.dart';
import 'package:yymusic/features/catalog_detail/common/catalog_detail_screen.dart';
import 'package:yymusic/features/catalog_detail/common/catalog_detail_state.dart';

import 'catalog_detail_graph_fixture.dart';
import 'close_graph.dart';

Future<void> mountDetail(
  WidgetTester tester,
  CatalogDetailGraphFixture fixture, {
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
  await fixture.initialize();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [dependencyGraphProvider.overrideWithValue(fixture.graph)],
      child: RepaintBoundary(
        key: const ValueKey('detail-golden'),
        child: YYMusicApp(
          platform: platform,
          initialLocation:
              location ??
              catalogDetailLocation(AlbumDetailTarget(fixture.album.ref))
                  .toString(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

CatalogDetailScreenState detailState(WidgetTester tester) =>
    tester.state<CatalogDetailScreenState>(find.byType(CatalogDetailScreen));

Future<void> closeDetail(
  WidgetTester tester,
  CatalogDetailGraphFixture fixture,
) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await closeGraph(tester, fixture.graph);
  await tester.runAsync(fixture.disposeFakes);
}
