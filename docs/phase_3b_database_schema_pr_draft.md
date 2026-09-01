# PR 草稿：Drift schema and initial migration

Head：`feat/database-schema-migrations`；Base：`feat/domain-model-contracts@9ebee65`。Draft PR [#10](https://github.com/Z-YO-YI/YYMusic/pull/10)；不自动合并、不改写历史。

## 变更

- 新增Drift/SQLite3 Android+Windows数据层：17表、10索引、复合身份、外键/唯一/检查约束和v1创建Migration。
- 新增迁移审计、空队列状态、官方v1 Schema快照及后台应用支持目录打开函数；AppBootstrap不接线。
- 新增8项真实SQLite测试与CI生成零差异门禁；不实现正式Repository/Controller/UI、安全存储或生产Fixture。
- 依赖使用当前稳定drift/sqlite3/path_provider/build_runner/drift_dev，不引入sqlite3_flutter_libs/sqflite，不新增权限。

## 测试

- 定向8项数据库测试已通过；官方Schema自验证、外键/级联/约束、来源删除引用保留、敏感列和后台文件均覆盖。
- g.dart/v1 JSON二次生成SHA不变；lockfile、113文件format、strict analyze、155项Flutter/32 Golden、29项Node和ZIP24项全部通过。
- 实现提交`31121d4`的push 33484750785、PR 33484779370和手动 33485752421均为三job success，Android/Windows Debug均通过。
- 手动运行草稿Release三资产已复核；APK为183603621字节，SHA-256为`3bdd3a74f8344df0c5124ffe25eee8c01d0d8985639ed91ff9084dac67defc69`，metadata/SHA256SUMS/API digest一致，48份资产匹配且v2单签名有效。

## 影响与未验收项

影响限于data/database、依赖/锁文件、生成/迁移工具、测试、CI和文档。Phase2 UI、Phase3A Domain/Repository合同和播放骨架行为不变。

正式Repository/row映射、批量事务、v2+保数据迁移、安全存储、Controller、真实用户数据和本机Windows/Android真机均未验收。
