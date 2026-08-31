# 最终图标清单

生成来源：App.tsx NEW_ICON_SPRITE；44 个唯一 ID，未手绘、未引入 Material Icons、无 Download 图标。

所有 SVG 保留 viewBox 0 0 24 24 与原始路径；根元素补入原 .icon 的 fill/stroke/round 继承值，子元素的 filled 属性不变。Flutter 接入属于 Phase 2，本阶段不修改 pubspec。ID 语义为用途；消费行号见参考源。

| HTML ID / 用途 | 资产 | App.tsx 行 | 包含 Filled 元素 |
| --- | --- | --- | --- |
| i-home | assets/icons/yymusic/home.svg | 11 | 否 |
| i-search | assets/icons/yymusic/search.svg | 16 | 否 |
| i-library | assets/icons/yymusic/library.svg | 21 | 否 |
| i-settings | assets/icons/yymusic/settings.svg | 27 | 否 |
| i-moon | assets/icons/yymusic/moon.svg | 34 | 否 |
| i-sun | assets/icons/yymusic/sun.svg | 38 | 否 |
| i-play | assets/icons/yymusic/play.svg | 43 | 是（保留局部 stroke="none"） |
| i-pause | assets/icons/yymusic/pause.svg | 47 | 是（保留局部 stroke="none"） |
| i-prev | assets/icons/yymusic/prev.svg | 52 | 是（保留局部 stroke="none"） |
| i-next | assets/icons/yymusic/next.svg | 57 | 是（保留局部 stroke="none"） |
| i-shuffle | assets/icons/yymusic/shuffle.svg | 62 | 否 |
| i-repeat | assets/icons/yymusic/repeat.svg | 68 | 否 |
| i-volume | assets/icons/yymusic/volume.svg | 73 | 否 |
| i-queue | assets/icons/yymusic/queue.svg | 78 | 是（保留局部 stroke="none"） |
| i-more | assets/icons/yymusic/more.svg | 83 | 是（保留局部 stroke="none"） |
| i-heart | assets/icons/yymusic/heart.svg | 89 | 否 |
| i-folder | assets/icons/yymusic/folder.svg | 93 | 否 |
| i-cloud | assets/icons/yymusic/cloud.svg | 97 | 否 |
| i-plus | assets/icons/yymusic/plus.svg | 101 | 否 |
| i-chevron-right | assets/icons/yymusic/chevron-right.svg | 105 | 否 |
| i-chevron-down | assets/icons/yymusic/chevron-down.svg | 109 | 否 |
| i-x | assets/icons/yymusic/x.svg | 113 | 否 |
| i-minimize | assets/icons/yymusic/minimize.svg | 117 | 否 |
| i-maximize | assets/icons/yymusic/maximize.svg | 121 | 否 |
| i-music | assets/icons/yymusic/music.svg | 125 | 否 |
| i-palette | assets/icons/yymusic/palette.svg | 131 | 是（保留局部 stroke="none"） |
| i-key | assets/icons/yymusic/key.svg | 139 | 否 |
| i-info | assets/icons/yymusic/info.svg | 144 | 否 |
| i-check | assets/icons/yymusic/check.svg | 149 | 否 |
| i-playlist | assets/icons/yymusic/playlist.svg | 153 | 否 |
| i-history | assets/icons/yymusic/history.svg | 158 | 否 |
| i-timer | assets/icons/yymusic/timer.svg | 164 | 否 |
| i-device | assets/icons/yymusic/device.svg | 169 | 否 |
| i-trash | assets/icons/yymusic/trash.svg | 174 | 否 |
| i-list-plus | assets/icons/yymusic/list-plus.svg | 179 | 否 |
| i-up | assets/icons/yymusic/up.svg | 183 | 否 |
| i-down | assets/icons/yymusic/down.svg | 187 | 否 |
| i-refresh | assets/icons/yymusic/refresh.svg | 191 | 否 |
| i-speaker | assets/icons/yymusic/speaker.svg | 196 | 否 |
| i-drag | assets/icons/yymusic/drag.svg | 201 | 是（保留局部 stroke="none"） |
| i-wave | assets/icons/yymusic/wave.svg | 210 | 否 |
| i-fullscreen | assets/icons/yymusic/fullscreen.svg | 214 | 否 |
| i-fullscreen-exit | assets/icons/yymusic/fullscreen-exit.svg | 221 | 否 |
| i-lyrics | assets/icons/yymusic/lyrics.svg | 228 | 否 |

按钮必须在 Flutter 提供本地化 Semantics Label；桌面提供 Tooltip；视觉 16/20/24 不限制 44×44 命中区。
