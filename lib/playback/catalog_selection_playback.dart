part of 'playback_controller.dart';

typedef _SelectionMode = ({bool enabled, List<String> order});

extension _CatalogSelectionPlayback on PlaybackController {
  Future<bool> _playSelection(
    Iterable<TrackRef> input, {
    required bool shuffle,
    bool Function()? canPlay,
  }) async {
    final tracks = List<TrackRef>.unmodifiable(input);
    if (tracks.isEmpty) return false;
    var revoked = false;
    bool allowed() {
      revoked = revoked || _disposed || canPlay?.call() == false;
      return !revoked;
    }

    var started = false;
    await _schedule(
      () => _guarded('catalog-play-selection', () async {
        if (!allowed()) return;
        _requireEngine();
        final now = _clock().toUtc();
        final used = _state.queue.entries.map((e) => e.id).toSet();
        final entries = <QueueEntry>[];
        for (final track in tracks) {
          String id;
          do {
            id =
                'selection-${now.microsecondsSinceEpoch}-${_catalogSequence++}';
          } while (!used.add(id));
          entries.add(
            QueueEntry(
              id: id,
              track: track,
              position: entries.length,
              addedAt: now,
            ),
          );
        }
        final order = entries.map((e) => e.id).toList();
        if (shuffle) {
          // Complete validation before stopping old audio or persisting anything.
          for (var i = order.length - 1; i > 0; i--) {
            final j = _randomIndex(i + 1);
            if (j < 0 || j > i) throw StateError('Invalid shuffle index');
            final value = order[i];
            order[i] = order[j];
            order[j] = value;
          }
        }
        final first = order.first;
        final snapshot = QueueSnapshot(
          entries: entries,
          currentEntryId: first,
          updatedAt: now,
        );
        final committed = await _commitQueue(
          snapshot,
          selectionMode: (
            enabled: shuffle,
            order: shuffle ? List.unmodifiable(order) : const [],
          ),
          canCommit: allowed,
        );
        if (!committed || !allowed()) return;
        await _playEntryInternal(first, canPlay: allowed);
        started = allowed();
      }),
    );
    return started;
  }
}
