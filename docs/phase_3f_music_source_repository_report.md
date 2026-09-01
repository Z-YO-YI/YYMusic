# Phase 3F — Drift MusicSourceRepository 报告

2026-09-01。开始前已fetch并确认`feat/lyrics-repository-drift@607267b`与远端同步、工作树干净；从该提交创建`feat/music-source-repository-drift`，未在main/master开发。范围与出口见[计划](phase_3f_music_source_repository_plan.md)。

## 当前实际进度

本批实现第四个正式数据Repository：MusicSourceConfig与既有`music_sources`之间的严格JSON/row映射，以及`MusicSourceRepository`的watch/get/save/delete全合同。AppBootstrap/DependencyGraph仍未构造它，启动应用不会打开数据库或生成来源Fixture。SecureCredentialGateway实现、REST Adapter、Dev Fixture和Controller仍待后续独立批次。

## 公开配置、身份与删除

1. sourceId确定排序并作为稳定身份；已存sourceType/builtIn不可转换，内置来源不可删除，自定义来源删除不存在行幂等成功。
2. publicHeaders/endpoints/responseMapping按key排序为确定性JSON；返回前拒绝非对象/非字符串值并重走Domain的敏感Header、相对endpoint和受限字段路径验证。
3. REST base URL必须是无userinfo/query/fragment的绝对HTTPS；local必须无URL。auth/status/lastError枚举、非负精确延迟和UTC测试时间全部严格解码。
4. 数据库只保存不透明`credentialRef`，mapper/Repository不导入或接收SensitiveCredential；秘密值的创建、读取、更新和删除不在本批。
5. 删除自定义来源只移除配置；收藏等用户TrackRef无外键级联并继续保留。JSON、row或SQLite异常不泄露名称、URL、Header、credentialRef、SQL或路径。

## 本地验证

| 检查 | 当前结果 |
| --- | --- |
| Source定向 | 8项真实内存SQLite通过：REST完整往返/规范JSON、local内置、确定watch、身份/删除保护、引用保留、损坏row脱敏、SQLite失败与生命周期 |
| 架构边界 | Node定向通过：只有data导入Drift，Repository/mapper不导入SensitiveCredential/安全存储/网络，AppBootstrap不打开DB |
| 全量门禁 | lockfile严格复现；125文件format零改动、严格分析0问题；189项Flutter含32 Golden、29项Node、ZIP24项全部通过；代码生成/make-migrations后v1 g.dart/快照零差异 |

## 云端与限制

实现提交、Draft PR、push/PR/手动运行、Windows/Android Debug和本批APK尚待目标commit创建后独立核验；不沿用Phase3E APK冒充。本机Windows C++/Developer Mode仍受远程/UAC限制，不声称本机Windows构建或安装成功。

## 主要文件

- `lib/data/repositories/music_source_row_mapper.dart`
- `lib/data/repositories/drift_music_source_repository.dart`
- `test/unit/drift_music_source_repository_test.dart`
- 架构边界、ADR、依赖、状态与验证文档

下一批应先核验Android/Windows安全存储插件，再独立实现SecureCredentialGateway与失败边界；不把REST请求、测试连接、Controller或UI混进安全存储提交。
