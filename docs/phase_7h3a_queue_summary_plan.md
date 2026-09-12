# Phase 7H3A：侧栏队列摘要投影

2026-09-13，基线d3e26cb，已fetch/ff-only pull且工作区干净，独立分支codex/inspector-queue-summary，Draft base codex/inspector-sleep-settings。前置CI仍进行中，无已知失败。先ADR105，再共享API与测试。

新增根只读PlaybackQueueSummary，保留准确QueueEntry身份和1起始列表序号，总数与当前缺失状态。PlaybackPresenter按QueueSnapshot身份缓存，不因音频位置通知反复遍历列表。不加载其他曲目元数据、不创建第二队列、不预测随机顺序、不做界面变更。

验证空队列、无当前项、首/中/末项、相同引用重复条目、原快照不可变、替换/重排/清空后的更新、位置通知缓存稳定和零音频副作用。完整Flutter/Node/格式/分析/生成迁移及Android预检通过后提交推送Draft；H3B继续原设计摘要/入口UI和视觉验收，不能把本批称为侧栏已完成。
