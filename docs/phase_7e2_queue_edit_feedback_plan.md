# Phase 7E2 — 根队列编辑反馈与可重试失败

2026-09-09；已核对远程/worktree并fetch/pull最新，独立分支`codex/queue-edit-feedback`，基线3d89cc8，Draft PR base=`codex/queue-edit-intents`。前置E1双组CI在运行，无已知失败，单独跟进。

目标：在现有根QueueController中加入提交结果、共享busy、跨页面保留的安全失败、显式同快照重试和按失败身份知悉；不创建第二份队列。重复提交返回busy，旧快照/离页返回取消。失败后的其他成功操作不能抹掉未处理失败；新队列使旧失败不可重试，不把旧确认自动重定向到新内容。注册待处理Future先于通知或依赖调用，根关闭排空失败处理后再释放资源。

已读来源：主指令20/Phase7/38–39、HTML renderQueue交互及既有审计、App.tsx完整图标/POLISH_CSS的源审计10项和24ZIP复核、QueueEdit/串行编辑核心、根依赖图及系统歌单写入反馈模式。本批仅状态接口，不修改Figma/UI或使用设计生成技能。

修改：QueueController及DependencyGraph关闭屏障，架构决策/README/状态/矩阵；新增结果/失败模型、反馈实现part、单元/实际SQLite测试、Node门禁。既有edit/程序化API保持兼容，无Schema/依赖/原生/Golden变化。

风险：busy通知重入关闭、成功通知再次提交、旧失败重试/知悉、停止后失败、SQL期间卸载、恢复失败覆盖、关闭时未观察异步错误。错误只保留固定DomainFailure，不储存私有异常。出口为完整格式/严格分析/Flutter/Node/生成/迁移/Android预检通过，审查提交push/Draft PR并核对精确云端状态；下一阶段独立队列视图及编辑UI，不把本批接口称为页面完成。
