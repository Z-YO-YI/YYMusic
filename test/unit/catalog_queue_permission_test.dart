import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/features/catalog_detail/common/catalog_detail_state.dart';

import '../support/catalog_detail_graph_fixture.dart';
import '../support/catalog_detail_probe.dart';

void main() {
  for (final artist in [false, true]) {
    test(
      'detail artist=$artist permits missing exact object, not equal ref clone',
      () async {
        final f = CatalogDetailGraphFixture(trackCount: 4);
        addTearDown(f.close);
        await f.initialize();
        final c = f.graph.catalogDetails.open(
          artist
              ? ArtistDetailTarget(f.artist.ref)
              : AlbumDetailTarget(f.album.ref),
        );
        await c.start();
        final track = f.repository.trackData[2];
        expect(c.canPlay(track.ref), isFalse);
        expect(c.queueSourcePermit(track)!(), isTrue);
        final clone = detailTrack('002');
        expect(clone.ref, track.ref);
        expect(c.queueSourcePermit(clone), isNull);
        expect(f.engine.calls, isEmpty);
      },
    );
    for (final reason in ['refresh', 'hide', 'close']) {
      test(
        'detail artist=$artist permanently revokes source after $reason',
        () async {
          final f = CatalogDetailGraphFixture(trackCount: 4);
          addTearDown(f.close);
          await f.initialize();
          final c = f.graph.catalogDetails.open(
            artist
                ? ArtistDetailTarget(f.artist.ref)
                : AlbumDetailTarget(f.album.ref),
          );
          await c.start();
          final permit = c.queueSourcePermit(f.repository.trackData.first)!;
          switch (reason) {
            case 'refresh':
              await c.refresh();
            case 'hide':
              c.setActive(false);
              c.setActive(true);
            case 'close':
              await c.close();
          }
          expect(permit(), isFalse);
        },
      );
    }
  }
}
