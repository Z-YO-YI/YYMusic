part of 'fake_domain_repositories.dart';

typedef _SystemReference = ({TrackRef ref, DateTime time, String? id});

extension _FakeSystemPlaylists on FakeCollectionRepository {
  Future<SystemPlaylistContent> _systemContent(
    SystemPlaylistType type,
    PageRequest page,
  ) async {
    if (_systemChanges.isClosed) throw StateError('Collection disposed');
    final records = <_SystemReference>[];
    switch (type) {
      case SystemPlaylistType.favorites:
        final favorites = List.of(_favorites)
          ..sort((a, b) {
            final time = b.addedAt.compareTo(a.addedAt);
            return time != 0 ? time : _key(a.track).compareTo(_key(b.track));
          });
        records.addAll(
          favorites.map((e) => (ref: e.track, time: e.addedAt, id: null)),
        );
      case SystemPlaylistType.recent:
        final history = List.of(_history)..sort(_compareHistory);
        records.addAll(
          history
              .take(20)
              .map((e) => (ref: e.track, time: e.startedAt, id: e.id)),
        );
      case SystemPlaylistType.queue:
        records.addAll(
          _queue.entries.map((e) => (ref: e.track, time: e.addedAt, id: e.id)),
        );
    }
    final selected = records.skip(page.offset).take(page.limit).toList();
    return SystemPlaylistContent(
      type: type,
      page: page,
      totalCount: records.length,
      currentQueueEntryId: type == SystemPlaylistType.queue
          ? _queue.currentEntryId
          : null,
      entries: [
        for (var i = 0; i < selected.length; i++)
          SystemPlaylistEntry(
            reference: selected[i].ref,
            position: page.offset + i,
            addedAt: selected[i].time,
            entryId: selected[i].id,
            track: _contentTracks[selected[i].ref],
          ),
      ],
    );
  }
}

int _compareHistory(PlayHistoryEntry a, PlayHistoryEntry b) {
  final time = b.startedAt.compareTo(a.startedAt);
  return time != 0 ? time : a.id.compareTo(b.id);
}
