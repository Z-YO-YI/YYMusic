# Phase 7E5A — 添加/下一首的可靠根编辑

2026-09-12；基线 `8d9b4da7c838a0f222014f66b029a69b22fbc9be`，fetch/pull 已最新且工作区干净；独立分支 `codex/queue-insert-intents`，Stacked Draft PR base=`codex/queue-drag-sorting`。前置 E4 两组常规 CI 仍在运行，独立跟进。

主指令20与Phase7要求添加末尾、下一首与共享队列；当前低层 add/insertNext 不带页面身份许可或根失败反馈，随机重建还可能破坏显式下一首。先扩展既有 QueueEdit，再在后续 E5B 接页面菜单；不一次生成所有入口，不伪称本批已交付按钮。

实现：QueueEdit.addToEnd/playNext 捕获不可变根及新 QueueEntry，拒绝重复 entry ID、允许重复完整 TrackRef，归一化位置、保留 addedAt/current。复用根 submitEdit 的 busy、失败、同请求显式重试与关闭排空。已接受插入不启动/停止/重载音频；空队列不自动播放。

随机：插入只扩展既有随机顺序，不重排已存在条目；显式下一首移到当前随机游标之后，连续下一首按最近指定优先，后续末尾添加不抹掉优先项。仅成功 SQL 后更新该根运行时顺序，不新增播放器/持久化表；跨启动恢复物理队列，随机顺序本身维持既有非持久化边界。兼容现有低层 add/playNext 同一行为，单曲循环的自动重播不改变。

文件：纯 Domain QueueEdit、根 queue_editing/PlaybackController、单元与真实 SQLite 测试、Node 门禁、README/ADR/计划/报告/矩阵/状态。无 UI、Golden、依赖、Schema、平台/原始资产改动。本地完整测试/生成/格式/分析/Android预检，GitHub精确提交双平台构建；保留本批独立验证，先处理失败CI。不合并/Release/付费/手动媒体诊断。

后续核验：E4 两组精确 `8d9b4da` 的 CI 均 SUCCESS，Windows161 Golden/2Runner/65文件包与Android资产/许可/签名通过，已回填PR#74；本批云端按新提交独立验证。
