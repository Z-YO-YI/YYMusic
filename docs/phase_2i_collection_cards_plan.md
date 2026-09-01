# Phase 2I 开始 — 跨平台来源与歌单卡片

日期：2026-09-01。开始前已fetch并确认`feat/cross-platform-state-surfaces@dc2758c`与远端0/0同步、工作树干净；从该提交创建`feat/cross-platform-collection-cards`，不在main/master开发。

## 本阶段目标

- 新增主指令组件清单中的原生受控`YYSourceCard`与`YYPlaylistCard`，并加入Android/Windows共享Gallery。
- Source Card保留72最小高、12内边距、42图标、16卡片圆角及App.tsx最终13图标圆角；状态点为6。
- Playlist Card保留16内边距、最终20圆角、44图标与最终14图标圆角、18标题间距；Phone沿用13内边距和40图标。
- 覆盖指针、键盘、焦点、选中、禁用、加载、Light/Dark、自定义Accent及130%窄宽。

## 已读取与校验的来源

- 主指令第16节组件清单、17节页面数据边界、31节无障碍与Phase2出口。
- 基础HTML`.source-cards/.source-card/.source-icon/.source-state`及`.playlist-grid/.playlist-card/.playlist-icon`完整CSS、599/760/1180断点和对应渲染脚本。
- 完整App.tsx最终`POLISH_CSS`：Source icon 14→13、Playlist card 19/Phone17→最终20、Playlist icon 15→最终14；没有忽略后置覆盖。
- Phase2H最终分支头的五份指纹、44 SVG、52派生产物、113项Flutter、26张Golden与双平台云端证据均保持完成状态。

## 风险与边界

- 本批不创建Source/Playlist Domain模型、Repository、网络测试、计时器、数据库、凭据、曲目集合或持久化。
- Source状态标签和色调均由调用方提供；卡片不把HTML的“在线”“128首”演示状态接入正式Shell。
- Playlist选择与Create只通知回调；不打开真实页面/Dialog，不修改队列、喜欢、历史或用户歌单。
- Gallery所有内容明确为Fixture；业务状态与计数不伪造成真实数据。

## 出口条件

- 两组件几何、长文字、动作、语义、指针/键盘、禁用/加载/选中及Phone响应式有Widget约束。
- 新增Golden逐张检查，既有26张保持不变；完整Flutter/Node/ZIP/指纹门禁通过。
- 独立提交推送GitHub、创建Draft PR、双平台Debug成功，APK仍只由GitHub手动工作流构建并独立复核。
