import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/domain/models/pagination.dart';
import 'package:yymusic/domain/models/playlist_content.dart';
import 'package:yymusic/domain/models/track.dart';

import '../support/catalog_detail_probe.dart' show detailTrack;
import '../support/playlist_content_probe.dart';
import 'playlist_controller_test.dart' show commandPlaylist;

void main() {
  test('content windows are immutable and retain repeated tracks under distinct entry IDs', () {
    final track = detailTrack('same');
    final input = [
      contentItem('p', 'a', 0, track),
      contentItem('p', 'b', 1, track),
    ];
    final content = PlaylistContent(
      playlist: contentPlaylist('p'),
      page: PageRequest(limit: 2),
      totalCount: 3,
      entries: input,
    );
    input.clear();
    expect(content.entries.length, 2);
    expect(content.entries.map((item) => item.entry.track).toSet().length, 1);
    expect(content.hasMore, isTrue);
    expect(() => content.entries.clear(), throwsUnsupportedError);
  });

  test(
    'empty and beyond-end windows have zero entries and truthful hasMore',
    () {
      expect(contentWindow(count: 0).hasMore, isFalse);
      final end = contentWindow(count: 3, offset: 20);
      expect(end.entries, isEmpty);
      expect(end.totalCount, 3);
      expect(end.hasMore, isFalse);
      expect(
        contentWindow(count: 3, offset: 1).entries.map((e) => e.entry.position),
        [1, 2],
      );
    },
  );

  test('missing catalog data and all persisted availability states are explicit without inventing a Track', () {
    final missing = contentWindow(unresolved: true).entries.first;
    expect(missing.track, isNull);
    expect(missing.entry.track.trackId, 'track-0');
    expect(missing.isAvailable, isFalse);
    for (final state in TrackAvailability.values) {
      final item = contentItem(
        'p',
        'id',
        0,
        detailTrack('t', availability: state),
      );
      expect(item.isAvailable, state == TrackAvailability.available);
    }
  });

  test('wrong full track references cannot be attached to an entry', () {
    final original = contentWindow().entries.first;
    for (final wrong in [
      detailTrack('wrong'),
      detailTrack('track-0', source: 'other'),
      detailTrack('track-0', type: MusicSourceType.rest),
    ]) {
      expect(
        () => PlaylistContentEntry(entry: original.entry, track: wrong),
        throwsArgumentError,
      );
    }
  });

  test('invalid count system identity incomplete pages duplicated IDs or discontinuous positions fail', () {
    final track = detailTrack('t');
    final page = PageRequest(limit: 2);
    expect(
      () => PlaylistContent(
        playlist: contentPlaylist('p'),
        page: page,
        totalCount: -1,
        entries: [],
      ),
      throwsArgumentError,
    );
    expect(
      () => PlaylistContent(
        playlist: commandPlaylist('p', system: true),
        page: page,
        totalCount: 0,
        entries: [],
      ),
      throwsArgumentError,
    );
    for (final entries in [
      <PlaylistContentEntry>[],
      [contentItem('p', 'a', 0, track)],
      [contentItem('p', 'a', 0, track), contentItem('p', 'a', 1, track)],
      [contentItem('p', 'a', 0, track), contentItem('p', 'b', 3, track)],
      [contentItem('p', 'a', 0, track), contentItem('other', 'b', 1, track)],
      [
        contentItem('p', 'a', 0, track),
        contentItem('p', 'b', 1, track),
        contentItem('p', 'c', 2, track),
      ],
    ]) {
      expect(
        () => PlaylistContent(
          playlist: contentPlaylist('p'),
          page: page,
          totalCount: 2,
          entries: entries,
        ),
        throwsArgumentError,
      );
    }
  });
}
