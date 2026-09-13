# Phase 7H4B1：恢复快照与存储契约

2026-09-13；基线a4ca54e4db9f7ca4e449b17f621b4db7dab962c4，fetch/pull --ff-only核实最新且干净，分支codex/sleep-restore-snapshot，Draft base codex/sleep-countdown-panel。先审计既有存储/关闭顺序并写[计划](phase_7h4b1_snapshot_plan.md)/ADR110，再实现纯快照和测试。

SleepTimerSnapshot位于domain，只接受原15/30/60分钟、统一UTC绝对deadline；remainingAt显式接收时钟，到期及其后返回null，时钟回拨可以增加剩余量而不改原选项/截止。值相等包含精确截止，toString脱敏。没有Flutter、播放器或隐式系统时钟依赖。

SleepTimerSnapshotCodec位于data，固定version=1，限定512字符和三个字段。拒绝未知版本/类型、额外字段、非法日期、非规范UTC；保留微秒精度。FormatException使用固定安全消息，无原文source，不执行存储、清理或播放动作。过期但合法记录可以解析，避免把过期与格式损坏混为一谈。

SleepTimerRepository定义read/save/clear/dispose契约：按接受顺序串行，专用设置原子写入，旧保存不得在clear后复活，读取失败不伪装missing，关闭拒绝新工作并真实排空且不关闭借用数据库。**本批仅接口，没有实际适配器，也未接入根恢复。** 本曲结束依赖会话entryId，不纳入分钟快照，不宣称它已跨启动恢复。session-only文案未变。

29新单测及1新Node检查。完整2018 Flutter通过（113秒），155 Node最终通过（15.7秒），551 Dart格式零修改，严格分析0问题（13.8秒），214原Golden不变。初次Node正则未转义点号，将DateTime now参数误判为DateTime.now调用；修正字面点号与调用边界后全量重跑通过，未改应用行为来迎合检查。

四份设计原文件SHA256一致、24ZIP条目逐字节一致，App.tsx NEW_ICON_SPRITE/POLISH_CSS沿用已完成审计，无UI/资产修改。不涉及schema/代码生成输入，本批未重跑codegen/Drift，A2b记录继续有效。

Android Debug41.4秒，48打包资产/音频许可/v2单签名者通过；APK232270343 bytes，SHA256 `866e1582dbd4d3fa8050902d0d64267b3d01e2dc4421faff6ec707c4c6fac8a5`，与A2b相同（快照未被生产入口引用）。保留Java native-access警告，不提交APK。没有新的实机安装/出声或本地Windows编译验收。父运行34731476534/34731489397核验时仍in_progress，不冒称成功；本提交云端另验。

主要文件：sleep_timer_snapshot.dart、sleep_timer_snapshot_codec.dart、sleep_timer_repository.dart、单测/Node、ADR/README/状态/矩阵/计划。B2接真实存储并验证顺序/失败/关闭，B3接根恢复与用户操作竞争；H4C淡出及其余Phase7–11验收仍待完成，不自动合并或发布。
