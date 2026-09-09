# Phase 7E1 — 队列编辑意图与根串行写入

2026-09-09；已核对仓库、工作区、fetch/pull最新，独立分支`codex/queue-edit-intents`，基线dff7c32，Draft PR base=`codex/fullscreen-page-lifecycle`。前置D2两组CI运行中，无已知失败，按精确SHA继续核对。

目标：为后续独立队列页提供不可变、绑定根快照的移除/清空/锚点排序意图。统一走既有PlaybackController串行队列；旧快照、离页或已释放Facade不能改新队列，已接受SQL必须排空。重复曲目按queue entry ID处理，完整TrackRef保留。非当前项编辑不重载/停止音乐；编辑失败不伪装播放失败。移除当前项沿用停止并选择相邻项但不擅自播放的既有策略。

已读：主指令20/Phase7/38–39，HTML renderQueue上移/下移/移除/清空及原审计，App.tsx图标/全部POLISH_CSS的确定性源审计10项和ZIP24条目复核，QueueController/PlaybackController/QueueSnapshot/CollectionRepository及Fake/实际SQLite测试基础。仅Domain/播放核心，不改视觉，不调用Figma或新增技能要求的设计动作。

修改：PlaybackController增加受保护编辑入口，QueueController转发并撤销已释放的待执行请求，架构决策/README/状态/测试矩阵。新增QueueEdit纯模型、queue_editing part、模型/核心/真实SQLite测试及Node门禁。不改Schema、依赖、原生平台或页面；旧程序化队列API保持兼容。

风险：索引过期与同ID快照替换、当前项变化、SQL失败回滚、停止已接受但界面随后离开、写入期间关闭、重入监听。请求开始执行前及停止后再次检查授权；进入SQL后不因离页回滚，成功后应用已保存快照；停止后保存失败不自动重启音频，保留旧队列并返回安全失败。

出口：模型/串行/关闭与真实SQLite事务回归、全量Flutter/Node/严格分析/格式/生成/迁移/指纹/Android预检通过；无旧Golden差异，审查后提交push并维护Draft PR。GitHub双平台按新SHA验证，不能把核心接口称为队列管理UI完成；下一批接根编辑反馈和独立队列界面。
