# PR 草稿：Drift-backed LibraryRepository

Head：`feat/library-repository-drift`；Base：`feat/database-schema-migrations@8f5b369`。Draft PR编号待推送后记录；不自动合并、不改写历史。

## 变更

- 新增Track/Album/Artist严格row mapper及Drift-backed `LibraryRepository`全合同。
- 新增确定分页、关联感知watch、TrackRef查询、可用性更新与脱敏DomainFailure。
- upsert使用单事务+batch，维护Track/Artist/Album关联及聚合计数；无中间watch状态。
- `crypto` 3.0.7从已锁定传递包提升为直接依赖，仅为派生artist ID；不修改v1 Schema/快照、不新增原生包或权限。

## 测试

- 9项Repository SQLite测试和1项Domain JSON有限数测试已通过。
- 116文件format零改动、strict analyze 0问题、165项Flutter/32 Golden通过。
- lockfile严格复现；Node29、ZIP24、生成代码/v1快照零差异已通过。GitHub Android/Windows待目标提交后记录。

## 影响与未验收项

影响限于data/repositories、Domain JSON输入约束、直接依赖声明、测试与文档。AppBootstrap、DependencyGraph、UI、Shell、播放与v1 Schema不变。

Collection/Lyrics/MusicSource Repository、SecureCredentialGateway实现、Dev Fixture、Controller、真实来源/本地扫描、本机Windows与Android真机均未验收。
