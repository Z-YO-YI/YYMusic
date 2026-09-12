# Phase 7F1 开始：当前曲目收藏核心

2026-09-12。仓库Z-YO-YI/YYMusic；fetch/ff-only pull后基线449b1ffde107961ba31b75fc78587f1a5289e356，工作区干净。分支codex/current-track-favorite-core，Stacked Draft base=codex/system-playlist-queue-actions。前置#79双CI仍运行，独立核验，不将pending计成功。

## 目标与来源

按总指令Phase7播放器剩余收藏能力，先实现根级当前曲目收藏投影与真实Repository写入，下一批再接三端按钮。本批不改UI/Golden。已读Phase7与阶段/代码规则、PlaybackController/State、DependencyGraph、CollectionRepository、原收藏读写、Shell/播放器/歌词组件；ZIP/App.tsx（包括NEW_ICON_SPRITE/POLISH_CSS）/基础HTML/总指令四源SHA256复核一致。

## 文件与接口

先记录ADR090。新增lib/playback/playback_favorite_controller.dart及模型/动作分文件、单元和真实SQLite测试、Node门禁；修改DependencyGraph注册/启动/有序关闭、必要的根生命周期断言，更新README/状态/矩阵/报告。无新播放器、Schema、依赖、平台或原设计资产变更。

## 风险与出口

- 收藏依完整TrackRef，当前队列条目ID/根快照与收藏读取代数用于撤销旧动作；重复歌曲不能混淆队列身份，失效引用也可收藏，空队列/未知收藏状态不可操作。
- 构造无I/O，显式启动唯一订阅；切歌/队列替换/读取变化撤销旧快照，位置更新不重读收藏。读取失败/结束/重订阅与晚到事件安全处理。
- 显式目标值而非延迟toggle；同步busy防重复，执行前复核页面许可，接受后的Repository写入关闭仍排空；不乐观伪造成功状态。
- 读/写错误脱敏并保留身份，失败只显式重试/知悉，过期重试不可重新解释为新曲目。取消订阅和写入先于数据库/引擎关闭，覆盖监听器重入。
- 单元、真实SQLite回滚/重试/外部收藏同步、图根关闭回归通过；全量Flutter/Node、格式/严格分析、生成/迁移零漂移、Android预检及资产许可检查后提交/push/Draft PR。GitHub双平台按新SHA另验；不声称按钮/设备出声/日常导入或上线已完成。
