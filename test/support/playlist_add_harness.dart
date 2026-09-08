import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/design_system/yy_button.dart';
import 'package:yymusic/features/playlists/common/playlist_add_dialog.dart';

import 'catalog_detail_graph_fixture.dart';
import 'catalog_detail_menu_harness.dart';
import 'playlist_content_harness.dart';

Finder pickerButton(String label) => find.descendant(
  of: find.byType(PlaylistAddDialog),
  matching: find.byWidgetPredicate((w) => w is YYButton && w.label == label),
);
PlaylistAddDialogState pickerState(WidgetTester tester) =>
    tester.state(find.byType(PlaylistAddDialog));
Finder choiceButton(String id) => find.descendant(
  of: find.byKey(ValueKey(('playlist-choice', id))),
  matching: find.byWidgetPredicate((w) => w is YYButton && w.label == '添加'),
);
Future<void> openDetailPicker(
  WidgetTester tester,
  CatalogDetailGraphFixture f, {
  int index = 2,
}) async {
  await openDetailMenu(tester, f.repository.trackData[index]);
  await tester.tap(find.text('添加到歌单'));
  await settleContent(tester);
}
