# Phase 3C 开始 — Database↔Domain 映射与 LibraryRepository

日期：2026-09-01。开始前已fetch并确认`feat/database-schema-migrations@8f5b369`与远端0/0同步、工作树干净；从该提交创建`feat/library-repository-drift`，不在main/master开发。

## 本阶段目标

- 实现Track/Album/Artist与Phase3B Drift row的双向映射，包括稳定TrackRef、UTC epoch milliseconds、Duration、URI、可用性与严格JSON metadata。
- 实现Phase3A `LibraryRepository`的initialize/watch/list/get/upsert/setAvailability/dispose合同，只暴露Domain类型。
- 使用单个SQLite事务和batch完成Track、Artist、Album及关联写入；分页使用确定排序和`limit + 1`，watch在事务提交后只观察一致快照。
- 对数据库中的损坏JSON/枚举/URI/关联转换为不泄露原始数据的`DomainFailure(databaseCorrupted)`，缺失TrackRef使用`notFound`。

## 官方资料与实现约束

- [Drift transactions](https://drift.simonbinder.eu/dart_api/transactions/)：事务内数据只在提交后通知外部watch，回滚时不暴露中间状态。
- [Drift writes](https://drift.simonbinder.eu/dart_api/writes/)：多行写入使用batch与conflict update，不用循环伪装原子性。
- [Drift streams](https://drift.simonbinder.eu/dart_api/streams/)：watch query必须显式依赖tracks、track_artists与artists，避免只监听主表而漏掉关联变更。
- [Drift selects](https://drift.simonbinder.eu/dart_api/selects/)：分页使用limit/offset且在应用limit前固定标题/来源/ID排序。

`Track`当前只提供艺术家显示名，没有来源artist ID。本批用“sourceId范围 + 精确UTF-8名称SHA-256”生成可复现的内部artist ID，不用随机/时间ID；未来来源适配器要保留真实artist ID时，必须先单独升级Domain合同。

## 数据与安全不变量

- 同一批次禁止重复TrackRef、重复艺术家名和冲突的Album标题；入参在事务前失败，不部分写入。
- upsert替换指定Track的艺术家关联，重建确定的Album艺术家顺序并重算track/album count；无引用的派生Album/Artist不保留为假目录。
- metadata只接受有限JSON值；不记录原始SQL异常、本地路径、URI、metadata或用户文字到DomainFailure。
- Repository不自动打开网络、扫描文件、读取凭据或创建Fixture；默认不拥有共享`AppDatabase`，只有显式owned构造才在dispose关闭数据库。

## 不在本批

- 不实现Collection/Lyrics/MusicSource Repository、SecureCredentialGateway、Dev Fixture或Controller；它们保持Phase3后续独立批次。
- 不修改v1 Schema/快照，不伪造v2 Migration；如现有表无法完成合同，必须停止并单独设计保数据迁移。
- 不接AppBootstrap/DependencyGraph/UI，不生成演示曲库，不接播放、下载/离线、网络、文件扫描或平台权限。

## 出口条件

- 真实内存SQLite测试覆盖双向映射、跨来源身份、确定分页、事务回滚、单次提交流、聚合计数、关联替换、可用性和损坏数据脱敏。
- Domain/UI/Shell不导入Drift/SQLite；v1生成代码和Schema快照零差异，不产生数据库文件或敏感信息。
- 全量format、strict analyze、Flutter/Node/ZIP门禁通过；独立提交、Draft PR、GitHub Android/Windows Debug与手动APK核验均绑定目标实现commit。

结论：上述出口已由实现提交`a155d65`、Draft PR #11、push/PR/手动三条全成功云端运行以及独立APK复核满足。
