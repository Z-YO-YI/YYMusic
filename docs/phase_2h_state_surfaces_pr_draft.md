# PR 草稿：Cross-platform state and feedback primitives

Head：`feat/cross-platform-state-surfaces`；Base：`feat/cross-platform-overlay-primitives@6642ad0`；[Draft PR #6](https://github.com/Z-YO-YI/YYMusic/pull/6)。不自动合并、不改写历史。

## 变更

- 新增Widgets-only受控`YYThemeSwatch`、`YYEmptyState`、`YYErrorBanner`与`YYSkeleton`，实现审计几何、动作、语义和独立状态。
- Gallery强调色选择改用Swatch，并新增跨平台本地状态Fixture；不引入网络、Repository、计时器、假数据、依赖或权限。
- Skeleton使用静止纯色且默认填宽，不使用参考中不存在的渐变shimmer。
- 新增6项Widget、3张130%状态组件Golden，以及ADR、架构、视觉、映射、矩阵和阶段文档。

## 测试

- 80个Dart文件格式无变更，严格分析0问题；完整113项Flutter通过，包含26张Windows宿主精确Golden，三张新增图已逐张视觉审计且旧23张不更新。
- 28项Node、五份源指纹/44 SVG/52项派生产物与24个ZIP entry逐字节核验通过。
- 实现提交`9f71d14`的push运行33468979883、PR运行33469047182及手动运行33469832392各自三个job全部成功。
- 私有草稿Release三资产已下载复核；APK为175828689字节，SHA-256/API digest为`b9494ff75b5176b97ac11360a4b496c5182acdc5b0e875087a25d299989f6231`，metadata身份一致且v2签名有效。

## 影响与未验收项

影响范围限于设计系统状态原语、跨平台Gallery Fixture、测试与文档；正式异步状态、Controller、Repository、路由、AudioEngine和CI合同不变。

本机Windows C++工具链仍受UAC限制。网页截图对照、Windows本机安装/系统无障碍/GPU性能、Android真机及真实loading/data/empty/error流程均未验收。
