import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/domain/models/pagination.dart';
import 'package:yymusic/domain/models/system_playlist_content.dart';

import '../support/catalog_detail_probe.dart';
import '../support/playlist_content_probe.dart';

void main() {
  final track = detailTrack('a');
  SystemPlaylistEntry item({String? id, int position = 0}) =>
      SystemPlaylistEntry(
        reference: track.ref,
        position: position,
        entryId: id,
        addedAt: contentEpoch,
        track: track,
      );
  test('system models freeze a bounded window and retain a current queue ID outside it', () {
    final entries = [item(id: 'entry', position: 4)];
    final data = SystemPlaylistContent(
      type: SystemPlaylistType.queue,
      page: PageRequest(offset: 4, limit: 1),
      totalCount: 6,
      entries: entries,
      currentQueueEntryId: 'outside',
    );
    entries.clear();
    expect(data.entries.single.identity, 'entry');
    expect(data.entries.single.isAvailable, isTrue);
    expect(data.currentQueueEntryId, 'outside');
    expect(data.hasMore, isTrue);
    expect(() => data.entries.clear(), throwsUnsupportedError);
    expect(item().identity, track.ref);
  });
  test('queue preserves repeat references but duplicate entry IDs and wrong type identity fail', () {
    expect(
      SystemPlaylistContent(
        type: SystemPlaylistType.queue,
        page: PageRequest(),
        totalCount: 2,
        entries: [
          item(id: 'a'),
          item(id: 'b', position: 1),
        ],
      ).entries.length,
      2,
    );
    for (final (type, entries) in [
      (SystemPlaylistType.favorites, [item(id: 'bad')]),
      (SystemPlaylistType.queue, [item()]),
      (SystemPlaylistType.recent, [item()]),
      (SystemPlaylistType.queue, [item(id: 'a'), item(id: 'a', position: 1)]),
      (SystemPlaylistType.favorites, [item(), item(position: 1)]),
    ]) {
      expect(
        () => SystemPlaylistContent(
          type: type,
          page: PageRequest(),
          totalCount: entries.length,
          entries: entries,
        ),
        throwsArgumentError,
      );
    }
  });
  test('incomplete order counts recent cap timestamps and mismatched tracks fail closed', () {
    expect(() => item(position: -1), throwsArgumentError);
    expect(() => item(id: ' bad '), throwsArgumentError);
    expect(
      () => SystemPlaylistEntry(
        reference: track.ref,
        position: 0,
        addedAt: contentEpoch.toLocal(),
      ),
      throwsArgumentError,
    );
    expect(
      () => SystemPlaylistEntry(
        reference: track.ref,
        position: 0,
        addedAt: contentEpoch,
        track: detailTrack('other'),
      ),
      throwsArgumentError,
    );
    for (final (type, count, entries, current) in [
      (SystemPlaylistType.favorites, -1, <SystemPlaylistEntry>[], null),
      (SystemPlaylistType.favorites, 2, [item()], null),
      (SystemPlaylistType.favorites, 1, [item(position: 1)], null),
      (SystemPlaylistType.favorites, 1, [item()], 'a'),
      (SystemPlaylistType.recent, 21, <SystemPlaylistEntry>[], null),
      (SystemPlaylistType.queue, 0, <SystemPlaylistEntry>[], 'a'),
    ]) {
      expect(
        () => SystemPlaylistContent(
          type: type,
          page: PageRequest(),
          totalCount: count,
          entries: entries,
          currentQueueEntryId: current,
        ),
        throwsArgumentError,
      );
    }
  });
}
