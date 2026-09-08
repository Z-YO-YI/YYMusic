import '../../../design_system/yy_icon.dart';
import '../../../domain/models/collection_models.dart';

/// Labels for virtual collections; these are not persisted Playlist records.
extension SystemPlaylistPresentation on SystemPlaylistType {
  String get title => switch (this) {
    SystemPlaylistType.favorites => '喜欢的音乐',
    SystemPlaylistType.recent => '最近播放',
    SystemPlaylistType.queue => '当前队列',
  };
  YYGlyph get glyph => switch (this) {
    SystemPlaylistType.favorites => YYGlyph.heart,
    SystemPlaylistType.recent => YYGlyph.history,
    SystemPlaylistType.queue => YYGlyph.queue,
  };
  String get description => switch (this) {
    SystemPlaylistType.favorites => '按收藏时间倒序',
    SystemPlaylistType.recent => '最近 20 首记录',
    SystemPlaylistType.queue => '按当前队列顺序',
  };
  String get emptyMessage => switch (this) {
    SystemPlaylistType.favorites => '还没有收藏的歌曲。可从歌曲菜单添加喜欢。',
    SystemPlaylistType.recent => '还没有播放记录。',
    SystemPlaylistType.queue => '当前队列为空。可从音乐库选择歌曲播放。',
  };
}
