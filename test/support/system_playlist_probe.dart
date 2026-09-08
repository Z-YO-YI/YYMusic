import 'dart:async';

import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/domain/models/pagination.dart';
import 'package:yymusic/domain/models/system_playlist_content.dart';
import 'package:yymusic/features/playlists/common/system_playlist_controller.dart';

import 'catalog_detail_probe.dart';
import 'playlist_content_probe.dart';

SystemPlaylistContent systemWindow({
  SystemPlaylistType type = SystemPlaylistType.queue,
  int count = 3,
  int limit = 20,
  int offset = 0,
  String? current,
  bool unresolved = false,
}) => SystemPlaylistContent(
  type: type,
  page: PageRequest(limit: limit, offset: offset),
  totalCount: count,
  currentQueueEntryId: current,
  entries: [
    for (var i = offset; i < count && i < offset + limit; i++)
      SystemPlaylistEntry(
        reference: detailTrack('track-$i').ref,
        position: i,
        addedAt: contentEpoch,
        entryId: type == SystemPlaylistType.favorites ? null : 'entry-$i',
        track: unresolved ? null : detailTrack('track-$i'),
      ),
  ],
);

Future<void> waitForSystem(
  SystemPlaylistController controller,
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

Future<void> expandSystemWindow(SystemPlaylistController controller) async {
  await waitForSystem(controller, () => controller.isCurrent);
  while (controller.canLoadMore) {
    controller.loadMore(controller.content!);
    await waitForSystem(controller, () => controller.isCurrent);
  }
}
