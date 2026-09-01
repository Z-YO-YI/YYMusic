# PR 草稿：Cross-platform queue and lyrics primitives

Head：`feat/cross-platform-queue-lyrics-primitives`；Base：`feat/cross-platform-collection-cards@995016a`。Draft PR编号待推送后记录；不自动合并、不改写历史。

## 变更

- 新增Widgets-only受控`YYQueueTile`、`YYLyricsLine`与`YYLyricsPlayerDock`，实现基础HTML及App.tsx最终`POLISH_CSS`几何、动作、语义和响应式状态。
- Queue主动作/上移/下移/移除、歌词行和Dock Transport/Slider/收藏/返回保持独立；Gallery只更新本页确定性Fixture。
- 不引入Queue/Lyrics Domain、音频Seek、LRC解析、自动滚动、计时器、拖拽排序、数据库、持久化或正式页面。
- 新增7项Widget、3张130%队列歌词Golden，以及ADR、架构、视觉、映射、矩阵和阶段文档。

## 测试

- 91个Dart文件格式无变更，严格分析0问题；完整131项Flutter通过，包含32张Windows宿主精确Golden，三张新增图已逐张视觉审计且旧29张不更新。
- 28项Node、五份源指纹/44 SVG/52项派生产物与24个ZIP entry逐字节核验通过。
- GitHub push、PR、手动双平台运行及草稿Release三资产复核待目标实现提交后记录，当前不沿用Phase2I证据。

## 影响与未验收项

影响范围限于设计系统队列/歌词原语、共享Slider的歌词外观、跨平台Gallery Fixture、测试与文档；正式Controller、Repository、路由、AudioEngine和CI合同不变。

本机Windows C++工具链仍受UAC限制。网页截图对照、Windows本机安装/系统无障碍/GPU性能、Android真机、真实队列/Seek/LRC/自动跟随流程均未验收。
