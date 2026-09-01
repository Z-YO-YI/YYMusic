# Phase 2J 开始 — 跨平台队列与歌词原语

日期：2026-09-01。开始前已fetch并确认`feat/cross-platform-collection-cards@995016a`与远端0/0同步、工作树干净；从该提交创建`feat/cross-platform-queue-lyrics-primitives`，不在main/master开发。

## 本阶段目标

- 完成主指令通用组件清单中最后三个原生受控组件：`YYQueueTile`、`YYLyricsLine`、`YYLyricsPlayerDock`。
- Queue保留50/7/36基础几何、60/9/42沉浸几何、26视觉动作及App.tsx最终10封面圆角，同时将实际动作命中提升到44dp。
- Lyrics Line保留future 24%、past 50%、hover 56%、active纯白/1.018缩放、7/6状态点，并应用App.tsx最终780字重、紧字距和6px外环。
- Lyrics Dock保留82最小高、11/13内边距、50封面、34/44控制、两层响应式重排及App.tsx最终26圆角；Phone/低高度采用40/38封面。

## 已读取与校验的来源

- 主指令第4.5节最终形状、第16节组件清单、第19节独立歌词页和第20节队列边界。
- 基础HTML`.queue-item*`、`.fullscreen-lyric-line/.lyric-primary/.lyric-translation`及`.lyrics-player-dock/.lyrics-dock-*`完整CSS、900/599/低高度断点和对应行为脚本。
- 完整App.tsx最终`POLISH_CSS`：Queue artwork 9→10、Lyrics Primary 760→780与最终字距、active dot ring 7→6、Dock基础24/Phone21/低高度19→最终26；没有忽略后置覆盖。
- `NEW_ICON_SPRITE`中的up/down/x、prev/play/pause/next/heart/music均继续使用已提取原始SVG。

## 风险与边界

- 本批不创建QueueEntry/LyricsDocument Domain、QueueController/LyricsController新行为、音频Seek、自动滚动、计时器、数据库、持久化、拖拽排序或全屏路由页面。
- 所有当前项、歌词行状态、播放进度和回调均由调用方控制；组件不自行推进时间或修改队列。
- Gallery使用明确标注的确定性Fixture；点击只更新本页状态，不调用现有PlaybackController/QueueController。
- 歌词背景只使用主指令允许的单一纯色，不使用渐变或模糊封面铺满。

## 出口条件

- 三组件几何、动作分离、键盘、语义、禁用/加载、130%、Phone/桌面响应式与Reduce Motion/Glass有Widget约束。
- 新增Golden逐张检查，既有29张保持不变；完整Flutter/Node/ZIP/指纹门禁通过。
- 独立提交推送GitHub、创建Draft PR、双平台Debug成功，APK仍只由GitHub手动工作流构建并独立复核。
