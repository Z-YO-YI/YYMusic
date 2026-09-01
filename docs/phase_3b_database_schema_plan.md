# Phase 3B 开始 — Drift Schema 与首版 Migration

日期：2026-09-01。开始前已fetch并确认`feat/domain-model-contracts@9ebee65`与远端0/0同步、工作树干净；从该提交创建`feat/database-schema-migrations`，不在main/master开发。

## 本阶段目标

- 按主指令第29节建立`tracks`、`albums`、`artists`、两个关联表、歌单/收藏/历史/队列、来源、本地目录、歌词缓存、搜索历史、设置和迁移审计表；另用单行`queue_state`保存空队列也需要的current/updated状态。
- 提供schemaVersion 1的显式`onCreate` Migration、外键开启、迁移审计记录和可提交的Schema快照；用内存SQLite验证创建、约束、索引、删除语义和无明文凭据列。
- 提供Android/Windows共用的后台原生数据库打开函数，但不在AppBootstrap/DependencyGraph调用；测试可直接注入内存executor。

## 官方资料与依赖边界

- 采用Drift 2.34.x与SQLite3 3.5.x当前兼容稳定线；Drift官方说明2.32起原生Android/Windows不再需要`sqlite3_flutter_libs`，SQLite由build hooks打包。
- 生产文件放`getApplicationSupportDirectory()/YYMusic/yymusic.sqlite`，后台isolate执行；路径创建和打开只在调用显式构造函数时发生。
- Drift table/row、QueryExecutor、File和path_provider只允许出现在data层；Domain、UI、Shell和Controller不导入它们。

## 数据与安全不变量

- Track稳定身份由`sourceType/sourceId/trackId`组成；歌单、收藏、历史和队列保存该引用，队列entryId独立并允许重复曲目。
- 用户集合引用不会因来源删除而级联消失；来源/本地歌曲应通过availability变为不可用。歌单自身删除可级联其entries。
- `music_sources`只保存`credential_ref`和公开JSON；没有API Key、Token、Password、Authorization或敏感Header列。JSON存储先保持不透明文本，正式Repository批次负责Domain编解码和再次验证。
- 时间统一存UTC epoch milliseconds；Duration存非负milliseconds。位置使用非负检查与唯一约束。

## 不在本批

- 不实现Library/Collection/Lyrics/MusicSource正式Repository，不接SecureCredentialGateway，不写Dev歌曲/在线来源成功Fixture。
- 不接Controller、UI、搜索、扫描、播放或网络；不创建下载/离线能力，不增加平台权限。
- 不做v1→v2虚构迁移；本批测试首装`onCreate`，未来每次Schema变更必须新增真实版本、迁移步骤、旧Schema快照和保数据测试。

## 出口条件

- 16张业务/状态表及迁移审计存在，主键、唯一/检查/级联约束和必要索引有内存数据库测试；schema_migrations记录v1。
- 生成代码与schema快照可重复，未提交数据库文件或构建缓存；Domain/UI数据库依赖门禁通过。
- 全量format、strict analyze、Flutter/Node/ZIP门禁通过；Android与Windows GitHub Debug均能解析build hooks并构建。
- 独立提交、Draft PR、手动APK Release与下载后校验按完整commit完成。
