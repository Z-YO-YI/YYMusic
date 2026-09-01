import 'package:flutter/foundation.dart';

import 'yy_artwork_placeholder.dart';

/// Presentation-only repeat state; queue algorithms belong to Phase 4.
enum YYRepeatState { off, all, one }

/// Immutable UI input. It is not a Domain Track or playback source of truth.
@immutable
final class YYNowPlayingViewData {
  YYNowPlayingViewData({
    required this.title,
    required this.artist,
    required this.position,
    required this.duration,
    this.artwork = YYArtworkKind.local,
    this.playing = false,
    this.favorite = false,
    this.shuffle = false,
    this.repeat = YYRepeatState.off,
    this.volume = .72,
  }) : assert(title.isNotEmpty),
       assert(artist.isNotEmpty),
       assert(!position.isNegative),
       assert(!duration.isNegative),
       assert(position <= duration || duration == Duration.zero),
       assert(volume >= 0 && volume <= 1);

  final String title;
  final String artist;
  final Duration position;
  final Duration duration;
  final YYArtworkKind artwork;
  final bool playing;
  final bool favorite;
  final bool shuffle;
  final YYRepeatState repeat;
  final double volume;

  double get progress => duration == Duration.zero
      ? 0
      : (position.inMilliseconds / duration.inMilliseconds).clamp(0, 1);

  YYNowPlayingViewData copyWith({
    String? title,
    String? artist,
    Duration? position,
    Duration? duration,
    YYArtworkKind? artwork,
    bool? playing,
    bool? favorite,
    bool? shuffle,
    YYRepeatState? repeat,
    double? volume,
  }) => YYNowPlayingViewData(
    title: title ?? this.title,
    artist: artist ?? this.artist,
    position: position ?? this.position,
    duration: duration ?? this.duration,
    artwork: artwork ?? this.artwork,
    playing: playing ?? this.playing,
    favorite: favorite ?? this.favorite,
    shuffle: shuffle ?? this.shuffle,
    repeat: repeat ?? this.repeat,
    volume: volume ?? this.volume,
  );
}
