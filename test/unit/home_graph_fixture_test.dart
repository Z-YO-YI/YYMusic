import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/domain/models/pagination.dart';

import '../support/home_graph_fixture.dart';

void main() {
  test(
    'Home fixture captures one timestamp even when the host clock advances',
    () async {
      final start = DateTime.utc(2026, 9, 6, 12);
      var reads = 0;
      final fixture = HomeGraphFixture(
        clock: () => start.add(Duration(microseconds: reads++)),
      );
      addTearDown(() async {
        await fixture.graph.close();
        await fixture.disposeFakes();
      });
      final page = await fixture.library.listRecentlyAdded(
        PageRequest(),
        since: start,
        until: start.add(const Duration(seconds: 1)),
      );
      expect(reads, 1);
      expect(
        page.items.map((track) => track.id),
        fixture.tracks.map((track) => track.id),
      );
    },
  );

  test(
    'Home fixture recent order is the same for coarse and precise clocks',
    () async {
      final start = DateTime.utc(2026, 9, 6, 12);
      final orders = <List<String>>[];
      for (final step in [
        Duration.zero,
        const Duration(microseconds: 1),
        const Duration(seconds: 1),
      ]) {
        var reads = 0;
        final fixture = HomeGraphFixture(
          clock: () => start.add(step * reads++),
        );
        try {
          final page = await fixture.library.listRecentlyAdded(
            PageRequest(),
            since: start.subtract(const Duration(days: 7)),
            until: start.add(const Duration(minutes: 1)),
          );
          orders.add(page.items.map((track) => track.id).toList());
        } finally {
          await fixture.graph.close();
          await fixture.disposeFakes();
        }
      }
      expect(orders[1], orders[0]);
      expect(orders[2], orders[0]);
    },
  );
}
