import 'package:flutter/foundation.dart';

import '../design_system/yy_player_data.dart';
import '../playback/playback_controller.dart';
import '../playback/playback_state.dart';

/// Root-owned UI projection; the controller remains the only playback truth.
final class PlaybackPresenter extends ChangeNotifier {
  PlaybackPresenter(this._playback) {
    _playback.addListener(_changed);
  }

  final PlaybackController _playback;
  bool _pending = false;
  bool _disposed = false;
  bool _actionFailed = false;

  String? get entryId => _playback.state.queue.currentEntryId;
  bool get busy => _pending || _playback.state.phase == PlaybackPhase.loading;
  bool get canControl =>
      !_disposed &&
      !busy &&
      _playback.isAvailable &&
      _playback.state.queue.entries.isNotEmpty;
  bool get canSeek =>
      canControl &&
      _playback.state.currentTrack != null &&
      (_playback.state.duration?.inMicroseconds ?? 0) > 0 &&
      _playback.state.phase != PlaybackPhase.error;
  bool get canChangeVolume => !_disposed && !busy && _playback.isAvailable;
  String? get errorMessage => _actionFailed || _playback.state.failure != null
      ? '播放操作未完成，请重试或选择其他曲目。'
      : null;

  YYNowPlayingViewData get data {
    final state = _playback.state;
    final track = state.currentTrack;
    final duration = state.duration ?? Duration.zero;
    return YYNowPlayingViewData(
      title: track?.title ?? (state.queue.entries.isEmpty ? '尚未选择音乐' : '队列已就绪'),
      artist: track == null
          ? '从音乐库选择曲目后播放'
          : (track.artists.isEmpty ? '未知艺人' : track.artists.join(' / ')),
      position: duration > Duration.zero && state.position > duration
          ? duration
          : state.position,
      duration: duration,
      playing:
          state.phase == PlaybackPhase.playing ||
          state.phase == PlaybackPhase.buffering,
      volume: state.volume,
      shuffle: state.shuffleEnabled,
      repeat: switch (state.repeatMode) {
        RepeatMode.off => YYRepeatState.off,
        RepeatMode.all => YYRepeatState.all,
        RepeatMode.one => YYRepeatState.one,
      },
    );
  }

  Future<void> togglePlayback() => _run(
    () => data.playing ? _playback.pause() : _playback.play(),
    enabled: canControl,
  );
  Future<void> previous() => _run(_playback.skipPrevious, enabled: canControl);
  Future<void> next() => _run(_playback.skipNext, enabled: canControl);

  void toggleShuffle() {
    if (canControl) {
      _playback.setShuffleEnabled(!_playback.state.shuffleEnabled);
    }
  }

  void cycleRepeat() {
    if (!canControl) return;
    _playback.setRepeatMode(switch (_playback.state.repeatMode) {
      RepeatMode.off => RepeatMode.all,
      RepeatMode.all => RepeatMode.one,
      RepeatMode.one => RepeatMode.off,
    });
  }

  Future<void> seek(double fraction, {required String expectedEntryId}) => _run(
    () => _playback.seek(
      Duration(
        microseconds: (_playback.state.duration!.inMicroseconds * fraction)
            .round(),
      ),
      expectedEntryId: expectedEntryId,
    ),
    enabled:
        canSeek &&
        entryId == expectedEntryId &&
        fraction.isFinite &&
        fraction >= 0 &&
        fraction <= 1,
  );

  Future<void> setVolume(double value) => _run(
    () => _playback.setVolume(value),
    enabled: canChangeVolume && value.isFinite && value >= 0 && value <= 1,
  );

  Future<void> _run(
    Future<void> Function() command, {
    required bool enabled,
  }) async {
    if (!enabled || _disposed) return;
    _pending = true;
    _actionFailed = false;
    notifyListeners();
    try {
      await command();
    } catch (_) {
      _actionFailed = true;
    } finally {
      _pending = false;
      if (!_disposed) notifyListeners();
    }
  }

  void _changed() {
    if (_disposed) return;
    if (_playback.state.phase == PlaybackPhase.playing) _actionFailed = false;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _playback.removeListener(_changed);
    super.dispose();
  }
}
