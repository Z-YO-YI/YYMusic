# PR 草稿：Cross-platform source and playlist cards

Head：`feat/cross-platform-collection-cards`；Base：`feat/cross-platform-state-surfaces@dc2758c`。Draft PR待实现提交推送后创建；不自动合并、不改写历史。

## 变更

- 新增Widgets-only受控`YYSourceCard`与`YYPlaylistCard`，实现基础HTML及App.tsx最终`POLISH_CSS`几何、动作、语义和独立状态。
- Source标签/色调由调用方提供；Playlist collection/create只通知动作；Gallery只更新本页确定性Fixture。
- 不引入Source/Playlist Domain、Repository、网络、连接测试、凭据、数据库、计时器、真实曲目计数、队列或持久化。
- 新增5项Widget、3张130%集合卡片Golden，以及ADR、架构、视觉、映射、矩阵和阶段文档。

## 测试

- 85个Dart文件格式无变更，严格分析0问题；完整121项Flutter通过，包含29张Windows宿主精确Golden，三张新增图已逐张视觉审计且旧26张不更新。
- 28项Node、五份源指纹/44 SVG/52项派生产物与24个ZIP entry逐字节核验通过。
- GitHub push/PR/手动三组双平台运行与云端APK复核待实现提交后补充。

## 影响与未验收项

影响范围限于设计系统集合卡片、跨平台Gallery Fixture、测试与文档；正式来源/歌单业务、Controller、Repository、路由、AudioEngine和CI合同不变。

本机Windows C++工具链仍受UAC限制。网页截图对照、Windows本机安装/系统无障碍/GPU性能、Android真机、真实连接及歌单读写流程均未验收。
