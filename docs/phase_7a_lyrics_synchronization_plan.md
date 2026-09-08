# Phase 7A 开始 — 共享歌词时间轴与同步核心

2026-09-09；仓库 Z-YO-YI/YYMusic；分支 `codex/lyrics-synchronization-core`。
开始前已 fetch，并从 `origin/codex/native-settings-surfaces` ff-only 拉取，基线 `1d24bdc`，工作区干净。

## 本阶段目标

- 为后续独立 `/lyrics` 页面提供唯一根歌词同步器，读取真实 LyricsRepository，消费唯一 PlaybackController 位置流。
- 明确时间区间、偏移、重复时间与纯文本语义；点击歌词经根串行播放通道 Seek。
- 验证切歌、隐藏、刷新、晚到读取与关闭时的隔离；不引入第二个播放时钟或生产歌词样本。

## 已读取的来源

- 开发总指令 Phase 7、歌词模型、共享核心及生命周期约束；已审计的完整 App.tsx（NEW_ICON_SPRITE / POLISH_CSS）和基础 HTML。
- 本次重核设计源 5 指纹、44 SVG、52 确定产物；基础 HTML 的 renderFullscreenLyrics / updateLyricsUI 仅作交互参考，标题匹配和自动生成歌词不迁移。
- LyricsDocument、DriftLyricsRepository、PlaybackController、DependencyGraph、现有实际 SQLite 关闭测试与架构门禁。

## 准备修改与新增

- 先追加 ADR-075；新增 `lib/domain/models/lyrics_timeline.dart`、`lib/playback/lyrics_controller.dart`。
- 修改 `lib/playback/playback_controller.dart`（可撤销 Seek、通知重入关闭）和 `lib/app/dependency_graph.dart`（唯一同步器及关闭顺序）。
- 新增时间轴、同步、SQLite 排空测试；更新 Node 架构门禁、README、实施状态与阶段报告。
- 回填前置 Phase 6J2 两组精确云端成功及 PR #63；不把前置结果当本批验收。

## 风险与边界

- Seek 排队期间可能切离又回到同一队列项；需要状态快照身份与活动代次，不能只比曲目 ID。
- 仓储没有中断读取接口：取消是撤销结果与后续工作，已接受读取必须排空后才关数据库。
- 根通知中可能关闭应用；先停止接受工作，ChangeNotifier 等通知栈结束才销毁。
- 本批无 UI/自动滚动/沉浸模式/解析器/Schema/依赖变化；纯文本和双语文档原样保留，无歌词明确空态。
- 新安装仍为空库，导入扫描属 Phase 8；本批不等于完整 Phase 7 或可日常使用的发行版。

## 出口条件

- 时间边界、偏移与溢出、同时间行、纯文本、来源隔离、每位置不重读、旧响应与旧 Seek、读错重试、通知重入及真实 SQLite 排空测试通过。
- 格式、严格分析、完整 Flutter/Node 测试、生成/迁移与源审计通过；112 旧 Golden 不变。
- Android Debug 预检及资产/许可/签名验证；GitHub 精确提交 Android/Windows 构建单独报告。
- 审查无敏感信息、提交、推送并创建以上阶段为 base 的 Draft PR；不修改 main、不合并、不发布。
