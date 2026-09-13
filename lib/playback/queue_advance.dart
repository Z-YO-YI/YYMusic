part of 'playback_controller.dart';

extension on PlaybackController {
  Future<void> _advanceCandidates(bool Function()? canAdvance) async {
    final first = _nextEntry();
    if (first == null) return;
    final order = _state.shuffleEnabled
        ? List<String>.of(_shuffleOrder)
        : _state.queue.entries.map((entry) => entry.id).toList();
    final index = order.indexOf(first.id);
    final candidates = [
      ...order.skip(index),
      if (_state.repeatMode == RepeatMode.all) ...order.take(index),
    ];
    DomainFailure? lastFailure;
    for (final id in candidates) {
      if (_disposed || canAdvance?.call() == false) return;
      DomainFailure? skippable;
      try {
        await _playEntryInternal(
          id,
          canPlay: canAdvance,
          onSkippableFailure: (failure) => skippable = failure,
        );
        return;
      } on DomainFailure {
        final failure = skippable;
        if (failure == null) rethrow;
        lastFailure = failure;
        if (_disposed) return;
        final entry = _entry(id);
        _queuePlaybackFailures = List.unmodifiable([
          ..._queuePlaybackFailures.skip(
            _queuePlaybackFailures.length >= 20 ? 1 : 0,
          ),
          QueuePlaybackFailure(
            entryId: id,
            track: entry.track,
            code: failure.code,
          ),
        ]);
        _publish(_state);
      }
    }
    if (lastFailure != null && !_disposed && canAdvance?.call() != false) {
      throw lastFailure;
    }
  }

  bool _isSkippableTrackFailure(DomainFailure failure) =>
      switch (failure.code) {
        DomainFailureCode.localFileMissing ||
        DomainFailureCode.unsupportedAudioFormat ||
        DomainFailureCode.sourceDisabled ||
        DomainFailureCode.sourceRemoved ||
        DomainFailureCode.playbackOpenFailed ||
        DomainFailureCode.streamUrlExpired ||
        DomainFailureCode.notFound => true,
        _ => false,
      };
}
