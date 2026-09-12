# Phase 7E5E 开始：系统歌单队列菜单

2026-09-12。仓库 Z-YO-YI/YYMusic，fetch/ff-only pull 后基线 a2a8b41a1e0a51e944c427a8538de21bf320fb1e，工作区干净；新分支 codex/system-playlist-queue-actions，Stacked Draft base=codex/playlist-queue-actions。

## 本阶段目标

我喜欢和最近播放的 Phone/Tablet/Windows 原生歌曲菜单接入下一首/添加队列及共享反馈；重复入队使用独立 ID，缺失/未解析歌曲仅保存软引用，不播放、不改变收藏或播放历史。保留收藏取消及独立清除历史确认，不扩大到第二份队列或导入。

## 已读取的来源

总指令 Phase7–11、阶段出口与代码规则；已完整审计的基础 HTML 与 App.tsx NEW_ICON_SPRITE/POLISH_CSS；四源 SHA256 本轮复核与 Phase0 一致。SystemPlaylist Controller/Actions/Screen/Sections/ManagementPanel、模型/路由、原系统歌单测试，以及 E5D 菜单许可/根反馈实现。

使用 Figma 转代码技能的本地完整导出路径，无线上 node URL，不虚构线上读取。沿用精确 next/list-plus/heart SVG、YYContextMenu/YYButton/YYErrorBanner 与原三套布局。

## 准备修改与新增

修改 AppRouter、SystemPlaylistActions/Screen/Sections/ManagementPanel、系统歌单 Node 门禁，README/状态/矩阵/ADR/报告；新增 system_queue_actions.dart、源许可/Widget/真实 SQLite/Golden 测试与对应基线。仅精确更新确实受新菜单及最近播放更多按钮影响的旧图。先记录 ADR089，再改共享 API。

## 风险与策略

- 收藏以 TrackRef、历史以历史 ID 标识；请求捕获准确窗口和 SystemPlaylistEntry 对象，不复用历史 ID 作为队列 ID。
- 源读取意图、页面代数、根快照三层许可；刷新/换组/覆盖/尺寸/零面积/关闭撤销旧动作。跨正常尺寸保留菜单外观但重发请求；历史清除确认同样重发身份，旧确认不可执行。
- 清除历史仍须单独确认，队列编辑不生成历史或删除收藏；根队列变化不取消独立历史确认。卸载和旧遮罩回调不得 setState 或关闭新菜单。
- 共享 busy/失败与显式同 ID 重试沿用根；已接受写入排空。无新播放器、数据库字段或依赖。

## 出口条件

三端实际手势/键盘、重复引用、失效引用、旧回调、源刷新/窗口/路由、失败重试、关闭排空和清除确认隔离测试通过；真实 SQLite 证明收藏/历史不变；Golden 逐张查看。完整 Flutter/Node、格式/严格分析、生成/迁移零漂移、指纹/许可、Android Debug 预检通过后审查提交、push、Draft PR；新 SHA 的 GitHub Android/Windows 构建独立记录，不借上批成功。
