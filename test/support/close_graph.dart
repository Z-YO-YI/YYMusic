import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/dependency_graph.dart';

/// Flush both real-zone SDK stream-cancel callbacks and binding fake microtasks.
Future<void> closeGraph(WidgetTester tester, DependencyGraph graph) async {
  var closed = false;
  final closing = graph.close().then((_) => closed = true);
  for (var i = 0; i < 12 && !closed; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
  }
  expect(
    closed,
    isTrue,
    reason: 'Owned shutdown must finish, not be abandoned',
  );
  await closing;
}
