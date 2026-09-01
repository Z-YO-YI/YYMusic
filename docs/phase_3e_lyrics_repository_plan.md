# Phase 3E 开始 — Drift LyricsRepository

日期：2026-09-01。开始前已fetch并确认`feat/collection-repository-drift@bc49b38`与远端同步、工作树干净；从该提交创建`feat/lyrics-repository-drift`，不在main/master开发。

## 本阶段目标

- 实现Phase3A `LyricsRepository`全部合同：以完整TrackRef读取、保存和幂等删除LyricsDocument。
- 将plain/synchronized、逐行时间、原文/翻译、语言、偏移量严格映射到既有`lyrics_cache`表，不要求catalog Track或MusicSource row存在。
- 使用确定性JSON行格式，读取时拒绝非数组、未知/缺失字段、错误类型、歌词kind/时间不一致、翻译语言不一致和损坏TrackRef。
- SQLite/JSON/row异常只返回无歌词文字、TrackRef、SQL或路径的`DomainFailure(databaseCorrupted)`。

## 不在本批

- 不修改v1 Schema/快照，不新增依赖、原生包、权限或Migration。
- 不解析/生成LRC，不联网搜索歌词，不读取文件或下载/离线音频。
- 不实现MusicSourceRepository、SecureCredentialGateway、Controller、自动跟随/Seek、UI或AppBootstrap接线。

## 出口条件

- 真实内存SQLite覆盖plain/synchronized双语往返、完整TrackRef隔离、upsert、删除、不依赖catalog、损坏JSON/row脱敏与shared/owned生命周期。
- Domain/UI/Shell不导入Drift/SQLite；AppBootstrap不打开DB；生成代码和v1 Schema快照零差异。
- 全量format、strict analyze、Flutter/Node/ZIP门禁通过；独立提交、Draft PR、GitHub Android/Windows Debug与唯一一次手动APK核验均绑定目标实现commit。

结论：上述出口已由实现提交`1e45532`、Draft PR #13、push/PR/手动三条全成功云端运行以及独立APK复核满足。
