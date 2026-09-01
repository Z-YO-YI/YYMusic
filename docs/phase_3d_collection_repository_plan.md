# Phase 3D 开始 — Drift CollectionRepository

日期：2026-09-01。开始前已fetch并确认`feat/library-repository-drift@0fd7c0f`与远端同步、工作树干净；从该提交创建`feat/collection-repository-drift`，不在main/master开发。

## 本阶段目标

- 实现Phase3A `CollectionRepository`的全部合同：Playlist、PlaylistEntry、FavoriteEntry、PlayHistoryEntry与QueueSnapshot只暴露Domain类型。
- 自定义歌单可保存/重命名/删除，删除歌单只级联条目；系统歌单的身份不可更改且不可删除，同一系统类型不得重复。
- 歌单条目与队列在单个Drift事务中整体替换；队列entryId独立于TrackRef，允许同一曲目重复并保存currentEntryId。
- 收藏以稳定TrackRef幂等更新；最近播放按TrackRef去重移顶并只保留最新20条，支持清空。

## 事务、排序与安全不变量

- `replacePlaylistEntries`在写入前拒绝其他playlistId、重复entryId或非0起始连续position；不存在歌单返回脱敏`notFound`。
- `saveQueue`先清除旧current引用，再在同一事务替换entries并更新单行queue_state；watch显式依赖两张表，只在提交后观察一致快照。
- Playlist、Favorite、History与watch结果全部使用确定排序和不可变List；来源ID相同但source type/sourceId不同的TrackRef不冲突。
- 来源被删除或曲目不可用不级联删除歌单/收藏/历史/队列引用；Repository不要求目标Track已存在catalog。
- 损坏枚举、时间、队列/条目位置和SQLite异常统一转换为无原始数据的`DomainFailure(databaseCorrupted)`；系统歌单保护使用`forbidden`。

## 不在本批

- 不修改v1 Schema/快照，不伪造v2 Migration。
- 不实现Lyrics/MusicSource Repository、SecureCredentialGateway、Dev Fixture、Controller或AppBootstrap接线。
- 不实现队列随机/循环/下一首算法，不开始音频、网络、下载/离线、文件扫描、权限或UI开发。

## 出口条件

- 真实内存SQLite覆盖歌单/条目、系统保护、收藏、历史去重20条、重复队列、单次提交watch、事务回滚、损坏row脱敏和shared/owned生命周期。
- Domain/UI/Shell不导入Drift/SQLite；AppBootstrap不打开DB；v1生成代码和Schema快照零差异，不产生数据库文件或敏感信息。
- 全量format、strict analyze、Flutter/Node/ZIP门禁通过；独立提交、Draft PR、GitHub Android/Windows Debug与手动APK核验均绑定目标实现commit。

结论：上述出口已由实现提交`9468c2a`、Draft PR #12、push/PR/手动三条全成功云端运行以及独立APK复核满足。
