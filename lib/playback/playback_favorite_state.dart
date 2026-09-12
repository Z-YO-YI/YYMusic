part of 'playback_favorite_controller.dart';

/// Exact read identity. Null favorite means unknown, never an assumed false.
final class PlaybackFavoriteState {
  PlaybackFavoriteState._(this.queue, this.reference, this.isFavorite);
  final QueueSnapshot queue;
  final TrackRef? reference;
  final bool? isFavorite;
  String? get entryId => queue.currentEntryId;
}

enum PlaybackFavoriteFailureKind { read, write }

enum PlaybackFavoriteEditResult { applied, cancelled, busy, failed, unchanged }

/// Retains only safe intent data, never exception text, paths or credentials.
final class PlaybackFavoriteFailure {
  PlaybackFavoriteFailure._(this.kind, this.expected, this.favorite)
    : failure = DomainFailure(
        code: DomainFailureCode.unknown,
        diagnosticId: 'playback-favorite.${kind.name}',
        retryable: true,
      );
  final PlaybackFavoriteFailureKind kind;
  final PlaybackFavoriteState expected;
  final bool? favorite;
  final DomainFailure failure;
  String get message => kind == PlaybackFavoriteFailureKind.read
      ? '收藏状态读取失败，请重试。播放不受影响。'
      : '收藏操作未完成，请检查当前歌曲后重试。播放不受影响。';
}
