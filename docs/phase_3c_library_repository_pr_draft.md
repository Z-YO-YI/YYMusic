# PR 草稿：Drift-backed LibraryRepository

Head：`feat/library-repository-drift`；Base：`feat/database-schema-migrations@8f5b369`。Draft PR [#11](https://github.com/Z-YO-YI/YYMusic/pull/11)；不自动合并、不改写历史。

## 变更

- 新增Track/Album/Artist严格row mapper及Drift-backed `LibraryRepository`全合同。
- 新增确定分页、关联感知watch、TrackRef查询、可用性更新与脱敏DomainFailure。
- upsert使用单事务+batch，维护Track/Artist/Album关联及聚合计数；无中间watch状态。
- `crypto` 3.0.7从已锁定传递包提升为直接依赖，仅为派生artist ID；不修改v1 Schema/快照、不新增原生包或权限。

## 测试

- 9项Repository SQLite测试和1项Domain JSON有限数测试已通过。
- 116文件format零改动、strict analyze 0问题、165项Flutter/32 Golden通过。
- lockfile严格复现；Node29、ZIP24、生成代码/v1快照零差异已通过。
- 实现提交`a155d65`的push 33490505244、PR 33490538057和手动 33491551841均为三job success，Android/Windows Debug均通过。
- 手动运行草稿Release三资产已复核；APK为183604101字节，SHA-256为`ed964e21cbf6e4994c3829b330399d4b30a6ee31f80a8d3d1089b87f6d380be2`，metadata/SHA256SUMS/API digest一致，48份资产匹配且v2单签名有效。

## 影响与未验收项

影响限于data/repositories、Domain JSON输入约束、直接依赖声明、测试与文档。AppBootstrap、DependencyGraph、UI、Shell、播放与v1 Schema不变。

Collection/Lyrics/MusicSource Repository、SecureCredentialGateway实现、Dev Fixture、Controller、真实来源/本地扫描、本机Windows与Android真机均未验收。
