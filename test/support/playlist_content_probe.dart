import 'dart:async';

import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/domain/models/pagination.dart';
import 'package:yymusic/domain/models/playlist_content.dart';
import 'package:yymusic/domain/models/track.dart';
import 'package:yymusic/features/playlists/common/playlist_content_controller.dart';

import 'catalog_detail_probe.dart' show detailTrack;

final contentEpoch = DateTime.utc(2026, 9, 8);
Playlist contentPlaylist(String id, {String name = '测试歌单'}) => Playlist(
  id: id,
  name: name,
  description: '保留说明',
  createdAt: contentEpoch,
  updatedAt: contentEpoch,
);

PlaylistContent contentWindow({
  String id = 'p',
  int count = 3,
  int limit = 20,
  int offset = 0,
  bool unresolved = false,
  String name = '测试歌单',
}) {
  final tracks = [for (var i = 0; i < count; i++) detailTrack('track-$i')];
  return PlaylistContent(
    playlist: contentPlaylist(id, name: name),
    page: PageRequest(limit: limit, offset: offset),
    totalCount: count,
    entries: [
      for (var i = offset; i < count && i < offset + limit; i++)
        contentItem(id, 'entry-$i', i, tracks[i], unresolved: unresolved),
    ],
  );
}

PlaylistContentEntry contentItem(
  String playlistId,
  String entryId,
  int position,
  Track track, {
  bool unresolved = false,
}) => PlaylistContentEntry(
  entry: PlaylistEntry(
    id: entryId,
    playlistId: playlistId,
    track: track.ref,
    position: position,
    addedAt: contentEpoch,
  ),
  track: unresolved ? null : track,
);

Future<void> waitForContent(
  PlaylistContentController controller,
  bool Function() predicate,
) {
  final completion = Completer<void>();
  void check() {
    if (!completion.isCompleted && predicate()) completion.complete();
  }

  controller.addListener(check);
  check();
  return completion.future
      .timeout(const Duration(seconds: 5))
      .whenComplete(() => controller.removeListener(check));
}

Future<void> contentTick() async {
  for (var i = 0; i < 12; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}
