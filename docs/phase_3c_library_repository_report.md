# Phase 3C — Database↔Domain 映射与 LibraryRepository 报告

2026-09-01。开始前已fetch并确认`feat/database-schema-migrations@8f5b369`与远端0/0同步、工作树干净；从该提交创建`feat/library-repository-drift`，未在main/master开发。范围与出口见[计划](phase_3c_library_repository_plan.md)。

## 当前实际进度

本批实现首个正式数据Repository：Track/Album/Artist row映射及`LibraryRepository`全合同。AppBootstrap/DependencyGraph仍未构造它，因此启动应用不会打开数据库或生成曲库。Collection/Lyrics/MusicSource正式Repository、安全存储、Dev Fixture和Controller仍待后续小批次。

## 映射、查询与事务

1. `LibraryRowMapper`严格映射来源类型、可用性、Duration milliseconds、UTC epoch milliseconds、HTTP/content URI与递归JSON metadata；损坏row只返回脱敏`databaseCorrupted`。
2. `Track`尚无来源artist ID，因此以`sourceId + NUL + 精确艺术家名`的SHA-256作为可复现内部ID。`crypto` 3.0.7从已锁定的传递依赖提升为直接纯Dart依赖，没有更换版本或新增原生库。
3. upsert先拒绝重复TrackRef/艺术家与冲突Album，再在一个Drift事务中以batch更新tracks/artists/albums/关联。任一SQL失败整批回滚，watch不暴露中间表状态。
4. Album艺术家顺序由首个TrackRef/曲目内position确定，track/album count在同一事务重算；失去所有引用的派生Album/Artist被清理。
5. Track/Album/Artist分页先固定标题/来源/ID排序，再用`limit + 1`/offset计算`hasMore`。Track watch的join显式依赖tracks、track_artists和artists，艺术家关联变更不会漏通知。

## 生命周期与安全边界

`initialize`验证`user_version`、`PRAGMA quick_check`与foreign keys，但不导入只属开发测试的`drift_dev` API。默认Repository不关闭未来可由多Repository共享的`AppDatabase`；只有`.owned`构造才在幂等dispose时关闭。未初始化或已dispose后调用明确失败。

数据库/SQLite/crypto只在data层；Domain、UI、Shell和AppBootstrap不导入row、SQL或新Repository实现。本批没有HTTP、文件扫描、凭据、下载/离线、权限或用户数据Fixture。

## 本地验证

| 检查 | 当前结果 |
| --- | --- |
| Repository定向 | 9项真实内存SQLite通过：双向映射、分页/身份、单次流快照、回滚/脱敏、聚合/替换、可用性、损坏row、歧义输入与生命周期 |
| Domain增量 | 1项通过：非有限double在进入JSON存储前拒绝 |
| 架构边界 | Node定向通过：只有data导入Drift，生产代码无drift_dev，AppBootstrap不打开DB，v1表集不变 |
| 全量门禁 | lockfile严格复现；116文件format零改动、严格分析0问题；165项Flutter含32 Golden、29项Node、ZIP24项全部通过；代码生成/make-migrations后v1 g.dart/快照零差异 |

## 云端与限制

实现提交`a155d6518ea1c20f3bd3b4bfb33f98f362a898ff`已推送。push运行[33490505244](https://github.com/Z-YO-YI/YYMusic/actions/runs/33490505244)、Draft PR [#11](https://github.com/Z-YO-YI/YYMusic/pull/11)运行[33490538057](https://github.com/Z-YO-YI/YYMusic/actions/runs/33490538057)和唯一一次手动运行[33491551841](https://github.com/Z-YO-YI/YYMusic/actions/runs/33491551841)均为三job success：Ubuntu源码/生成/测试门禁、Windows2025 Debug+宿主Golden与Android Debug+验签/资产核验全部通过。

手动运行创建了标签字段`ci-debug-33491551841-1`的[私有草稿/prerelease](https://github.com/Z-YO-YI/YYMusic/releases/tag/untagged-9c1e5657ad5924a2461c)，target_commitish精确等于实现提交，且只有`build-metadata.json`、`SHA256SUMS`和`YYMusic-debug.apk`三资产。下载后独立复核APK为183604101字节，metadata、SHA256SUMS、本地计算与API digest均为`ed964e21cbf6e4994c3829b330399d4b30a6ee31f80a8d3d1089b87f6d380be2`；48份打包SVG/字体/许可逐字节匹配，apksigner显示v2单签名有效，v1/v3/v3.1/v4为false。临时下载副本已安全删除，草稿Release保留可恢复。

本机Windows C++/Developer Mode仍受远程/UAC限制，不声称本机Windows构建或安装成功。

## 主要文件

- `lib/data/repositories/library_row_mapper.dart`
- `lib/data/repositories/drift_library_repository.dart`
- `test/unit/drift_library_repository_test.dart`
- `lib/domain/models/domain_validation.dart`
- `pubspec.yaml` / `pubspec.lock`
- 架构边界、ADR、依赖、状态与验证文档

下一批应从CollectionRepository的Playlist/Favorite/History/Queue事务小批次继续；不与Source/安全存储、Dev Fixture、Controller、UI或音频混成一次提交。

Draft PR：[#11](https://github.com/Z-YO-YI/YYMusic/pull/11)，保持待审核，不自动合并。
