# Phase 7H4B3a：一次性根恢复许可

接口审查补充：许可对象提供非消费式isCurrent，供存储返回missing或失败时判断用户是否已更改意图；不读取时钟、不消费许可。避免为了检查有效性而传入伪造快照。调用仍保持action(snapshot)语法。

基线ff55750；先实现captureSleepRestore返回的一次性许可，再接异步存储协调。许可只能在根未关闭且睡眠off时取得，捕获现有sleep generation；执行前/依赖调用后检查同一generation与off，用户新设、显式取消（即使仍off）、关闭或另一恢复都会撤销旧许可。

输入为B1验证快照，按原deadline减根注入UTC时钟求剩余，过期返回expired且不暂停/重设。可恢复时保留原duration与deadline，复用唯一根one-shot调度，不调用setSleepTimer重新计时或任何播放命令。结果区分restored/expired/superseded/unavailable/failed，供后续协调器决定反馈与清理，B3a不读写存储。

时钟、调度器与通知监听器可能重入，必须复核许可。调度返回的Timer若已被更新意图淘汰，应立即cancel且不得覆盖新根Timer。捕获/执行均不创建播放器或新队列；业务到期仍由原_sleepWoke负责。测试覆盖原截止/选中项、过期边界、旧许可/重复许可、关闭/用户操作、失败/不可用、时钟及调度/通知重入、到期真实暂停与无自动播放。

后续B3b再接存储读写、失败反馈、AppDataServices及初始化/关闭；本阶段不改session-only提示，不声明应用重启恢复已可用。
