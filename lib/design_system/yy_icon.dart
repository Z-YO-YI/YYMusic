import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'yy_theme.dart';

/// Exact names of the 44 NEW_ICON_SPRITE assets extracted in Phase 0.
enum YYGlyph {
  home('home', '首页'),
  search('search', '搜索'),
  library('library', '音乐库'),
  settings('settings', '设置'),
  moon('moon', '深色'),
  sun('sun', '浅色'),
  play('play', '播放'),
  pause('pause', '暂停'),
  previous('prev', '上一首'),
  next('next', '下一首'),
  shuffle('shuffle', '随机'),
  repeat('repeat', '循环'),
  volume('volume', '音量'),
  queue('queue', '队列'),
  more('more', '更多'),
  heart('heart', '喜欢'),
  folder('folder', '文件夹'),
  cloud('cloud', '来源'),
  plus('plus', '添加'),
  chevronRight('chevron-right', '展开'),
  chevronDown('chevron-down', '向下展开'),
  close('x', '关闭'),
  minimize('minimize', '最小化'),
  maximize('maximize', '最大化'),
  music('music', '音乐'),
  palette('palette', '外观'),
  key('key', '凭据'),
  info('info', '信息'),
  check('check', '勾选'),
  playlist('playlist', '歌单'),
  history('history', '历史'),
  timer('timer', '定时'),
  device('device', '设备'),
  trash('trash', '删除'),
  listPlus('list-plus', '加入列表'),
  up('up', '向上'),
  down('down', '向下'),
  refresh('refresh', '刷新'),
  speaker('speaker', '扬声器'),
  drag('drag', '拖动'),
  wave('wave', '声波'),
  fullscreen('fullscreen', '全屏'),
  fullscreenExit('fullscreen-exit', '退出全屏'),
  lyrics('lyrics', '歌词');

  const YYGlyph(this.assetName, this.label);
  final String assetName;
  final String label;
  String get assetPath => 'assets/icons/yymusic/$assetName.svg';
}

/// Tint original SVG geometry, including its filled playback shapes.
class YYIcon extends StatelessWidget {
  const YYIcon({
    required this.glyph,
    super.key,
    this.size = 20,
    this.color,
    this.semanticLabel,
  });
  final YYGlyph glyph;
  final double size;
  final Color? color;
  final String? semanticLabel;
  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    glyph.assetPath,
    width: size,
    height: size,
    colorFilter: ColorFilter.mode(
      color ?? YYTheme.of(context).colors.icon,
      BlendMode.srcIn,
    ),
    semanticsLabel: semanticLabel,
    excludeFromSemantics: semanticLabel == null,
  );
}
