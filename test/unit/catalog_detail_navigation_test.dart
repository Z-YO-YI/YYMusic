import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/catalog_detail_location.dart';
import 'package:yymusic/domain/models/catalog_reference.dart';
import 'package:yymusic/features/catalog_detail/common/catalog_detail_state.dart';

void main() {
  test('detail links round-trip complete identities including separators and unicode', () {
    for (final id in ['normal', 'a/b?c#d', '空 格+%', 'a%2Fb', '.dot', 'a:b@c']) {
      final album = AlbumRef(sourceId: 'source/$id', albumId: id);
      final artist = ArtistRef(sourceId: 'source/$id', artistId: id);
      final a = parseCatalogDetailLocation(
        catalogDetailLocation(AlbumDetailTarget(album)),
      ) as AlbumDetailTarget;
      final b = parseCatalogDetailLocation(
        catalogDetailLocation(ArtistDetailTarget(artist)),
      ) as ArtistDetailTarget;
      expect(a.reference, album);
      expect(b.reference, artist);
    }
  });
  test('malformed ambiguous or external detail links fail closed', () {
    for (final value in [
      '/album/a',
      '/album/a?source=',
      '/artist/a?source=x&source=y',
      '/album/a?source=x&extra=1',
      '/album/a?source=x#fragment',
      '/album/a/b?source=x',
      '/album/?source=x',
      '/other/a?source=x',
      '/album/a?source=%0Aprivate',
      '/artist/${'a' * 257}?source=x',
      'https://example.invalid/album/a?source=x',
    ]) {
      expect(
        parseCatalogDetailLocation(Uri.parse(value)),
        isNull,
        reason: value,
      );
    }
  });
}
