# Phase 3F 开始 — Drift MusicSourceRepository

日期：2026-09-01。开始前已fetch并确认`feat/lyrics-repository-drift@607267b`与远端同步、工作树干净；从该提交创建`feat/music-source-repository-drift`，不在main/master开发。

## 本阶段目标

- 实现Phase3A `MusicSourceRepository`全部合同：确定watch、按ID读取、upsert与幂等删除公开来源配置。
- 将type/baseUrl/authType/credentialRef、公开Header、endpoint、字段映射、启用/连接状态、延迟、测试时间和错误分类严格映射到既有`music_sources`表。
- 三类Map使用按key排序的确定性JSON；读取时拒绝非对象、非字符串值、敏感Header、可执行映射、无效URL/枚举/时间。
- 稳定sourceId已经存在后不得改变sourceType或builtIn身份；内置来源不可删除。删除自定义来源不得级联抹除收藏、歌单、历史、队列或歌词TrackRef。
- SQLite/JSON/row异常只返回不包含配置文字、URL、Header、credentialRef或SQL的`DomainFailure(databaseCorrupted)`。

## 安全与不在本批

- 数据库只保存`credentialRef`；本批不读取、接收、序列化或记录`SensitiveCredential`值。
- 不实现SecureCredentialGateway、不选择安全存储插件，不实现REST Adapter、测试连接、认证、网络搜索或流URL解析。
- 不修改v1 Schema/快照，不新增依赖、原生包、权限或Migration；不接AppBootstrap、Dev Fixture、Controller或UI。

## 出口条件

- 真实内存SQLite覆盖REST/local完整往返、规范JSON、确定watch、身份/内置保护、删除保留用户引用、损坏row脱敏和shared/owned生命周期。
- 架构测试确认Repository/mapper不导入SensitiveCredential或网络/安全存储；AppBootstrap不打开DB；v1生成代码和快照零差异。
- 全量format、strict analyze、Flutter/Node/ZIP门禁通过；独立提交、Draft PR、GitHub Android/Windows Debug与唯一一次手动APK核验均绑定目标实现commit。
