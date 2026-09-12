import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/domain/models/pagination.dart';

import '../support/lyrics_fixture.dart';

void main() {
  test(
    'one import timestamp keeps same-title fixture order host-independent',
    () async {
      var reads = 0;
      final importedAt = DateTime.utc(2026, 9, 13);
      final fixture = LyricsFixture(
        clock: () => importedAt.add(Duration(microseconds: reads++)),
      );
      try {
        final page = await fixture.graph.library!.listRecentlyAdded(
          PageRequest(limit: 20),
          since: importedAt.subtract(const Duration(days: 1)),
          until: importedAt.add(const Duration(days: 1)),
        );
        expect(reads, 1);
        expect(page.items.map((track) => track.sourceId), [
          'one',
          'three',
          'two',
        ]);
        expect(page.items.first.ref, lyricsTracks.first.ref);
      } finally {
        await fixture.graph.close();
      }
    },
  );
}
