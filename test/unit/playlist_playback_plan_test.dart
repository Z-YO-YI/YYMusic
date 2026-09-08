import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/domain/models/playlist_playback_plan.dart';
import 'package:yymusic/domain/models/track.dart';

import '../support/catalog_detail_probe.dart';

void main() {
  PlaylistPlaybackEntry entry(String id, int position) => PlaylistPlaybackEntry(
    id: id,
    position: position,
    track: detailTrack('same').ref,
    availability: TrackAvailability.available,
  );
  test(
    'complete plans freeze entries but preserve repeated full references',
    () {
      final entries = [entry('a', 0), entry('b', 1)];
      final plan = PlaylistPlaybackPlan(playlistId: 'p', entries: entries);
      entries.clear();
      expect(plan.entries.length, 2);
      expect(plan.entries.map((e) => e.track).toSet().length, 1);
      expect(plan.entries.every((e) => e.isAvailable), isTrue);
      expect(() => plan.entries.clear(), throwsUnsupportedError);
      expect(
        PlaylistPlaybackEntry(
          id: 'c',
          position: 0,
          track: detailTrack('x').ref,
        ).isAvailable,
        isFalse,
      );
    },
  );
  test('ambiguous identities and incomplete positions fail closed', () {
    for (final entries in [
      [entry('a', 1)],
      [entry('a', 0), entry('a', 1)],
      [entry('a', 0), entry('b', 2)],
    ]) {
      expect(
        () => PlaylistPlaybackPlan(playlistId: 'p', entries: entries),
        throwsArgumentError,
      );
    }
    expect(() => entry('a', -1), throwsArgumentError);
    expect(() => entry(' bad ', 0), throwsArgumentError);
    expect(
      () => PlaylistPlaybackPlan(playlistId: '', entries: []),
      throwsArgumentError,
    );
  });
}
