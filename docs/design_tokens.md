# YYMusic 设计 Token 计划

来源优先级：产品/平台硬约束 → App.tsx Sprite/Polish → 基础HTML结构与行为。这里只建立语义映射，不生成Dart主题。81规则/203声明全部映射见 [polish_rule_mapping.md](generated/polish_rule_mapping.md)；这里的数值是参考与目标，不是已验证的Flutter像素结果。

## 颜色

| Token | Light | Dark |
| --- | --- | --- |
| bg/base | #F5F5F2 | #0B0C0E |
| bg/elevated | #FFFFFF | #16181B |
| bg/subtle | #ECEDEA | #202328 |
| bg/pressed | #E4E5E1 | #2A2E34 |
| text/primary | #111214 | #F5F6F7 |
| text/secondary | #62666C | #A7ACB3 |
| text/tertiary | #93989F | #737982 |
| border/default | #D9DBD7 | #2B2F35 |
| border/strong | #BEC1BC | #3C424A |
| icon/primary | #202226 | #F1F3F4 |
| icon/secondary | #777C83 | #A7ACB3 |
| glass/fill | rgba(255,255,255,.68) | rgba(24,26,30,.70) |
| glass/stroke | rgba(255,255,255,.66) | rgba(255,255,255,.12) |
| glass/highlight | rgba(255,255,255,.82) | rgba(255,255,255,.16) |
| scrim | rgba(12,14,16,.38) | rgba(0,0,0,.58) |

| Accent | Default | Pressed | 网页Soft |
| --- | --- | --- | --- |
| Coral（默认） | #FF3B5C | #D92847 | 12% |
| Cobalt | #0A84FF | #0067CC | 12% |
| Jade | #00A67E | #007F61 | 12% |
| Amber | #F59E0B | #C67A00 | 14% |
| Graphite | #56606B | #3F4852 | 14% |

功能色success #20A464 / warning #E89200 / error #E5484D。

自定义色保留原Hex，生成pressed/约12% soft并用相对亮度计算黑白onAccent。不能照搬HTML固定lum>.53；需比较实际对比度并处理明亮Amber。预设也验证可读性，不只测试custom。没有紫色预设，不加任何Gradient。

## 字体与布局

Inter → Noto Sans SC → Segoe UI Variable → Segoe UI → system sans。原包没有字体文件和@font-face；不能声称已加载Inter。Phase 2选定可分发字体与中文fallback，锁定字体版本用于Golden。

| 文本语义 | 最新参考 |
| --- | --- |
| OpenType | cv01/cv02/ss01/calt；字体支持时启用 |
| pageTitle | 24（Phone22），weight800，spacing-.82，line1.2 |
| sectionTitle | 18，weight740（基础），spacing-.45 |
| hero | 桌面clamp30–50，手机32/窄370为29；spacing-2.1，weight790（基础） |
| heroKicker | 10.5 /760 /+.55 / uppercase |
| albumTitle | 12.5 /700 /-.15 |
| account/name | 13.5 /720 /-.4 |
| account/subtitle | 10 /540 /+.05，top2 |
| search | weight460 |
| badge | weight720 /+.1 |
| lyrics/primary | weight780，spacing clamp(-1.9px,-.05em,-.45px)，桌面34–68/手机29–43；行高1.12/1.14 |
| lyrics/translation | 桌面14–20/手机12–16，opacity.58，weight570 |
| time | 等宽数字；原型8–10是视觉参考，正式需可读性与缩放验证 |

间距语义：0/4/8/12/16/20/24/32/40/48/64/80。布局特定14gap、42titlebar、72rail、88player不要硬凑4的倍数；集中命名，不散落页面魔数。

## 圆角与形状

| 组件 | Token数值 |
| --- | --- |
| Hero / DropZone | 28 /26 |
| FloatingNote / Artwork | 20 /12 |
| AlbumArtwork / TrackArtwork / QueueArtwork | 20 /10 /10 |
| 普通NowArtwork | 26（immersive变体保留独立规则） |
| Sidebar / NowPanel | 24 /24 |
| NavigationItem / TrackRow | 14 /14 |
| IconButton / SourceIcon / SourceStatus | 13 /13 /20 |
| 普通Dialog / NowDialog / ContextMenu | 30 /30 /20 |
| SettingsNav / NowPanelActionIcon | 11 /11 |
| PlaylistCard / PlaylistIcon | 20 /14 |
| MetricCard / FolderRow | 18 /16 |
| LyricsPlayerDock | 26 |
| PhoneBottomNavigation | 32（主指令平台适配，不照搬合成页24） |
| 头像 | 44×44 /full，文字15 /800 /-1.5 |

## 阴影、玻璃、控制

| Token | 最新CSS值 |
| --- | --- |
| shadow/hero | 0 4 20 rgba(15,18,20,.06) + 0 1 3 rgba(15,18,20,.05) |
| shadow/heroDisc | 0 30 72 rgba(15,18,20,.26)；内部24 inset + 22/52/82环纹 |
| shadow/surface | 0 1 4 rgba(15,18,20,.04) + 0 4 18 rgba(15,18,20,.04) |
| shadow/card | 基础light 0 8 24 rgba(15,18,20,.08)；dark 0 10 28 rgba(0,0,0,.24) |
| shadow/album /hover | 0 10 26 rgba(15,18,20,.13) / 0 16 34 rgba(15,18,20,.19) |
| shadow/floating | light 0 14 44 rgba(15,18,20,.16)；dark 0 16 48 rgba(0,0,0,.38) |
| shadow/playerArtwork/light | 普通0 22 50 rgba(15,18,20,.20) |
| shadow/playerArtwork/dark | 普通0 24 58 rgba(0,0,0,.46) |
| shadow/primaryButton /hover | 0 6 18 accent.20 / 0 9 26 accent.30 |
| shadow/iconButton | 0 1 6 rgba(15,18,20,.06) |
| shadow/primaryControl /hover | 0 12 32 rgba(15,18,20,.20) / 0 16 40 rgba(15,18,20,.27) |
| shadow/playerControl | 0 8 22 rgba(15,18,20,.16) |
| shadow/focus | 0 0 0 3 accent.24 |

Glass只用于导航、浮动播放器、临时工具/菜单、歌词Dock。普通Surface不玻璃化。`.glass`目标blur42/saturate1.3；Flutter不是机械sigma42：Phone26–32、Tablet32–38、Windows Standard34–40、Expanded38–42，按设备性能/Golden校准。Reduce Glass关闭blur、提高fill并保留stroke/highlight/shadow；不能用渐变补偿。

Slider正式目标track3、thumb14、focus ring3、桌面hover1.24/130ms；保留44×44命中区。网页immersive5/15、lyrics4/12的specificity差异须记录；不把WebKit margin-top直接变成Flutter偏移。

Motion：standard cubic(.2,.8,.2,1)、enter cubic(.16,1,.3,1)；press100–130ms、hover130–160、selected180–220、page260–280、overlay220–320、expand320–360。Reduced Motion关闭大位移、封面缩放，歌词即时/弱动画。

## 纯色封面与歌词色

| Fixture | 封面背景 /主要几何色 | 歌词纯色 |
| --- | --- | --- |
| Orbit | #0D0F12 /#C42230 /#ECE7DC | #3D4A52 |
| Tide | #0468C4 /#EDF2F8 /#FFA820 | #245064 |
| Noon | #E9DDC8 /#13171B /#C83828 | #684A38 |
| Mono | #0C2030 /#009970 /#E2E4D8 | #282D33 |
| Signal | #F0A018 /#14181C /#FFF3DE | #315247 |
| Quiet | #F2EEE8 /#0F1113 /#C82826 | #64584A |
| Local | #1A1E24 /#E4E7F0 /当前accent | #40515B |

圆/矩形的百分比、旋转、线宽、阴影在全量polish表中逐项保留。未来真实Artwork优先；歌词只提取单一代表色并限制亮度/饱和度、检查白字对比，不生成模糊封面或渐变背景。
