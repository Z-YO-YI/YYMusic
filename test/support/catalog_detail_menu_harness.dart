import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/design_system/yy_button.dart';
import 'package:yymusic/domain/models/track.dart';

Future<Finder> revealDetailTrack(WidgetTester tester, Track track) async {
  final row = find.byKey(ValueKey(track.ref));
  await tester.scrollUntilVisible(
    row,
    180,
    scrollable: find
        .descendant(
          of: find.byKey(const PageStorageKey('detail-scroll')),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await Scrollable.ensureVisible(tester.element(row), alignment: 0.5);
  await tester.pumpAndSettle();
  return row;
}

Finder detailMore(Track track) => find.byWidgetPredicate(
  (widget) => widget is YYButton && widget.label == '${track.title} 的更多操作',
);

Future<void> openDetailMenu(WidgetTester tester, Track track) async {
  await revealDetailTrack(tester, track);
  await tester.tap(detailMore(track));
  await tester.pumpAndSettle();
}

/// Drain deferred event tasks and SDK stream cancellation in both test zones.
Future<void> drainMenuWork(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(Duration.zero);
  }
}
