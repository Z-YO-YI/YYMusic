# Phase 3D — Drift CollectionRepository 报告

2026-09-01。开始前已fetch并确认`feat/library-repository-drift@0fd7c0f`与远端同步、工作树干净；从该提交创建`feat/collection-repository-drift`，未在main/master开发。范围与出口见[计划](phase_3d_collection_repository_plan.md)。

## 当前实际进度

本批实现第二个正式数据Repository：Playlist/Entry、Favorite、History和Queue的严格row映射及`CollectionRepository`全合同。AppBootstrap/DependencyGraph仍未构造它，启动应用不会打开数据库、生成系统歌单或写入Fixture。Lyrics/MusicSource正式Repository、安全存储、Dev Fixture和Controller仍待后续小批次。

## 歌单、收藏与历史

1. Playlist返回前重走Domain构造，系统歌单按favorites/recent/queue固定在前，自定义歌单按updatedAt/名称/ID确定排序并返回不可变List。
2. 同一系统歌单类型只能有一个，已存歌单不能在system/custom间转换；删除系统歌单返回脱敏`forbidden`。删除自定义歌单只级联entries，不删除Track或来源。
3. 歌单条目在写入前验证playlistId、唯一entryId与0起始连续position；整体替换使用单事务+batch，不存在歌单返回`notFound`。
4. Favorite以完整TrackRef主键保存，重复收藏幂等更新addedAt并移顶；跨source type/sourceId的同trackId不冲突。
5. History记录前删除同TrackRef的旧项，再按startedAt/ID排序裁剪到20条，实现重复曲目移顶与清空；未存在catalog的稳定引用仍保留。

## 队列、事务与安全

`saveQueue`在一个事务中清空currentEntryId、替换queue_entries、再写回current/updated单行状态。自定义watch query显式声明queue_state与queue_entries两张表，事务提交后只发布一份完整快照。QueueEntry ID独立于TrackRef，同一曲目可重复入队。

所有row枚举、UTC milliseconds、位置和引用在返回前重走Domain验证。损坏row或SQLite异常不包含原始SQL、用户文字或TrackRef，只返回日志安全`databaseCorrupted`。默认Repository不关闭共享`AppDatabase`；只有`.owned`在幂等dispose时关闭。

## 本地验证

| 检查 | 当前结果 |
| --- | --- |
| Collection定向 | 10项真实内存SQLite通过：歌单/系统保护、混合来源entries、输入校验、歌单/队列回滚、单次队列流、收藏、历史20条、损坏row与生命周期 |
| 架构边界 | Node定向通过：只有data导入Drift，实现只覆盖Collection合同，AppBootstrap不打开DB，v1表集不变 |
| 全量门禁 | lockfile严格复现；119文件format零改动、严格分析0问题；175项Flutter含32 Golden、29项Node、ZIP24项全部通过；代码生成/make-migrations后v1 g.dart/快照零差异 |

## 云端与限制

实现提交、Draft PR、push/PR/手动运行、Windows/Android Debug和本批APK尚待目标commit创建后独立核验；不沿用Phase3C APK冒充。本机Windows C++/Developer Mode仍受远程/UAC限制，不声称本机Windows构建或安装成功。

## 主要文件

- `lib/data/repositories/collection_row_mapper.dart`
- `lib/data/repositories/drift_collection_repository.dart`
- `test/unit/drift_collection_repository_test.dart`
- 架构边界、ADR、依赖、状态与验证文档

下一批应以LyricsRepository的小型row映射/缓存合同继续，再单独处理MusicSourceRepository与SecureCredentialGateway；不与Controller、UI或音频混成一次提交。
