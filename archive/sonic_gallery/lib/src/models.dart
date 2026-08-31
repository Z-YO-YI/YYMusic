class Album {
  const Album(this.title, this.artist, this.atlasIndex, {this.caption});

  final String title;
  final String artist;
  final int atlasIndex;
  final String? caption;
}

class Track {
  const Track(
    this.title,
    this.artist,
    this.album,
    this.atlasIndex,
    this.duration, {
    this.source = '本地音乐',
    this.quality = 'Hi-Res',
  });

  final String title;
  final String artist;
  final String album;
  final int atlasIndex;
  final String duration;
  final String source;
  final String quality;
}

const albums = <Album>[
  Album('夜航', '林渡', 0, caption: '把海风留给夜晚'),
  Album('日光之间', '白栖', 1, caption: '编辑精选'),
  Album('唱针落下', '黑胶事务所', 2, caption: '专注聆听'),
  Album('赤色地平线', '旷野电台', 3, caption: '本周新发行'),
  Album('雾林来信', '潮汐森林', 4, caption: '清晨氛围'),
  Album('留白练习', '纸上声场', 5, caption: '安静时刻'),
];

const tracks = <Track>[
  Track('夜航', '林渡', '远岸来信', 0, '04:12'),
  Track('海面以北', '林渡', '远岸来信', 0, '03:48', quality: '无损'),
  Track('白色庭院', '白栖', '日光之间', 1, '03:36', source: '服务 A'),
  Track('慢速唱针', '黑胶事务所', '唱针落下', 2, '05:04'),
  Track('落日前二十分钟', '旷野电台', '赤色地平线', 3, '04:31', source: '服务 B'),
  Track('穿过雾林', '潮汐森林', '雾林来信', 4, '03:57'),
  Track('纸的弧线', '纸上声场', '留白练习', 5, '02:59', quality: '无损'),
];

