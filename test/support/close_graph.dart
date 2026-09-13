import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/dependency_graph.dart';

/// Flush both real-zone SDK stream-cancel callbacks and binding fake microtasks.
Future<void> closeGraph(WidgetTester tester, DependencyGraph graph) async {
  var closed = false;
  final closing = graph.close().then((_) => closed = true);
  // Native channel and stream teardown crosses real/fake zones. Bound by time,
  // not twelve event turns whose wall-clock allowance varies with CI load.
  final elapsed = Stopwatch()..start();
  while (!closed && elapsed.elapsed < const Duration(seconds: 5)) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 1)),
    );
    // A duration also advances zero-delay event tasks registered during dispose.
    await tester.pump(Duration.zero);
  }
  elapsed.stop();
  expect(
    closed,
    isTrue,
    reason: 'Owned shutdown must finish, not be abandoned',
  );
  await closing;
}
