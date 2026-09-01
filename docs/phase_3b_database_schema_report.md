# Phase 3B — Drift Schema 与首版 Migration 报告

2026-09-01。开始前已fetch并确认`feat/domain-model-contracts@9ebee65`与远端0/0同步、工作树干净；从该提交创建`feat/database-schema-migrations`，未在main/master开发。范围与出口见[计划](phase_3b_database_schema_plan.md)。

## 当前实际进度

本批只实现数据库Schema、首版创建Migration、版本快照和打开边界。Library/Collection/Lyrics/MusicSource正式Repository、Domain row映射、安全存储、Dev Fixture、Controller和UI接线均未开始；应用启动不会创建数据库。

## Schema 与安全边界

1. 主指令15张建议表全部存在；另加单行`queue_state`和`schema_migrations`，合计17表、10个显式查询索引。
2. tracks以sourceType/sourceId/trackId为复合主键；queue_entries使用独立entryId和唯一position，同一TrackRef可重复。用户集合引用不外键到来源/track，来源删除不丢收藏/歌单/历史/队列。
3. catalog关联表与playlist_entries使用外键级联；Track/Queue/Playlist/Lyrics/LocalFolder/MusicSource关键数值和类型使用CHECK/UNIQUE约束，beforeOpen开启foreign_keys。
4. schemaVersion1的onCreate创建全部表，记录UTC迁移审计并插入空队列状态。v1 JSON由官方make-migrations生成；未来不得覆盖，必须升版本并保数据迁移。
5. music_sources只有credential_ref和公开JSON列，没有Authorization/API Key/Token/Password列；敏感内容仍必须由后续Repository通过Phase3A Domain校验并交SecureCredentialGateway。

## 依赖与双平台

采用drift2.34.3、sqlite3 3.5.2、path/path_provider1.9.1/2.1.6、drift_dev2.34.5和build_runner2.16.0。当前官方Drift/SQLite使用build hooks给Android/Windows打包SQLite，不增加sqlite3_flutter_libs、sqflite、SQLCipher或平台权限。

`openDefaultDatabase`仅在显式调用时创建`Application Support/YYMusic/yymusic.sqlite`，并用NativeDatabase后台isolate打开；测试注入临时目录。本机pub get提示Windows插件开发者模式的symlink要求，但解析/锁文件、生成、分析和数据库测试可运行；不把它冒充本机Windows构建，最终原生插件链接由GitHub Windows验证。

## 本地验证结果

| 检查 | 当前结果 |
| --- | --- |
| 数据库定向测试 | 8项通过：精确表/索引、user_version/审计/队列状态、官方Schema验证、CHECK/UNIQUE、外键级联、来源删除引用保留、敏感列、后台文件 |
| 生成复现 | g.dart SHA-256 `42355394719cb7f77a9082c212a030a9564ef4ba5830316b5e8648326b9e9694`；v1 JSON `ac5e1081f89f20f79f06b08331f5f1f522db0bcf0cd6fd20e5b6ecd19290f653`；二次build_runner/make-migrations后不变 |
| 首次测试修正 | 6/7时发现SQLite CHECK对NULL视为通过；system playlist约束补显式IS NOT NULL后8/8通过。测试前关闭内存实例，后台文件测试无多实例警告 |
| 快照纪律 | 初次v1快照后补catalog复合外键，make-migrations拒绝同版本静默覆盖；因尚未提交且仍属首版，删除该生成快照后以最终DDL重建。提交后禁止此做法 |
| 全量门禁 | lockfile严格复现；113文件format零改动、严格分析0问题；155项Flutter含32 Golden、29项Node、ZIP24项全部通过 |

## 云端与限制

实现提交`31121d4af12f6164ad16ad89164bae7e3ad5b2e2`已推送。push运行[33484750785](https://github.com/Z-YO-YI/YYMusic/actions/runs/33484750785)、Draft PR #10运行[33484779370](https://github.com/Z-YO-YI/YYMusic/actions/runs/33484779370)和手动运行[33485752421](https://github.com/Z-YO-YI/YYMusic/actions/runs/33485752421)均为三job success：Ubuntu源码/生成/测试门禁、Windows2025 Debug+宿主Golden与Android Debug+验签/资产核验全部通过。

手动运行创建了标签字段`ci-debug-33485752421-1`的[私有草稿/prerelease](https://github.com/Z-YO-YI/YYMusic/releases/tag/untagged-fede995dd640f1fdc4f6)，target_commitish精确等于实现提交，且只有`build-metadata.json`、`SHA256SUMS`和`YYMusic-debug.apk`三资产。下载后独立复核APK为183603621字节，metadata、SHA256SUMS、本地计算与API digest均为`3bdd3a74f8344df0c5124ffe25eee8c01d0d8985639ed91ff9084dac67defc69`；48份打包SVG/字体/许可逐字节匹配，apksigner显示v2单签名有效，v1/v3/v3.1/v4为false。临时下载副本已安全删除，草稿Release保留可恢复。

本机Windows C++/Developer Mode仍无法远程确认，不声称本机构建或安装成功。

SQLite Schema存在不代表正式Repository或用户数据持久化已完成。公开Header JSON的内容校验仍需后续Repository执行；本批测试只证明Schema无敏感专用列和应用层边界未越过。

## 主要文件

- `lib/data/database/tables.dart`
- `lib/data/database/app_database.dart`及生成`app_database.g.dart`
- `lib/data/database/database_connection.dart`
- `drift_schemas/yymusic/drift_schema_v1.json`
- `test/unit/database_schema_test.dart`
- `build.yaml`、`pubspec.yaml`、`pubspec.lock`
- CI代码生成零差异门禁、ADR、依赖、架构、矩阵和状态文档

下一批应实现Database↔Domain映射和首个正式LibraryRepository小批次，先覆盖事务/分页/流/不可用引用；不得一次接完Collection/Source/Controller/UI或音频。

Draft PR：[#10](https://github.com/Z-YO-YI/YYMusic/pull/10)，保持待审核，不自动合并。
