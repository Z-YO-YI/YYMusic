enum PlaylistCommandStatus {
  succeeded,
  invalidName,
  busy,
  unavailable,
  notFound,
  protectedPlaylist,
  failed,
}

/// Safe command outcome; raw storage errors and user text are never included.
final class PlaylistCommandResult {
  const PlaylistCommandResult(this.status, {this.playlistId})
    : assert(
        (status == PlaylistCommandStatus.succeeded) == (playlistId != null),
      );
  final PlaylistCommandStatus status;
  final String? playlistId;
  bool get succeeded => status == PlaylistCommandStatus.succeeded;
  String get message => switch (status) {
    PlaylistCommandStatus.succeeded => '歌单已更新。',
    PlaylistCommandStatus.invalidName => '请输入1–512个字符的歌单名称，不含换行或控制字符。',
    PlaylistCommandStatus.busy => '另一项歌单操作正在保存，请稍候。',
    PlaylistCommandStatus.unavailable => '歌单存储暂不可用。',
    PlaylistCommandStatus.notFound => '此歌单已不存在，请刷新列表。',
    PlaylistCommandStatus.protectedPlaylist => '系统歌单不允许此操作。',
    PlaylistCommandStatus.failed => '歌单操作未完成，请重试。',
  };
}
